import 'dart:async';

import 'package:beewise_core/beewise_core.dart' as core;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/tutor.dart';
import '../models/chat_message.dart';
import '../models/chat_preview.dart';
import '../models/tutor_workspace_models.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/crash_reporting_service.dart';
import '../services/export_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/matching_service.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';
import '../services/server_notification_service.dart';
import '../services/tutor_application_api.dart';
import '../services/tutor_application_service.dart';
import '../services/tutor_repository.dart';
import '../services/tutor_workspace_service.dart';
import '../services/payment_api.dart';
import '../services/workflow_service.dart';

final firebaseReadyProvider = Provider<bool>((ref) => FirebaseBootstrap.ready);
final firebaseSetupErrorProvider = Provider<Object?>(
  (ref) => FirebaseBootstrap.initializationError,
);

final remoteConfigProvider = Provider<RemoteConfigService>(
  (ref) => RemoteConfigService(
    ref.watch(firebaseReadyProvider) &&
            !usesFirebaseEmulators &&
            Firebase.apps.isNotEmpty
        ? FirebaseRemoteConfig.instance
        : null,
  ),
);

final remoteConfigInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(remoteConfigProvider).initialize();
  ref.invalidate(activeTutorsProvider);
});

final analyticsPreferenceStoreProvider = Provider<AnalyticsPreferenceStore>(
  (ref) => const SharedPreferencesAnalyticsStore(),
);

final analyticsSdkGatewayProvider = Provider<AnalyticsSdkGateway?>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  if (!ready || Firebase.apps.isEmpty) return null;
  return FirebaseAnalyticsSdkGateway(FirebaseAnalytics.instance);
});

final analyticsPrivacyPolicyPermitsProvider = Provider<bool>(
  (ref) => FirebaseBootstrap.analyticsPolicyPermits,
);

final analyticsInstanceProvider = Provider<FirebaseAnalytics?>(
  (ref) =>
      ref.watch(firebaseReadyProvider) &&
          !usesFirebaseEmulators &&
          Firebase.apps.isNotEmpty
      ? FirebaseAnalytics.instance
      : null,
);

final analyticsPrivacyProvider =
    NotifierProvider<AnalyticsPrivacyNotifier, AnalyticsPrivacyState>(
      AnalyticsPrivacyNotifier.new,
    );

/// Compatibility selector reporting whether analytics collection is suppressed
/// (`true` when opted out, policy-blocked, emulator mode, unread, or failed closed).
final analyticsOptOutProvider = Provider<bool>(
  (ref) => !ref.watch(analyticsPrivacyProvider).isCollectionEnabled,
);

class AnalyticsPrivacyNotifier extends Notifier<AnalyticsPrivacyState> {
  int _operationToken = 0;

  @override
  AnalyticsPrivacyState build() {
    final ready = ref.watch(firebaseReadyProvider);
    final policyPermits = ref.watch(analyticsPrivacyPolicyPermitsProvider);
    final store = ref.watch(analyticsPreferenceStoreProvider);
    final sdk = ref.watch(analyticsSdkGatewayProvider);

    final initial = AnalyticsPrivacyState(
      bootstrapReady: ready,
      isEmulator: usesFirebaseEmulators,
      privacyPolicyPermits: policyPermits,
      preferenceLoaded: false,
      nativeCollectionEnabled: false,
      sdkSynced: false,
    );
    unawaited(
      _reconcile(
        token: ++_operationToken,
        ready: ready,
        policyPermits: policyPermits,
        store: store,
        sdk: sdk,
      ),
    );
    return initial;
  }

