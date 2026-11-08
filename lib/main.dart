import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bee_wise_app.dart';
import 'models/tutor_workspace_models.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.initialize();
  if (firebaseReady) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  runApp(
    ProviderScope(
      // Riverpod 3 retries failed providers with backoff, which keeps screens
      // on "loading" for a long time. Permission/ownership failures are not
      // transient, so surface them immediately.
      retry: (retryCount, error) =>
          error is TutorBackendRulesDependencyException ||
              error is TutorUnauthorizedException ||
              error is TutorResourceNotFoundException
          ? null
          : ProviderContainer.defaultRetry(retryCount, error),
      child: const BeeWiseApp(),
    ),
  );
}
