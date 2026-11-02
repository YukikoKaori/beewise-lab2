import 'dart:async';
import 'dart:io';

import 'package:beewise/models/tutor.dart';
import 'package:beewise/services/analytics_service.dart';
import 'package:beewise/services/crash_reporting_service.dart';
import 'package:beewise/services/export_service.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:beewise/viewmodels/controllers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingAnalytics extends AnalyticsService {
  final events = <String>[];
  final parameters = <Map<String, Object>?>[];
  @override
  Future<void> event(String name, [Map<String, Object>? values]) async {
    events.add(name);
    parameters.add(values);
  }
}

class FakeExport extends ExportService {
  FakeExport() : super(null, null);
  String? owner = 'alice';
  final identities = StreamController<String?>.broadcast(sync: true);
  @override
  Stream<String?> get ownerChanges => identities.stream;
  Completer<SavedReport>? gate;
  Completer<ExportedReport>? generationGate;
  Object? failure;
  bool cancelOnFailure = false;
  int saves = 0;
  final report = ExportedReport(file: File('local-test.pdf'), sizeBytes: 16419);
  @override
  String? get currentOwnerUid => owner;
  @override
  Future<ExportedReport> buildTutorSummary(Tutor tutor) async =>
      generationGate == null ? report : await generationGate!.future;
  @override
  Future<SavedReport> saveReport({
    required String tutorId,
    required ExportedReport report,
    required ReportOperation operation,
    void Function()? onSaving,
  }) async {
    saves++;
    onSaving?.call();
    if (failure != null) {
      if (cancelOnFailure) operation.cancel();
      throw failure!;
    }
    return await gate!.future;
  }

  @override
  Future<File> downloadReport(
    String id, {
    required ReportOperation operation,
  }) async {
    if (failure != null) throw failure!;
    return File('downloaded-test.pdf');
  }
}