  Future<void> _reconcile({
    required int token,
    required bool ready,
    required bool policyPermits,
    required AnalyticsPreferenceStore store,
    required AnalyticsSdkGateway? sdk,
  }) async {
    final reconciled = await FirebaseBootstrap.reconcileAnalyticsPrivacy(
      isEmulator: usesFirebaseEmulators,
      preferenceStore: store,
      sdkGateway: sdk,
      setAnalyticsEnabled: sdk == null && (!ready || Firebase.apps.isEmpty)
          ? (_) async {}
          : null,
      clearUserId: sdk == null && (!ready || Firebase.apps.isEmpty)
          ? () async {}
          : null,
      privacyPolicyPermits: policyPermits,
      bootstrapReady: ready,
    );
    if (!ref.mounted || token != _operationToken) return;
    state = reconciled;
  }

  Future<void> retryReconcile() async {
    if (!ref.mounted) return;
    final token = ++_operationToken;
    state = state.copyWith(isUpdating: true, clearErrorMessage: true);
    await _reconcile(
      token: token,
      ready: ref.read(firebaseReadyProvider),
      policyPermits: ref.read(analyticsPrivacyPolicyPermitsProvider),
      store: ref.read(analyticsPreferenceStoreProvider),
      sdk: ref.read(analyticsSdkGatewayProvider),
    );
  }

  Future<bool> setOptOut(bool optedOut) async {
    if (!ref.mounted) return false;
    final token = ++_operationToken;
    final ready = ref.read(firebaseReadyProvider);
    final policyPermits = ref.read(analyticsPrivacyPolicyPermitsProvider);
    final store = ref.read(analyticsPreferenceStoreProvider);
    final sdk = ref.read(analyticsSdkGatewayProvider);

    state = state.copyWith(
      isUpdating: true,
      nativeCollectionEnabled: optedOut ? false : state.nativeCollectionEnabled,
      clearErrorMessage: true,
      clearLastError: true,
    );

    try {
      final updated = await FirebaseBootstrap.setPersistedAnalyticsOptOut(
        optedOut,
        isEmulator: usesFirebaseEmulators,
        privacyPolicyPermits: policyPermits,
        bootstrapReady: ready,
        preferenceStore: store,
        sdkGateway: sdk,
        setAnalyticsEnabled: sdk == null && (!ready || Firebase.apps.isEmpty)
            ? (_) async {}
            : null,
        clearUserId: sdk == null && (!ready || Firebase.apps.isEmpty)
            ? () async {}
            : null,
      );
      if (!ref.mounted || token != _operationToken) return false;
      state = updated;
      return true;
    } on AnalyticsPrivacyException catch (error) {
      if (!ref.mounted || token != _operationToken) return false;
      state = error.state;
      return false;
    } catch (error) {
      if (!ref.mounted || token != _operationToken) return false;
      final fallback = state.copyWith(
        nativeCollectionEnabled: false,
        sdkSynced: false,
        isUpdating: false,
        failureKind: AnalyticsPrivacyFailureKind.sdkSyncFailed,
        failedOptOutIntent: optedOut,
        errorMessage: optedOut
            ? 'Không thể hoàn tất tắt thống kê. Thu thập trong ứng dụng vẫn bị khóa.'
            : 'Không thể bật thu thập thống kê. Dữ liệu vẫn đang tắt.',
        lastError: error,
      );
      FirebaseBootstrap.analyticsCollectionActive = false;
      state = fallback;
      return false;
    }
  }

  Future<bool> retryFailedAction() async {
    if (!ref.mounted) return false;
    if (state.preferenceStatus == AnalyticsPreferenceStatus.readFailed ||
        state.failureKind == AnalyticsPrivacyFailureKind.readFailed) {
      await retryReconcile();
      return !state.hasError;
    }
    final intent = state.failedOptOutIntent;
    if (intent != null) {
      return setOptOut(intent);
    }
    await retryReconcile();
    return !state.hasError;
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final privacy = ref.watch(analyticsPrivacyProvider);
  final instance = ref.watch(analyticsInstanceProvider);
  return AnalyticsService(
    analytics: instance,
    isCollectionEnabled: () =>
        privacy.isCollectionEnabled &&
        FirebaseBootstrap.analyticsCollectionActive,
  );
});

