import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

class FirebaseBootstrap {
  static bool ready = false;
  static Object? initializationError;

  static Future<bool> initialize() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) return false;
    try {
      await Firebase.initializeApp(options: options);
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
