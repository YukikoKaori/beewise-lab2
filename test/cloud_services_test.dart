// SDK classes are mocked only at the injected service boundary.
// ignore_for_file: subtype_of_sealed_class

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:beewise/services/analytics_service.dart';
import 'package:beewise/services/chat_service.dart';
import 'package:beewise/services/export_service.dart';
import 'package:beewise/services/remote_config_service.dart';
import 'package:beewise/models/tutor.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:beewise/viewmodels/controllers.dart';

class MockConfig extends Mock implements FirebaseRemoteConfig {}

class MockAnalytics extends Mock implements FirebaseAnalytics {}

class MockChat extends Mock implements ChatService {}

class TestPaths extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(File('unused.pdf'));
    registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );
  });

  test('Remote Config without Firebase keeps documented defaults', () {
    final service = RemoteConfigService(null);
    expect(service.homeTutorLimit, 6);
    expect(service.aiResultLimit, 3);
    expect(service.matchingEnabled, isTrue);
    expect(service.modelName, 'gemini-3.5-flash-lite');
  });
  test(
    'invalid Remote Config values cannot break catalog or Iterable.take',
    () {
      final config = MockConfig();
      when(() => config.getInt('home_tutor_limit')).thenReturn(0);
      when(() => config.getInt('ai_result_limit')).thenReturn(-4);
      when(() => config.getString('gemini_model')).thenReturn('  ');
      final service = RemoteConfigService(config);
      expect(service.homeTutorLimit, 6);
      expect(service.aiResultLimit, 3);
      expect(service.modelName, 'gemini-3.5-flash-lite');
      when(() => config.getInt('home_tutor_limit')).thenReturn(10000);
      when(() => config.getInt('ai_result_limit')).thenReturn(10000);
      expect(service.homeTutorLimit, 100);
      expect(service.aiResultLimit, 3);
    },
  );
  test(
    'valid Remote Config values change both behavior limits and feature gate',
    () {
      final config = MockConfig();
      when(() => config.getInt('home_tutor_limit')).thenReturn(2);
      when(() => config.getInt('ai_result_limit')).thenReturn(1);
      when(() => config.getBool('ai_matching_enabled')).thenReturn(false);
      when(() => config.getString('gemini_model'))
          .thenReturn(' gemini-3.8-flash ');
      final service = RemoteConfigService(config);
      expect(service.homeTutorLimit, 2);
      expect(service.aiResultLimit, 1);
      expect(service.matchingEnabled, isFalse);
      expect(service.modelName, 'gemini-3.8-flash');
    },
  );
  test(
    'Remote Config installs defaults before fetch and survives offline fetch',
    () async {
      final config = MockConfig();
      final calls = <String>[];
      when(() => config.setDefaults(any())).thenAnswer((_) async {
        calls.add('defaults');
      });
      when(() => config.setConfigSettings(any())).thenAnswer((_) async {
        calls.add('settings');
      });
      when(() => config.fetchAndActivate()).thenAnswer((_) async {
        calls.add('fetch');
        throw FirebaseException(
          plugin: 'firebase_remote_config',
          code: 'unavailable',
        );
      });
      await RemoteConfigService(config).initialize();
      expect(calls, ['defaults', 'settings', 'fetch']);
    },
  );
  test(
    'Analytics search is typed and contains no query text or document IDs',
    () async {
      final analytics = MockAnalytics();
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});
      when(() => analytics.setUserId(id: any(named: 'id')))
          .thenAnswer((_) async {});
      final service = AnalyticsService(analytics: analytics);
      await service.search(
        queryLength: 4,
        filterCount: 1,
        sortMode: 'price',
        resultCount: 2,
        outcome: 'results',
      );
      verify(
        () => analytics.logEvent(
          name: 'search',
          parameters: {
            'query_length': 4,
            'filter_count': 1,
            'sort_mode': 'price',
            'result_count': 2,
            'outcome': 'results',
          },
        ),
      ).called(1);
      await service.setUserId('synthetic-test-uid');
      await service.setUserId(null);
      verifyInOrder([
        () => analytics.setUserId(id: 'synthetic-test-uid'),
        () => analytics.setUserId(id: null),
      ]);
    },
  );
  test(
    'successful connection logs only the privacy-approved request category',
    () async {
      final analytics = MockAnalytics();
      final chat = MockChat();
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => chat.createConnectionRequest(
          tutorId: any(named: 'tutorId'),
          learningGoal: any(named: 'learningGoal'),
          area: any(named: 'area'),
          schedule: any(named: 'schedule'),
          note: any(named: 'note'),
        ),
      ).thenAnswer((_) async => 'synthetic-chat');
      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(analytics: analytics),
          ),
          chatServiceProvider.overrideWithValue(chat),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(connectionControllerProvider.notifier)
          .submit(
            tutorId: 'private-document-id',
            goal: 'test',
            area: 'test',
            schedule: 'test',
          );
      expect(
        container.read(connectionControllerProvider).value,
        'synthetic-chat',
      );
      verify(
        () => analytics.logEvent(
          name: 'connection_request_submitted',
          parameters: {'request_type': 'parent_connection'},
        ),
      ).called(1);
    },
  );
  test('actual tutor PDF generation uses bundled Vietnamese fonts and writes a PDF', () async {
    final original = PathProviderPlatform.instance;
    PathProviderPlatform.instance = TestPaths();
    addTearDown(() {
      PathProviderPlatform.instance = original;
    });
    const tutor = Tutor(
      id: 'bao-synthetic-local-only',
      name: 'SYNTHETIC - Kiểm thử PDF',
      credential: 'Local fixture',
      introduction: 'Dữ liệu kiểm thử tổng hợp, không phải hồ sơ gia sư thật.',
      subjects: ['Toán'],
      grades: ['8'],
      hourlyFee: 98765,
      areas: ['Khu vực kiểm thử'],
      teachingModes: ['online'],
      availability: 'Lịch kiểm thử',
      verified: false,
      active: false,
    );
    final report = await ExportService(null, null).buildTutorSummary(tutor);
    final bytes = await report.file.readAsBytes();
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, report.sizeBytes);
    expect(bytes.length, greaterThan(1000));
    // Retain the original locally generated artifact for independent extraction.
    // This fixture is never inserted into Firestore or the application catalog.
    // ignore: avoid_print
    print('LOCAL_PDF_EVIDENCE=${report.file.path}');
  });
}
