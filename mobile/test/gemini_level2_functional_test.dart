// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'dart:convert';

import 'package:beewise/screens/beewise_screens.dart';
import 'package:beewise/screens/confirm_tutor_need_screen.dart';
import 'package:beewise/services/analytics_service.dart';
import 'package:beewise/services/matching_service.dart';
import 'package:beewise/services/need_normalizer.dart';
import 'package:beewise/services/remote_config_service.dart';
import 'package:beewise/services/tutor_application_service.dart';
import 'package:beewise/services/tutor_repository.dart';
import 'package:beewise/theme/bee_wise_theme.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:beewise_core/beewise_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

class _FakeTutorRepo implements TutorRepository {
  _FakeTutorRepo({this.tutors = const [], this.error});

  List<Tutor> tutors;
  Object? error;
  int calls = 0;

  @override
  Future<List<Tutor>> activeTutors({int limit = 50}) async {
    calls++;
    if (error != null) throw error!;
    return tutors;
  }

  @override
  Future<Tutor> tutorById(String id) async =>
      tutors.firstWhere((t) => t.id == id);
}

class _ConfigurableRc extends RemoteConfigService {
  _ConfigurableRc({this.enabled = true, this.limit = 3}) : super(null);
  final bool enabled;
  final int limit;

  @override
  bool get matchingEnabled => enabled;

  @override
  int get aiResultLimit => limit;
}

