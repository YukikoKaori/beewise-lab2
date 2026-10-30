import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashReportingService {
  CrashReportingService({this._crashlytics});

  final FirebaseCrashlytics? _crashlytics;

  Future<void> setUser(String? uid) async {
    try {
      await _crashlytics?.setUserIdentifier(uid ?? 'guest');
      await _crashlytics?.setCustomKey('app_area', 'beewise_mobile');
    } catch (_) {
      // Diagnostics must not prevent the parent action from completing.
    }
  }

  Future<void> recordHandled(
    Object error,
    StackTrace stack,
    String reason,
  ) async {
    try {
      await _crashlytics?.recordError(
        error,
        stack,
        reason: reason,
        fatal: false,
      );
    } catch (_) {
      // A reporting failure must not replace the original handled error.
    }
  }

  Future<void> setDemoKey(String value) async {
    try {
      await _crashlytics?.setCustomKey('demo_action', value);
    } catch (_) {
      // The demo key is diagnostic metadata, not a product action.
    }
  }

  void triggerTestCrash() => _crashlytics?.crash();
}