final crashReportingServiceProvider = Provider<CrashReportingService>(
  (ref) => CrashReportingService(
    crashlytics:
        ref.watch(firebaseReadyProvider) &&
            !usesFirebaseEmulators &&
            Firebase.apps.isNotEmpty
        ? FirebaseCrashlytics.instance
        : null,
  ),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => ref.watch(firebaseReadyProvider)
      ? FirebaseAuthService(FirebaseAuth.instance, FirebaseFirestore.instance)
      : const UnavailableAuthService(),
);

final tutorApplicationServiceProvider = Provider<TutorApplicationService?>(
  (ref) => ref.watch(firebaseReadyProvider)
      ? TutorApplicationService(
          FirebaseAuth.instance,
          FirebaseFirestore.instance,
          api: TutorApplicationApi(auth: FirebaseAuth.instance),
          finalAccountRoles: usesFinalFirestore,
          isResubmissionBackendAvailable: usesFinalFirestore,
        )
      : null,
);

final tutorApplicationStatusProvider = StreamProvider.family<String, String>((
  ref,
  uid,
) {
  final service = ref.watch(tutorApplicationServiceProvider);
  if (service == null) {
    return Stream.error(const FirebaseNotConfiguredException());
  }
  return service.watchStatus(uid);
});

final tutorApplicationDataProvider =
    StreamProvider.family<TutorApplicationData?, String>((ref, uid) {
      final service = ref.watch(tutorApplicationServiceProvider);
      if (service == null) {
        return Stream.error(const FirebaseNotConfiguredException());
      }
      return service.watchApplicationData(uid);
    });

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(authServiceProvider);
  final crashReporting = ref.watch(crashReportingServiceProvider);
  String? previousUid;
  User? latestUser;
  var hasUser = false;

  ref.listen<AnalyticsService>(analyticsServiceProvider, (_, nextAnalytics) {
    if (!hasUser) return;
    final uid = latestUser?.isAnonymous == false ? latestUser!.uid : null;
    unawaited(
      nextAnalytics.setUserId(nextAnalytics.collectionEnabled ? uid : null),
    );
  });

  return auth.authStateChanges().asyncMap((user) async {
    latestUser = user;
    hasUser = true;
    final analytics = ref.read(analyticsServiceProvider);
    final uid = user?.isAnonymous == false ? user!.uid : null;
    if (previousUid != null && uid != null && uid != previousUid) {
      await analytics.setUserId(null);
    }
    previousUid = uid;
    await analytics.setUserId(uid);
    await crashReporting.setUser(uid);
    return user;
  });
});

final currentAuthenticatedUidProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null || user.isAnonymous) return null;
  return user.uid;
});

final tutorWorkspaceServiceProvider = Provider<TutorWorkspaceService>((ref) {
  final appService = ref.watch(tutorApplicationServiceProvider);
  if (!ref.watch(firebaseReadyProvider) || appService == null) {
    return const UnavailableTutorWorkspaceService();
  }
  return FirebaseTutorWorkspaceService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    appService,
  );
});

final tutorDashboardProvider = StreamProvider.autoDispose<TutorDashboardData>((
  ref,
) {
  final uid = ref.watch(currentAuthenticatedUidProvider);
  if (uid == null) {
    return Stream.error(const TutorUnauthorizedException());
  }
  return ref.watch(tutorWorkspaceServiceProvider).watchDashboard(uid).map((
    data,
  ) {
    if (data.tutorUid != null && data.tutorUid != uid) {
      throw const TutorUnauthorizedException(
        'Dữ liệu bảng điều khiển không khớp với tài khoản hiện tại.',
      );
    }
    return data;
  });
});

final tutorChatsProvider = StreamProvider.autoDispose<List<TutorChatSummary>>((
  ref,
) {
  final uid = ref.watch(currentAuthenticatedUidProvider);
  if (uid == null) {
    return Stream.error(const TutorUnauthorizedException());
  }
  return ref
      .watch(tutorWorkspaceServiceProvider)
      .watchTutorChats(uid)
      .map(
        (chats) => chats.where((c) => c.tutorId == uid).toList(growable: false),
      );
});

