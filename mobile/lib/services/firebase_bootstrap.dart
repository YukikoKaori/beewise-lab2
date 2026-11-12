import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

/// Host of local Firebase emulators for the EMULATOR demo build, e.g.
/// `--dart-define=BEEWISE_FIREBASE_EMULATOR_HOST=10.0.2.2`. Ignored in
/// release builds, so a production APK can never be pointed at emulators.
const firebaseEmulatorHost = String.fromEnvironment(
  'BEEWISE_FIREBASE_EMULATOR_HOST',
);

bool get usesFirebaseEmulators => kDebugMode && firebaseEmulatorHost.isNotEmpty;

/// Enable after Final Rules are deployed; emulator builds always exercise them.
bool get usesFinalFirestore =>
    usesFirebaseEmulators ||
    const bool.fromEnvironment('BEEWISE_FINAL_FIRESTORE');

/// Persisted user preference state for Firebase Analytics telemetry.
///
/// Product privacy policy ([docs/analytics-plan.md]): BeeWise records only
/// bounded, non-PII product events using an opt-out preference model when the
/// active build is not an emulator (`isEmulator == false`), [privacyPolicyPermits]
/// is `true`, and preference storage is readable with status [absent]. A
/// [readFailed] status is NEVER conflated with [absent] and always fails closed.
enum AnalyticsPreferenceStatus { absent, optedIn, optedOut, readFailed }

/// Distinct failure classifications surfaced by the Analytics privacy state machine.
enum AnalyticsPrivacyFailureKind {
  none,
  readFailed,
  persistenceFailed,
  sdkSyncFailed,
  policyBlocked,
  bootstrapFailed,
}

/// Deterministic preference persistence abstraction for Firebase Analytics opt-out.
abstract interface class AnalyticsPreferenceStore {
  /// Reads the stored opt-out flag (`true` opted out, `false` opted in, `null`
  /// strictly when no preference has been persisted yet). Implementations must
  /// throw on storage/platform failure rather than returning `null`.
  Future<bool?> readOptOut();

  /// Durably writes [optedOut]. Implementations must throw on failure.
  Future<void> writeOptOut(bool optedOut);
}

class SharedPreferencesAnalyticsStore implements AnalyticsPreferenceStore {
  const SharedPreferencesAnalyticsStore([this._preferences]);

  final SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _store => _preferences ?? SharedPreferencesAsync();

  @override
  Future<bool?> readOptOut() =>
      _store.getBool(FirebaseBootstrap.analyticsOptOutPrefKey);

  @override
  Future<void> writeOptOut(bool optedOut) =>
      _store.setBool(FirebaseBootstrap.analyticsOptOutPrefKey, optedOut);
}

/// Native Firebase Analytics SDK synchronization boundary.
abstract interface class AnalyticsSdkGateway {
  Future<void> setCollectionEnabled(bool enabled);
  Future<void> clearUserId();
}

class FirebaseAnalyticsSdkGateway implements AnalyticsSdkGateway {
  FirebaseAnalyticsSdkGateway([this._analytics]);

  final FirebaseAnalytics? _analytics;

  FirebaseAnalytics get _instance => _analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _instance.setAnalyticsCollectionEnabled(enabled);

  @override
  Future<void> clearUserId() => _instance.setUserId(id: null);
}

/// Snapshot of the fail-closed Analytics privacy & SDK synchronization state.
@immutable
class AnalyticsPrivacyState {
  const AnalyticsPrivacyState({
    this.preferenceStatus = AnalyticsPreferenceStatus.absent,
    this.preferenceLoaded = false,
    this.privacyPolicyPermits = true,
    this.isEmulator = false,
    this.bootstrapReady = true,
    this.nativeCollectionEnabled = false,
    this.sdkSynced = false,
    this.isUpdating = false,
    this.failureKind = AnalyticsPrivacyFailureKind.none,
    this.failedOptOutIntent,
    this.errorMessage,
    this.lastError,
  });

