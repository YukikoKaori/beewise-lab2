import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/tutor.dart';
import '../models/tutor_workspace_models.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/export_service.dart';
import '../services/matching_service.dart';
import '../services/payment_api.dart';
import '../services/tutor_application_service.dart';
import '../services/workflow_service.dart';
import '../services/tutor_repository.dart';
import 'app_providers.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  void _invalidateTutorWorkspaceProviders() {
    ref.invalidate(tutorDashboardProvider);
    ref.invalidate(tutorChatsProvider);
    ref.invalidate(tutorChatSessionProvider);
    ref.invalidate(tutorClassDetailProvider);
    ref.invalidate(tutorScheduleProvider);
    ref.invalidate(tutorProfileViewProvider);
    ref.invalidate(tutorApplicationDataProvider);
    ref.invalidate(tutorApplicationStatusProvider);
  }

  Future<void> googleSignIn() async {
    ref.read(reportControllerProvider.notifier).reset();
    ref.read(tutorChatComposerControllerProvider.notifier).reset();
    _invalidateTutorWorkspaceProviders();
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
    ref.read(reportControllerProvider.notifier).reset();
    ref.read(tutorChatComposerControllerProvider.notifier).reset();
    _invalidateTutorWorkspaceProviders();
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
    ref.read(reportControllerProvider.notifier).reset();
    ref.read(tutorChatComposerControllerProvider.notifier).reset();
    ref.read(tutorApplicationControllerProvider.notifier).reset();
    state = const AsyncLoading();
    try {
      await ref.read(analyticsServiceProvider).event('logout');
      await ref.read(notificationServiceProvider).detachCurrentUser();
      await ref.read(analyticsServiceProvider).setUserId(null);
      await ref.read(crashReportingServiceProvider).setUser(null);
      await ref.read(authServiceProvider).signOut();
      state = const AsyncData(null);
      _invalidateTutorWorkspaceProviders();
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

  void reset() => state = const AsyncData(null);

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

  Future<bool> resubmit({
    required String uid,
    required String name,
    required String phone,
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
      final currentUid = ref.read(currentAuthenticatedUidProvider);
      if (currentUid == null || currentUid != uid) {
        throw const TutorApplicationException(
          'Phiên đăng nhập đã thay đổi. Vui lòng đăng nhập lại.',
        );
      }
      final service = ref.read(tutorApplicationServiceProvider);
      if (service == null) throw const FirebaseNotConfiguredException();
      await service.resubmit(
        uid: uid,
        name: name,
        phone: phone,
        qualification: qualification,
        introduction: introduction,
        subjects: subjects,
        grades: grades,
        hourlyFee: hourlyFee,
        areas: areas,
        teachingModes: teachingModes,
        availability: availability,
      );
      if (ref.read(currentAuthenticatedUidProvider) != uid) {
        state = const AsyncData(null);
        return false;
      }
      ref.invalidate(tutorApplicationDataProvider(uid));
      ref.invalidate(tutorApplicationStatusProvider(uid));
      await ref
          .read(analyticsServiceProvider)
          .event('tutor_application_resubmitted');
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      await ref
          .read(crashReportingServiceProvider)
          .recordHandled(error, stack, 'Tutor application resubmission failed');
      state = AsyncError(error, stack);
      return false;
    }
  }
}

enum TutorChatSendStage { idle, sending, sent, failed }

class TutorChatSendState {
  const TutorChatSendState({
    this.stage = TutorChatSendStage.idle,
    this.ownerUid,
    this.chatId,
    this.failedDraft,
    this.errorMessage,
  });

  final TutorChatSendStage stage;
  final String? ownerUid;
  final String? chatId;
  final String? failedDraft;
  final String? errorMessage;

  bool get isSending => stage == TutorChatSendStage.sending;
  bool get hasFailed => stage == TutorChatSendStage.failed;
}

final tutorChatComposerControllerProvider =
    NotifierProvider<TutorChatComposerController, TutorChatSendState>(
      TutorChatComposerController.new,
    );

class TutorChatComposerController extends Notifier<TutorChatSendState> {
  int _operationToken = 0;
  bool _disposed = false;

  @override
  TutorChatSendState build() {
    ref.listen<String?>(currentAuthenticatedUidProvider, (previous, next) {
      if ((previous != null && next != previous) ||
          (state.ownerUid != null && next != state.ownerUid)) {
        reset();
      }
    });
    final auth = ref.read(authServiceProvider);
    String? previousUid;
    final sub = auth.authStateChanges().listen((user) {
      final nextUid = user?.isAnonymous == false ? user!.uid : null;
      if ((previousUid != null && nextUid != previousUid) ||
          (state.ownerUid != null && nextUid != state.ownerUid)) {
        reset();
      }
      previousUid = nextUid;
    }, onError: (_, _) => reset());

    ref.onDispose(() {
      _disposed = true;
      _operationToken++;
      sub.cancel();
    });
    return const TutorChatSendState();
  }

  void reset() {
    _operationToken++;
    if (!_disposed) {
      state = const TutorChatSendState();
    }
  }

  Future<bool> send({required String chatId, required String text}) async {
    if (state.isSending) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final uid = ref.read(currentAuthenticatedUidProvider);
    if (uid == null) {
      state = TutorChatSendState(
        stage: TutorChatSendStage.failed,
        chatId: chatId,
        failedDraft: trimmed,
        errorMessage: 'Bạn cần đăng nhập tài khoản gia sư hợp lệ để gửi tin.',
      );
      return false;
    }

    final token = ++_operationToken;
    state = TutorChatSendState(
      stage: TutorChatSendStage.sending,
      ownerUid: uid,
      chatId: chatId,
    );

    try {
      await ref
          .read(tutorWorkspaceServiceProvider)
          .sendTutorMessage(tutorUid: uid, chatId: chatId, body: trimmed);
      if (_disposed ||
          token != _operationToken ||
          ref.read(currentAuthenticatedUidProvider) != uid) {
        return false;
      }
      await ref.read(analyticsServiceProvider).event('chat_message_sent', {
        'message_type': 'text',
        'sender_role': 'tutor',
      });
      if (_disposed ||
          token != _operationToken ||
          ref.read(currentAuthenticatedUidProvider) != uid) {
        return false;
      }
      state = TutorChatSendState(
        stage: TutorChatSendStage.sent,
        ownerUid: uid,
        chatId: chatId,
      );
      return true;
    } catch (error) {
      if (_disposed ||
          token != _operationToken ||
          ref.read(currentAuthenticatedUidProvider) != uid) {
        return false;
      }
      state = TutorChatSendState(
        stage: TutorChatSendStage.failed,
        ownerUid: uid,
        chatId: chatId,
        failedDraft: trimmed,
        errorMessage: friendlyError(error),
      );
      return false;
    }
  }

  Future<bool> retry() async {
    final draft = state.failedDraft;
    final chatId = state.chatId;
    if (!state.hasFailed || draft == null || chatId == null) {
      return false;
    }
    return send(chatId: chatId, text: draft);
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

  /// Clears a previous screen's error/loading state. The controller is shared
  /// by the trial, class and payment screens, so each one resets it on entry.
  void reset() => state = const AsyncData(null);

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

  /// Asks the trusted backend for a payOS checkout link and opens it.
  /// Opening the page is not payment: the invoice turns verified only when the
  /// server confirms the payment with payOS and updates Firestore.
  Future<void> startPayOsCheckout(String invoiceId) => _run(() async {
    final api = ref.read(paymentApiProvider);
    if (api == null) throw const FirebaseNotConfiguredException();
    final session = await api.createCheckout(invoiceId);
    await ref.read(analyticsServiceProvider).event('begin_checkout', {
      'payment_provider': 'payos',
      'reused_link': session.reused ? 1 : 0,
    });
    final opened = await ref.read(checkoutLauncherProvider)(
      session.checkoutUrl,
    );
    if (!opened) {
      throw const PaymentApiException(
        'Không mở được trang thanh toán payOS trên thiết bị này.',
      );
    }
  });

  /// Asks the server to re-check payOS (for a delayed or missed webhook).
  Future<void> refreshPaymentStatus(String invoiceId) => _run(() async {
    final api = ref.read(paymentApiProvider);
    if (api == null) throw const FirebaseNotConfiguredException();
    final result = await api.reconcile(invoiceId);
    await ref.read(analyticsServiceProvider).event('payment_status_checked', {
      'result': result.verified ? 'verified' : 'pending',
    });
  });

  /// Re-checks payOS without touching the visible state: used when the app comes back from
  /// the payment page or opens the invoice from a link. A failure is ignored on purpose; the
  /// "check again" button remains for a manual retry and the invoice stream still updates.
  Future<void> silentRefreshPaymentStatus(String invoiceId) async {
    final api = ref.read(paymentApiProvider);
    if (api == null || !api.configured) return;
    try {
      await api.reconcile(invoiceId);
    } catch (_) {}
  }

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

enum ReportStage {
  idle,
  generating,
  generated,
  encoding,
  saving,
  saved,
  downloading,
  downloaded,
  error,
}

class FileUploadState {
  const FileUploadState({
    this.stage = ReportStage.idle,
    this.result,
    this.localPath,
    this.error,
  });
  final ReportStage stage;
  final SavedReport? result;
  final String? localPath;
  final String? error;
  bool get isBusy => const {
    ReportStage.generating,
    ReportStage.encoding,
    ReportStage.saving,
    ReportStage.downloading,
  }.contains(stage);
}

final reportControllerProvider =
    NotifierProvider<ReportController, FileUploadState>(ReportController.new);

class ReportController extends Notifier<FileUploadState> {
  ReportOperation? _operation;
  ExportedReport? _report;
  String? _tutorId;
  String? _ownerUid;
  bool _disposed = false;

  @override
  FileUploadState build() {
    final service = ref.read(exportServiceProvider);
    var previousOwner = service.currentOwnerUid;
    // Observe the raw Auth stream: clearing private UI must not wait for the
    // telemetry work in authStateProvider's asyncMap.
    final subscription = service.ownerChanges.listen((owner) {
      if (owner != previousOwner) {
        reset();
        previousOwner = owner;
      }
    }, onError: (Object error, StackTrace stack) => reset());
    ref.onDispose(() {
      _disposed = true;
      _operation?.cancel();
      subscription.cancel();
    });
    return const FileUploadState();
  }

  bool _current(ReportOperation operation, String? uid) =>
      !_disposed &&
      identical(_operation, operation) &&
      !operation.cancelled &&
      _ownerUid == uid &&
      ref.read(exportServiceProvider).currentOwnerUid == uid;

  Future<void> generate(Tutor tutor) async {
    if (state.isBusy) return;
    reset();
    final operation = _operation = ReportOperation();
    final service = ref.read(exportServiceProvider);
    final uid = service.currentOwnerUid;
    _ownerUid = uid;
    state = const FileUploadState(stage: ReportStage.generating);
    try {
      // The route's Tutor comes from TutorRepository. Cloud save independently
      // rechecks the actual catalog document and rules recheck eligibility.
      final report = await service.buildTutorSummary(tutor);
      if (!_current(operation, uid)) return;
      _report = report;
      _tutorId = tutor.id;
      await ref.read(analyticsServiceProvider).event('export_report', {
        'subject_count': tutor.subjects.length,
        'file_size_kb': report.sizeBytes ~/ 1024,
      });
      if (!_current(operation, uid)) return;
      state = FileUploadState(
        stage: ReportStage.generated,
        localPath: report.file.path,
      );
    } catch (error, stack) {
      await _failed(operation, uid, error, stack);
    }
  }

  Future<void> save() async {
    if (state.isBusy ||
        state.result != null ||
        _report == null ||
        _tutorId == null) {
      return;
    }
    final service = ref.read(exportServiceProvider);
    final uid = service.currentOwnerUid;
    if (_ownerUid != uid) {
      reset();
      return;
    }
    final operation = _operation = ReportOperation();
    final report = _report!;
    state = FileUploadState(
      stage: ReportStage.encoding,
      localPath: report.file.path,
    );
    try {
      final result = await service.saveReport(
        tutorId: _tutorId!,
        report: report,
        operation: operation,
        onSaving: () {
          if (_current(operation, uid)) {
            state = FileUploadState(
              stage: ReportStage.saving,
              localPath: report.file.path,
            );
          }
        },
      );
      if (!_current(operation, uid)) return;
      final savedFile = result.localOnly
          ? await service.resolveLocalReport(result, operation)
          : report.file;
      if (!_current(operation, uid)) return;
      await ref.read(analyticsServiceProvider).event('upload_report', {
        'storage_backend': result.localOnly ? 'local_metadata' : 'firestore',
        'file_size_kb': result.sizeBytes ~/ 1024,
        'result': 'success',
      });
      if (!_current(operation, uid)) return;
      state = FileUploadState(
        stage: ReportStage.saved,
        result: result,
        localPath: savedFile.path,
      );
    } catch (error, stack) {
      await _failed(operation, uid, error, stack);
    }
  }

  Future<void> download() async {
    final result = state.result;
    if (result != null) await loadSaved(result);
  }

  Future<void> loadSaved(SavedReport result) async {
    if (state.isBusy) return;
    final service = ref.read(exportServiceProvider);
    final uid = service.currentOwnerUid;
    final collection = result.localOnly ? 'localFiles' : 'files';
    if (uid == null ||
        result.documentPath != 'reports/$uid/$collection/${result.reportId}') {
      reset();
      return;
    }
    reset();
    _ownerUid = uid;
    final operation = _operation = ReportOperation();
    state = FileUploadState(stage: ReportStage.downloading, result: result);
    try {
      final file = result.localOnly
          ? await service.resolveLocalReport(result, operation)
          : await service.downloadReport(result.reportId, operation: operation);
      if (!_current(operation, uid)) return;
      state = FileUploadState(
        stage: ReportStage.downloaded,
        result: result,
        localPath: file.path,
      );
    } catch (error, stack) {
      await _failed(operation, uid, error, stack);
    }
  }

  Future<void> openLocal() async {
    final report = state.result;
    final operation = _operation;
    final service = ref.read(exportServiceProvider);
    final uid = service.currentOwnerUid;
    if (report == null ||
        operation == null ||
        !report.localOnly ||
        !_current(operation, uid) ||
        state.isBusy) {
      return;
    }
    try {
      await service.openLocalReport(report, operation);
    } catch (error, stack) {
      await _failed(operation, uid, error, stack);
    }
  }

  Future<void> share() async {
    if (state.isBusy || state.localPath == null) return;
    final operation = _operation;
    final uid = ref.read(exportServiceProvider).currentOwnerUid;
    if (_ownerUid != uid) {
      reset();
      return;
    }
    if (_disposed || operation == null) return;
    try {
      final localPath = state.localPath!;
      if (!await File(localPath).exists()) {
        throw const ExportException('Không tìm thấy PDF trên thiết bị này.');
      }
      if (!_current(operation, uid)) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(localPath, mimeType: 'application/pdf')],
          title: 'BeeWise PDF',
        ),
      );
    } catch (error, stack) {
      await _failed(operation, uid, error, stack);
    }
  }

  Future<void> _failed(
    ReportOperation operation,
    String? uid,
    Object error,
    StackTrace stack,
  ) async {
    // A timeout cancels the operation itself; still show its error unless a
    // reset/logout/new operation invalidated its identity.
    if (_disposed ||
        !identical(_operation, operation) ||
        ref.read(exportServiceProvider).currentOwnerUid != uid) {
      return;
    }
    final previous = state;
    state = FileUploadState(
      stage: ReportStage.error,
      result: previous.result,
      localPath: previous.localPath,
      error: friendlyError(error),
    );
    // SDK errors can include document paths. Never send PDF content or raw UID.
    await ref
        .read(crashReportingServiceProvider)
        .recordHandled(
          const ExportException('Report operation failed'),
          stack,
          'Report generation/save/download failed',
        );
  }

  void reset() {
    _operation?.cancel();
    _operation = null;
    _report = null;
    _tutorId = null;
    _ownerUid = null;
    if (!_disposed) state = const FileUploadState();
  }
}