void main() {
  const tutor = Tutor(
    id: 'tutor',
    name: 'Synthetic unit-only tutor',
    credential: '',
    introduction: '',
    subjects: ['Toán'],
    grades: ['8'],
    hourlyFee: 1,
    areas: [],
    teachingModes: [],
    availability: '',
    verified: true,
    active: true,
  );
  const saved = SavedReport(
    reportId: 'abcdefghijklmnopqrst',
    documentPath: 'reports/alice/files/abcdefghijklmnopqrst',
    sizeBytes: 16419,
  );
  late ProviderContainer container;
  late FakeExport service;
  late RecordingAnalytics analytics;
  late ReportController controller;
  setUp(() async {
    service = FakeExport();
    analytics = RecordingAnalytics();
    container = ProviderContainer(
      overrides: [
        exportServiceProvider.overrideWithValue(service),
        analyticsServiceProvider.overrideWithValue(analytics),
        crashReportingServiceProvider.overrideWithValue(
          CrashReportingService(),
        ),
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
      ],
    );
    controller = container.read(reportControllerProvider.notifier);
    await pumpEventQueue();
    addTearDown(container.dispose);
    addTearDown(() => service.identities.close());
  });
  Future<void> generated() => controller.generate(tutor);
  test(
    'honest stages, concurrent save guard and success-only analytics',
    () async {
      await generated();
      expect(analytics.events, ['export_report']);
      expect(
        container.read(reportControllerProvider).stage,
        ReportStage.generated,
      );
      service.gate = Completer<SavedReport>();
      final future = controller.save();
      await controller.save();
      expect(service.saves, 1);
      expect(
        container.read(reportControllerProvider).stage,
        ReportStage.saving,
      );
      expect(container.read(reportControllerProvider).result, isNull);
      expect(analytics.events, ['export_report']);
      service.gate!.complete(saved);
      await future;
      expect(container.read(reportControllerProvider).stage, ReportStage.saved);
      expect(analytics.events, ['export_report', 'upload_report']);
      expect(analytics.parameters.last, {
        'storage_backend': 'firestore',
        'file_size_kb': 16,
        'result': 'success',
      });
      await controller.save();
      expect(service.saves, 1);
      await controller.download();
      expect(
        container.read(reportControllerProvider).stage,
        ReportStage.downloaded,
      );
      expect(
        container.read(reportControllerProvider).localPath,
        'downloaded-test.pdf',
      );
    },
  );
  test(
    'offline failure shows error and supports retry without success telemetry',
    () async {
      await generated();
      service.failure = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      await controller.save();
      expect(container.read(reportControllerProvider).stage, ReportStage.error);
      expect(analytics.events, ['export_report']);
      service.failure = null;
      service.gate = Completer<SavedReport>()..complete(saved);
      await controller.save();
      expect(container.read(reportControllerProvider).stage, ReportStage.saved);
      service.failure = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      await controller.download();
      expect(container.read(reportControllerProvider).error, contains('quyền'));
    },
  );
  test(
    'logout and A -> B never publish late save results or analytics',
    () async {
      for (final owner in [null, 'bob']) {
        service.owner = 'alice';
        await generated();
        service.gate = Completer<SavedReport>();
        final future = controller.save();
        service.owner = owner;
        service.identities.add(owner);
        service.gate!.complete(saved);
        await future;
        final state = container.read(reportControllerProvider);
        expect(state.stage, ReportStage.idle);
        expect(state.result, isNull);
        expect(state.localPath, isNull);
      }
      expect(analytics.events.where((e) => e == 'upload_report'), isEmpty);
    },
  );
  test(
    'cancel, then generate anew ignores earlier generation callback',
    () async {
      service.generationGate = Completer<ExportedReport>();
      final old = controller.generate(tutor);
      final gate = service.generationGate!;
      controller.reset();
      service.generationGate = null;
      await generated();
      gate.complete(
        ExportedReport(file: File('stale-private.pdf'), sizeBytes: 9),
      );
      await old;
      expect(
        container.read(reportControllerProvider).localPath,
        'local-test.pdf',
      );
      expect(analytics.events, ['export_report']);
    },
  );
  test(
    'timeout error is visible even when service cancelled its operation',
    () async {
      await generated();
      // Same observable timeout contract as the real service.
      service.failure = const ExportException('Chưa xác nhận được từ server.');
      service.cancelOnFailure = true;
      await controller.save();
      expect(container.read(reportControllerProvider).stage, ReportStage.error);
      expect(container.read(reportControllerProvider).isBusy, isFalse);
    },
  );
  test('dispose suppresses pending callbacks', () async {
    final localContainer = ProviderContainer(
      overrides: [
        exportServiceProvider.overrideWithValue(service),
        analyticsServiceProvider.overrideWithValue(analytics),
        authStateProvider.overrideWith((ref) => const Stream<User?>.empty()),
      ],
    );
    final notifier = localContainer.read(reportControllerProvider.notifier);
    await pumpEventQueue();
    service.generationGate = Completer<ExportedReport>();
    final pending = notifier.generate(tutor);
    localContainer.dispose();
    service.generationGate!.complete(service.report);
    await pending;
    expect(analytics.events, isEmpty);
  });

  test(
    'Auth stream errors fail closed and invalidate private report state',
    () async {
      await generated();
      service.identities.addError(StateError('synthetic auth stream failure'));
      await pumpEventQueue();
      expect(container.read(reportControllerProvider).localPath, isNull);
      expect(container.read(reportControllerProvider).stage, ReportStage.idle);
    },
  );

  test(
    'actions recheck the report owner before a delayed Auth stream event',
    () async {
      await generated();
      service.owner = 'bob'; // Deliberately do not emit the stream event yet.
      await controller.save();
      expect(service.saves, 0);
      expect(container.read(reportControllerProvider).localPath, isNull);
      service.owner = 'alice';
      await generated();
      service.owner = 'bob';
      await controller
          .share(); // Must not open the platform sheet with A's file.
      expect(container.read(reportControllerProvider).localPath, isNull);
      service.owner = 'alice';
      await generated();
      service.gate = Completer<SavedReport>()..complete(saved);
      await controller.save();
      service.owner = 'bob';
      await controller.download();
      expect(container.read(reportControllerProvider).result, isNull);
    },
  );
}