  final AnalyticsPreferenceStatus preferenceStatus;
  final bool preferenceLoaded;
  final bool privacyPolicyPermits;
  final bool isEmulator;
  final bool bootstrapReady;
  final bool nativeCollectionEnabled;
  final bool sdkSynced;
  final bool isUpdating;
  final AnalyticsPrivacyFailureKind failureKind;
  final bool? failedOptOutIntent;
  final String? errorMessage;
  final Object? lastError;

  bool get hasError => failureKind != AnalyticsPrivacyFailureKind.none;

  /// True ONLY when every policy, environment, bootstrap, preference, and
  /// native SDK gate positively permits active collection. Fails closed otherwise.
  bool get isCollectionEnabled =>
      bootstrapReady &&
      !isEmulator &&
      privacyPolicyPermits &&
      preferenceLoaded &&
      preferenceStatus != AnalyticsPreferenceStatus.readFailed &&
      preferenceStatus != AnalyticsPreferenceStatus.optedOut &&
      nativeCollectionEnabled &&
      sdkSynced &&
      failureKind == AnalyticsPrivacyFailureKind.none;

  /// Whether user-initiated opt-in could be attempted in the current runtime.
  bool get canEnableCollection =>
      bootstrapReady && !isEmulator && privacyPolicyPermits;

  AnalyticsPrivacyState copyWith({
    AnalyticsPreferenceStatus? preferenceStatus,
    bool? preferenceLoaded,
    bool? privacyPolicyPermits,
    bool? isEmulator,
    bool? bootstrapReady,
    bool? nativeCollectionEnabled,
    bool? sdkSynced,
    bool? isUpdating,
    AnalyticsPrivacyFailureKind? failureKind,
    bool? failedOptOutIntent,
    bool clearFailedOptOutIntent = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    Object? lastError,
    bool clearLastError = false,
  }) => AnalyticsPrivacyState(
    preferenceStatus: preferenceStatus ?? this.preferenceStatus,
    preferenceLoaded: preferenceLoaded ?? this.preferenceLoaded,
    privacyPolicyPermits: privacyPolicyPermits ?? this.privacyPolicyPermits,
    isEmulator: isEmulator ?? this.isEmulator,
    bootstrapReady: bootstrapReady ?? this.bootstrapReady,
    nativeCollectionEnabled:
        nativeCollectionEnabled ?? this.nativeCollectionEnabled,
    sdkSynced: sdkSynced ?? this.sdkSynced,
    isUpdating: isUpdating ?? this.isUpdating,
    failureKind: failureKind ?? this.failureKind,
    failedOptOutIntent: clearFailedOptOutIntent
        ? null
        : (failedOptOutIntent ?? this.failedOptOutIntent),
    errorMessage: clearErrorMessage
        ? null
        : (errorMessage ?? this.errorMessage),
    lastError: clearLastError ? null : (lastError ?? this.lastError),
  );
}

class AnalyticsPrivacyException implements Exception {
  const AnalyticsPrivacyException(
    this.message, {
    required this.state,
    this.cause,
  });

  final String message;
  final AnalyticsPrivacyState state;
  final Object? cause;

  @override
  String toString() => 'AnalyticsPrivacyException: $message';
}

class FirebaseBootstrap {
  static const analyticsOptOutPrefKey = 'beewise.analytics_opt_out.v1';

  static bool ready = false;
  static Object? initializationError;
  static bool analyticsCollectionActive = false;
  static bool analyticsPolicyPermits = true;
  static AnalyticsPrivacyState analyticsPrivacyState =
      const AnalyticsPrivacyState(bootstrapReady: false);

  static Future<void> Function(bool enabled) _resolveSetEnabled({
    AnalyticsSdkGateway? sdkGateway,
    Future<void> Function(bool enabled)? setAnalyticsEnabled,
  }) {
    if (setAnalyticsEnabled != null) return setAnalyticsEnabled;
    if (sdkGateway != null) return sdkGateway.setCollectionEnabled;
    return (enabled) async {
      if (Firebase.apps.isEmpty) {
        throw StateError('Firebase Analytics SDK is not initialized.');
      }
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    };
  }