final tutorChatSessionProvider = StreamProvider.autoDispose
    .family<TutorChatSession, String>((ref, chatId) {
      final uid = ref.watch(currentAuthenticatedUidProvider);
      if (uid == null) {
        return Stream.error(const TutorUnauthorizedException());
      }
      return ref
          .watch(tutorWorkspaceServiceProvider)
          .watchTutorChatSession(uid, chatId)
          .map((session) {
            if (session.summary.tutorId != uid) {
              throw const TutorUnauthorizedException(
                'Bạn không có quyền truy cập nhóm chat của gia sư khác.',
              );
            }
            return session;
          });
    });

final tutorClassDetailProvider = StreamProvider.autoDispose
    .family<TutorClassRecord, String>((ref, classId) {
      final uid = ref.watch(currentAuthenticatedUidProvider);
      if (uid == null) {
        return Stream.error(const TutorUnauthorizedException());
      }
      return ref
          .watch(tutorWorkspaceServiceProvider)
          .watchTutorClass(uid, classId)
          .map((record) {
            if (record.tutorId != uid) {
              throw const TutorUnauthorizedException(
                'Bạn không có quyền truy cập lớp học của gia sư khác.',
              );
            }
            return record;
          });
    });

final tutorScheduleProvider =
    StreamProvider.autoDispose<List<TutorLessonSession>>((ref) {
      final uid = ref.watch(currentAuthenticatedUidProvider);
      if (uid == null) {
        return Stream.error(const TutorUnauthorizedException());
      }
      return ref
          .watch(tutorWorkspaceServiceProvider)
          .watchTutorSchedule(uid)
          .map(
            (sessions) =>
                sessions.where((s) => s.tutorId == uid).toList(growable: false),
          );
    });

final tutorProfileViewProvider =
    StreamProvider.autoDispose<TutorProfileViewData>((ref) {
      final uid = ref.watch(currentAuthenticatedUidProvider);
      if (uid == null) {
        return Stream.error(const TutorUnauthorizedException());
      }
      return ref
          .watch(tutorWorkspaceServiceProvider)
          .watchTutorProfile(uid)
          .map((profile) {
            if (profile.application.uid != uid) {
              throw const TutorUnauthorizedException(
                'Hồ sơ gia sư không khớp với tài khoản hiện tại.',
              );
            }
            return profile;
          });
    });

final tutorRepositoryProvider = Provider<TutorRepository>((ref) {
  if (!ref.watch(firebaseReadyProvider)) {
    return const UnavailableTutorRepository();
  }
  return FirebaseTutorRepository(FirebaseFirestore.instance);
});

final activeTutorsProvider = FutureProvider<List<Tutor>>(
  (ref) async =>
      excludeSyntheticTutorFixtures(
            await ref.watch(tutorRepositoryProvider).activeTutors(limit: 100),
          )
          .take(ref.watch(remoteConfigProvider).homeTutorLimit)
          .toList(growable: false),
);

final tutorProvider = FutureProvider.family<Tutor, String>(
  (ref, id) => ref.watch(tutorRepositoryProvider).tutorById(id),
);

final tutorSearchProvider =
    FutureProvider.family<List<Tutor>, TutorSearchCriteria>((
      ref,
      criteria,
    ) async {
      final tutors = await ref
          .watch(tutorRepositoryProvider)
          .activeTutors(limit: 100);
      return filterTutors(excludeSyntheticTutorFixtures(tutors), criteria);
    });

final matchingServiceProvider = Provider<MatchingService>(
  (ref) => MatchingService(
    ref.watch(tutorRepositoryProvider),
    ref.watch(remoteConfigProvider),
  ),
);

final paymentModeProvider = Provider<core.BeeWisePaymentMode>(
  (ref) => usesFinalFirestore
      ? core.BeeWisePaymentMode.manualVietQr
      : core.BeeWisePaymentMode.legacyPayOs,
);