Tutor _tutor(
  String id, {
  required String name,
  required List<String> areas,
  int fee = 180000,
  String subject = 'Toán',
  bool active = true,
  bool synthetic = false,
}) => Tutor(
  id: id,
  name: name,
  credential: 'Cử nhân Sư phạm',
  introduction: 'Gia sư có kinh nghiệm dạy kèm 1-1 tận tâm.',
  subjects: [subject],
  grades: const ['Lớp 9'],
  hourlyFee: fee,
  areas: areas,
  teachingModes: const ['online', 'in_person'],
  availability: 'Buổi tối, cuối tuần',
  verified: true,
  active: active,
  isSyntheticTestFixture: synthetic,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );
  });

  group('F-FINAL-04 & providerSafeNeed vocabulary alignment', () {
    test('providerSafeNeed canonicalizes all supported geographic aliases & strips PII', () {
      expect(
        providerSafeNeed(
          'Nguyễn Văn An 0912345678 an@example.com https://evil.test '
          'tìm gia sư Toán lớp 9 ở Thành phố Hồ Chí Minh, ưu tiên Quận Cầu Giấy, '
          'tối đa 250k buổi tối',
        ),
        'Toán · lớp 9 · TP.HCM · ưu tiên · Cầu Giấy · giới hạn 250000 VND · buổi tối',
      );
      expect(
        providerSafeNeed('Học ở TP HCM hoặc q1 hoặc Ha Noi'),
        'TP.HCM · hoặc · Quận 1 · hoặc · Hà Nội',
      );
      expect(providerSafeNeed('  Sài Gòn  '), 'TP.HCM');
    });

    test('NeedNormalizer respects disabled Remote Config without calling generator', () async {
      var called = false;
      final parser = NeedNormalizer(
        _ConfigurableRc(enabled: false),
        generate: (_, _, _) async {
          called = true;
          return '{}';
        },
      );
      await expectLater(
        () => parser.parse('Toán lớp 9 ở Hà Nội'),
        throwsA(isA<MatchingException>()),
      );
      expect(called, isFalse);
    });

    test('NeedNormalizer accepts canonical tokens and geographical aliases hinted by input', () async {
      final parser = NeedNormalizer(
        RemoteConfigService(null),
        generate: (_, _, safeInput) async {
          expect(safeInput, contains('TP.HCM'));
          return jsonEncode({
            'subject': 'Toán',
            'grade': 9,
            'location': 'Thành phố Hồ Chí Minh',
            'maxHourlyFee': 200000,
            'schedule': 'buổi tối',
            'teachingMode': null,
          });
        },
      );

      final parsed = await parser.parse(
        'Toán lớp 9 ở Sài Gòn, học phí dưới 200k, buổi tối',
      );
      expect(parsed.location, 'TP.HCM');
      expect(parsed.subject, 'Toán');
    });

    test('matchConfirmedNeed & filterTutors match legacy and city/district aliases cleanly', () {
      final legacyHcmTutor = _tutor(
        't-legacy-hcm',
        name: 'Cô Lan',
        areas: const ['Thành phố Hồ Chí Minh'],
      );
      final cauGiayTutor = _tutor(
        't-cg',
        name: 'Thầy Hùng',
        areas: const ['Cầu Giấy'],
      );
      final q3Tutor = _tutor('t-q3', name: 'Cô Mai', areas: const ['Quận 3']);
      final syntheticTutor = _tutor(
        'bao-lab3-fixture',
        name: 'Synthetic',
        areas: const ['TP.HCM'],
        synthetic: true,
      );
      final candidates = [
        legacyHcmTutor,
        cauGiayTutor,
        q3Tutor,
        syntheticTutor,
      ];

      // Searching Thủ Đức / Quận 1 matches city-wide legacy HCM tutor, excludes Quận 3 and synthetic.
      expect(
        matchConfirmedNeed(
          candidates,
          const NormalizedTutorNeed(subject: 'Toán', location: 'Quận 1'),
        ).map((t) => t.id),
        ['t-legacy-hcm'],
      );
      // Searching Hà Nội matches tutor in Cầu Giấy.
      expect(
        matchConfirmedNeed(
          candidates,
          const NormalizedTutorNeed(subject: 'Toán', location: 'Hà Nội'),
        ).map((t) => t.id),
        ['t-cg'],
      );
      // Free-text & chip search via filterTutors supports geographical aliases.
      expect(
        filterTutors(
          candidates,
          const TutorSearchCriteria(query: 'Sài Gòn', area: 'TP.HCM'),
        ).map((t) => t.id),
        containsAll(['t-legacy-hcm', 't-q3']),
      );
      expect(
        filterTutors(
          candidates,
          const TutorSearchCriteria(area: 'Hà Nội'),
        ).map((t) => t.id),
        ['t-cg'],
      );
    });

    test('TutorApplicationService.resubmissionServerBlockMessage reflects Final rules accurately', () {
      expect(
        TutorApplicationService.resubmissionServerBlockMessage,
        isNot(contains('tutorApplications.update = false')),
      );
      expect(
        TutorApplicationService.resubmissionServerBlockMessage,
        contains('BEEWISE_FINAL_FIRESTORE=true'),
      );
    });
  });

  group('F-FINAL-02 duplicate ai_result_accepted fix & ConfirmTutorNeedScreen flows', () {
    late _MockAnalytics mockAnalytics;
    late List<({String name, Map<String, Object>? params})> loggedEvents;

    setUp(() {
      mockAnalytics = _MockAnalytics();
      loggedEvents = [];
      when(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((inv) async {
        loggedEvents.add((
          name: inv.namedArguments[#name] as String,
          params: (inv.namedArguments[#parameters] as Map?)
              ?.cast<String, Object>(),
        ));
      });
    });

    Widget buildScreen({
      required NeedNormalizer normalizer,
      required TutorRepository repo,
      RemoteConfigService? rc,
      Stream<String?>? uidStream,
    }) => ProviderScope(
      overrides: [
        firebaseReadyProvider.overrideWithValue(true),
        analyticsServiceProvider.overrideWithValue(
          AnalyticsService(analytics: mockAnalytics),
        ),
        remoteConfigProvider.overrideWithValue(rc ?? _ConfigurableRc()),
        remoteConfigInitializationProvider.overrideWith((_) async {}),
        needNormalizerProvider.overrideWithValue(normalizer),
        tutorRepositoryProvider.overrideWithValue(repo),
        if (uidStream != null)
          currentAuthenticatedUidProvider.overrideWithValue('parent-1'),
      ],
      child: MaterialApp(
        theme: BeeWiseTheme.light,
        home: const ConfirmTutorNeedScreen(),
      ),
    );

    testWidgets(
      'logs ai_result_accepted once per AI parse across errors, retries, filter edits, and manual confirm',
      (tester) async {
        tester.view.physicalSize = const Size(412, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final repo = _FakeTutorRepo(
          error: StateError('Transient network error'),
        );
        final parser = NeedNormalizer(
          _ConfigurableRc(),
          generate: (_, _, _) async => jsonEncode({
            'subject': 'Toán',
            'grade': 9,
            'location': 'Thủ Đức',
            'maxHourlyFee': 200000,
            'schedule': 'buổi tối',
            'teachingMode': null,
          }),
        );

        await tester.pumpWidget(buildScreen(normalizer: parser, repo: repo));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'Toán lớp 9 ở Thủ Đức, học phí dưới 200k, buổi tối',
        );
        await tester.tap(find.text('Phân tích nhu cầu bằng AI'));
        await tester.pumpAndSettle();

        expect(find.text('Gợi ý AI · Kiểm tra và chỉnh sửa'), findsOneWidget);
        expect(loggedEvents.where((e) => e.name == 'ai_request'), hasLength(1));
        expect(
          loggedEvents.where((e) => e.name == 'ai_result_accepted'),
          isEmpty,
        );

        // 1st confirm fails during repository fetch -> still logs acceptance once!
        await tester.tap(find.text('Xác nhận và tìm gia sư'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Chưa tải được danh mục gia sư. Kiểm tra kết nối rồi tìm lại.',
          ),
          findsOneWidget,
        );
        expect(
          loggedEvents.where((e) => e.name == 'ai_result_accepted'),
          hasLength(1),
        );

        // Edit max fee filter and retry confirm with working repository -> NO duplicate acceptance!
        repo.error = null;
        repo.tutors = [
          _tutor(
            't-1',
            name: 'Thầy Minh',
            areas: const ['Thủ Đức'],
            fee: 190000,
          ),
        ];
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phí tối đa mỗi giờ (VND)'),
          '250000',
        );
        await tester.tap(find.text('Xác nhận và tìm gia sư'));
        await tester.pumpAndSettle();
        expect(find.text('Thầy Minh'), findsOneWidget);
        expect(
          loggedEvents.where((e) => e.name == 'ai_result_accepted'),
          hasLength(1),
        );

        // Edit fee again & re-confirm without running a new AI parse -> STILL 1 acceptance!
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Phí tối đa mỗi giờ (VND)'),
          '300000',
        );
        await tester.tap(find.text('Xác nhận và tìm gia sư'));
        await tester.pumpAndSettle();
        expect(
          loggedEvents.where((e) => e.name == 'ai_result_accepted'),
          hasLength(1),
        );

        // Trigger a fresh 2nd AI parse -> acceptance flag resets and logs 2nd time on confirm.
        await tester.tap(find.text('Phân tích nhu cầu bằng AI'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xác nhận và tìm gia sư'));
        await tester.pumpAndSettle();
        expect(loggedEvents.where((e) => e.name == 'ai_request'), hasLength(2));
        expect(
          loggedEvents.where((e) => e.name == 'ai_result_accepted'),
          hasLength(2),
        );

        // Switch to manual form -> confirming manually does NOT increment ai_result_accepted.
        await tester.tap(find.text('Tự điền bộ lọc'));
        await tester.pumpAndSettle();
        expect(find.text('Yêu cầu học tập'), findsOneWidget);
        await tester.tap(find.text('Xác nhận và tìm gia sư'));
        await tester.pumpAndSettle();
        expect(
          loggedEvents.where((e) => e.name == 'ai_result_accepted'),
          hasLength(2),
        );
      },
    );

    testWidgets(
      'logs typed ai_error events, preserves input, and supports manual fallback + result limit clamping',
      (tester) async {
        tester.view.physicalSize = const Size(412, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        late Object nextError;
        final parser = NeedNormalizer(
          _ConfigurableRc(limit: 2),
          generate: (_, _, _) async => throw nextError,
        );
        final repo = _FakeTutorRepo(
          tutors: [
            _tutor('t-1', name: 'Gia sư 1', areas: const ['TP.HCM']),
            _tutor('t-2', name: 'Gia sư 2', areas: const ['TP.HCM']),
            _tutor('t-3', name: 'Gia sư 3', areas: const ['TP.HCM']),
          ],
        );

        await tester.pumpWidget(
          buildScreen(
            normalizer: parser,
            repo: repo,
            rc: _ConfigurableRc(limit: 2),
          ),
        );
        await tester.pumpAndSettle();

        const userText = 'Toán lớp 9 ở Sài Gòn';
        await tester.enterText(find.byType(TextField).first, userText);

        for (final entry in <(Object, String)>[
          (TimeoutException('slow'), 'timeout'),
          (const FormatException('bad json'), 'invalid_response'),
          (const MatchingException('disabled'), 'unavailable'),
          (StateError('unexpected'), 'provider'),
        ]) {
          nextError = entry.$1;
          await tester.tap(find.text('Phân tích nhu cầu bằng AI'));
          await tester.pumpAndSettle();
          expect(
            find.text('Chưa lấy được gợi ý AI. Thử lại hoặc tự điền bộ lọc.'),
            findsOneWidget,
          );
          expect(loggedEvents.last.name, 'ai_error');
          expect(loggedEvents.last.params, {
            'feature': 'tutor_need',
            'kind': entry.$2,
          });
          // Original description stays preserved across AI failures.
          expect(find.text(userText), findsOneWidget);
        }

        // Fallback to manual filter still respects aiResultLimit = 2.
        await tester.tap(find.text('Tự điền bộ lọc'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xác nhận và tìm gia sư'));
        await tester.pumpAndSettle();
        expect(find.text('Gia sư 1'), findsOneWidget);
        expect(find.text('Gia sư 2'), findsOneWidget);
        expect(find.text('Gia sư 3'), findsNothing);
      },
    );

    testWidgets(
      'Remote Config ai_matching_enabled=false disables AI button while keeping manual flow active',
      (tester) async {
        tester.view.physicalSize = const Size(412, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final rcMock = _MockRemoteConfig();
        when(() => rcMock.getBool('ai_matching_enabled')).thenReturn(false);
        when(() => rcMock.getInt('ai_result_limit')).thenReturn(10);
        when(() => rcMock.getInt('home_tutor_limit')).thenReturn(6);
        when(() => rcMock.getString('gemini_model'))
            .thenReturn('gemini-2.5-flash');
        when(() => rcMock.getString('ai_need_prompt')).thenReturn('');
        when(() => rcMock.setDefaults(any())).thenAnswer((_) async {});
        when(() => rcMock.setConfigSettings(any())).thenAnswer((_) async {});
        when(() => rcMock.fetchAndActivate()).thenAnswer((_) async => false);

        final rc = RemoteConfigService(rcMock);
        expect(rc.aiResultLimit, 3); // Clamped to <= 3 per contract.

        await tester.pumpWidget(
          buildScreen(
            normalizer: NeedNormalizer(rc),
            repo: _FakeTutorRepo(),
            rc: rc,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'AI hiện không khả dụng. Bạn vẫn có thể tự điền và tìm gia sư.',
          ),
          findsOneWidget,
        );
        final aiButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Phân tích nhu cầu bằng AI'),
        );
        expect(aiButton.onPressed, isNull);
        expect(find.text('Tự điền bộ lọc'), findsOneWidget);
      },
    );

    testWidgets('account switch clears in-flight AI form and description', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final uidNotifier = NotifierProvider<_TestUidNotifier, String?>(
        _TestUidNotifier.new,
      );
      final container = ProviderContainer(
        overrides: [
          firebaseReadyProvider.overrideWithValue(true),
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(analytics: mockAnalytics),
          ),
          remoteConfigProvider.overrideWithValue(_ConfigurableRc()),
          remoteConfigInitializationProvider.overrideWith((_) async {}),
          needNormalizerProvider.overrideWithValue(
            NeedNormalizer(
              _ConfigurableRc(),
              generate: (_, _, _) async => jsonEncode({
                'subject': 'Toán',
                'grade': 9,
                'location': 'Hà Nội',
                'maxHourlyFee': null,
                'schedule': null,
                'teachingMode': null,
              }),
            ),
          ),
          tutorRepositoryProvider.overrideWithValue(_FakeTutorRepo()),
          currentAuthenticatedUidProvider.overrideWith(
            (ref) => ref.watch(uidNotifier),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: BeeWiseTheme.light,
            home: const ConfirmTutorNeedScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Toán lớp 9 Hà Nội');
      await tester.tap(find.text('Phân tích nhu cầu bằng AI'));
      await tester.pumpAndSettle();
      expect(find.text('Gợi ý AI · Kiểm tra và chỉnh sửa'), findsOneWidget);

      container.read(uidNotifier.notifier).setUid('parent-b');
      await tester.pumpAndSettle();

      expect(find.text('Gợi ý AI · Kiểm tra và chỉnh sửa'), findsNothing);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, isEmpty);
    });

    testWidgets(
      'SearchScreen exposes all canonical areas at 360dp width and matches aliases cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(360, 2600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final hcmTutor = _tutor(
          't-hcm',
          name: 'Thầy Nam',
          areas: const ['Thành phố Hồ Chí Minh'],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firebaseReadyProvider.overrideWithValue(true),
              tutorSearchProvider.overrideWith(
                (ref, criteria) async => filterTutors([hcmTutor], criteria),
              ),
            ],
            child: MaterialApp(
              theme: BeeWiseTheme.light,
              home: const SearchScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        for (final city in ['TP.HCM', 'Hà Nội', 'Đà Nẵng', 'Hai Bà Trưng']) {
          expect(find.text(city), findsOneWidget);
        }

        await tester.tap(find.text('TP.HCM'));
        await tester.pumpAndSettle();
        expect(find.text('Thầy Nam'), findsOneWidget);
      },
    );
  });
}

class _TestUidNotifier extends Notifier<String?> {
  @override
  String? build() => 'parent-a';

  void setUid(String? uid) => state = uid;
}