final profileTutorProvider = FutureProvider<Tutor?>((ref) async {
  final tutors = await ref.watch(activeTutorsProvider.future);
  return tutors.isEmpty ? null : tutors.first;
});

final consultantMessagesProvider = StreamProvider.family(
  (ref, String chatId) => ref.watch(chatServiceProvider).watchMessages(chatId),
);

String friendlyError(Object error) {
  if (error is FirebaseAIException) {
    if (error is QuotaExceeded) {
      return 'AI đang đạt giới hạn sử dụng. Bạn có thể thử lại sau hoặc tự tìm gia sư.';
    }
    return 'AI tạm thời chưa phản hồi được. Bạn có thể thử lại sau hoặc tự tìm gia sư.';
  }
  if (error is TimeoutException) {
    return 'Dịch vụ phản hồi quá lâu. Nội dung vẫn được giữ để bạn thử lại.';
  }
  if (error is AuthFlowException ||
      error is ChatServiceException ||
      error is MatchingException ||
      error is ExportException ||
      error is WorkflowException ||
      error is PaymentApiException ||
      error is TutorApplicationException ||
      error is TutorUnauthorizedException ||
      error is TutorResourceNotFoundException ||
      error is TutorBackendRulesDependencyException ||
      error is TutorNetworkException) {
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