final chatServiceProvider = Provider<ChatService>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return const UnavailableChatService();
  return FirebaseChatService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    paymentMode: ref.watch(paymentModeProvider),
  );
});

final workflowServiceProvider = Provider<WorkflowService?>(
  (ref) => ref.watch(firebaseReadyProvider)
      ? WorkflowService(FirebaseFirestore.instance, FirebaseAuth.instance)
      : null,
);

final paymentApiProvider = Provider<PaymentApi?>(
  (ref) =>
      ref.watch(firebaseReadyProvider) &&
          ref.watch(paymentModeProvider) == core.BeeWisePaymentMode.legacyPayOs
      ? PaymentApi(
          auth: FirebaseAuth.instance,
          baseUrl: beeWiseApiBaseUrl,
          allowInsecureCheckout: usesFirebaseEmulators,
        )
      : null,
);

/// Opens the payOS checkout page outside the app (overridable in tests).
final checkoutLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

final exportServiceProvider = Provider<ExportService>((ref) {
  final enabled = ref.watch(firebaseReadyProvider) && Firebase.apps.isNotEmpty;
  return ExportService(
    enabled ? FirebaseFirestore.instance : null,
    enabled ? FirebaseAuth.instance : null,
    localMetadataOnly: usesFinalFirestore,
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final enabled = ref.watch(firebaseReadyProvider) && Firebase.apps.isNotEmpty;
  return NotificationService(
    enabled && !usesFirebaseEmulators ? FirebaseMessaging.instance : null,
    enabled ? FirebaseFirestore.instance : null,
    enabled ? FirebaseAuth.instance : null,
  );
});

final serverNotificationServiceProvider = Provider<ServerNotificationService?>(
  (ref) => ref.watch(firebaseReadyProvider)
      ? ServerNotificationService(
          FirebaseFirestore.instance,
          FirebaseAuth.instance,
        )
      : null,
);

/// Everything the signed-in user can open from "Thông báo": the backend-written inbox
/// (users/{uid}/notifications) merged with push notifications stored on this device, newest
/// first. Either source may be empty or unavailable without hiding the other.
final notificationsProvider = StreamProvider<List<BeeWiseNotification>>((ref) {
  final uid = ref.watch(currentAuthenticatedUidProvider);
  final local = ref.watch(notificationServiceProvider);
  final server = ref.watch(serverNotificationServiceProvider);
  final controller = StreamController<List<BeeWiseNotification>>();
  var localItems = const <BeeWiseNotification>[];
  var serverItems = const <BeeWiseNotification>[];
  var announcements = const <BeeWiseNotification>[];
  var reviews = const <BeeWiseNotification>[];
  var localReady = false;

  void emit() {
    if (controller.isClosed || !localReady) return;
    final byId = <String, BeeWiseNotification>{
      for (final item in [
        ...serverItems,
        ...announcements,
        ...reviews,
        ...localItems,
      ])
        item.id: item,
    };
    controller.add(
      byId.values.toList(growable: false)
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)),
    );
  }

  Future<void> loadLocal() async {
    try {
      localItems = await local.notifications();
    } catch (_) {
      localItems = const [];
    }
    localReady = true;
    emit();
  }

  unawaited(loadLocal());
  final localSubscription = local.updates.listen((_) => unawaited(loadLocal()));
  final serverSubscription = server?.watch().listen((items) {
    serverItems = items;
    emit();
  });
  final shared = usesFinalFirestore && ref.watch(firebaseReadyProvider)
      ? core.BeeWiseFirestore(FirebaseFirestore.instance)
      : null;
  List<BeeWiseNotification> mapNotices(List<core.InboxNotice> items) => [
    for (final item in items)
      BeeWiseNotification(
        id: '${item.kind.name}_${item.id}',
        title: item.title,
        body: item.body,
        route: '',
        receivedAt: item.createdAt,
        recipientUid: uid,
        kind: item.kind == core.InboxNoticeKind.announcement
            ? BeeWiseNotificationKind.announcement
            : BeeWiseNotificationKind.applicationReview,
      ),
  ];
  final announcementSubscription = uid == null || shared == null
      ? null
      : resubscribingStream(
          shared.watchAnnouncements,
          whenFailed: const <core.InboxNotice>[],
        ).listen((items) {
          announcements = mapNotices(items);
          emit();
        });
  final reviewSubscription = uid == null || shared == null
      ? null
      : resubscribingStream(
          () => shared.watchReviewNotices(uid),
          whenFailed: const <core.InboxNotice>[],
        ).listen((items) {
          reviews = mapNotices(items);
          emit();
        });
  ref.onDispose(() {
    unawaited(announcementSubscription?.cancel());
    unawaited(reviewSubscription?.cancel());
    unawaited(localSubscription.cancel());
    unawaited(serverSubscription?.cancel());
    unawaited(controller.close());
  });
  return controller.stream;
});

