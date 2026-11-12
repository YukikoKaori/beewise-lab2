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

class FirebaseBootstrap {
  static const analyticsOptOutPrefKey = 'beewise.analytics_opt_out.v1';

  static bool ready = false;
  static Object? initializationError;
  static bool analyticsCollectionActive = false;

  static Future<bool?> _readPersistedAnalyticsOptOut() async {
    try {
      return await SharedPreferencesAsync().getBool(analyticsOptOutPrefKey);
    } catch (_) {
      return null;
    }
  }

  /// Synchronizes the native Analytics SDK collection state with the active
  /// build target (`isEmulator`), explicit user opt-out preference, and
  /// privacy policy flag.
  ///
  /// Because Firebase Analytics persists `measurement_enabled=false` in native
  /// app data after running an emulator build, Final/production startup MUST
  /// explicitly re-enable collection whenever permitted and not opted out.
  static Future<bool> reconcileAnalyticsCollection({
    required bool isEmulator,
    required Future<void> Function(bool enabled) setAnalyticsEnabled,
    Future<bool?> Function()? readOptOut,
    bool privacyPolicyPermits = true,
  }) async {
    if (isEmulator) {
      await setAnalyticsEnabled(false);
      analyticsCollectionActive = false;
      return false;
    }
    var optedOut = false;
    if (readOptOut != null) {
      try {
        optedOut = await readOptOut() ?? false;
      } catch (_) {
        optedOut = false;
      }
    }
    final enabled = privacyPolicyPermits && !optedOut;
    await setAnalyticsEnabled(enabled);
    analyticsCollectionActive = enabled;
    return enabled;
  }

  /// Updates the persisted analytics opt-out preference and applies the new
  /// collection state immediately at runtime.
  static Future<void> setPersistedAnalyticsOptOut(
    bool optedOut, {
    Future<void> Function(bool enabled)? setAnalyticsEnabled,
    Future<void> Function()? clearUserId,
    Future<void> Function(bool optedOut)? writeOptOut,
    bool isEmulator = false,
  }) async {
    try {
      if (writeOptOut != null) {
        await writeOptOut(optedOut);
      } else {
        await SharedPreferencesAsync().setBool(
          analyticsOptOutPrefKey,
          optedOut,
        );
      }
    } catch (_) {
      // Preference persistence errors must not crash settings controls.
    }
    if (optedOut && clearUserId != null) {
      try {
        await clearUserId();
      } catch (_) {}
    }
    if (isEmulator) {
      analyticsCollectionActive = false;
      try {
        await (setAnalyticsEnabled ??
            FirebaseAnalytics.instance.setAnalyticsCollectionEnabled)(false);
      } catch (_) {}
      return;
    }
    final active = !optedOut;
    try {
      await (setAnalyticsEnabled ??
          FirebaseAnalytics.instance.setAnalyticsCollectionEnabled)(active);
    } catch (_) {}
    analyticsCollectionActive = active;
  }

  static Future<bool> initialize({
    bool? isEmulatorOverride,
    bool privacyPolicyPermits = true,
    Future<void> Function()? initializeFirebaseApp,
    Future<void> Function(bool enabled)? setAnalyticsEnabled,
    Future<bool?> Function()? readAnalyticsOptOut,
    Future<void> Function()? configureEmulators,
    Future<void> Function()? activateAppCheck,
  }) async {
    final options = DefaultFirebaseOptions.currentPlatform;
    final hasCustomInit = initializeFirebaseApp != null;
    if (!hasCustomInit && options == null) return false;
    final emulatorMode = isEmulatorOverride ?? usesFirebaseEmulators;
    analyticsCollectionActive = false;
    try {
      if (initializeFirebaseApp != null) {
        await initializeFirebaseApp();
      } else {
        await Firebase.initializeApp(options: options);
      }
      await reconcileAnalyticsCollection(
        isEmulator: emulatorMode,
        setAnalyticsEnabled:
            setAnalyticsEnabled ??
            (enabled) => FirebaseAnalytics.instance
                .setAnalyticsCollectionEnabled(enabled),
        readOptOut: readAnalyticsOptOut ?? _readPersistedAnalyticsOptOut,
        privacyPolicyPermits: privacyPolicyPermits,
      );
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
      return true;
    } catch (error, stackTrace) {
      initializationError = error;
      analyticsCollectionActive = false;
      debugPrint('Firebase initialization failed: $error\n$stackTrace');
      return false;
    }
  }
}