  static Future<void> Function() _resolveClearUserId({
    AnalyticsSdkGateway? sdkGateway,
    Future<void> Function()? clearUserId,
    Future<void> Function(bool enabled)? customSetEnabled,
  }) {
    if (clearUserId != null) return clearUserId;
    if (sdkGateway != null) return sdkGateway.clearUserId;
    if (customSetEnabled != null && Firebase.apps.isEmpty) {
      return () async {};
    }
    return () async {
      if (Firebase.apps.isEmpty) return;
      await FirebaseAnalytics.instance.setUserId(id: null);
    };
  }

  static void _publishPrivacyState(AnalyticsPrivacyState next) {
    analyticsPrivacyState = next;
    analyticsCollectionActive = next.isCollectionEnabled;
  }

  /// Synchronizes the native Analytics SDK collection state with the active
  /// build target ([isEmulator]), explicit user opt-out preference, and
  /// privacy policy flag, failing closed on any unreadable preference or SDK error.
  ///
  /// Because Firebase Analytics persists `measurement_enabled=false` in native
  /// app data after running an emulator build, Final/production startup MUST
  /// explicitly re-enable collection ONLY when all gates succeed and read state
  /// is readable (`absent` under documented opt-out policy or `optedIn`).
  static Future<AnalyticsPrivacyState> reconcileAnalyticsPrivacy({
    required bool isEmulator,
    Future<void> Function(bool enabled)? setAnalyticsEnabled,
    Future<void> Function()? clearUserId,
    Future<bool?> Function()? readOptOut,
    AnalyticsPreferenceStore? preferenceStore,
    AnalyticsSdkGateway? sdkGateway,
    bool privacyPolicyPermits = true,
    bool bootstrapReady = true,
  }) async {
    analyticsPolicyPermits = privacyPolicyPermits;
    final store = preferenceStore ?? const SharedPreferencesAnalyticsStore();
    final setEnabledFn = _resolveSetEnabled(
      sdkGateway: sdkGateway,
      setAnalyticsEnabled: setAnalyticsEnabled,
    );
    final clearUidFn = _resolveClearUserId(
      sdkGateway: sdkGateway,
      clearUserId: clearUserId,
      customSetEnabled: setAnalyticsEnabled,
    );

    AnalyticsPreferenceStatus prefStatus;
    Object? readError;
    try {
      final stored = readOptOut != null
          ? await readOptOut()
          : await store.readOptOut();
      prefStatus = switch (stored) {
        null => AnalyticsPreferenceStatus.absent,
        true => AnalyticsPreferenceStatus.optedOut,
        false => AnalyticsPreferenceStatus.optedIn,
      };
    } catch (error) {
      prefStatus = AnalyticsPreferenceStatus.readFailed;
      readError = error;
    }

    final shouldEnable =
        bootstrapReady &&
        !isEmulator &&
        privacyPolicyPermits &&
        prefStatus != AnalyticsPreferenceStatus.readFailed &&
        prefStatus != AnalyticsPreferenceStatus.optedOut;

    if (!shouldEnable) {
      Object? sdkError;
      if (bootstrapReady ||
          setAnalyticsEnabled != null ||
          sdkGateway != null ||
          Firebase.apps.isNotEmpty) {
        try {
          await setEnabledFn(false);
        } catch (error) {
          sdkError = error;
        }
        try {
          await clearUidFn();
        } catch (_) {}
      }

      final failureKind = !bootstrapReady
          ? AnalyticsPrivacyFailureKind.bootstrapFailed
          : readError != null
          ? AnalyticsPrivacyFailureKind.readFailed
          : sdkError != null
          ? AnalyticsPrivacyFailureKind.sdkSyncFailed
          : AnalyticsPrivacyFailureKind.none;

      final errorMessage = switch (failureKind) {
        AnalyticsPrivacyFailureKind.readFailed => 'Không đọc được tùy chọn quyền riêng tư đã lưu. Thu thập thống kê đã tự động tắt.',
        AnalyticsPrivacyFailureKind.sdkSyncFailed => 'Không thể đồng bộ tắt Analytics với SDK. Thu thập dữ liệu trong ứng dụng đã bị khóa.',
        AnalyticsPrivacyFailureKind.bootstrapFailed =>
          'Firebase chưa khởi tạo xong. Thu thập thống kê đang tắt.',
        _ => null,
      };

      final next = AnalyticsPrivacyState(
        preferenceStatus: prefStatus,
        preferenceLoaded: true,
        privacyPolicyPermits: privacyPolicyPermits,
        isEmulator: isEmulator,
        bootstrapReady: bootstrapReady,
        nativeCollectionEnabled: false,
        sdkSynced: sdkError == null && bootstrapReady,
        failureKind: failureKind,
        errorMessage: errorMessage,
        lastError: readError ?? sdkError,
      );
      _publishPrivacyState(next);
      return next;
    }

    try {
      await setEnabledFn(true);
      final next = AnalyticsPrivacyState(
        preferenceStatus: prefStatus,
        preferenceLoaded: true,
        privacyPolicyPermits: true,
        isEmulator: false,
        bootstrapReady: true,
        nativeCollectionEnabled: true,
        sdkSynced: true,
      );
      _publishPrivacyState(next);
      return next;
    } catch (error) {
      try {
        await setEnabledFn(false);
      } catch (_) {}
      try {
        await clearUidFn();
      } catch (_) {}
      final next = AnalyticsPrivacyState(
        preferenceStatus: prefStatus,
        preferenceLoaded: true,
        privacyPolicyPermits: true,
        isEmulator: false,
        bootstrapReady: true,
        nativeCollectionEnabled: false,
        sdkSynced: false,
        failureKind: AnalyticsPrivacyFailureKind.sdkSyncFailed,
        errorMessage: 'Không thể đồng bộ bật Firebase Analytics với SDK. Thu thập thống kê vẫn đang tắt.',
        lastError: error,
      );
      _publishPrivacyState(next);
      return next;
    }
  }

