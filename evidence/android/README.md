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



# Android actual verification — Bao, 2026-10-31

## Computer Use Console follow-up — 2026-10-31 (current)

**PARTIALLY COMPLETE.** Computer Use now controls the existing authenticated
Chrome Firebase tab. Actual Console evidence from `beewise-lab-3` supersedes the
previous browser-unavailable and no-receipt statements below.

- **B-01:** Existing same-key APK on isolated `emulator-5558` relaunched; actual
  guest TEST search, labeled synthetic tutor detail and AI empty result captured.
  Detail retest now PASS. System UI ANR recurred on boot; retained, not fixed.
  Original display/network/Analytics debug settings restored after testing.
- **B-02:** Existing approved strict rules/Auth evidence preserved. Exact installed
  APK certificate hashes and guarded commands prepared in
  `docs/workstreams/bao-google-sha-plan.md`; owner SHA permission and a dedicated
  Google account remain pending. No Google login claim or shared OAuth mutation.
  Authenticated cross-UID Firestore client denial remains NOT RUN.
- **B-03:** DebugView shows five distinct business event types: `login` with
  `method=password`, `logout`, `search`, `view_tutor` with
  `entry_source=profile_route`, and `ai_match_no_results`. Three additional SDK
  types (`screen_view`, `notification_foreground`, `notification_receive`) do not
  complete the seven-business-event requirement. Crashlytics actually contains
  the deliberate fatal test and real matching-disabled handled failure; inspected
  keys include `app_area=beewise_mobile` and matching error reason/exception.
  Signed-in Crashlytics user association remains NOT RUN. Historical Profile
  crash and binder ANR retained. RC Console shows empty configuration landing,
  consistent with prior API restore; version number is not visible. **Storage is
  explicitly DEFERRED by user for team discussion; no bucket/billing action.**
- **B-04:** Existing 59 Flutter/28 emulator rules and secure server-trusted payment
  and official schedule gates preserved. No app/rules code change this turn;
  no paid AI invocation or backend/staging completion claimed.
- **B-05:** New actual receipts and sanitized Android logs indexed in
  `evidence/cloud/console-runtime-validation.json`. Unmodified Console screenshots
  stay private on D with public SHA-256 receipts because browser/account chrome
  contains identifying information. Nguyen UI/theme/router/ARTEMIS/review/final
  presentation untouched. ARTEMIS/external review/physical hardware NOT RUN.

Public native proof: `evidence/android/screenshots/console-search-submitted.png`,
`console-tutor-detail.png`, `console-ai-no-results.png`. Failed first taps and
System UI ANR are classified separately in the manifest. No uninstall/data clear.
Final pushed HEAD/CI are reported in the handoff; earlier checks remain historical.

## Approved deployment and actual Android follow-up — 2026-10-31

**PARTIALLY COMPLETE.** Owner approved the exact frozen strict Firestore bundle.
28/28 emulator tests rerun PASS before deploy. Additive chats index reached READY
before rules release; both deploy commands exited 0. Active ruleset
`2aff57c1-3693-4bfa-9cd2-d77471ef08d6` matches repository normalized SHA-256
`759a35e408204bff48dac1f380009b76a661b39c4f649d809322643c616f6578`.
Missing own `tutorApplications/{uid}` lookup is now present. No Storage/provider/
billing change, weak rollback, record deletion or rules weakening was performed.

Actual Email/Password account A login after release created its parent profile;
force-stop/relaunch restored the SDK session. This exposed a real blank-name
Profile crash. Owner authorized exactly the fallback exception: six regressions
PASS (three failed before correction), full Flutter 59/59, format/analyzer and
debug APK build PASS. Same-signer install `-r` preserved A's data. Source APK
`9657d1b2f0c57a425298aab58fefbccb7119ac47`, SHA-256
`c963e08a7684c54bbc0893524a9a6e9168a38350b9fdfe08ff9475eeb4ef2701`.
Fixed restored Profile and managed logout PASS; A's own device registration was
removed and guest inbox emptied. B login/profile/session restore/logout PASS;
A inbox is absent under B, A profile unchanged, same installation belongs only
to B after explicit retry, and both registrations are absent after B logout.
Initial B automatic registration remained pending; manual retry recovered it.
This is a retained reliability finding, not an automatic-registration PASS.
B received its exact foreground probe; new-APK 360dp/412dp and guest offline
cache/reconnected Search were captured. Original device settings restored.

