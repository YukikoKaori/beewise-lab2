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

  static const String tutorSendRuleReason =
      'Chức năng gửi tin nhắn của gia sư đang chờ mở quyền trên máy chủ '
      '(firestore.rules hiện chỉ cho phép canWriteAsParent trên chats/messages).';

  static const String tutorReadRuleLimitation =
      'Đồng bộ nhóm chat và lớp học trực tiếp cho gia sư đang chờ mở quyền '
      'trên máy chủ (firestore.rules hiện giới hạn quyền đọc chats/classes cho phụ huynh).';

  Future<TutorApplicationData> _requireAuthorizedTutor(String tutorUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null ||
        tutorUid.trim().isEmpty ||
        currentUid != tutorUid) {
      throw const TutorUnauthorizedException(
        'Phiên đăng nhập gia sư không hợp lệ hoặc đã thay đổi.',
      );
    }
    final app = await _applicationService.getApplicationData(tutorUid);
    if (app == null || !app.isAuthorizedTutor) {
      throw const TutorUnauthorizedException(
        'Tài khoản gia sư chưa được duyệt đầy đủ hoặc chưa kích hoạt.',
      );
    }
    return app;
  }

  @override
  Stream<TutorDashboardData> watchDashboard(String tutorUid) async* {
    await _requireAuthorizedTutor(tutorUid);

    List<TutorChatSummary> chats = const [];
    List<TutorClassRecord> classes = const [];
    String? ruleLimitation;

    try {
      final chatSnap = await _firestore
          .collection('chats')
          .where('tutorId', isEqualTo: tutorUid)
          .get();
      chats = chatSnap.docs
          .map((d) => TutorChatSummary.fromMap(d.id, d.data()))
          .where((c) => c.tutorId == tutorUid)
          .toList(growable: false);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        ruleLimitation = tutorReadRuleLimitation;
      } else {
        rethrow;
      }
    }

    try {
      final classSnap = await _firestore
          .collection('classes')
          .where('tutorId', isEqualTo: tutorUid)
          .get();
      classes = classSnap.docs
          .map((d) => TutorClassRecord.fromMap(d.id, d.data()))
          .where((c) => c.tutorId == tutorUid)
          .toList(growable: false);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        ruleLimitation = tutorReadRuleLimitation;
      } else {
        rethrow;
      }
    }

    final sessions = <TutorLessonSession>[
      for (final cls in classes.where((c) => c.isPaymentVerified))
        ...cls.sessions.where((s) => s.tutorId == tutorUid),
    ]..sort((a, b) => a.startTime.compareTo(b.startTime));

    yield TutorDashboardData(
      chats: chats,
      upcomingSessions: List.unmodifiable(sessions),
      activeClasses: List.unmodifiable(classes),
      backendAccessLimitation: ruleLimitation,
    );
  }

  @override
  Stream<List<TutorChatSummary>> watchTutorChats(String tutorUid) async* {
    await _requireAuthorizedTutor(tutorUid);
    try {
      final snap = await _firestore
          .collection('chats')
          .where('tutorId', isEqualTo: tutorUid)
          .get();
      yield snap.docs
          .map((d) => TutorChatSummary.fromMap(d.id, d.data()))
          .where((c) => c.tutorId == tutorUid)
          .toList(growable: false);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        yield const <TutorChatSummary>[];
        return;
      }
      rethrow;
    }
  }

  @override
  Stream<TutorChatSession> watchTutorChatSession(
    String tutorUid,
    String chatId,
  ) async* {
    await _requireAuthorizedTutor(tutorUid);
    final normalizedId = chatId.trim();
    if (!_safeResourceIdPattern.hasMatch(normalizedId)) {
      throw const TutorResourceNotFoundException(
        'Mã nhóm chat không hợp lệ hoặc không tồn tại.',
      );
    }

    DocumentSnapshot<Map<String, dynamic>> chatDoc;
    try {
      chatDoc = await _firestore.collection('chats').doc(normalizedId).get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const TutorBackendRulesDependencyException(
          'Quyền đọc nhóm chat từ tài khoản gia sư chưa được mở trong '
          'firestore.rules (hiện chỉ cho phép isParent đọc chats/{chatId}).',
        );
      }
      rethrow;
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
        'Bạn không có quyền truy cập nhóm chat của gia sư khác.',
      );
    }

    try {
      await for (final msgSnap
          in _firestore
              .collection('chats')
              .doc(normalizedId)
              .collection('messages')
              .orderBy('createdAt')
              .snapshots()) {
        final messages = msgSnap.docs
            .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
            .toList(growable: false);
        yield TutorChatSession(
          summary: summary,
          messages: messages,
          canSendMessages: false,
          sendDisabledReason: tutorSendRuleReason,
        );
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const TutorBackendRulesDependencyException(
          'Quyền đọc tin nhắn nhóm chat từ tài khoản gia sư chưa được mở '
          'trong firestore.rules.',
        );
      }
      rethrow;
    }
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
      rethrow;
    }
  }

  @override
  Stream<TutorClassRecord> watchTutorClass(
    String tutorUid,
    String classId,
  ) async* {
    await _requireAuthorizedTutor(tutorUid);
    final normalizedId = classId.trim();
    if (!_safeResourceIdPattern.hasMatch(normalizedId)) {
      throw const TutorResourceNotFoundException(
        'Mã lớp học không hợp lệ hoặc không tồn tại.',
      );
    }

    try {
      await for (final doc
          in _firestore.collection('classes').doc(normalizedId).snapshots()) {
        if (!doc.exists) {
          throw const TutorResourceNotFoundException(
            'Không tìm thấy lớp học này.',
          );
        }
        final record = TutorClassRecord.fromMap(doc.id, doc.data() ?? const {});
        if (record.tutorId != tutorUid) {
          throw const TutorUnauthorizedException(
            'Bạn không có quyền truy cập lớp học của gia sư khác.',
          );
        }
        yield record;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const TutorBackendRulesDependencyException(
          'Quyền đọc chi tiết lớp học từ tài khoản gia sư chưa được mở trong '
          'firestore.rules (hiện chỉ cho phép isParent khi paymentStatus == verified).',
        );
      }
      rethrow;
    }
  }

  @override
  Stream<List<TutorLessonSession>> watchTutorSchedule(String tutorUid) async* {
    await _requireAuthorizedTutor(tutorUid);
    try {
      final snap = await _firestore
          .collection('classes')
          .where('tutorId', isEqualTo: tutorUid)
          .where('paymentStatus', isEqualTo: 'verified')
          .get();
      final classes = snap.docs
          .map((d) => TutorClassRecord.fromMap(d.id, d.data()))
          .where((c) => c.tutorId == tutorUid && c.isPaymentVerified)
          .toList(growable: false);
      final sessions = <TutorLessonSession>[
        for (final cls in classes)
          ...cls.sessions.where((s) => s.tutorId == tutorUid),
      ]..sort((a, b) => a.startTime.compareTo(b.startTime));
      yield List.unmodifiable(sessions);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        yield const <TutorLessonSession>[];
        return;
      }
      rethrow;
    }
  }

  @override
  Stream<TutorProfileViewData> watchTutorProfile(String tutorUid) async* {
    await _requireAuthorizedTutor(tutorUid);
    await for (final app in _applicationService.watchApplicationData(
      tutorUid,
    )) {
      if (app == null || !app.isAuthorizedTutor) {
        throw const TutorUnauthorizedException(
          'Hồ sơ gia sư không còn ở trạng thái hoạt động hợp lệ.',
        );
      }
      Tutor? publicProfile;
      try {
        final tutorDoc = await _firestore
            .collection('tutors')
            .doc(tutorUid)
            .get();
        if (tutorDoc.exists) {
          publicProfile = Tutor.fromMap(
            tutorDoc.id,
            tutorDoc.data() ?? const {},
          );
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          rethrow;
        }
      }
      yield TutorProfileViewData(
        application: app,
        publicCatalogProfile: publicProfile,
      );
    }
  }

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
      return null;
    }
    final route = rawRoute?.trim();
    if (route == null || route.isEmpty) return null;

    final uri = Uri.tryParse(route);
    if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
    final path = uri.path;

    if (const {
      '/tutor',
      '/tutor/schedule',
      '/tutor/chats',
      '/tutor/profile',
      '/tutor/notifications',
      '/tutor/pending',
    }.contains(path)) {
      return path;
    }

    final segments = uri.pathSegments;
    if (segments.length == 3 &&
        segments[0] == 'tutor' &&
        segments[1] == 'chats') {
      final chatId = segments[2];
      if (!_safeResourceIdPattern.hasMatch(chatId)) return null;
      try {
        final doc = await _firestore.collection('chats').doc(chatId).get();
        if (!doc.exists) return null;
        if (doc.data()?['tutorId'] != tutorUid) return null;
        return '/tutor/chats/$chatId';
      } catch (_) {
        return null;
      }
    }

    if (segments.length == 3 &&
        segments[0] == 'tutor' &&
        segments[1] == 'class') {
      final classId = segments[2];
      if (!_safeResourceIdPattern.hasMatch(classId)) return null;
      try {
        final doc = await _firestore.collection('classes').doc(classId).get();
        if (!doc.exists) return null;
        if (doc.data()?['tutorId'] != tutorUid) return null;
        return '/tutor/class/$classId';
      } catch (_) {
        return null;
      }
    }

    return null;
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
  }) async => null;
}
