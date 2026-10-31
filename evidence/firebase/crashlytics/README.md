## Google live verification follow-up — 2026-10-31 (current)

**B-01/B-03 PARTIALLY COMPLETE:** actual dedicated Google sign-in, parent
creation, signed-in Profile, process-death session restore, managed logout and
guest cold relaunch **PASS** on isolated `emulator-5558`, current same-signer
APK. Provider `google.com`, sign-in 08:17:19.108Z and parent creation
08:17:21.874249Z corroborate actual UI; Users metadata alone is not Auth proof.
Google installation appeared only under its owner after relaunch; managed logout
removed it while A/B registrations stayed empty and all parent records survived.
Initial automatic Google registration remained pending until relaunch: **OPEN**
reliability finding, consistent with earlier B retry. A transient role read after
the diagnostic crash failed closed; explicit retry restored Home/Profile.

**B-02:** exact approved SHA registration and additive Android OAuth config
verified; strict rules/index remain as previously authorized and deployed. No new
rules, provider, Storage, App Check or billing changes. Authenticated cross-UID
malicious client denial remains **NOT RUN**; IAM snapshots do not establish it.

**B-04:** new deliberate fatal received in actual Firebase Console at displayed
3:21:38 PM, Android 17 / version 0.1.0(1). Crashlytics Data > User ID hashes to
the dedicated Google UID alias; custom keys inspected. Broad browser metadata
ID matches were rejected; only the visible User ID leaf was compared. Fatal
persisted keys describe the prior nonfatal diagnostic, not its trigger. Google
Analytics method and logout UID-clear are **NOT VERIFIED**. Previously verified
five business Analytics event types remain five of seven; SDK events do not
close the gap. Native first-request spinner and stale callback failure retained;
fresh user-operated Google retry succeeded without credentials being collected.

**B-05:** formatter/analyzer PASS, Flutter **59/59**, Firebase Emulator rules
**28/28**, APK build/install PASS; application/config and prior evidence HEAD CI
3/3 PASS. Final evidence HEAD CI is checked after push. Original authenticated
screenshots are private on D; sanitized XML, metadata, screenshot hashes and
guest/error images are reviewable. Emulator debug/display/network settings restored.
No Nguyen UI/theme/router/ARTEMIS/review/final-presentation edits. Storage remains
**DEFERRED** for team discussion. App Check, trusted backend/payment/official
schedules, staging, physical device, ARTEMIS and external review remain
**BLOCKED/NOT RUN** as applicable. Overall **PARTIALLY COMPLETE**.

Primary receipt: `evidence/cloud/google-runtime-validation.json`; account
snapshots `evidence/cloud/google-user-*.json`; runtime `evidence/android/logs/google-*`.

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
