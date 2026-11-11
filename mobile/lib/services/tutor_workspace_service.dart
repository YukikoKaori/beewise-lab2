import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';
import '../models/tutor.dart';
import '../models/tutor_workspace_models.dart';
import 'tutor_application_service.dart';

final RegExp _safeResourceIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

abstract interface class TutorWorkspaceService {
  Stream<TutorDashboardData> watchDashboard(String tutorUid);

  Stream<List<TutorChatSummary>> watchTutorChats(String tutorUid);

  Stream<TutorChatSession> watchTutorChatSession(
    String tutorUid,
    String chatId,
  );

  Future<void> sendTutorMessage({
    required String tutorUid,
    required String chatId,
    required String body,
  });

  Stream<TutorClassRecord> watchTutorClass(String tutorUid, String classId);

  Stream<List<TutorLessonSession>> watchTutorSchedule(String tutorUid);

  Stream<TutorProfileViewData> watchTutorProfile(String tutorUid);

  Future<String?> validateTutorNotificationRoute(
    String tutorUid,
    String? rawRoute, {
    String? recipientUid,
  });
}

class FirebaseTutorWorkspaceService implements TutorWorkspaceService {
  FirebaseTutorWorkspaceService(
    this._firestore,
    this._auth,
    this._applicationService,
  );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TutorApplicationService _applicationService;

  static const String tutorRulesBlockedMessage =
      'Chức năng này chưa được cấp quyền đồng bộ cho tài khoản gia sư. Vui lòng liên hệ BeeWise.';

  static const String tutorReadRuleLimitation = tutorRulesBlockedMessage;

  static const String tutorSendRuleReason =
      'Trao đổi trong nhóm hiện do tư vấn viên BeeWise điều phối. '
      'Tính năng nhắn tin dành cho gia sư sẽ được mở sau.';

  String? get _currentAuthUid {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    return user.uid;
  }

