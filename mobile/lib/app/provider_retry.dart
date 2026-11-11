import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tutor_workspace_models.dart';

/// Riverpod 3 retries a failed provider with growing delays and shows "loading" meanwhile.
/// That is right for a dropped connection but wrong for an answer that will not change
/// (no permission, signed out, not found): the user would stare at a spinner for a minute
/// instead of reading the explanation. Those errors surface immediately.
Duration? beeWiseProviderRetry(int retryCount, Object error) {
  if (isPermanentProviderError(error)) return null;
  return ProviderContainer.defaultRetry(retryCount, error);
}

bool isPermanentProviderError(Object error) {
  if (error is TutorBackendRulesDependencyException ||
      error is TutorUnauthorizedException ||
      error is TutorResourceNotFoundException) {
    return true;
  }
  return error is FirebaseException &&
      const {
        'permission-denied',
        'unauthenticated',
        'not-found',
      }.contains(error.code);
}
