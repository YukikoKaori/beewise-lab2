import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bee_wise_app.dart';
import 'app/provider_retry.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.initialize();
  if (firebaseReady && usesFirebaseEmulators) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }
  if (firebaseReady && !usesFirebaseEmulators) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  runApp(
    ProviderScope(
      // Riverpod 3 retries failed providers with backoff, which keeps screens on "loading"
      // for a long time. Permission / ownership failures are not transient: surface them now.
      retry: beeWiseProviderRetry,
      child: const BeeWiseApp(),
    ),
  );
}