  /// Backwards-compatible boolean wrapper returning
  /// [AnalyticsPrivacyState.isCollectionEnabled].
  static Future<bool> reconcileAnalyticsCollection({
    required bool isEmulator,
    required Future<void> Function(bool enabled) setAnalyticsEnabled,
    Future<void> Function()? clearUserId,
    Future<bool?> Function()? readOptOut,
    AnalyticsPreferenceStore? preferenceStore,
    AnalyticsSdkGateway? sdkGateway,
    bool privacyPolicyPermits = true,
    bool bootstrapReady = true,
  }) async {
    final state = await reconcileAnalyticsPrivacy(
      isEmulator: isEmulator,
      setAnalyticsEnabled: setAnalyticsEnabled,
      clearUserId: clearUserId,
      readOptOut: readOptOut,
      preferenceStore: preferenceStore,
      sdkGateway: sdkGateway,
      privacyPolicyPermits: privacyPolicyPermits,
      bootstrapReady: bootstrapReady,
    );
    return state.isCollectionEnabled;
  }

  /// Updates the persisted analytics opt-out preference and synchronizes native
  /// SDK state immediately. Throws [AnalyticsPrivacyException] on persistence,
  /// SDK synchronization, or policy/environment violation instead of silently
  /// returning success.
  static Future<AnalyticsPrivacyState> setPersistedAnalyticsOptOut(
    bool optedOut, {
    Future<void> Function(bool enabled)? setAnalyticsEnabled,
    Future<void> Function()? clearUserId,
    Future<void> Function(bool optedOut)? writeOptOut,
    AnalyticsPreferenceStore? preferenceStore,
    AnalyticsSdkGateway? sdkGateway,
    bool isEmulator = false,
    bool? privacyPolicyPermits,
    bool bootstrapReady = true,
  }) async {
    final policyPermits = privacyPolicyPermits ?? analyticsPolicyPermits;
    if (privacyPolicyPermits != null) {
      analyticsPolicyPermits = privacyPolicyPermits;
    }
    final store = preferenceStore ?? const SharedPreferencesAnalyticsStore();
    final setEnabledFn = _resolveSetEnabled(
      sdkGateway: sdkGateway,
      setAnalyticsEnabled: setAnalyticsEnabled,
    );
    final clearUidFn = _resolveClearUserId(
      sdkGateway: sdkGateway,
      clearUserId: clearUserId,
      customSetEnabled: setAnalyticsEnabled,
    );

    Future<void> persistPref(bool value) async {
      if (writeOptOut != null) {
        await writeOptOut(value);
      } else {
        await store.writeOptOut(value);
      }
    }

    if (optedOut) {
      // Apply explicit user opt-out to the native SDK immediately.
      analyticsCollectionActive = false;
      Object? sdkError;
      if (bootstrapReady ||
          setAnalyticsEnabled != null ||
          sdkGateway != null ||
          Firebase.apps.isNotEmpty) {
        try {
          await setEnabledFn(false);
        } catch (error) {
          sdkError = error;
        }
        try {
          await clearUidFn();
        } catch (_) {}
      }

      try {
        await persistPref(true);
      } catch (persistError) {
        final priorDurable =
            analyticsPrivacyState.preferenceStatus ==
                AnalyticsPreferenceStatus.optedOut
            ? AnalyticsPreferenceStatus.absent
            : analyticsPrivacyState.preferenceStatus;
        final failedState = AnalyticsPrivacyState(
          preferenceStatus: priorDurable,
          preferenceLoaded: analyticsPrivacyState.preferenceLoaded,
          privacyPolicyPermits: policyPermits,
          isEmulator: isEmulator,
          bootstrapReady: bootstrapReady,
          nativeCollectionEnabled: false,
          sdkSynced: sdkError == null && bootstrapReady,
          failureKind: AnalyticsPrivacyFailureKind.persistenceFailed,
          failedOptOutIntent: true,
          errorMessage: 'Đã tắt thu thập thống kê trong phiên này, nhưng không thể lưu tùy chọn vào bộ nhớ thiết bị.',
          lastError: persistError,
        );
        _publishPrivacyState(failedState);
        throw AnalyticsPrivacyException(
          failedState.errorMessage!,
          state: failedState,
          cause: persistError,
        );
      }

      if (sdkError != null) {
        final failedState = AnalyticsPrivacyState(
          preferenceStatus: AnalyticsPreferenceStatus.optedOut,
          preferenceLoaded: true,
          privacyPolicyPermits: policyPermits,
          isEmulator: isEmulator,
          bootstrapReady: bootstrapReady,
          nativeCollectionEnabled: false,
          sdkSynced: false,
          failureKind: AnalyticsPrivacyFailureKind.sdkSyncFailed,
          failedOptOutIntent: true,
          errorMessage: 'Đã lưu tùy chọn từ chối, nhưng đồng bộ tắt với SDK Analytics gặp lỗi. Thu thập trong ứng dụng vẫn bị khóa.',
          lastError: sdkError,
        );
        _publishPrivacyState(failedState);
        throw AnalyticsPrivacyException(
          failedState.errorMessage!,
          state: failedState,
          cause: sdkError,
        );
      }

      final cleanState = AnalyticsPrivacyState(
        preferenceStatus: AnalyticsPreferenceStatus.optedOut,
        preferenceLoaded: true,
        privacyPolicyPermits: policyPermits,
        isEmulator: isEmulator,
        bootstrapReady: bootstrapReady,
        nativeCollectionEnabled: false,
        sdkSynced: bootstrapReady,
      );
      _publishPrivacyState(cleanState);
      return cleanState;
    }

    // Opt-in requested (`optedOut == false`): enforce environment, policy, and
    // bootstrap gates before ever enabling native SDK collection.
    if (isEmulator || !policyPermits || !bootstrapReady) {
      Object? sdkError;
      if (bootstrapReady ||
          setAnalyticsEnabled != null ||
          sdkGateway != null ||
          Firebase.apps.isNotEmpty) {
        try {
          await setEnabledFn(false);
        } catch (error) {
          sdkError = error;
        }
        try {
          await clearUidFn();
        } catch (_) {}
      }

      final failureKind = !bootstrapReady
          ? AnalyticsPrivacyFailureKind.bootstrapFailed
          : AnalyticsPrivacyFailureKind.policyBlocked;
      final message = isEmulator
          ? 'Không thể bật thống kê trong chế độ Emulator.'
          : !policyPermits
          ? 'Chính sách quyền riêng tư hiện không cho phép bật thu thập thống kê.'
          : 'Firebase chưa khởi tạo xong; thu thập thống kê vẫn đang tắt.';
      final blockedState = analyticsPrivacyState.copyWith(
        preferenceLoaded: true,
        privacyPolicyPermits: policyPermits,
        isEmulator: isEmulator,
        bootstrapReady: bootstrapReady,
        nativeCollectionEnabled: false,
        sdkSynced: sdkError == null && bootstrapReady,
        failureKind: failureKind,
        failedOptOutIntent: false,
        errorMessage: message,
        lastError: sdkError,
      );
      _publishPrivacyState(blockedState);
      throw AnalyticsPrivacyException(message, state: blockedState);
    }

    try {
      await persistPref(false);
    } catch (persistError) {
      try {
        await setEnabledFn(false);
      } catch (_) {}
      try {
        await clearUidFn();
      } catch (_) {}
      final priorStatus =
          analyticsPrivacyState.preferenceStatus ==
              AnalyticsPreferenceStatus.optedIn
          ? AnalyticsPreferenceStatus.absent
          : analyticsPrivacyState.preferenceStatus;
      final failedState = AnalyticsPrivacyState(
        preferenceStatus: priorStatus,
        preferenceLoaded: analyticsPrivacyState.preferenceLoaded,
        privacyPolicyPermits: true,
        isEmulator: false,
        bootstrapReady: true,
        nativeCollectionEnabled: false,
        sdkSynced: false,
        failureKind: AnalyticsPrivacyFailureKind.persistenceFailed,
        failedOptOutIntent: false,
        errorMessage: 'Không thể lưu tùy chọn bật thống kê vào bộ nhớ thiết bị. Thu thập dữ liệu vẫn đang tắt.',
        lastError: persistError,
      );
      _publishPrivacyState(failedState);
      throw AnalyticsPrivacyException(
        failedState.errorMessage!,
        state: failedState,
        cause: persistError,
      );
    }

    try {
      await setEnabledFn(true);
    } catch (sdkError) {
      try {
        await setEnabledFn(false);
      } catch (_) {}
      try {
        await clearUidFn();
      } catch (_) {}
      final failedState = AnalyticsPrivacyState(
        preferenceStatus: AnalyticsPreferenceStatus.optedIn,
        preferenceLoaded: true,
        privacyPolicyPermits: true,
        isEmulator: false,
        bootstrapReady: true,
        nativeCollectionEnabled: false,
        sdkSynced: false,
        failureKind: AnalyticsPrivacyFailureKind.sdkSyncFailed,
        failedOptOutIntent: false,
        errorMessage:
            'Không thể kích hoạt SDK Analytics. Thu thập dữ liệu vẫn đang tắt.',
        lastError: sdkError,
      );
      _publishPrivacyState(failedState);
      throw AnalyticsPrivacyException(
        failedState.errorMessage!,
        state: failedState,
        cause: sdkError,
      );
    }

    const enabledState = AnalyticsPrivacyState(
      preferenceStatus: AnalyticsPreferenceStatus.optedIn,
      preferenceLoaded: true,
      privacyPolicyPermits: true,
      isEmulator: false,
      bootstrapReady: true,
      nativeCollectionEnabled: true,
      sdkSynced: true,
    );
    _publishPrivacyState(enabledState);
    return enabledState;
  }

