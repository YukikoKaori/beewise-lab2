import 'dart:async';

import 'package:beewise/app/provider_retry.dart';
import 'package:beewise/models/tutor_workspace_models.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FirebaseException firebase(String code) =>
      FirebaseException(plugin: 'cloud_firestore', code: code);

  test('answers that will not change are never retried', () {
    for (final error in <Object>[
      firebase('permission-denied'),
      firebase('unauthenticated'),
      firebase('not-found'),
      const TutorBackendRulesDependencyException('x'),
      const TutorUnauthorizedException(),
      const TutorResourceNotFoundException('x'),
    ]) {
      expect(isPermanentProviderError(error), isTrue, reason: '$error');
      expect(beeWiseProviderRetry(0, error), isNull, reason: '$error');
    }
  });

  test('transient failures keep Riverpod’s backoff', () {
    for (final error in <Object>[
      firebase('unavailable'),
      firebase('deadline-exceeded'),
      TimeoutException('slow'),
      Exception('boom'),
    ]) {
      expect(isPermanentProviderError(error), isFalse, reason: '$error');
      expect(beeWiseProviderRetry(0, error), isNotNull, reason: '$error');
    }
  });
}