Real FCM API sends plus exact probe IDs on device establish foreground receipt,
background notification/tap and verified process-death notification/cold-start
Search routing. Malformed URL and inaccessible chat taps keep Profile visible.
An earlier terminated attempt retained its PID and is explicitly NOT counted.
API acceptance alone is never treated as delivery. Original authenticated PNGs
remain private on D; sanitized XML/logs and non-identifying screenshots are public.

Google provider became enabled externally and owner-supplied web OAuth config
was preserved separately; Android SHA registration/Google runtime remain BLOCKED.
No Storage bucket/release; billing disabled. Analytics DebugView/Crashlytics
Console receipts, staging, trusted payment/staff backend, ARTEMIS and external
review remain NOT RUN/BLOCKED. Previous live Remote Config publish/restore remains
valid; all six labeled synthetic tutor records remain preserved and unverified.

Receipts: `evidence/cloud/authorized-deploy-*.json`, `firestore-release-state.json`,
`test-users-*.json`, `fcm-*.json`, `checks/authorized-profile-final/`, and
`evidence/android/logs/auth-*`. Four real unauthenticated private reads were
denied; those and IAM snapshots are not authenticated cross-UID client tests.

## Earlier evidence (historical; superseded where stated above)

## Auth provisioning follow-up

`auth-ready-installed-apk.json` hashes the installed base APK itself: matches
`f6a66bc0d90ad68d64052b7beda0c33bc54c4f59c1da1d16561f13e1fbdc578d`.
No app source changed in this follow-up. Cold launch Status ok / 6412ms on isolated
`emulator-5558`; Home 360dp and guest Profile/Search 412dp inspected. Original
PNG hashes/dimensions and precise limitations: `auth-ready-runtime.json`.

`screenshots/auth-ready-360.png` records a real **System UI ANR**, not PASS.
After Wait, `auth-ready-360-settled.png` shows Home and
`auth-ready-412-profile.png` explicitly shows signed-out state. Offline/online
Search captures retain six labeled TEST records. Network toggles and restoration
receipts are in `logs/auth-ready-*`; no fresh device server-read claim. Separate
host SDK server reads are in `../cloud/guest-firestore-query.json`.
UI dump now reads actual XML from the device instead of the `/dev/tty` completion
message. Sanitized PID3473 logs retained; raw originals stay privately on D.
Display/network/Analytics debug state restored. Original BeeWise data untouched.

Two password identities are provisioned, but parent login/profile creation,
logout/session restore/account isolation are **NOT RUN**, pending explicit owner
permission for strict rules/index deployment and direct user login. Password
forms must not be captured while credentials are entered. Console/real hardware,
ARTEMIS and external review remain NOT RUN/BLOCKED.

## Earlier install and service runtime evidence

**PARTIALLY COMPLETE.** Latest app source `9ef5907b2d296fcdafaa869a53e9780692f4cc56`
built on D and actually installed/launched on **separate** `emulator-5558`.
APK SHA-256 `f6a66bc0d90ad68d64052b7beda0c33bc54c4f59c1da1d16561f13e1fbdc578d`,
227,800,966 bytes. Exact install/Success/hash: `logs/corrective-4gb-source-install.json`.
APK path remains `D:/CodexTemp/beewise-lab3-build/build/app/outputs/flutter-apk/app-debug.apk`.
Toolchain Flutter 3.47.8/Dart 3.13.7, JDK21, Gradle9.3.1/AGP9.1.0. Future Kotlin
plugin warnings remain; this is a debug build, not release/hardware certification.

