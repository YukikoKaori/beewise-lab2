// ignore_for_file: subtype_of_sealed_class

import 'package:beewise/screens/beewise_screens.dart';
import 'package:beewise/services/analytics_service.dart';
import 'package:beewise/services/firebase_bootstrap.dart';
import 'package:beewise/services/remote_config_service.dart';
import 'package:beewise/theme/bee_wise_theme.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FirebaseBootstrap.ready = false;
    FirebaseBootstrap.initializationError = null;
    FirebaseBootstrap.analyticsCollectionActive = false;
  });

  group('F-FINAL-05 Firebase Analytics bootstrap & runtime opt-out', () {
    test(
      'emulator startup disables native collection and preserves user opt-out',
      () async {
        await SharedPreferencesAsync().setBool(
          FirebaseBootstrap.analyticsOptOutPrefKey,
          false,
        );
        final calls = <bool>[];
        var configuredEmulators = false;
        var activatedAppCheck = false;

        final ok = await FirebaseBootstrap.initialize(
          isEmulatorOverride: true,
          initializeFirebaseApp: () async {},
          setAnalyticsEnabled: (enabled) async => calls.add(enabled),
          configureEmulators: () async => configuredEmulators = true,
          activateAppCheck: () async => activatedAppCheck = true,
        );

        expect(ok, isTrue);
        expect(calls, [false]);
        expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
        expect(configuredEmulators, isTrue);
        expect(activatedAppCheck, isFalse);
        expect(
          await SharedPreferencesAsync().getBool(
            FirebaseBootstrap.analyticsOptOutPrefKey,
          ),
          isFalse,
        );
      },
    );

    test('in-place emulator -> Final upgrade explicitly re-enables native Analytics collection', () async {
      final calls = <bool>[];
      // Step 1: Emulator run sets analytics off (persists measurement_enabled=false natively).
      await FirebaseBootstrap.initialize(
        isEmulatorOverride: true,
        initializeFirebaseApp: () async {},
        setAnalyticsEnabled: (enabled) async => calls.add(enabled),
        configureEmulators: () async {},
        activateAppCheck: () async {},
      );
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);

      // Step 2: Upgrade to Final APK without stored user opt-out.
      var appCheckActivated = false;
      final ok = await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        initializeFirebaseApp: () async {},
        setAnalyticsEnabled: (enabled) async => calls.add(enabled),
        configureEmulators: () async {},
        activateAppCheck: () async => appCheckActivated = true,
      );

      expect(ok, isTrue);
      expect(calls, [false, true]);
      expect(FirebaseBootstrap.analyticsCollectionActive, isTrue);
      expect(appCheckActivated, isTrue);
    });

    test(
      'Final startup respects persisted user opt-out and privacy policy gate',
      () async {
        final calls = <bool>[];
        await SharedPreferencesAsync().setBool(
          FirebaseBootstrap.analyticsOptOutPrefKey,
          true,
        );

        await FirebaseBootstrap.initialize(
          isEmulatorOverride: false,
          initializeFirebaseApp: () async {},
          setAnalyticsEnabled: (enabled) async => calls.add(enabled),
          activateAppCheck: () async {},
        );
        expect(calls, [false]);
        expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);

        // Even without opt-out, privacyPolicyPermits=false keeps collection disabled.
        await SharedPreferencesAsync().setBool(
          FirebaseBootstrap.analyticsOptOutPrefKey,
          false,
        );
        await FirebaseBootstrap.initialize(
          isEmulatorOverride: false,
          privacyPolicyPermits: false,
          initializeFirebaseApp: () async {},
          setAnalyticsEnabled: (enabled) async => calls.add(enabled),
          activateAppCheck: () async {},
        );
        expect(calls, [false, false]);
        expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      },
    );

    test('setPersistedAnalyticsOptOut toggles state, persists pref, and clears userId on opt-out', () async {
      final calls = <bool>[];
      var clearedUserId = false;

      await FirebaseBootstrap.setPersistedAnalyticsOptOut(
        true,
        setAnalyticsEnabled: (enabled) async => calls.add(enabled),
        clearUserId: () async => clearedUserId = true,
      );

      expect(calls, [false]);
      expect(clearedUserId, isTrue);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        await SharedPreferencesAsync().getBool(
          FirebaseBootstrap.analyticsOptOutPrefKey,
        ),
        isTrue,
      );

      await FirebaseBootstrap.setPersistedAnalyticsOptOut(
        false,
        setAnalyticsEnabled: (enabled) async => calls.add(enabled),
      );
      expect(calls, [false, true]);
      expect(FirebaseBootstrap.analyticsCollectionActive, isTrue);
      expect(
        await SharedPreferencesAsync().getBool(
          FirebaseBootstrap.analyticsOptOutPrefKey,
        ),
        isFalse,
      );
    });

    test('AnalyticsService suppresses event/login and clamps setUserId(null) when collection disabled', () async {
      final mockAnalytics = _MockFirebaseAnalytics();
      when(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockAnalytics.logLogin(loginMethod: any(named: 'loginMethod')))
          .thenAnswer((_) async {});
      when(() => mockAnalytics.setUserId(id: any(named: 'id')))
          .thenAnswer((_) async {});

      var active = false;
      final service = AnalyticsService(
        analytics: mockAnalytics,
        isCollectionEnabled: () => active,
      );

      await service.event('ai_request', {'feature': 'tutor_need'});
      await service.login('password');
      await service.setUserId('parent-uid-123');

      verifyNever(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
      verifyNever(
        () => mockAnalytics.logLogin(loginMethod: any(named: 'loginMethod')),
      );
      verify(() => mockAnalytics.setUserId(id: null)).called(1);

      active = true;
      await service.event('ai_request', {'feature': 'tutor_need'});
      await service.setUserId('parent-uid-123');

      verify(
        () => mockAnalytics.logEvent(
          name: 'ai_request',
          parameters: {'feature': 'tutor_need'},
        ),
      ).called(1);
      verify(() => mockAnalytics.setUserId(id: 'parent-uid-123')).called(1);
    });

    testWidgets(
      'ProfileScreen analytics opt-out toggle updates persisted preference cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(412, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firebaseReadyProvider.overrideWithValue(false),
              remoteConfigProvider.overrideWithValue(RemoteConfigService(null)),
              authStateProvider.overrideWith((_) => Stream.value(null)),
              notificationsProvider.overrideWith((_) => Stream.value(const [])),
            ],
            child: MaterialApp(
              theme: BeeWiseTheme.light,
              home: const ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Gửi thống kê sử dụng ẩn danh'), findsOneWidget);
        expect(
          find.text('Chỉ ghi nhận sự kiện ẩn danh; có thể tắt bất kỳ lúc nào.'),
          findsOneWidget,
        );

        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();

        expect(
          find.text('Đã tắt thu thập Firebase Analytics trên thiết bị này.'),
          findsOneWidget,
        );
        expect(
          await SharedPreferencesAsync().getBool(
            FirebaseBootstrap.analyticsOptOutPrefKey,
          ),
          isTrue,
        );

        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();
        expect(
          find.text('Chỉ ghi nhận sự kiện ẩn danh; có thể tắt bất kỳ lúc nào.'),
          findsOneWidget,
        );
        expect(
          await SharedPreferencesAsync().getBool(
            FirebaseBootstrap.analyticsOptOutPrefKey,
          ),
          isFalse,
        );
      },
    );
  });
}
