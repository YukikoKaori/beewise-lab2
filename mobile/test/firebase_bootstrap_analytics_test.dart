// ignore_for_file: subtype_of_sealed_class

import 'package:beewise/screens/beewise_screens.dart';
import 'package:beewise/services/analytics_service.dart';
import 'package:beewise/services/crash_reporting_service.dart';
import 'package:beewise/services/export_service.dart';
import 'package:beewise/services/firebase_bootstrap.dart';
import 'package:beewise/services/notification_service.dart';
import 'package:beewise/services/remote_config_service.dart';
import 'package:beewise/theme/bee_wise_theme.dart';
import 'package:beewise/viewmodels/app_providers.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class _MockUser extends Mock implements User {}

class _FakePreferenceStore implements AnalyticsPreferenceStore {
  _FakePreferenceStore({this.storedOptOut, this.readError, this.writeError});

  bool? storedOptOut;
  Object? readError;
  Object? writeError;
  int readCalls = 0;
  final List<bool> writes = <bool>[];

  @override
  Future<bool?> readOptOut() async {
    readCalls++;
    if (readError != null) throw readError!;
    return storedOptOut;
  }

  @override
  Future<void> writeOptOut(bool optedOut) async {
    if (writeError != null) throw writeError!;
    writes.add(optedOut);
    storedOptOut = optedOut;
  }
}

class _FakeSdkGateway implements AnalyticsSdkGateway {
  _FakeSdkGateway({this.enableError, this.disableError});