  static Object mapFirestoreError(Object error) {
    if (error is TutorUnauthorizedException ||
        error is TutorResourceNotFoundException ||
        error is TutorBackendRulesDependencyException ||
        error is TutorNetworkException) {
      return error;
    }
    if (error is TimeoutException) {
      return const TutorNetworkException(
        'Không kết nối được dịch vụ. Hãy kiểm tra mạng rồi thử lại.',
      );
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => const TutorBackendRulesDependencyException(
          tutorRulesBlockedMessage,
        ),
        'unauthenticated' => const TutorUnauthorizedException(
          'Phiên đăng nhập gia sư không hợp lệ hoặc đã hết hạn.',
        ),
        'not-found' => const TutorResourceNotFoundException(
          'Không tìm thấy dữ liệu được yêu cầu.',
        ),
        'unavailable' ||
        'network-request-failed' ||
        'deadline-exceeded' => const TutorNetworkException(
          'Không kết nối được dịch vụ. Hãy kiểm tra mạng rồi thử lại.',
        ),
        _ => error,
      };
    }
    return error;
  }

  Future<TutorApplicationData> _requireAuthorizedTutor(String tutorUid) async {
    final currentUid = _currentAuthUid;
    if (currentUid == null ||
        tutorUid.trim().isEmpty ||
        currentUid != tutorUid) {
      throw const TutorUnauthorizedException(
        'Phiên đăng nhập gia sư không hợp lệ hoặc đã thay đổi.',
      );
    }
    final TutorApplicationData? app;
    try {
      app = await _applicationService.getApplicationData(tutorUid);
    } catch (error) {
      Error.throwWithStackTrace(mapFirestoreError(error), StackTrace.current);
    }
    if (_currentAuthUid != tutorUid) {
      throw const TutorUnauthorizedException(
        'Phiên đăng nhập gia sư đã thay đổi.',
      );
    }
    if (app == null || !app.isAuthorizedTutor) {
      throw const TutorUnauthorizedException(
        'Tài khoản gia sư chưa được duyệt đầy đủ hoặc chưa kích hoạt.',
      );
    }
    return app;
  }

  /// Guards any tutor workspace stream with live authentication and
  /// `tutorApplications/{tutorUid}` authorization checks.
  ///
  /// - Immediately cancels inner Firestore subscriptions on logout, account
  ///   switch (`User A -> User B`), or tutor role revocation.
  /// - Translates `permission-denied` to [TutorBackendRulesDependencyException]
  ///   and network errors to [TutorNetworkException].
  Stream<T> _guardAuthorizedTutorStream<T>(
    String tutorUid,
    Stream<T> Function(Stream<TutorApplicationData> appStream) buildStream,
  ) {
    if (tutorUid.trim().isEmpty || _currentAuthUid != tutorUid) {
      return Stream<T>.error(
        const TutorUnauthorizedException(
          'Phiên đăng nhập gia sư không hợp lệ hoặc đã thay đổi.',
        ),
      );
    }

    late final StreamController<T> controller;
    final appBroadcast = StreamController<TutorApplicationData>.broadcast();
    StreamSubscription<User?>? authSub;
    StreamSubscription<TutorApplicationData?>? appSub;
    StreamSubscription<T>? innerSub;
    TutorApplicationData? latestApp;

    Future<void> cancelAll() async {
      final toCancelInner = innerSub;
      final toCancelApp = appSub;
      final toCancelAuth = authSub;
      innerSub = null;
      appSub = null;
      authSub = null;
      await toCancelInner?.cancel();
      await toCancelApp?.cancel();
      await toCancelAuth?.cancel();
      if (!appBroadcast.isClosed) {
        await appBroadcast.close();
      }
    }

    controller = StreamController<T>(
      onListen: () {
        if (_currentAuthUid != tutorUid) {
          controller.addError(
            const TutorUnauthorizedException(
              'Phiên đăng nhập gia sư không hợp lệ hoặc đã thay đổi.',
            ),
          );
          unawaited(controller.close());
          return;
        }

        authSub = _auth.authStateChanges().listen((user) {
          final activeUid = user?.isAnonymous == false ? user!.uid : null;
          if (activeUid != tutorUid && !controller.isClosed) {
            latestApp = null;
            unawaited(innerSub?.cancel());
            innerSub = null;
            controller.addError(
              const TutorUnauthorizedException(
                'Phiên đăng nhập gia sư đã thay đổi.',
              ),
            );
            unawaited(cancelAll());
            unawaited(controller.close());
          }
        });

        appSub = _applicationService
            .watchApplicationData(tutorUid)
            .listen(
              (app) {
                if (controller.isClosed) return;
                if (_currentAuthUid != tutorUid) {
                  latestApp = null;
                  unawaited(innerSub?.cancel());
                  innerSub = null;
                  controller.addError(
                    const TutorUnauthorizedException(
                      'Phiên đăng nhập gia sư đã thay đổi.',
                    ),
                  );
                  unawaited(cancelAll());
                  unawaited(controller.close());
                  return;
                }

                if (app == null || !app.isAuthorizedTutor) {
                  latestApp = null;
                  final prevInner = innerSub;
                  innerSub = null;
                  unawaited(prevInner?.cancel());
                  controller.addError(
                    const TutorUnauthorizedException(
                      'Tài khoản gia sư chưa được duyệt đầy đủ hoặc quyền truy cập đã bị thu hồi.',
                    ),
                  );
                  return;
                }

                latestApp = app;

                // Subscribe the inner stream BEFORE emitting on the broadcast
                // controller; otherwise the first application snapshot is lost
                // and consumers of `appStream` never receive it.
                innerSub ??= buildStream(appBroadcast.stream).listen(
                  (data) {
                    if (controller.isClosed) return;
                    if (_currentAuthUid != tutorUid ||
                        latestApp == null ||
                        !latestApp!.isAuthorizedTutor) {
                      controller.addError(
                        const TutorUnauthorizedException(
                          'Quyền truy cập gia sư không còn hiệu lực.',
                        ),
                      );
                      return;
                    }
                    controller.add(data);
                  },
                  onError: (Object error, StackTrace stack) {
                    if (controller.isClosed) return;
                    controller.addError(mapFirestoreError(error), stack);
                  },
                );

                if (!appBroadcast.isClosed) {
                  appBroadcast.add(app);
                }
              },
              onError: (Object error, StackTrace stack) {
                if (controller.isClosed) return;
                latestApp = null;
                final prevInner = innerSub;
                innerSub = null;
                unawaited(prevInner?.cancel());
                controller.addError(mapFirestoreError(error), stack);
              },
            );
      },
      onCancel: cancelAll,
    );

    return controller.stream;
  }

  @override
  Stream<TutorDashboardData> watchDashboard(
    String tutorUid,
  ) => _guardAuthorizedTutorStream(tutorUid, (_) {
    late final StreamController<TutorDashboardData> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? chatSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? classSub;

    var chatSettled = false;
    var classSettled = false;
    List<TutorChatSummary> chats = const [];
    List<TutorClassRecord> classes = const [];
    var chatsState = TutorDataSourceState.loading;
    var classesState = TutorDataSourceState.loading;

    void emitIfReady() {
      if (!chatSettled || !classSettled || controller.isClosed) return;

      if (chatsState == TutorDataSourceState.rulesBlocked &&
          classesState == TutorDataSourceState.rulesBlocked) {
        controller.addError(
          const TutorBackendRulesDependencyException(tutorRulesBlockedMessage),
        );
        return;
      }

      final sessions = <TutorLessonSession>[
        for (final cls in classes.where((c) => c.isPaymentVerified))
          ...cls.sessions.where((s) => s.tutorId == tutorUid),
      ]..sort((a, b) => a.startTime.compareTo(b.startTime));

      final hasRulesBlock =
          chatsState == TutorDataSourceState.rulesBlocked ||
          classesState == TutorDataSourceState.rulesBlocked;

      controller.add(
        TutorDashboardData(
          tutorUid: tutorUid,
          chats: List.unmodifiable(chats),
          upcomingSessions: List.unmodifiable(sessions),
          activeClasses: List.unmodifiable(classes),
          chatsState: chatsState,
          classesState: classesState,
          chatsBlockMessage: chatsState == TutorDataSourceState.rulesBlocked
              ? tutorRulesBlockedMessage
              : null,
          classesBlockMessage: classesState == TutorDataSourceState.rulesBlocked
              ? tutorRulesBlockedMessage
              : null,
          backendAccessLimitation: hasRulesBlock
              ? tutorRulesBlockedMessage
              : null,
        ),
      );
    }

    controller = StreamController<TutorDashboardData>(
      onListen: () {
        chatSub = _firestore
            .collection('chats')
            .where('tutorId', isEqualTo: tutorUid)
            .snapshots()
            .listen(
              (snap) {
                chats = snap.docs
                    .map((d) => TutorChatSummary.fromMap(d.id, d.data()))
                    .where((c) => c.tutorId == tutorUid)
                    .toList(growable: false);
                chatsState = chats.isEmpty
                    ? TutorDataSourceState.emptyVerified
                    : TutorDataSourceState.populated;
                chatSettled = true;
                emitIfReady();
              },
              onError: (Object error, StackTrace stack) {
                if (classifyTutorDataError(error) ==
                    TutorDataSourceState.rulesBlocked) {
                  chats = const [];
                  chatsState = TutorDataSourceState.rulesBlocked;
                  chatSettled = true;
                  emitIfReady();
                } else if (!controller.isClosed) {
                  controller.addError(mapFirestoreError(error), stack);
                }
              },
            );

        classSub = _firestore
            .collection('classes')
            .where('tutorId', isEqualTo: tutorUid)
            .snapshots()
            .listen(
              (snap) {
                classes = snap.docs
                    .map((d) => TutorClassRecord.fromMap(d.id, d.data()))
                    .where((c) => c.tutorId == tutorUid)
                    .toList(growable: false);
                classesState = classes.isEmpty
                    ? TutorDataSourceState.emptyVerified
                    : TutorDataSourceState.populated;
                classSettled = true;
                emitIfReady();
              },
              onError: (Object error, StackTrace stack) {
                if (classifyTutorDataError(error) ==
                    TutorDataSourceState.rulesBlocked) {
                  classes = const [];
                  classesState = TutorDataSourceState.rulesBlocked;
                  classSettled = true;
                  emitIfReady();
                } else if (!controller.isClosed) {
                  controller.addError(mapFirestoreError(error), stack);
                }
              },
            );
      },
      onCancel: () async {
        await chatSub?.cancel();
        await classSub?.cancel();
      },
    );

    return controller.stream;
  });

  @override
  Stream<List<TutorChatSummary>> watchTutorChats(String tutorUid) =>
      _guardAuthorizedTutorStream(
        tutorUid,
        (_) => _firestore
            .collection('chats')
            .where('tutorId', isEqualTo: tutorUid)
            .snapshots()
            .map(
              (snap) => snap.docs
                  .map((d) => TutorChatSummary.fromMap(d.id, d.data()))
                  .where((c) => c.tutorId == tutorUid)
                  .toList(growable: false),
            ),
      );

  @override
  Stream<TutorChatSession> watchTutorChatSession(
    String tutorUid,
    String chatId,
  ) {
    final normalizedId = chatId.trim();
    if (!_safeResourceIdPattern.hasMatch(normalizedId)) {
      return Stream.error(
        const TutorResourceNotFoundException(
          'Mã nhóm chat không hợp lệ hoặc không tồn tại.',
        ),
      );
    }

    return _guardAuthorizedTutorStream(tutorUid, (_) {
      late final StreamController<TutorChatSession> controller;
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? chatSub;
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? msgSub;
      TutorChatSummary? latestSummary;
      List<ChatMessage>? latestMessages;

      void emitSessionIfReady() {
        if (latestSummary == null ||
            latestMessages == null ||
            controller.isClosed) {
          return;
        }
        controller.add(
          TutorChatSession(
            summary: latestSummary!,
            messages: latestMessages!,
            canSendMessages: false,
            sendDisabledReason: tutorSendRuleReason,
          ),
        );
      }

      controller = StreamController<TutorChatSession>(
        onListen: () {
          chatSub = _firestore
              .collection('chats')
              .doc(normalizedId)
              .snapshots()
              .listen(
                (chatDoc) {
                  if (controller.isClosed) return;
                  if (!chatDoc.exists) {
                    latestSummary = null;
                    unawaited(msgSub?.cancel());
                    msgSub = null;
                    controller.addError(
                      const TutorResourceNotFoundException(
                        'Không tìm thấy nhóm chat này.',
                      ),
                    );
                    return;
                  }

                  final summary = TutorChatSummary.fromMap(
                    chatDoc.id,
                    chatDoc.data() ?? const {},
                  );
                  if (summary.tutorId != tutorUid) {
                    latestSummary = null;
                    unawaited(msgSub?.cancel());
                    msgSub = null;
                    controller.addError(
                      const TutorUnauthorizedException(
                        'Bạn không có quyền truy cập nhóm chat của gia sư khác.',
                      ),
                    );
                    return;
                  }

                  latestSummary = summary;
                  emitSessionIfReady();

                  msgSub ??= _firestore
                      .collection('chats')
                      .doc(normalizedId)
                      .collection('messages')
                      .orderBy('createdAt')
                      .snapshots()
                      .listen(
                        (msgSnap) {
                          latestMessages = msgSnap.docs
                              .map((doc) {
                                // Firestore returns a Timestamp; ChatMessage
                                // expects a DateTime (same as the parent chat).
                                final data = Map<String, dynamic>.from(
                                  doc.data(),
                                );
                                final createdAt = data['createdAt'];
                                if (createdAt is Timestamp) {
                                  data['createdAt'] = createdAt.toDate();
                                }
                                return ChatMessage.fromMap(doc.id, data);
                              })
                              .toList(growable: false);
                          emitSessionIfReady();
                        },
                        onError: (Object error, StackTrace stack) {
                          if (!controller.isClosed) {
                            controller.addError(
                              mapFirestoreError(error),
                              stack,
                            );
                          }
                        },
                      );
                },
                onError: (Object error, StackTrace stack) {
                  latestSummary = null;
                  unawaited(msgSub?.cancel());
                  msgSub = null;
                  if (!controller.isClosed) {
                    controller.addError(mapFirestoreError(error), stack);
                  }
                },
              );
        },
        onCancel: () async {
          await msgSub?.cancel();
          await chatSub?.cancel();
        },
      );

      return controller.stream;
    });
  }

  @override
  Future<void> sendTutorMessage({
    required String tutorUid,
    required String chatId,
    required String body,
  }) async {
    await _requireAuthorizedTutor(tutorUid);
    final normalizedId = chatId.trim();
    if (!_safeResourceIdPattern.hasMatch(normalizedId)) {
      throw const TutorResourceNotFoundException('Mã nhóm chat không hợp lệ.');
    }
    final trimmed = body.trim();
    if (trimmed.isEmpty || trimmed.length > 1000) {
      throw const FormatException('Tin nhắn cần từ 1 đến 1.000 ký tự.');
    }

    try {
      final chatDoc = await _firestore
          .collection('chats')
          .doc(normalizedId)
          .get();
      if (_currentAuthUid != tutorUid) {
        throw const TutorUnauthorizedException(
          'Phiên đăng nhập gia sư đã thay đổi.',
        );
      }
      if (!chatDoc.exists) {
        throw const TutorResourceNotFoundException(
          'Không tìm thấy nhóm chat này.',
        );
      }
      final summary = TutorChatSummary.fromMap(
        chatDoc.id,
        chatDoc.data() ?? const {},
      );
      if (summary.tutorId != tutorUid) {
        throw const TutorUnauthorizedException(
          'Bạn không thuộc nhóm chat này.',
        );
      }

      await _firestore
          .collection('chats')
          .doc(normalizedId)
          .collection('messages')
          .add({
            'senderId': tutorUid,
            'senderRole': 'tutor',
            'type': 'text',
            'body': trimmed,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const TutorBackendRulesDependencyException(tutorSendRuleReason);
      }
      Error.throwWithStackTrace(mapFirestoreError(e), StackTrace.current);
    }
  }

  @override
  Stream<TutorClassRecord> watchTutorClass(String tutorUid, String classId) {
    final normalizedId = classId.trim();
    if (!_safeResourceIdPattern.hasMatch(normalizedId)) {
      return Stream.error(
        const TutorResourceNotFoundException(
          'Mã lớp học không hợp lệ hoặc không tồn tại.',
        ),
      );
    }

    return _guardAuthorizedTutorStream(
      tutorUid,
      (_) => _firestore.collection('classes').doc(normalizedId).snapshots().map(
        (doc) {
          if (!doc.exists) {
            throw const TutorResourceNotFoundException(
              'Không tìm thấy lớp học này.',
            );
          }
          final record = TutorClassRecord.fromMap(
            doc.id,
            doc.data() ?? const {},
          );
          if (record.tutorId != tutorUid) {
            throw const TutorUnauthorizedException(
              'Bạn không có quyền truy cập lớp học của gia sư khác.',
            );
          }
          return record;
        },
      ),
    );
  }

  @override
  Stream<List<TutorLessonSession>> watchTutorSchedule(String tutorUid) =>
      _guardAuthorizedTutorStream(
        tutorUid,
        (_) => _firestore
            .collection('classes')
            .where('tutorId', isEqualTo: tutorUid)
            .where('paymentStatus', isEqualTo: 'verified')
            .snapshots()
            .map((snap) {
              final classes = snap.docs
                  .map((d) => TutorClassRecord.fromMap(d.id, d.data()))
                  .where((c) => c.tutorId == tutorUid && c.isPaymentVerified)
                  .toList(growable: false);
              final sessions = <TutorLessonSession>[
                for (final cls in classes)
                  ...cls.sessions.where((s) => s.tutorId == tutorUid),
              ]..sort((a, b) => a.startTime.compareTo(b.startTime));
              return List.unmodifiable(sessions);
            }),
      );

  @override
  Stream<TutorProfileViewData> watchTutorProfile(String tutorUid) =>
      _guardAuthorizedTutorStream(tutorUid, (appStream) {
        late final StreamController<TutorProfileViewData> controller;
        StreamSubscription<TutorApplicationData>? appSub;
        StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? tutorSub;

        TutorApplicationData? latestApp;
        Tutor? publicProfile;
        var catalogSettled = false;
        var catalogState = TutorDataSourceState.loading;

        void emitIfReady() {
          if (latestApp == null || !catalogSettled || controller.isClosed) {
            return;
          }
          controller.add(
            TutorProfileViewData(
              application: latestApp!,
              publicCatalogProfile: publicProfile,
              publicCatalogState: catalogState,
            ),
          );
        }

        controller = StreamController<TutorProfileViewData>(
          onListen: () {
            appSub = appStream.listen((app) {
              latestApp = app;
              emitIfReady();
            });

            tutorSub = _firestore
                .collection('tutors')
                .doc(tutorUid)
                .snapshots()
                .listen(
                  (doc) {
                    if (doc.exists) {
                      publicProfile = Tutor.fromMap(
                        doc.id,
                        doc.data() ?? const {},
                      );
                      catalogState = TutorDataSourceState.populated;
                    } else {
                      publicProfile = null;
                      catalogState = TutorDataSourceState.emptyVerified;
                    }
                    catalogSettled = true;
                    emitIfReady();
                  },
                  onError: (Object error, StackTrace stack) {
                    if (classifyTutorDataError(error) ==
                        TutorDataSourceState.rulesBlocked) {
                      publicProfile = null;
                      catalogState = TutorDataSourceState.rulesBlocked;
                      catalogSettled = true;
                      emitIfReady();
                    } else if (!controller.isClosed) {
                      controller.addError(mapFirestoreError(error), stack);
                    }
                  },
                );
          },
          onCancel: () async {
            await tutorSub?.cancel();
            await appSub?.cancel();
          },
        );

        return controller.stream;
      });

  @override
  Future<String?> validateTutorNotificationRoute(
    String tutorUid,
    String? rawRoute, {
    String? recipientUid,
  }) async {
    await _requireAuthorizedTutor(tutorUid);
    if (recipientUid != null &&
        recipientUid.trim().isNotEmpty &&
        recipientUid != tutorUid) {
      throw const TutorUnauthorizedException(
        'Thông báo này không thuộc tài khoản gia sư hiện tại.',
      );
    }
    final route = rawRoute?.trim();
    if (route == null || route.isEmpty) {
      throw const TutorResourceNotFoundException(
        'Thông báo không có đường dẫn chi tiết.',
      );
    }

    final uri = Uri.tryParse(route);
    if (uri == null || uri.hasScheme || uri.hasAuthority) {
      throw const TutorResourceNotFoundException(
        'Liên kết thông báo không hợp lệ.',
      );
    }
    final path = uri.path;

    if (const {
      '/tutor',
      '/tutor/home',
      '/tutor/schedule',
      '/tutor/chats',
      '/tutor/profile',
      '/tutor/notifications',
      '/tutor/pending',
    }.contains(path)) {
      return path == '/tutor' ? '/tutor/home' : path;
    }

    final segments = uri.pathSegments;
    if (segments.length == 3 &&
        segments[0] == 'tutor' &&
        segments[1] == 'chats') {
      final chatId = segments[2];
      if (!_safeResourceIdPattern.hasMatch(chatId)) {
        throw const TutorResourceNotFoundException(
          'Mã nhóm chat trong thông báo không hợp lệ.',
        );
      }
      try {
        final doc = await _firestore.collection('chats').doc(chatId).get();
        if (_currentAuthUid != tutorUid) {
          throw const TutorUnauthorizedException(
            'Phiên đăng nhập gia sư đã thay đổi.',
          );
        }
        if (!doc.exists) {
          throw const TutorResourceNotFoundException(
            'Không tìm thấy nhóm chat này.',
          );
        }
        if (doc.data()?['tutorId'] != tutorUid) {
          throw const TutorUnauthorizedException(
            'Bạn không có quyền truy cập nhóm chat của gia sư khác.',
          );
        }
        return '/tutor/chats/$chatId';
      } catch (error) {
        Error.throwWithStackTrace(mapFirestoreError(error), StackTrace.current);
      }
    }

    if (segments.length == 3 &&
        segments[0] == 'tutor' &&
        segments[1] == 'class') {
      final classId = segments[2];
      if (!_safeResourceIdPattern.hasMatch(classId)) {
        throw const TutorResourceNotFoundException(
          'Mã lớp học trong thông báo không hợp lệ.',
        );
      }
      try {
        final doc = await _firestore.collection('classes').doc(classId).get();
        if (_currentAuthUid != tutorUid) {
          throw const TutorUnauthorizedException(
            'Phiên đăng nhập gia sư đã thay đổi.',
          );
        }
        if (!doc.exists) {
          throw const TutorResourceNotFoundException(
            'Không tìm thấy lớp học này.',
          );
        }
        if (doc.data()?['tutorId'] != tutorUid) {
          throw const TutorUnauthorizedException(
            'Bạn không có quyền truy cập lớp học của gia sư khác.',
          );
        }
        return '/tutor/class/$classId';
      } catch (error) {
        Error.throwWithStackTrace(mapFirestoreError(error), StackTrace.current);
      }
    }

    throw const TutorResourceNotFoundException(
      'Liên kết thông báo không được hỗ trợ.',
    );
  }
}