## Native evidence actually inspected

All PNGs are original `adb exec-out screencap -p` bytes. SHA/dimensions and
VERIFIED_SCREEN vs HISTORICAL_ATTEMPT_ONLY classification are in
`runtime-manifest.json`. Failed/splash/black screenshots do not count as PASS.

| Scenario | Actual evidence/result |
|---|---|
| 360dp Home/Profile | `screenshots/corrective-360-home.png`, `corrective-360-profile.png` |
| 412dp Profile | `screenshots/corrective-412-profile-ready.png` |
| Native permission | `screenshots/corrective-360-permission.png`; Allow tap receipt |
| Firestore catalog | `screenshots/corrective-412-search-data.png`: six TEST/unverified synthetic tutors |
| Guest Chats | `screenshots/corrective-412-chats-ready.png`: login gate |
| Offline/recovery | Both Wi-Fi/cellular disabled; active default network none observed; PID log has Firestore UNAVAILABLE/DNS failure; `corrective-412-offline-error.png` renders cached Home (filename does not mean error screen). Restored network then fetched changed RC successfully |
| RC before/change/restore | `corrective-412-profile-ready.png` enabled/3 -> `corrective-412-rc-changed-profile.png` disabled/1 -> `corrective-412-rc-restored-profile.png` enabled/3 |
| Actual behavior gates | `corrective-412-matching-disabled-result.png`, `corrective-412-home-limit-two-bottom.png`; same APK, no reinstall/rebuild |
| Handled diagnostic | `logs/corrective-360-nonfatal-logcat.log`: Profile diagnostic StateError; not a business-flow failure or Console receipt |
| Intentional crash | `logs/corrective-deliberate-crash-logcat.log`: native FlutterFirebaseCrashlytics test exception, PID5565; app relaunched |

## Failures and limits

Original emulator's `INSTALL_FAILED_UPDATE_INCOMPATIBLE` was bypassed by a fully
independent AVD on D, not by removing its package/data. Original AVD only shut
down for RAM. New API37 revision6 AVD uses 4096MB, software GPU, 2 cores.
Initial 2GB run had GMS SIGBUS; that crash buffer was observed but not retained
across reboot. 4GB first boot had System UI ANR and slow initialization, followed
by successful rendering. Do not claim an app-code fix resolved those failures.
API37 minimum-memory guidance: [official emulator release notes](https://developer.android.com/studio/releases/emulator).

Tutor-detail retest interrupted: `logs/corrective-gms-package-update.log` proves
PID6589 was killed for Google Play services package update. Detail is not PASS.
Host C filled from paging and some captures could not be written; after restoring
and stopping the isolated emulator about 6.3GB returned. Generated dart cache was
moved intact to D; no personal file deleted, no registry/pagefile setting changed.
No RenderFlex overflow observed in selected package logs; not comprehensive QA.
Status-only `.xml` outputs from the first hierarchy method are not XML evidence.

Dedicated account absent: authenticated session/native Google picker/signout/
account switch/private workflows BLOCKED. FCM delivery, real Storage upload,
seven Analytics DebugView events and Crashlytics Console receipt NOT RUN/BLOCKED.
Staging, ARTEMIS, external review and physical hardware NOT RUN.

Display/network/Analytics debug restoration:
`logs/corrective-restored-device-restore.json`. Isolated AVD then shut down;
no user app uninstall, clear-data or wipe was executed. Cloud RC restored empty
version2 with ETag guards; native enabled/3 confirms refetch. Raw logs/configs
remain private on D; committed PID logs redact credential-bearing lines.

Reproduce in a coordinated test window:
`scripts/start-bao-isolated-android.ps1`, then prepare/install/resize/launch/capture
with `scripts/verify-bao-android.py --serial emulator-5558`; observe each screen
before tapping, and always restore device state. Account-dependent cases need a
dedicated authorized identity first. Never install over or clear the original AVD.