  Object? enableError;
  Object? disableError;
  bool nativeCollectionEnabled = false;
  int clearUserIdCount = 0;
  final List<bool> enabledCalls = <bool>[];

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    enabledCalls.add(enabled);
    if (enabled && enableError != null) throw enableError!;
    if (!enabled && disableError != null) throw disableError!;
    nativeCollectionEnabled = enabled;
  }

  @override
  Future<void> clearUserId() async {
    clearUserIdCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FirebaseBootstrap.ready = false;
    FirebaseBootstrap.initializationError = null;
    FirebaseBootstrap.analyticsCollectionActive = false;
    FirebaseBootstrap.analyticsPolicyPermits = true;
    FirebaseBootstrap.analyticsPrivacyState = const AnalyticsPrivacyState(
      bootstrapReady: false,
    );
  });

  group('F-FINAL-05 Firebase Analytics fail-closed privacy state machine', () {
    test('1. emulator startup disables native collection, clears userId, and preserves stored user opt-out', () async {
      final store = _FakePreferenceStore(storedOptOut: false);
      final sdk = _FakeSdkGateway()..nativeCollectionEnabled = true;
      var configuredEmulators = false;
      var activatedAppCheck = false;

      final ok = await FirebaseBootstrap.initialize(
        isEmulatorOverride: true,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        configureEmulators: () async => configuredEmulators = true,
        activateAppCheck: () async => activatedAppCheck = true,
      );

      expect(ok, isTrue);
      expect(sdk.enabledCalls, [false]);
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(sdk.clearUserIdCount, 1);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.isCollectionEnabled,
        isFalse,
      );
      expect(configuredEmulators, isTrue);
      expect(activatedAppCheck, isFalse);
      expect(store.storedOptOut, isFalse);
      expect(store.writes, isEmpty);
    });

    test('2. in-place emulator -> Final upgrade with absent preference uses documented opt-out default and re-enables native SDK', () async {
      final store = _FakePreferenceStore(storedOptOut: null);
      final sdk = _FakeSdkGateway();

      // Step 1: Emulator run keeps analytics disabled natively.
      await FirebaseBootstrap.initialize(
        isEmulatorOverride: true,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        configureEmulators: () async {},
        activateAppCheck: () async {},
      );
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(sdk.enabledCalls, [false]);

      // Step 2: Upgrade to Final build with readable, absent preference under permitted policy.
      var appCheckActivated = false;
      final ok = await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        configureEmulators: () async {},
        activateAppCheck: () async => appCheckActivated = true,
      );

      expect(ok, isTrue);
      expect(sdk.enabledCalls, [false, true]);
      expect(sdk.nativeCollectionEnabled, isTrue);
      expect(FirebaseBootstrap.analyticsCollectionActive, isTrue);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.preferenceStatus,
        AnalyticsPreferenceStatus.absent,
      );
      expect(appCheckActivated, isTrue);
    });

    test('3. Final startup respects persisted user opt-out and privacy policy gate', () async {
      final store = _FakePreferenceStore(storedOptOut: true);
      final sdk = _FakeSdkGateway()..nativeCollectionEnabled = true;

      await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        activateAppCheck: () async {},
      );
      expect(sdk.enabledCalls, [false]);
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(sdk.clearUserIdCount, 1);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.preferenceStatus,
        AnalyticsPreferenceStatus.optedOut,
      );

      // Even with optedOut == false, privacyPolicyPermits=false keeps collection off.
      store.storedOptOut = false;
      await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        privacyPolicyPermits: false,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        activateAppCheck: () async {},
      );
      expect(sdk.enabledCalls, [false, false]);
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.privacyPolicyPermits,
        isFalse,
      );
    });

    test('4. failed preference read is never treated as absent and fails closed (with recovery on next read)', () async {
      final store = _FakePreferenceStore(
        storedOptOut: true,
        readError: StateError('disk I/O failure'),
      );
      final sdk = _FakeSdkGateway()..nativeCollectionEnabled = true;

      final ok = await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        activateAppCheck: () async {},
      );

      expect(ok, isTrue);
      expect(sdk.enabledCalls, [false]);
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(sdk.clearUserIdCount, 1);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.preferenceStatus,
        AnalyticsPreferenceStatus.readFailed,
      );
      expect(
        FirebaseBootstrap.analyticsPrivacyState.failureKind,
        AnalyticsPrivacyFailureKind.readFailed,
      );

      // Recover storage while user preference is still optedOut=true -> stays disabled!
      store.readError = null;
      await FirebaseBootstrap.reconcileAnalyticsPrivacy(
        isEmulator: false,
        preferenceStore: store,
        sdkGateway: sdk,
      );
      expect(sdk.enabledCalls, [false, false]);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.preferenceStatus,
        AnalyticsPreferenceStatus.optedOut,
      );

      // If recovered preference is optedIn (false), collection resumes cleanly.
      store.storedOptOut = false;
      await FirebaseBootstrap.reconcileAnalyticsPrivacy(
        isEmulator: false,
        preferenceStore: store,
        sdkGateway: sdk,
      );
      expect(sdk.enabledCalls, [false, false, true]);
      expect(FirebaseBootstrap.analyticsCollectionActive, isTrue);
    });

    test('5. explicit opt-out disables native SDK & clears userId immediately even when persistence fails, and throws instead of silent success', () async {
      final store = _FakePreferenceStore(
        storedOptOut: false,
        writeError: StateError('readonly storage'),
      );
      final sdk = _FakeSdkGateway()..nativeCollectionEnabled = true;

      await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        activateAppCheck: () async {},
      );
      expect(FirebaseBootstrap.analyticsCollectionActive, isTrue);

      await expectLater(
        () => FirebaseBootstrap.setPersistedAnalyticsOptOut(
          true,
          preferenceStore: store,
          sdkGateway: sdk,
        ),
        throwsA(isA<AnalyticsPrivacyException>()),
      );

      // Immediate native fail-closed behavior took effect before throwing.
      expect(sdk.enabledCalls, [true, false]);
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(sdk.clearUserIdCount, 1);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.failureKind,
        AnalyticsPrivacyFailureKind.persistenceFailed,
      );
      expect(
        FirebaseBootstrap.analyticsPrivacyState.failedOptOutIntent,
        isTrue,
      );
      // Must NOT pretend preference was durably written as optedOut.
      expect(
        FirebaseBootstrap.analyticsPrivacyState.preferenceStatus,
        isNot(AnalyticsPreferenceStatus.optedOut),
      );
      expect(store.storedOptOut, isFalse);
    });

    test('6. failed persistence on opt-in never enables native SDK and keeps collection disabled', () async {
      final store = _FakePreferenceStore(
        storedOptOut: true,
        writeError: StateError('write failure'),
      );
      final sdk = _FakeSdkGateway();

      await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        activateAppCheck: () async {},
      );
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);

      await expectLater(
        () => FirebaseBootstrap.setPersistedAnalyticsOptOut(
          false,
          preferenceStore: store,
          sdkGateway: sdk,
        ),
        throwsA(isA<AnalyticsPrivacyException>()),
      );

      expect(sdk.enabledCalls, isNot(contains(true)));
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.failureKind,
        AnalyticsPrivacyFailureKind.persistenceFailed,
      );
      expect(store.storedOptOut, isTrue);
    });

    test('7. setPersistedAnalyticsOptOut(false) refuses to enable collection when privacyPolicyPermits is false or in emulator mode', () async {
      final store = _FakePreferenceStore(storedOptOut: true);
      final sdk = _FakeSdkGateway();

      await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        privacyPolicyPermits: false,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        activateAppCheck: () async {},
      );
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);

      // Even without passing privacyPolicyPermits again, persisted startup gate forbids opt-in!
      await expectLater(
        () => FirebaseBootstrap.setPersistedAnalyticsOptOut(
          false,
          preferenceStore: store,
          sdkGateway: sdk,
        ),
        throwsA(isA<AnalyticsPrivacyException>()),
      );
      expect(sdk.enabledCalls, isNot(contains(true)));
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(store.storedOptOut, isTrue);

      // Emulator mode gate likewise blocks enabling collection.
      await expectLater(
        () => FirebaseBootstrap.setPersistedAnalyticsOptOut(
          false,
          isEmulator: true,
          privacyPolicyPermits: true,
          preferenceStore: store,
          sdkGateway: sdk,
        ),
        throwsA(isA<AnalyticsPrivacyException>()),
      );
      expect(sdk.enabledCalls, isNot(contains(true)));
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
    });

    test('8. native SDK synchronization failure fails closed on both bootstrap and opt-in toggle', () async {
      final store = _FakePreferenceStore(storedOptOut: false);
      final sdk = _FakeSdkGateway(
        enableError: StateError('Play Services measurement unavailable'),
      )..nativeCollectionEnabled = true;

      await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        initializeFirebaseApp: () async {},
        preferenceStore: store,
        sdkGateway: sdk,
        activateAppCheck: () async {},
      );

      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.failureKind,
        AnalyticsPrivacyFailureKind.sdkSyncFailed,
      );
      // Defensive disable call followed failed enable attempt.
      expect(sdk.enabledCalls, [true, false]);
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(sdk.clearUserIdCount, 1);

      // Opt-in toggle fails loudly and stays disabled when SDK enable fails.
      await expectLater(
        () => FirebaseBootstrap.setPersistedAnalyticsOptOut(
          false,
          preferenceStore: store,
          sdkGateway: sdk,
        ),
        throwsA(isA<AnalyticsPrivacyException>()),
      );
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(sdk.nativeCollectionEnabled, isFalse);

      // Opt-out toggle also fails loudly when disabling native SDK itself throws,
      // while keeping in-app collection fail-closed.
      final disableFailingSdk = _FakeSdkGateway(
        disableError: StateError('native disable threw'),
      )..nativeCollectionEnabled = true;
      await expectLater(
        () => FirebaseBootstrap.setPersistedAnalyticsOptOut(
          true,
          preferenceStore: store,
          sdkGateway: disableFailingSdk,
        ),
        throwsA(isA<AnalyticsPrivacyException>()),
      );
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.failureKind,
        AnalyticsPrivacyFailureKind.sdkSyncFailed,
      );
    });

    test('9. Firebase bootstrap failure leaves collection disabled even if app check fails after FirebaseApp init', () async {
      final store = _FakePreferenceStore(storedOptOut: null);
      final sdk = _FakeSdkGateway()..nativeCollectionEnabled = true;

      final ok = await FirebaseBootstrap.initialize(
        isEmulatorOverride: false,
        initializeFirebaseApp: () async {},
        activateAppCheck: () async => throw StateError('app check failed'),
        preferenceStore: store,
        sdkGateway: sdk,
      );

      expect(ok, isFalse);
      expect(FirebaseBootstrap.ready, isFalse);
      expect(FirebaseBootstrap.analyticsCollectionActive, isFalse);
      expect(
        FirebaseBootstrap.analyticsPrivacyState.failureKind,
        AnalyticsPrivacyFailureKind.bootstrapFailed,
      );
      expect(sdk.enabledCalls, [false]);
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(sdk.clearUserIdCount, 1);
    });

    test('10. AnalyticsService suppresses event/login and clamps setUserId(null) whenever collection disabled', () async {
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

    test('11. opting out while signed in immediately clears native analytics userId via Riverpod pipeline', () async {
      final store = _FakePreferenceStore(storedOptOut: null);
      final sdk = _FakeSdkGateway();
      final mockAnalytics = _MockFirebaseAnalytics();
      when(() => mockAnalytics.setUserId(id: any(named: 'id')))
          .thenAnswer((_) async {});
      when(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      final user = _MockUser();
      when(() => user.uid).thenReturn('parent-signed-in');
      when(() => user.isAnonymous).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          firebaseReadyProvider.overrideWithValue(true),
          analyticsPrivacyPolicyPermitsProvider.overrideWithValue(true),
          analyticsPreferenceStoreProvider.overrideWithValue(store),
          analyticsSdkGatewayProvider.overrideWithValue(sdk),
          analyticsInstanceProvider.overrideWithValue(mockAnalytics),
          authStateProvider.overrideWith((_) => Stream.value(user)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(analyticsPrivacyProvider, (_, _) {});
      await pumpEventQueue();
      expect(
        container.read(analyticsPrivacyProvider).isCollectionEnabled,
        isTrue,
      );

      final ok = await container
          .read(analyticsPrivacyProvider.notifier)
          .setOptOut(true);
      expect(ok, isTrue);
      expect(sdk.nativeCollectionEnabled, isFalse);
      expect(sdk.clearUserIdCount, greaterThanOrEqualTo(1));
      expect(
        container.read(analyticsPrivacyProvider).isCollectionEnabled,
        isFalse,
      );
      expect(container.read(analyticsOptOutProvider), isTrue);

      // Even an attempted event now does nothing and setUserId clamps to null.
      await container.read(analyticsServiceProvider).event('search', {});
      await container
          .read(analyticsServiceProvider)
          .setUserId('parent-signed-in');
      verifyNever(
        () => mockAnalytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
      verify(() => mockAnalytics.setUserId(id: null)).called(1);
    });

    testWidgets(
      '12. ProfileScreen opt-out switch reflects real state, handles save failure & retry cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(412, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final store = _FakePreferenceStore(storedOptOut: null);
        final sdk = _FakeSdkGateway();

        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('case-a'),
            overrides: [
              firebaseReadyProvider.overrideWithValue(true),
              analyticsPrivacyPolicyPermitsProvider.overrideWithValue(true),
              analyticsPreferenceStoreProvider.overrideWithValue(store),
              analyticsSdkGatewayProvider.overrideWithValue(sdk),
              remoteConfigProvider.overrideWithValue(RemoteConfigService(null)),
              notificationServiceProvider.overrideWithValue(
                NotificationService(null, null, null),
              ),
              exportServiceProvider.overrideWithValue(
                ExportService(null, null),
              ),
              crashReportingServiceProvider.overrideWithValue(
                CrashReportingService(crashlytics: null),
              ),
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
        expect(sdk.nativeCollectionEnabled, isTrue);

        // Fail preference persistence on opt-out -> native SDK MUST still disable
        // immediately, and UI MUST expose the non-durable save error with retry!
        store.writeError = StateError('disk full');
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();

        expect(sdk.nativeCollectionEnabled, isFalse);
        expect(sdk.clearUserIdCount, 1);
        expect(
          find.text('Tạm tắt trong phiên này; chưa lưu được vào thiết bị.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('không thể lưu tùy chọn vào bộ nhớ thiết bị'),
          findsOneWidget,
        );

        // Recover disk write and tap Retry -> saves cleanly and clears error.
        store.writeError = null;
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();

        expect(store.storedOptOut, isTrue);
        expect(
          find.text('Đã tắt thu thập Firebase Analytics trên thiết bị này.'),
          findsOneWidget,
        );
        expect(
          find.textContaining('không thể lưu tùy chọn vào bộ nhớ thiết bị'),
          findsNothing,
        );

        // Toggle back ON cleanly.
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();
        expect(store.storedOptOut, isFalse);
        expect(sdk.nativeCollectionEnabled, isTrue);
        expect(
          find.text('Chỉ ghi nhận sự kiện ẩn danh; có thể tắt bất kỳ lúc nào.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '13. ProfileScreen fails closed on read failure, policy block, and unready bootstrap',
      (tester) async {
        tester.view.physicalSize = const Size(412, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // Case A: read failure on startup -> Switch OFF + visible error + Retry recovery.
        final store = _FakePreferenceStore(
          storedOptOut: true,
          readError: StateError('corrupt prefs'),
        );
        final sdk = _FakeSdkGateway()..nativeCollectionEnabled = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              firebaseReadyProvider.overrideWithValue(true),
              analyticsPrivacyPolicyPermitsProvider.overrideWithValue(true),
              analyticsPreferenceStoreProvider.overrideWithValue(store),
              analyticsSdkGatewayProvider.overrideWithValue(sdk),
              remoteConfigProvider.overrideWithValue(RemoteConfigService(null)),
              notificationServiceProvider.overrideWithValue(
                NotificationService(null, null, null),
              ),
              exportServiceProvider.overrideWithValue(
                ExportService(null, null),
              ),
              crashReportingServiceProvider.overrideWithValue(
                CrashReportingService(crashlytics: null),
              ),
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

        final switchAfterReadError = tester.widget<Switch>(
          find.byType(Switch).first,
        );
        expect(switchAfterReadError.value, isFalse);
        expect(sdk.nativeCollectionEnabled, isFalse);
        expect(
          find.text(
            'Không đọc được tùy chọn quyền riêng tư; thu thập đang tắt.',
          ),
          findsOneWidget,
        );
        expect(find.text('Thử lại'), findsOneWidget);

        // Recover prefs with optedIn (`false`) and tap Retry -> restores cleanly.
        store.readError = null;
        store.storedOptOut = false;
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
        expect(sdk.nativeCollectionEnabled, isTrue);

        // Case B: privacy policy prohibits collection -> Switch locked OFF.
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('case-b'),
            overrides: [
              firebaseReadyProvider.overrideWithValue(true),
              analyticsPrivacyPolicyPermitsProvider.overrideWithValue(false),
              analyticsPreferenceStoreProvider.overrideWithValue(store),
              analyticsSdkGatewayProvider.overrideWithValue(sdk),
              remoteConfigProvider.overrideWithValue(RemoteConfigService(null)),
              notificationServiceProvider.overrideWithValue(
                NotificationService(null, null, null),
              ),
              exportServiceProvider.overrideWithValue(
                ExportService(null, null),
              ),
              crashReportingServiceProvider.overrideWithValue(
                CrashReportingService(crashlytics: null),
              ),
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

        final policySwitch = tester.widget<Switch>(find.byType(Switch).first);
        expect(policySwitch.value, isFalse);
        expect(policySwitch.onChanged, isNull);
        expect(sdk.nativeCollectionEnabled, isFalse);
        expect(
          find.text(
            'Chính sách quyền riêng tư hiện không cho phép thu thập thống kê.',
          ),
          findsOneWidget,
        );

        // Case C: bootstrap not ready -> Switch locked OFF.
        await tester.pumpWidget(
          ProviderScope(
            key: const ValueKey('case-c'),
            overrides: [
              firebaseReadyProvider.overrideWithValue(false),
              analyticsPrivacyPolicyPermitsProvider.overrideWithValue(true),
              analyticsPreferenceStoreProvider.overrideWithValue(store),
              analyticsSdkGatewayProvider.overrideWithValue(null),
              remoteConfigProvider.overrideWithValue(RemoteConfigService(null)),
              notificationServiceProvider.overrideWithValue(
                NotificationService(null, null, null),
              ),
              exportServiceProvider.overrideWithValue(
                ExportService(null, null),
              ),
              crashReportingServiceProvider.overrideWithValue(
                CrashReportingService(crashlytics: null),
              ),
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

        final unreadySwitch = tester.widget<Switch>(find.byType(Switch).first);
        expect(unreadySwitch.value, isFalse);
        expect(unreadySwitch.onChanged, isNull);
        expect(
          find.text('Firebase chưa khởi tạo xong; thu thập thống kê đang tắt.'),
          findsOneWidget,
        );
      },
    );
  });
}
