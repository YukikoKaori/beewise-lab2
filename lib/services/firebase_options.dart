import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase client identifiers for the BeeWise Android app.
/// These values are public client configuration, not service-account secrets.
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAp43qx39hEbjXzvGhYZXB7EsnJ9g38Cgc',
    appId: '1:840483888286:android:50c11fbb460437ed6a2f8f',
    messagingSenderId: '840483888286',
    projectId: 'beewise-lab-3',
    storageBucket: 'beewise-lab-3.firebasestorage.app',
  );
}
