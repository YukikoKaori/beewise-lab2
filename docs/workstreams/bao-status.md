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



# Bao cloud + Android status

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

## Approved deployment and authenticated runtime follow-up (historical)

Owner approved and the exact frozen Firestore rules/index bundle was deployed.
Preflight hashes/baseline unchanged; **28/28 frozen rules tests rerun PASS**.
Index reached READY before rules release; both CLI exits 0. Live rules now match
repository hash `759a35e...`, ruleset `2aff57c1-3693-4bfa-9cd2-d77471ef08d6`,
including the missing own-application match. Four real guest private-read denials
and public server tutor reads PASS; these are not authenticated cross-UID tests.

Account A actually signed in after deployment and created its parent profile.
Cold-start restored its Auth SDK session and registered its own Android device.
Profile then exposed `Bad state: No element` for a blank restored display name.
Owner granted an explicit exception for that fallback only; correction committed
with six widget regressions (before: 3 FAIL; after: 6 PASS). Full Flutter **59/59**,
format/analyzer and APK build PASS. Same-signer install preserved A; restored
Profile and managed logout PASS. A registration removed and guest inbox empty.
B login/profile/restore/logout and visible inbox isolation PASS; same installation
belongs only to B after explicit retry, then neither account after logout. B
automatic registration initially stalled pending; manual retry recovered it.
Keep that reliability finding open. Fresh new-APK 360dp/412dp PNGs and guest
offline cache/reconnected Search captured; device settings restored. Real foreground/background/process-death FCM
delivery and Search routing PASS; malformed/inaccessible routes rejected.
No other Nguyen UI/theme/router/ARTEMIS/review/final files changed.

The owner-supplied Google config update was preserved (same project/app/client
key; one web OAuth client). Google provider became enabled externally; Android
SHA remains absent in the latest inspection, so Google login is not verified.
Storage/billing unchanged. Console/DebugView receipts, staging, trusted
backend/provider, ARTEMIS and external review remain NOT RUN/BLOCKED.

Deployment receipts and exact scope are in `bao-deployment-plan.md` and
`evidence/cloud/authorized-deploy-*.json`; account metadata snapshots are
`evidence/cloud/test-users-*.json`. No passwords/tokens requested or exported.

## Earlier readiness snapshot (superseded by approved deployment above)

## Auth provisioning follow-up — 2026-10-31

**PARTIALLY COMPLETE.** Fetched PR #3 HEAD
`f0fd2f73c5e8aa39bb5626169d5d0c9d1ea1e882`; preserved existing fixes.
This section supersedes historical statements below about missing test users.

| Task | Current evidence | Remaining blocker |
|---|---|---|
| B-01 | Installed base APK hash matches the existing current build; fresh cold launch Status ok, Home 360dp and guest Profile 412dp PNG/XML/PID logs | System UI ANR on boot retained; parent login/logout/session restore/isolation NOT RUN |
| B-02 | Two enabled password identities verified using server-projected metadata only; six synthetic tutors re-audited; deployed rules lack tutorApplications match | Explicit owner permission for frozen rules/index deployment pending; Google provider/SHA still absent |
| B-03 | Fresh read-only six-service management audit; previous real RC publish/restore remains valid | Authenticated FCM/Storage and Console receipts remain NOT RUN/BLOCKED; no credentials used |
| B-04 | Original 27/27 rules PASS, extended 28/28 PASS in repo and exact frozen bundle; 6/6 Auth mocks and 53/53 full Flutter tests PASS | These do not prove live Auth; trusted payment/staff/backend/staging still absent |
| B-05 | Updated readiness, frozen deployment manifest, native evidence and status; formatter/analyzer PASS | Latest pushed HEAD/CI reported in handoff; ARTEMIS/external review/final presentation NOT RUN/BLOCKED |

Root cause: Auth reads its own `tutorApplications/{uid}` before parent bootstrap.
The deployed rules deny that read even for an absent document. Repository rules
already allow the strict owner lookup; retain fail-closed client behavior.
New tests cover missing-own-document bootstrap, cross-UID denial, ordered parent
creation, role lookup permission denial and applicant separation. No app source
or rules were weakened. No shared deployment or account login was performed.

Receipts: `evidence/cloud/auth-provisioning-readiness.json`,
`prepared-firestore-deployment.json`, `checks/auth-provisioned-20261031/`
(original 27), `checks/auth-bootstrap-regression/` (28),
`checks/auth-frozen-bundle/` (28), `checks/auth-bootstrap-final/` (53).
Exact commands/preflight/secure forward-repair policy: `bao-deployment-plan.md`.
Device evidence: `evidence/android/auth-ready-runtime.json`.

## Previous corrective delivery (historical)

