import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/export_service.dart';
import '../services/matching_service.dart';
import '../services/workflow_service.dart';
import '../services/tutor_repository.dart';
import 'app_providers.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> googleSignIn() async {
    state = const AsyncLoading();
    try {
      await ref.read(notificationServiceProvider).detachCurrentUser();
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      final uid = credential.user?.uid;
      await ref.read(analyticsServiceProvider).login('google');
      await ref.read(analyticsServiceProvider).setUserId(uid);
      await ref.read(crashReportingServiceProvider).setUser(uid);
      state = const AsyncData(null);
    } catch (error, stack) {
      await ref
          .read(crashReportingServiceProvider)
          .recordHandled(error, stack, 'Google sign-in failed/cancelled');
      state = AsyncError(error, stack);
    } finally {
      await ref.read(notificationServiceProvider).retryRegistration();
    }
  }

  Future<void> emailSignIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(notificationServiceProvider).detachCurrentUser();
      final credential = await ref
          .read(authServiceProvider)
          .signInWithEmail(email, password);
      final uid = credential.user?.uid;
      await ref.read(analyticsServiceProvider).login('password');
      await ref.read(analyticsServiceProvider).setUserId(uid);
      await ref.read(crashReportingServiceProvider).setUser(uid);
      state = const AsyncData(null);
    } catch (error, stack) {
      await ref
          .read(crashReportingServiceProvider)
          .recordHandled(error, stack, 'Email sign-in failed');
      state = AsyncError(error, stack);
    } finally {
      await ref.read(notificationServiceProvider).retryRegistration();
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(notificationServiceProvider).detachCurrentUser();
      final credential = await ref
          .read(authServiceProvider)
          .registerParent(
            name: name,
            email: email,
            phone: phone,
            password: password,
          );
      final uid = credential.user?.uid;
      await ref.read(analyticsServiceProvider).event('sign_up', {
        'method': 'password',
        'account_type': 'parent',
      });
      await ref.read(analyticsServiceProvider).setUserId(uid);
      await ref.read(crashReportingServiceProvider).setUser(uid);
      state = const AsyncData(null);
    } catch (error, stack) {
      await ref
          .read(crashReportingServiceProvider)
          .recordHandled(error, stack, 'Parent registration failed');
      state = AsyncError(error, stack);
    } finally {
      await ref.read(notificationServiceProvider).retryRegistration();
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(analyticsServiceProvider).event('logout');
      await ref.read(notificationServiceProvider).detachCurrentUser();
      await ref.read(analyticsServiceProvider).setUserId(null);
      await ref.read(crashReportingServiceProvider).setUser(null);
      await ref.read(authServiceProvider).signOut();
      state = const AsyncData(null);
      ref.invalidate(authStateProvider);
      ref.invalidate(notificationsProvider);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    } finally {
      await ref.read(notificationServiceProvider).retryRegistration();
    }
  }
}

final tutorApplicationControllerProvider =
    NotifierProvider<TutorApplicationController, AsyncValue<void>>(
      TutorApplicationController.new,
    );

class TutorApplicationController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String qualification,
    required String introduction,
    required List<String> subjects,
    required List<String> grades,
    required int hourlyFee,
    required List<String> areas,
    required List<String> teachingModes,
    required String availability,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(notificationServiceProvider).detachCurrentUser();
      final service = ref.read(tutorApplicationServiceProvider);
      if (service == null) throw const FirebaseNotConfiguredException();
      final uid = await service.submit(
        name: name,
        email: email,
        phone: phone,
        password: password,
        qualification: qualification,
        introduction: introduction,
        subjects: subjects,
        grades: grades,
        hourlyFee: hourlyFee,
        areas: areas,
        teachingModes: teachingModes,
        availability: availability,
      );
      await ref.read(notificationServiceProvider).refreshAccountRole();
      await ref.read(analyticsServiceProvider).event('sign_up', {
        'method': 'password',
        'account_type': 'tutor',
      });
      await ref
          .read(analyticsServiceProvider)
          .event('tutor_application_submitted');
      await ref.read(analyticsServiceProvider).setUserId(uid);
      await ref.read(crashReportingServiceProvider).setUser(uid);
      state = const AsyncData(null);
    } catch (error, stack) {
      await ref
          .read(crashReportingServiceProvider)
          .recordHandled(error, stack, 'Tutor application submission failed');
      state = AsyncError(error, stack);
    } finally {
      await ref.read(notificationServiceProvider).retryRegistration();
    }
  }
}

