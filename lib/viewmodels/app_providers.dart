import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor.dart';
import '../models/chat_message.dart';
import '../models/chat_preview.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/crash_reporting_service.dart';
import '../services/export_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/matching_service.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';
import '../services/tutor_application_service.dart';
import '../services/tutor_repository.dart';
import '../services/workflow_service.dart';

final firebaseReadyProvider = Provider<bool>((ref) => FirebaseBootstrap.ready);
final firebaseSetupErrorProvider = Provider<Object?>(
  (ref) => FirebaseBootstrap.initializationError,
);

final remoteConfigProvider = Provider<RemoteConfigService>(
  (ref) => RemoteConfigService(
    ref.watch(firebaseReadyProvider) ? FirebaseRemoteConfig.instance : null,
  ),
);

final remoteConfigInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(remoteConfigProvider).initialize();
  ref.invalidate(activeTutorsProvider);
});

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(
    analytics: ref.watch(firebaseReadyProvider)
        ? FirebaseAnalytics.instance
        : null,
  ),
);

final crashReportingServiceProvider = Provider<CrashReportingService>(
  (ref) => CrashReportingService(
    crashlytics: ref.watch(firebaseReadyProvider)
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
        )
      : null,
);

final tutorApplicationStatusProvider = FutureProvider.family<String, String>((
  ref,
  uid,
) async {
  final service = ref.watch(tutorApplicationServiceProvider);
  if (service == null) throw const FirebaseNotConfiguredException();
  return service.status(uid);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(authServiceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  final crashReporting = ref.watch(crashReportingServiceProvider);
  return auth.authStateChanges().asyncMap((user) async {
    final uid = user?.isAnonymous == false ? user!.uid : null;
    await analytics.setUserId(uid);
    await crashReporting.setUser(uid);
    return user;
  });
});

final tutorRepositoryProvider = Provider<TutorRepository>((ref) {
  if (!ref.watch(firebaseReadyProvider)) {
    return const UnavailableTutorRepository();
  }
  return FirebaseTutorRepository(FirebaseFirestore.instance);
});

final activeTutorsProvider = FutureProvider<List<Tutor>>(
  (ref) => ref
      .watch(tutorRepositoryProvider)
      .activeTutors(limit: ref.watch(remoteConfigProvider).homeTutorLimit),
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
      return filterTutors(tutors, criteria);
    });

final matchingServiceProvider = Provider<MatchingService>(
  (ref) => MatchingService(
    ref.watch(tutorRepositoryProvider),
    ref.watch(remoteConfigProvider),
  ),
);

final chatServiceProvider = Provider<ChatService>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return const UnavailableChatService();
  return FirebaseChatService(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final workflowServiceProvider = Provider<WorkflowService?>(
  (ref) => ref.watch(firebaseReadyProvider)
      ? WorkflowService(FirebaseFirestore.instance, FirebaseAuth.instance)
      : null,
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(
    ref.watch(firebaseReadyProvider) ? FirebaseStorage.instance : null,
  ),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(
    ref.watch(firebaseReadyProvider) ? FirebaseMessaging.instance : null,
    ref.watch(firebaseReadyProvider) ? FirebaseFirestore.instance : null,
    ref.watch(firebaseReadyProvider) ? FirebaseAuth.instance : null,
  ),
);

final notificationsProvider = StreamProvider((ref) async* {
  final service = ref.watch(notificationServiceProvider);
  yield await service.notifications();
  yield* service.updates.asyncMap((_) => service.notifications());
});

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