  static Future<bool> initialize({
    bool? isEmulatorOverride,
    bool privacyPolicyPermits = true,
    Future<void> Function()? initializeFirebaseApp,
    Future<void> Function(bool enabled)? setAnalyticsEnabled,
    Future<void> Function()? clearAnalyticsUserId,
    Future<bool?> Function()? readAnalyticsOptOut,
    AnalyticsPreferenceStore? preferenceStore,
    AnalyticsSdkGateway? sdkGateway,
    Future<void> Function()? configureEmulators,
    Future<void> Function()? activateAppCheck,
  }) async {
    final options = DefaultFirebaseOptions.currentPlatform;
    final hasCustomInit = initializeFirebaseApp != null;
    if (!hasCustomInit && options == null) return false;
    final emulatorMode = isEmulatorOverride ?? usesFirebaseEmulators;
    ready = false;
    analyticsPolicyPermits = privacyPolicyPermits;
    _publishPrivacyState(
      AnalyticsPrivacyState(
        isEmulator: emulatorMode,
        privacyPolicyPermits: privacyPolicyPermits,
        bootstrapReady: false,
      ),
    );
    try {
      if (initializeFirebaseApp != null) {
        await initializeFirebaseApp();
      } else {
        await Firebase.initializeApp(options: options);
      }
      if (emulatorMode) {
        if (configureEmulators != null) {
          await configureEmulators();
        } else {
          await FirebaseAuth.instance.useAuthEmulator(
            firebaseEmulatorHost,
            const int.fromEnvironment(
              'BEEWISE_FIREBASE_AUTH_PORT',
              defaultValue: 9099,
            ),
          );
          FirebaseFirestore.instance.useFirestoreEmulator(
            firebaseEmulatorHost,
            const int.fromEnvironment(
              'BEEWISE_FIRESTORE_PORT',
              defaultValue: 8080,
            ),
          );
        }
      } else {
        if (activateAppCheck != null) {
          await activateAppCheck();
        } else {
          await FirebaseAppCheck.instance.activate(
            providerAndroid: kDebugMode
                ? AndroidDebugProvider()
                : const AndroidPlayIntegrityProvider(),
          );
        }
      }
      ready = true;
      initializationError = null;
      await reconcileAnalyticsPrivacy(
        isEmulator: emulatorMode,
        setAnalyticsEnabled: setAnalyticsEnabled,
        clearUserId: clearAnalyticsUserId,
        readOptOut: readAnalyticsOptOut,
        preferenceStore: preferenceStore,
        sdkGateway: sdkGateway,
        privacyPolicyPermits: privacyPolicyPermits,
        bootstrapReady: true,
      );
      return true;
    } catch (error, stackTrace) {
      ready = false;
      initializationError = error;
      if (setAnalyticsEnabled != null ||
          sdkGateway != null ||
          Firebase.apps.isNotEmpty) {
        try {
          await _resolveSetEnabled(
            sdkGateway: sdkGateway,
            setAnalyticsEnabled: setAnalyticsEnabled,
          )(false);
        } catch (_) {}
        try {
          await _resolveClearUserId(
            sdkGateway: sdkGateway,
            clearUserId: clearAnalyticsUserId,
            customSetEnabled: setAnalyticsEnabled,
          )();
        } catch (_) {}
      }
      _publishPrivacyState(
        AnalyticsPrivacyState(
          isEmulator: emulatorMode,
          privacyPolicyPermits: privacyPolicyPermits,
          bootstrapReady: false,
          nativeCollectionEnabled: false,
          sdkSynced: false,
          failureKind: AnalyticsPrivacyFailureKind.bootstrapFailed,
          errorMessage:
              'Khởi tạo Firebase thất bại. Thu thập thống kê đã bị tắt.',
          lastError: error,
        ),
      );
      debugPrint('Firebase initialization failed: $error\n$stackTrace');
      return false;
    }
  }
}