class UnavailableTutorWorkspaceService implements TutorWorkspaceService {
  const UnavailableTutorWorkspaceService();

  @override
  Stream<TutorDashboardData> watchDashboard(String tutorUid) => Stream.error(
    const TutorUnauthorizedException('Dịch vụ gia sư chưa sẵn sàng.'),
  );

  @override
  Stream<List<TutorChatSummary>> watchTutorChats(String tutorUid) =>
      Stream.error(
        const TutorUnauthorizedException('Dịch vụ gia sư chưa sẵn sàng.'),
      );

  @override
  Stream<TutorChatSession> watchTutorChatSession(
    String tutorUid,
    String chatId,
  ) => Stream.error(
    const TutorUnauthorizedException('Dịch vụ gia sư chưa sẵn sàng.'),
  );

  @override
  Future<void> sendTutorMessage({
    required String tutorUid,
    required String chatId,
    required String body,
  }) => Future.error(
    const TutorUnauthorizedException('Dịch vụ gia sư chưa sẵn sàng.'),
  );

  @override
  Stream<TutorClassRecord> watchTutorClass(String tutorUid, String classId) =>
      Stream.error(
        const TutorUnauthorizedException('Dịch vụ gia sư chưa sẵn sàng.'),
      );

  @override
  Stream<List<TutorLessonSession>> watchTutorSchedule(String tutorUid) =>
      Stream.error(
        const TutorUnauthorizedException('Dịch vụ gia sư chưa sẵn sàng.'),
      );

  @override
  Stream<TutorProfileViewData> watchTutorProfile(String tutorUid) =>
      Stream.error(
        const TutorUnauthorizedException('Dịch vụ gia sư chưa sẵn sàng.'),
      );

  @override
  Future<String?> validateTutorNotificationRoute(
    String tutorUid,
    String? rawRoute, {
    String? recipientUid,
  }) async =>
      throw const TutorUnauthorizedException('Dịch vụ gia sư chưa sẵn sàng.');
}