/// When the signed-in user last opened "Thông báo" on this device. The bell shows a dot only
/// for notifications newer than this, so a persistent server inbox does not leave it lit.
final notificationsSeenAtProvider =
    NotifierProvider<NotificationsSeenAt, DateTime?>(NotificationsSeenAt.new);

class NotificationsSeenAt extends Notifier<DateTime?> {
  String? get _key {
    final uid = ref.read(currentAuthenticatedUidProvider);
    return uid == null ? null : 'beewise.notifications_seen.v1.$uid';
  }

  @override
  DateTime? build() {
    ref.watch(currentAuthenticatedUidProvider);
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    final key = _key;
    if (key == null) return;
    try {
      final raw = await SharedPreferencesAsync().getString(key);
      if (!ref.mounted || _key != key) return;
      state = raw == null ? null : DateTime.tryParse(raw);
    } catch (_) {}
  }

  Future<void> markSeen() async {
    final key = _key;
    if (key == null) return;
    final now = DateTime.now();
    state = now;
    try {
      await SharedPreferencesAsync().setString(key, now.toIso8601String());
    } catch (_) {}
  }
}

final notificationInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationServiceProvider).initialize();
});

final chatMessagesProvider = StreamProvider.family(
  (ref, String chatId) => ref.watch(chatServiceProvider).watchMessages(chatId),
);

final parentChatsProvider = StreamProvider.family<List<ChatPreview>, String>(
  (ref, parentId) => ref.watch(chatServiceProvider).watchParentChats(parentId),
);

final invoiceQueryProvider = StreamProvider.family((ref, String invoiceId) {
  final service = ref.watch(workflowServiceProvider);
  if (service == null) throw const FirebaseNotConfiguredException();
  return service.watchInvoice(invoiceId);
});

final scheduleProvider = StreamProvider.family((ref, String classId) {
  final service = ref.watch(workflowServiceProvider);
  if (service == null) throw const FirebaseNotConfiguredException();
  return service.watchSchedule(classId);
});

class UnavailableTutorRepository implements TutorRepository {
  const UnavailableTutorRepository();
  @override
  Future<List<Tutor>> activeTutors({int limit = 50}) =>
      Future.error(const FirebaseNotConfiguredException());
  @override
  Future<Tutor> tutorById(String id) =>
      Future.error(const FirebaseNotConfiguredException());
}

class UnavailableChatService implements ChatService {
  const UnavailableChatService();
  @override
  Future<String> createConnectionRequest({
    required String tutorId,
    required String learningGoal,
    required String area,
    required String schedule,
    String? note,
  }) => Future.error(const FirebaseNotConfiguredException());
  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) =>
      Stream.error(const FirebaseNotConfiguredException());
  @override
  Stream<List<ChatPreview>> watchParentChats(String parentId) =>
      Stream.error(const FirebaseNotConfiguredException());
  @override
  Future<void> sendMessage(String chatId, String body) =>
      Future.error(const FirebaseNotConfiguredException());
}
