import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
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

class FirebaseBootstrap {
  static bool ready = false;
  static Object? initializationError;

  static Future<bool> initialize() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) return false;
    try {
      await Firebase.initializeApp(options: options);
      if (usesFirebaseEmulators) {
        await FirebaseAuth.instance.useAuthEmulator(firebaseEmulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(
          firebaseEmulatorHost,
          8080,
        );
      }
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
      ready = true;
      return true;
    } catch (error, stackTrace) {
      initializationError = error;
      debugPrint('Firebase initialization failed: $error\n$stackTrace');
      return false;
    }
  }
}
