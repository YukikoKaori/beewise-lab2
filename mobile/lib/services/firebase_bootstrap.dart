import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
  static bool ready = false;
  static Object? initializationError;

  static Future<bool> initialize() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) return false;
    try {
      await Firebase.initializeApp(options: options);
      if (usesFirebaseEmulators) {
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
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
      if (!usesFirebaseEmulators) {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
        );
      }
      ready = true;
      return true;
    } catch (error, stackTrace) {
      initializationError = error;
      debugPrint('Firebase initialization failed: $error\n$stackTrace');
      return false;
    }
  }
}