final matchingControllerProvider =
    NotifierProvider<MatchingController, AsyncValue<List<TutorRecommendation>>>(
      MatchingController.new,
    );

class MatchingController
    extends Notifier<AsyncValue<List<TutorRecommendation>>> {
  @override
  AsyncValue<List<TutorRecommendation>> build() => const AsyncData([]);

  Future<void> match(String need) async {
    state = const AsyncLoading();
    try {
      final results = await ref.read(matchingServiceProvider).match(need);
      if (results.isEmpty) {
        await ref.read(analyticsServiceProvider).event('ai_match_no_results');
      } else {
        await ref.read(analyticsServiceProvider).event('ai_match_success', {
          'result_count': results.length,
        });
      }
      state = AsyncData(results);
    } catch (error, stack) {
      await ref
          .read(crashReportingServiceProvider)
          .recordHandled(error, stack, 'AI matching failed');
      state = AsyncError(error, stack);
    }
  }

  void reset() => state = const AsyncData([]);
}

final connectionControllerProvider =
    NotifierProvider<ConnectionController, AsyncValue<String?>>(
      ConnectionController.new,
    );

class ConnectionController extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  Future<void> submit({
    required String tutorId,
    required String goal,
    required String area,
    required String schedule,
    String? note,
  }) async {
    state = const AsyncLoading();
    try {
      final chatId = await ref
          .read(chatServiceProvider)
          .createConnectionRequest(
            tutorId: tutorId,
            learningGoal: goal,
            area: area,
            schedule: schedule,
            note: note,
          );
      await ref.read(analyticsServiceProvider).event(
        'connection_request_submitted',
        {'request_type': 'parent_connection'},
      );
      state = AsyncData(chatId);
    } catch (error, stack) {
      await ref
          .read(crashReportingServiceProvider)
          .recordHandled(error, stack, 'Connection request failed');
      state = AsyncError(error, stack);
    }
  }
}

final chatComposerControllerProvider =
    NotifierProvider<ChatComposerController, AsyncValue<void>>(
      ChatComposerController.new,
    );

class ChatComposerController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> send(String chatId, String text) async {
    state = const AsyncLoading();
    try {
      await ref.read(chatServiceProvider).sendMessage(chatId, text);
      await ref.read(analyticsServiceProvider).event('chat_message_sent', {
        'message_type': 'text',
      });
      state = const AsyncData(null);
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }
}

final workflowControllerProvider =
    NotifierProvider<WorkflowController, AsyncValue<void>>(
      WorkflowController.new,
    );

