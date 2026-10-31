# Crashlytics — actual Console follow-up 2026-10-31

**PARTIALLY COMPLETE.** Existing authenticated Chrome Console for `beewise-lab-3`
actually shows uploaded Android version 0.1.0(1), Android 17 test-device events:

- Fatal `FirebaseCrashlyticsTestCrash`, `FlutterFirebaseCrashlyticsPlugin.crash$lambda$0`,
  one event; displayed Oct 31, 2026, 5:14:51 AM. Stack explicitly identifies the
  deliberate Dart `.crash()` diagnostic. No new fatal triggered this turn.
- Real handled business failure `MatchingService.match (matching_service.dart:30)`
  through MatchingController; displayed Oct 31, 2026, 5:13:33 AM, one event.
  Remote Config disabled matching; localized exception and reason
  `thrown AI matching failed` inspected. This is distinct from the sample diagnostic.
- Inspected keys: `app_area=beewise_mobile`, `flutter_error_exception` matching
  the localized disabled message, `flutter_error_reason=thrown AI matching failed`.
  Keys persist across events; their presence on fatal does not identify its action.
- Retained issues: two historical blank-name Profile fatal events (separately
  fixed with owner-approved fallback), one Profile diagnostic nonfatal, and one
  `_ioctl` binder-wait ANR. No claim the ANR has been fixed.

Fatal/nonfatal receipt and custom-key inspection **PASS**. Signed-in Crashlytics
user-ID association **NOT RUN**; these captures do not complete that rubric item.
Displayed Console times have no assumed timezone. A snackbar or SDK log alone
was never counted as receipt. Private unmodified Console PNG hashes/paths and
observed facts: `../../cloud/console-runtime-validation.json`.