**PARTIALLY COMPLETE**, 2026-10-31 local (receipts use UTC 2026-10-30).
Fetched PR #3 HEAD `18bd6d47a7d9135b3054217faef2dd4835be5976` before editing;
preserved its fixes. App source tested/built: `9ef5907b2d296fcdafaa869a53e9780692f4cc56`.
Subsequent commits change validation scripts/evidence/docs only. Final full HEAD
and newest-head CI are reported in the PR handoff; PR remains open, not merged.

| Task | Actual result | Remaining work |
|---|---|---|
| B-01 | PASS latest APK install/launch on isolated API37 AVD on D; native 360dp/412dp Home/Profile, Search data, matching gate, offline cached catalog and recovery | Auth session tests BLOCKED; initial 2GB GMS SIGBUS and 4GB System UI ANR/slow boot retained as environmental findings |
| B-02 | PASS six fixed-ID fixture audits and live guest SDK/native reads; deployed rules compared again | No dedicated identity (user confirmed); Google provider absent/SHA empty; rules/index deployment requires separate authorization |
| B-03 | PASS live RC conditional publish/restore and same-APK visible changes; permission UI, handled diagnostic and deliberate crash actually exercised | FCM delivery, Storage upload, seven DebugView events and Console Crashlytics receipt NOT RUN/BLOCKED |
| B-04 | PASS existing secure client/rules gates, all 27 emulator tests; fixture-only AI path negative test | Trusted processor, staff identity, payment provider and staging absent; no live business E2E claim |
| B-05 | Updated task/status/native/six-service manifests, authentic PNGs, sanitized PID logs and deploy/rollback preparation | Console screenshots, ARTEMIS, external review and final presentation remain NOT RUN/BLOCKED; Nguyen-owned files untouched |

New fix: synthetic metadata/known fixture namespace forces `[TEST]` name and
`verified=false` in the model; synthetic tutors cannot enter AI as real profiles.
Five new regression tests cover both metadata forms, metadata removal, genuine
profile preservation, and fixture-only service execution without initializing AI.
No cloud record was changed/deactivated/deleted by this fix. No hardcoded tutor
catalog was added to the submitted app. Existing six fixtures remain active and
clearly labeled/unverified; cleanup/isolation needs explicit authorization.

## Quality gates actually executed

`evidence/cloud/checks/corrective-final/` records exact commands, SHA, exits:
locked pub get PASS; formatter PASS (31 files, 0 changes); analyzer PASS (no
issues); Flutter tests **50/50 PASS**; isolated demo-project Firebase rules
**27/27 PASS**; real Android debug APK build PASS. Build retains future Kotlin
plugin migration warnings. Source did not change after these application checks.
Final-head GitHub Actions is verified separately in the PR/final handoff.

## Actual cloud state and constraints

See `evidence/cloud/live-management-state.json` and six-service manifest.
Correct project `beewise-lab-3`; no alternate project used. Email/password enabled,
anonymous disabled, Google provider CONFIGURATION_NOT_FOUND, Android SHA list empty.
No Storage bucket/release; billing disabled. Analytics linked, not DebugView proof.
Deployed Firestore rules hash still differs: missing applicant separation for parent/device writes, current
proposal/revision/expiry guards and reciprocal request/chat creation. Composite
index audit/receipts are separate from emulator tests. No malicious live write.
`bao-deployment-plan.md` has exact commands, preflight/READY-index checks and a
secure rollback policy. No rules/index/provider/billing/enforcement deployment.

Authorized RC experiment: original empty template -> version 1 (home limit 2,
AI limit 1, matching false) -> restored empty template version 2 with conditional
ETags. Device before/after shows 3->1 and enabled->disabled; submit is blocked,
and Home ends after two tutors. API confirms restoration; Console screenshot
still NOT RUN. Offline validation disables BOTH Wi-Fi and cellular; Wi-Fi alone
was insufficient. No identity or password was used or captured.

## Native environment findings

Independent `BeeWise_Bao_PR3_API37`, emulator-5558, API37 revision 6, 4096MB RAM,
software GPU, 2 cores, on D. Original emulator was shut down to free RAM; its
package/userdata were never uninstalled/cleared/copied. First 2GB run had native
SIGBUS through GMS Dynamite/dex verification; 4GB cold boot had System UI ANR and
slow first startup before successful app rendering. Do not attribute these to a
proven Dart defect or claim they were fixed by application code.
Windows C filled during paging; only the generated `.dart_tool` cache was moved
intact to D with a junction. No personal files deleted or system configuration
changed. APK/cache/toolchain remain on D. Raw logs/private config remain there.

Runtime follow-up: PID6589 was killed by Google Play services package update; tutor detail remains RETEST/BLOCKED. RC restored enabled/3 and guest Chats login gate have genuine screenshots. Device settings restored and isolated AVD shut down.