class WorkflowController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> answerTrial({
    required String chatId,
    required String proposalId,
    required bool accepted,
    String? alternateTime,
  }) => _run(() async {
    final service = ref.read(workflowServiceProvider);
    if (service == null) throw const FirebaseNotConfiguredException();
    await service.answerTrial(
      chatId: chatId,
      proposalId: proposalId,
      accepted: accepted,
      alternateTime: alternateTime,
    );
    await ref.read(analyticsServiceProvider).event('trial_response', {
      'response': accepted ? 'accepted' : 'alternate_time',
    });
  });

  Future<void> adjustClass({
    required String chatId,
    required String revisionId,
    required String reason,
  }) => _run(() async {
    final service = ref.read(workflowServiceProvider);
    if (service == null) throw const FirebaseNotConfiguredException();
    await service.requestClassAdjustment(
      chatId: chatId,
      revisionId: revisionId,
      reason: reason,
    );
    await ref
        .read(analyticsServiceProvider)
        .event('class_adjustment_requested');
  });

  Future<void> confirmClass({
    required String chatId,
    required String revisionId,
  }) => _run(() async {
    final service = ref.read(workflowServiceProvider);
    if (service == null) throw const FirebaseNotConfiguredException();
    await service.confirmClassRevision(chatId: chatId, revisionId: revisionId);
    await ref.read(analyticsServiceProvider).event('class_revision_confirmed');
  });

  Future<void> requestPaymentVerification(String invoiceId) => _run(() async {
    final service = ref.read(workflowServiceProvider);
    if (service == null) throw const FirebaseNotConfiguredException();
    await service.requestPaymentVerification(invoiceId);
    await ref
        .read(analyticsServiceProvider)
        .event('payment_verification_requested');
  });

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
    } catch (error, stack) {
      await ref
          .read(crashReportingServiceProvider)
          .recordHandled(error, stack, 'Onboarding workflow action failed');
      state = AsyncError(error, stack);
    }
  }
}

class FileUploadState {
  const FileUploadState({
    this.progress = 0,
    this.result,
    this.localPath,
    this.error,
  });
  final double progress;
  final UploadResult? result;
  final String? localPath;
  final String? error;
  bool get isBusy => progress > 0 && progress < 1;
}

final reportControllerProvider =
    NotifierProvider<ReportController, FileUploadState>(ReportController.new);

class ReportController extends Notifier<FileUploadState> {
  @override
  FileUploadState build() => const FileUploadState();

  Future<void> exportAndUpload(Tutor tutor) async {
    state = const FileUploadState(progress: 0.01);
    try {
      final service = ref.read(exportServiceProvider);
      final report = await service.buildTutorSummary(tutor);
      await ref.read(analyticsServiceProvider).event('export_report', {
        'subject_count': tutor.subjects.length,
        'file_size_kb': report.sizeBytes ~/ 1024,
      });
      state = FileUploadState(progress: 0.05, localPath: report.file.path);
      final user = await ref.read(authStateProvider.future);
      if (user == null || user.isAnonymous) {
        throw const ExportException(
          'Đăng nhập để tải tệp lên vùng lưu trữ riêng.',
        );
      }
      final result = await service.upload(
        uid: user.uid,
        report: report,
        onProgress: (progress) => state = FileUploadState(
          progress: progress,
          localPath: report.file.path,
        ),
      );
      await ref.read(analyticsServiceProvider).event('upload_report', {
        'file_size_kb': report.sizeBytes ~/ 1024,
      });
      state = FileUploadState(
        progress: 1,
        result: result,
        localPath: report.file.path,
      );
    } catch (error, stack) {
      await ref
          .read(crashReportingServiceProvider)
          .recordHandled(error, stack, 'Report export/upload failed');
      state = FileUploadState(error: error.toString());
    }
  }

  void reset() => state = const FileUploadState();
}

final profileTutorProvider = FutureProvider<Tutor?>((ref) async {
  final tutors = await ref.watch(activeTutorsProvider.future);
  return tutors.isEmpty ? null : tutors.first;
});

final consultantMessagesProvider = StreamProvider.family(
  (ref, String chatId) => ref.watch(chatServiceProvider).watchMessages(chatId),
);

String friendlyError(Object error) {
  if (error is AuthFlowException ||
      error is ChatServiceException ||
      error is MatchingException ||
      error is ExportException ||
      error is WorkflowException) {
    return error.toString();
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Bạn chưa có quyền thực hiện thao tác này.',
      'unavailable' || 'network-request-failed' =>
        'Không kết nối được dịch vụ. Hãy kiểm tra mạng rồi thử lại.',
      'not-found' => 'Dữ liệu này không còn khả dụng.',
      _ => 'Dịch vụ đang gặp sự cố. Hãy thử lại sau ít phút.',
    };
  }
  return error.toString().replaceFirst('Exception: ', '');
}
