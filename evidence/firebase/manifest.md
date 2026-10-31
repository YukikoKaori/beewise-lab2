## Reliability corrective validation — 2026-10-31 (latest)

Application source: `be2b44515af637db1c7ded6b94797d1cf4adc746`.
This update supersedes the historical status entries below. Final delivery HEAD
and its CI are recorded in PR #3 description; no merge or new PR.

- **B-01 PARTIALLY COMPLETE:** same-signer default APK build/install PASS without
  data clearing. Native A first-login PASS on default entrypoint; B/Google PASS on
  explicit debug diagnostic entrypoint using the same production services/UI.
  A session restore, actual A/B foreground FCM receipt/tap and managed logout PASS.
  Role failure stays on account-check; restored network plus explicit retry returns
  Home. Final default APK reinstall hit a genuine input ANR/slow startup; subsequent
  relaunch renders Home. Failure evidence retained; clean cold-start is not PASS.
- **B-02 scoped checks COMPLETE:** actual native authenticated A→B, B→A, Google→A
  each allow own server Parent read and deny foreign Parent/application/devices
  reads: **9/9 permission-denied**, no Admin bypass. Live malicious writes NOT RUN.
  Existing strict rules/index and approved SHA configuration preserved; no deploy.
  Six labeled synthetic tutors preserved; no new tutor/request/payment records.
- **B-03 PARTIALLY COMPLETE:** FCM race reproduced and fixed with generation guards
  and acknowledgement deadline; first-login A/B/Google succeed without retry or
  restart. Exactly one owner-authorized test signup and Parent confirmed. Analytics
  **7 distinct business events** have real DebugView receipts, adding `sign_up`
  (`method=password`, `account_type=parent`) and guest `export_report`
  (`subject_count=1`, `file_size_kb=16`). Google `login(method=google)` verified.
  UID-clear acceptance remains **NOT VERIFIED**: later guest event's DebugView
  properties still show prior dedicated UID. No successful clear claim.
  Local PDF is real (16,419 bytes); Storage upload stays **DEFERRED**. Prior real
  Crashlytics and RC receipts retained; not rerun or substituted with unit tests.
- **B-04 PARTIALLY COMPLETE:** transient role reads use bounded server reads and
  fail closed; unit/native retry PASS. Trusted payments/official schedules still
  require backend/provider and are **BLOCKED**, with no client privilege changes.
- **B-05 PARTIALLY COMPLETE:** formatter/analyzer PASS; Flutter **64/64**; Firebase
  Emulator rules **28/28**; APK build PASS; application HEAD CI **3/3 PASS**.
  Final evidence HEAD checks must match newest PR SHA. Actual client negative
  probe and aliased logs are reviewable; originals private on D. ARTEMIS/external
  review/physical hardware **NOT RUN**; staging/App Check out of scope. No Nguyen
  UI/router/theme/review/presentation edits. **NOT MERGE READY** overall.

Primary current manifest: `evidence/cloud/reliability-validation.json`.
Root cause, implementation and regressions: `docs/workstreams/bao-reliability.md`.

## Google live verification follow-up — 2026-10-31 (historical)

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



# Firebase evidence index — Bao

## Computer Use Console follow-up — 2026-10-31 (historical)

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

## 2026-10-31 Auth provisioning follow-up (historical)

Two enabled Password identities exist, verified through metadata-only API fields;
no passwords, emails, hashes or tokens requested or stored. This supersedes prior
"identity absent" blockers below. **Actual Auth login/profile/logout/session
restore/cross-account isolation: NOT RUN**, pending explicit owner authorization
and completion of the strict Firestore deployment, then user-entered device login.
Deployed `tutorApplications/{uid}` match is missing; repository rules are strict
and already contain it. Readiness and exact frozen deployment receipts are in
`../cloud/auth-provisioning-readiness.json` and
`../cloud/prepared-firestore-deployment.json`.

Fresh checks: original rules **27/27**, extended rules **28/28** (also exact frozen
bundle), Flutter **53/53**, formatter/analyzer PASS. These are local checks.
Read-only live service audit refreshed in `../cloud/live-management-state.json`:
Google provider/SHA absent; no Storage bucket/release; billing disabled;
Analytics linkage is not DebugView; Crashlytics Console receipt and authenticated
FCM delivery remain NOT RUN/BLOCKED. Previous RC roundtrip restored empty version
2; no new live mutation. Six existing labeled synthetic tutors re-audited and
preserved. New native guest receipts: `../android/auth-ready-runtime.json`.

## Previous corrective delivery (historical)

2026-10-31 local; project `beewise-lab-3`, package `com.beewise.beewise`.
App source `9ef5907b2d296fcdafaa869a53e9780692f4cc56`.
Local checks: `../cloud/checks/corrective-final/`. Rules use `demo-beewise` only.

| Service | Actual device/cloud verification | Remaining blocker |
|---|---|---|
| Authentication | Live management configuration read; guest app state observed; unit/rules PASS | Dedicated identity absent; Google provider/SHA absent; sign-in/out/account switching NOT RUN live |
| Storage | Real local PDF + upload mocks + owner/type/size emulator PASS | No live bucket, billing disabled, no identity; upload/URL/Console NOT RUN |
| FCM | Native Android notification permission requested and allowed; guest inbox empty; ownership/routes unit/emulator PASS | No authenticated receiver/sender; foreground/background/terminated delivery and live account switching NOT RUN |
| Analytics | Native SDK initialized; guest navigation exercised; project linked; privacy mocks PASS | Seven meaningful events in DebugView NOT RUN; no Console evidence |
| Crashlytics | Device log records handled diagnostic; intentional native SDK crash and relaunch exercised | Console receipt/user/custom-key association NOT RUN; guest diagnostic is not a real business-flow failure |
| Remote Config | LIVE_VERIFIED API publish/restore and same-APK visible gate/limits; original restored to empty version 2 | Console screenshots NOT RUN; native restore confirmation documented in Android manifest |

Actual PNG/PID evidence: `../android/README.md`; RC receipts:
`../cloud/remote-config-roundtrip.json`. Never substitute mocks or a snackbar for
server receipt. Supporting Core initialized on device; App Check management reads
are not attestation proof; no paid AI request was made.

Deployed rules still drift and composite index is missing; no deployment was
authorized. See `firestore/README.md` and
`../../docs/workstreams/bao-deployment-plan.md`. Six fixed tutor IDs were audited
from the real server, all labeled/synthetic/active/unverified. They remain preserved.
Model now enforces labels and excludes synthetic data from AI. No genuine tutor
endorsement is asserted. No Console screenshot: native browser tools fail before
control; isolated browser lacks an authenticated session. Credentials never copied.
