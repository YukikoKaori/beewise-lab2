# Bao acceptance — native API35 and Firebase Console, 2026-11-03

**B-03.2 COMPLETE — FIRESTORE ALTERNATIVE VERIFIED.** All independently executable
PDF acceptance gaps are now backed by real runtime/Console evidence. Overall:
**BAO TASKS NOT FULLY COMPLETE — EXACT BLOCKERS LISTED**, because B-04 still lacks
an authorized trusted producer and successful AI-provider execution.

Base/main: `8c494f0780aab7c41796244ab78b5c4ffb1daff4`, refetched during execution.
PR #12 is MERGED at that SHA (2026-11-03 07:48:29Z). Application code/configuration
is unchanged in this branch. The implementation change improves startup capture
and adds four timing/transport regression tests to CI; it is not an invented
application ANR fix. Final delivery SHA/CI are recorded in the delivery PR.

## All Bao tasks

| Task | Final status | Missing items resolved | Environment / actual artifacts | Remaining limit or dependency |
|---|---|---|---|---|
| B-01 | COMPLETE for controlled Android runtime | Fresh API35, three final-APK cold starts, warm timing, responsive navigation, real 360/412dp | [Startup measurements](startup/results.json), [360dp](startup/final-360-home.png), [412dp](startup/final-412-home.png) | Debug/software emulator is slow; intermittent ADB dump/trace loss retained. Immediate-boot API37, release and physical-device parity not claimed. |
| B-02 | COMPLETE for approved Auth/Firestore scope | Actual Users Console, normal A/B sessions/logout, own server reads, foreign parent/report denials; consented demo disclosure | [Users Console](auth-users.png), [native server excerpts](native-client-server-excerpts.txt), [live rules/index readback](firestore-readonly-state.json), [demo](demo-detail.png) | One owner-consented demo is professionally unverified; no general production-catalog or malicious-write claim. |
| B-03.1 | COMPLETE in tested scope | Users Console durable receipt; normal native login/logout and recovery | [Users Console receipt](auth-users.json), [prior valid Auth/Google/restore evidence](../approved-runtime-validation.json) | Prior Google/cancel/restore receipts reused; no account created this run. |
| B-03.2 | COMPLETE — FIRESTORE ALTERNATIVE VERIFIED | Actual 30s timeout, UI retry/hash equality, missing-auth UI, late callback after B, fresh export DebugView parameters | [PDF matrix below](#pdf-live-acceptance), [DebugView](export-debugview.json), [actual parameter pane](export-debugview-subjects.png) | Account-switch instrumentation uses raw native Auth SDK; separately tested managed UI logout/recovery is distinguished. |
| B-03.3 | COMPLETE in tested scope | Android denied-permission UI and actual Firebase Console test send | [Denied permission](notification-denied-profile.png), [Console sender](fcm-console.png), [device receipt](console-fcm-background-received.png) | New Console test is background receipt + tap to Home, not a recipient-scoped deep-link. Prior foreground/background/terminated guarded-tap evidence retained. |
| B-03.4 | COMPLETE for minimum seven business types / tested identity sequence | Durable historical parameter-pane artifacts and fresh PDF export receipt; plan traceability corrected | [Historical actual Console artifacts](historical-console/manifest.json), [fresh export](export-debugview-size-readable.png), [event traceability](#analytics-traceability) | Do not infer every planned workflow event, historical user-property display, or universal identity behavior. |
| B-03.5 | COMPLETE for prior scoped Console checks | Actual historical fatal/nonfatal/keys/stack captures now accessible in Git | [Historical Console manifest](historical-console/manifest.json) | No new deliberate crash; persisted keys do not identify the fatal trigger. No new nonfatal identity/logout-clear claim. |
| B-03.6 | COMPLETE | Exact-approved Console before/applied/restored and same-APK app gate/default recovery | [Console applied](rc-applied.png), [restore](rc-restored.png), [conditional restore receipt](rc-restore-receipt.json), [app restored](rc-restored-profile.png) | Fresh one-record catalog cannot demonstrate a binding Home cap; valid earlier same-APK Home two-card cap evidence reused. Five-minute fetch cache respected. |
| B-04 | PARTIALLY VERIFIED; exact live dependencies BLOCKED | Real parent discovery → request/chat batch → text; genuine server readback; AI error/manual recovery; negative owner boundaries | [Actual chat](f01-chat-message-sent.png), [server receipt](native-client-server-excerpts.txt), [AI safe error](f02-ai-submit.png), [API state](appcheck-api-state.json) | Owner confirms no trusted staging/backend. App Check API DISABLED and native AI reports `Too many attempts`; successful provider response not verified. See minimum unblock actions below. |
| B-05 | COMPLETE for Bao evidence/handoff package | Consolidated indexed captures, source/APK/time/hash attribution, prior artifacts made accessible, current tracker/handoff and explicit blockers | [Manifest](manifest.json), [full audit matrix](audit-matrix.md), [Nguyen handoff](../../../docs/workstreams/bao-to-nguyen-final-handoff.md) | Does not mark B-04, Nguyen ARTEMIS/review/report/slides or all Lab 3 complete. Exact delivery CI belongs to final PR. |

The [audit matrix](audit-matrix.md) records requirement, prior status/evidence,
missing condition, root cause, engineering action, validation and final status
for every B task/subtask. Old dated packages remain immutable.

## Android startup and implementation

Fresh official Google APIs API35 x86_64 r9, isolated AVD
`BeeWise_Bao_Acceptance_API35`, emulator-5562: 2 vCPUs, 2048 MiB, software GPU,
no snapshot; 720×1600 / density320 = 360dp. Actual 412dp capture uses an Android
824×1832 display override at density320, restored afterwards. Old API37 userdata
and working Firebase files were preserved. No physical device was available.
The serial-console performance warning remains visible; no boot setting was
changed to hide it.

Final default `lib/main.dart` debug APK: **187179439 bytes**,
SHA256 **`1ccb8ea3fbc1bc916c00dbf8e6ace783a9ff049e00e85a01acf96dd9dddc414c`**.
Built from base application's unchanged tree; installed with `adb install -r`
success, preserving authentication/data. Three final controlled cold attempts:

| Cold attempt | New PID | Android `am start -W` wall time | Actual outcome |
|---|---|---|---|
| 1 | 10296 | 7469ms | Home, no ANR dialog, main sampled in `do_epoll_wait` |
| 2 | 10483 | 7391ms | Home, no ANR dialog, main sampled in `do_epoll_wait` |
| 3 | 10686 | 8266ms | Home, no ANR dialog, main sampled in `do_epoll_wait` |

These wall times include ADB/ActivityManager overhead; they are **not** substituted
for Flutter first frame. Warm start retains PID10686, 328ms; ADB disappeared
during subsequent dump, so that attempt's XML/ANR result is unknown. A separate
[actual Home follow-up](startup/final-warm-followup.png), later native navigation
and [final last-ANR readback](restoration.json) confirm responsiveness/no ANR since
boot. Do not relabel the failed dump as a successful dump.

Earlier same application tree/default APK
`9f24102645ef0adada294a8f1a113e21c9ad2a88a822e461c758eb6354ed47f3`
also passed three cold attempts (5234/5141/5281ms) and a same-PID warm328ms.
Its explicit VM markers measured process→first framework frame9415.675ms and
process→first raster9862.530ms (engine-relative6396.804/6843.659ms). This sample
overlapped host quality gates, so it is supplemental timing, not a settled
performance baseline for the rebuilt APK. Further large timeline transfers were
truncated and ADB went offline; incomplete attempts stay private/hash-indexed.

Host snapshot: 8 logical CPUs, 32% load, ~7.7GiB free of15.8GiB RAM. The settle
gate required three consecutive Android load1≤3 / available RAM>512MiB samples;
actual final three were2.93/2.47/2.09 and ~1317MiB available. Per-attempt CPU,
memory, lifecycle, logcat, ANR, process exit, main-thread state and frame-stat
artifacts are retained privately with hashes in [results](startup/results.json).
The successful cold attempts report no ANR since boot. Kernel stack access is
denied and is not represented as a captured Java/native stack.

Historical matched API37 BeeWise/minimal Flutter control runs and the original
ANR traces remain in [controlled diagnosis](../../../docs/workstreams/bao-reliability.md)
and [prior manifest](../../android/pr3-controlled/manifest.json). No new control
APK was built this run. Together, settled API35 success and prior matched control
support emulator/host scheduling sensitivity as the scoped diagnosis. They do
not prove the precise cause of every original API37 incident or eliminate all
possible application contribution. No reproducible BeeWise-specific startup
defect justified changing bootstrap, identity, role gates or FCM.

Engineering change: `measure-bao-startup.py --trace-startup` reads explicit
Flutter first-useful-frame markers and process clock ticks, keeps framework and
raster times distinct, and refuses generic later frames as first-frame proof.
Tracing is opt-in; a truncated HTTP trace becomes NOT_OBSERVED without aborting
UI/ANR collection. Four tests cover origins, wrapped/missing markers, invalid
clock and incomplete-transfer cleanup. No startup delay, detector suppression,
dialog hiding, data clear or diagnostic entrypoint was introduced.

**Scoped startup assessment: APPROVE_MERGE for controlled-runtime evidence/tooling.**
An unresolved emulator-only immediate-boot condition does not block this change
indefinitely. Reopen with a captured BeeWise-only ANR on a settled device, a
continuous main-thread trace showing application blocking, or a release/physical
reproduction. Full Bao business acceptance remains blocked separately by B-04.

## PDF live acceptance

API35 live Firebase `beewise-lab-3`; production entrypoint/services/controllers.
Most timeout/security captures use prior default APK9f241… from the identical
application tree. Fresh Console export uses rebuilt default APK1ccb8… . Every
capture/receipt identifies its own source/APK; these are not mock-only PASSes.

| Case | Expected / actual observation | Result / timestamp / evidence | Scope limit |
|---|---|---|---|
| TC-PDF-01 | Actual tutor-detail button generates valid local PDF with two subjects; actual bytes19315 → integer KiB18 | PASS; event17:11:50 UTC+7, [fresh native/Console receipt](export-debugview.json), [size pane](export-debugview-size-readable.png), [subject pane](export-debugview-subjects.png) | PDF remains private; only length/header/hash exported. |
| TC-PDF-02 | Exactly one separately authorized A report saved by normal UI; forced server acknowledgement/readback; inventory A2→3, B2 unchanged | PASS; 09:25Z, [native server excerpts](native-client-server-excerpts.txt), [prior live roundtrip/upload Console](../firestore-reports/live-20261103/manifest.json) | Four pre-existing reports preserved; no duplicate save used to emit export. |
| TC-PDF-03 | Old report baseline/retry server download19315bytes with equal SHA; new UI-created original/download equal too | PASS; 09:19/09:30Z, [old hashes](native-report-hashes.json), [UI hashes](ui-report-hashes.json) | Prior Android preview/share proof reused; baseline service call is debugger-invoked and labelled. |
| TC-PDF-04 | A pending real download → signed out → B authenticated before transport restore → old Future settles, state remains idle/no result/path; B own reads succeed and A parent/report denied | PASS; 09:31–09:33Z, [settlement](switch-1793698300043187500-result.json), [server denial excerpts](native-client-server-excerpts.txt), [B UI](b-profile-after-settlement.png) | Raw native Auth SDK signOut/signIn via attached debugger exercises auth-state edge; managed logout/recovery tested separately. Immutable/malformed denials retained from prior real Client SDK package. |
| TC-PDF-05 | Guest cloud-save gives visible sign-in error. Real UID-scoped dropped transport keeps actual UI downloading through29.140s; error at30.203s, busy=false/path absent; restore + actual UI retry succeeds without extra report | PASS; 09:27–09:30Z, [loading](ui-timeout-loading.png), [readable actual error](ui-timeout-error-readable.png), [samples](ui-timeout-result-1793698065463448500.json), [hash recovery](ui-report-hashes.json), [guest error](guest-pdf-save-error.png) | Missing-auth download UI is unreachable after state reset; save UI is tested. An initial SDK `unavailable` at10.036s is a different outcome, not the 30s PASS. |

Actual old-report application boundary: native ExportException at30003ms;
[receipt](native-timeout-impaired-1793697481048048300.json). Error text:
“Chưa xác nhận được từ server. Hãy kiểm tra mạng và thử lại.” Network impairment
was confined to the app Linux UID and removed in `finally`. UI timeout never
claimed success after transport restoration. Old report retry155ms and19315bytes,
SHA256`8e8d5f2f2c565c45c00081afb944f69f0aa1151f754dfa6e1617aa5286ad0bfe`.
New UI report original/download SHA256
`b95c76eeb1c3371ea77542b5c040a11f73d3e0d43d0c3db160f02f2fd853b23d`.

The unexpected raw SDK account switch correctly quarantined the old FCM journal.
Normal B logout and A login recovered owned cleanup; no cross-UID deletion or
fail-open registration was added. Existing deterministic timeout/cancellation
tests remain useful regression coverage, distinct from this native live proof.

DebugView root cause/recovery: existing Chrome Analytics iframe and direct
Analytics page rendered blank without an explicit permission-denied error.
A fresh IAB session authenticated by the owner loaded the correct property
560584336. Actual UI local generation then delivered `export_report` at17:11:50,
`subject_count=2`, `file_size_kb=18`, matching measured19315-byte PDF. No synthetic
event, extra cloud report, identity workaround or Analytics data reset was used.
Historical user properties were not interpreted as post-logout event identity.
All temporary Analytics debug properties were restored exactly afterwards.

## Firebase / Analytics traceability

Auth Users Console shows four existing rows (three Email, one Google), with
identifiers masked. Native B own Parent/reports are server reads; foreign A Parent
and report return permission-denied. Active ruleset
`67a6d7ce-798f-44b4-8350-fe8bea890edc` matches repository normalized SHA256
`a2bc4d7c98b9b6ed128100d7465caa789675a7970419a3b6757bad7727838f80`.
Chat compound index is READY; explicit Base64 indexing exemption remains. No
rules/index deployment was performed this run.

FCM Console **test** targeted only the consented emulator installation ID,
not a campaign audience. A genuine background notification was received and
tapped to Home. No arbitrary recipient-free deep-link claim is made. Previous
generation/journal/cross-UID/fail-closed routing evidence and all regressions are
preserved. Notification permission was first denied, then granted via real
Android settings for the send test; final state is granted.

| Event | Actual evidence / limit |
|---|---|
| login | Historical Console password method PNG; prior native Google method preserved. |
| logout | Historical actual Console receipt; identity sequence remains accepted. |
| search | Historical seven-type union in console-runtime/reliability manifests; no free-text export. |
| view_tutor | Historical entry_source pane and fresh stream preceding PDF export. |
| ai_match_no_results | Historical actual event pane. Fresh AI failure is not a no-results success. |
| sign_up | Historical method/account_type panes; no new account creation. |
| export_report | Historical one-subject record retained as history; fresh two-subject/actual-size panes above satisfy current PDF acceptance. |
| upload_report | Existing real Firestore-backed DebugView proof in live-20261103; fresh native FA-SVC success bundle retained. |
| connection_request_submitted / chat_message_sent | Real parent UI/server roundtrip + native SDK event logs; fresh Console parameter panes NOT RUN. |
| tutor_application_submitted / view_detail / ai_match_success / trial_response / class_revision_confirmed / class_adjustment_requested / payment_verification_requested | Implemented event contract; no blanket native/Console PASS. Trusted/provider-dependent events remain outside verified minimum. |

The [historical manifest](historical-console/manifest.json) verifies original
hashes before publishing cropped/PII-masked real screenshots. Browser tabs,
bookmarks/account avatar and Crashlytics UID are omitted; event/stack values are
unchanged. Actual fatal/nonfatal Console receipts are reused without crashing
the app again. See [Analytics plan](../../../docs/analytics-plan.md).

RC exact-approved SHA256`ea9611c111e0db6786900041db4d29394f651ed7ee9a8cf19d0385d1a9c93b4f`:
version2 empty → version3(false/1/2) at09:47:14Z → version4 empty at09:50:06Z.
ETag guards and exact readbacks PASS. Same APK shows disabled/1 and real blocked
submit, then enabled/3 after natural five-minute fetch interval. Earlier valid
[same-APK Home cap](../../firebase/remote-config/README.md) provides the second
binding behavior (Home ends after two cards); fresh single eligible record cannot
exercise that cap and is not called new cap proof. No pending RC restoration.

## B-04: exact remaining dependencies

Three existing flows remain Discover/connect, Guest AI, and consultant onboarding
through verified payment/schedule. No business flow was replaced by a mock.

1. **Discover/connect — tested parent scope PASS.** One actual UI connection
   request creates reciprocal request/chat in a batch; one non-sensitive test
   text follows. Forced native Client SDK server read confirms goal match,
   reciprocal IDs, `connection_pending_consultant`, queue=true, two messages and
   one expected parent text. Preliminary parser used wrong field names and is
   preserved; corrected source fields give the final positive readback. No
   consultant assignment or accepted schedule was invented.
2. **Guest AI — error/retry/manual recovery PASS, provider success BLOCKED.** Real
   native exception is `[firebase_app_check/unknown] Too many attempts.` Read-only
   Service Usage API confirms `firebaseappcheck.googleapis.com` is **DISABLED**
   at09:59:23Z. No App Check configuration/enforcement/billing change. Minimum
   unblock: project owner authorizes/configures App Check/provider prerequisites
   for this registered Android client, then run a real matching response against
   the allowed catalog. Merely showing the safe error or mock response cannot
   establish provider success. Separate product contract is also needed if the
   Lab 2 one-success guest allowance becomes an accepted requirement.
3. **Trusted onboarding — BLOCKED by unavailable producer/operator.** Owner
   explicitly confirmed no trusted staging/backend. Repository has client and
   rules, no deployed trusted producer. Required dependency: an authorized
   consultant/staging producer following [backend contract](../../../docs/backend-contract.md)
   for current proposal/revision pointers, pending/expiry, one immutable response,
   idempotent invoice issue, independently verified payment and derived official
   class/schedule. Obtain a legitimate approved fixture/producer with rollback
   and exercise parent responses end-to-end. Parent writes, Admin SDK fabricated
   paid invoices or weakened rules cannot replace this trust boundary.

No backend expansion, payment transaction, trusted fixture, fake qualification,
Storage/bucket/billing deployment or Nguyen UI/ARTEMIS/report/slides change.

## Validation and handoff

Local full gates: pub get, format(41 files/0changed), analyze(no issues),
Flutter95/95, Firebase Firestore Emulator58/58, default debug APK build and
harness structure27 PASS. Startup metrics tests4/4 PASS and added to Actions.
Harness structure/pytest collection are **not** native ARTEMIS runtime results.
First rules invocation lacked installed Firebase dependencies; `npm ci` fixed
the tooling prerequisite and the actual emulator suite then passed. No test
expectation was weakened. Node25 local tooling warning/dev dependency audit
is distinct from CI's configured Node24. Gradle/Kotlin plugin deprecation
warnings remain; build succeeded.

[Quality receipts](quality.json), [artifact hashes](manifest.json), actual
PNG/XML/compact native receipts in this folder, plus prior immutable packages
are reviewable by Nguyen without private D: paths. Large full logcat, ANR traces,
private PDFs, VM endpoints and credentials stay outside Git; hashes/selected
sanitized diagnostics are retained. The readable timeout screenshot masks only
the private report path; the earlier broad-mask copy is retained as an alternate
redaction, not relied upon to prove its hidden error text.

Reproduce: use settled API35/default entrypoint, authenticate only consented
accounts privately, demonstrate disclosed demo → local PDF → existing private
server download; use the current screenshots for timeout/account-switch rather
than silently impairing a shared device. Any new report or cloud publication
must stay within independently scoped approval. All temporary network rules,
Analytics debug properties, display override and adbd root were restored;
[restoration receipt](restoration.json). Emulator userdata/app authentication and
five private reports remain intact. Exact final HEAD Actions must be checked in
the single delivery PR; no automatic merge.
