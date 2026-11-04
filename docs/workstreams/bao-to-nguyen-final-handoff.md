## Final ownership correction — 2026-11-04 (effective)

> **Latest owner decision, 2026-11-04:** the owner accepted the disclosed
> authorized1/actual2 request deviation retrospectively. The earlier draft
> hold below is historical and resolved; ready for review is conditional on
> final-HEAD gates. No additional provider calls, cloud/billing changes or
> deployment are authorized. Bao retains F-02; Nguyen owns F-03 only.
> [Owner acceptance and existing-data DebugView inspection](../../evidence/cloud/f02-lite-native-20261104/owner-finalization.md).


**B-04 is shared: F-01 existing verified cloud integration; F-02 owned by Bao;
F-03 owned by Nguyen.** Bao retains AI Matching/Firebase AI Logic/App Check,
genuine provider/native validation and acceptance evidence. F-02 is COMPLETE /
LIVE VERIFIED in API35 guest/debug scope. Nguyen owns consultant/trial/revision/invoice/payOS/
webhook/payment/schedule implementation and tests, status HANDOFF / PENDING
IMPLEMENTATION. Bao provides approved Firebase/security support for F-03.

[Precise F-03 handoff and preserved WIP](bao-to-nguyen-b04-handoff.md) supersede
the earlier broad transfer. B-01/B-02/B-03.1–6/B-05 remain COMPLETE scoped;
expanded Bao scope includes F-02. No entire B-04 or Lab 3 completion is claimed.
Earlier dated configuration/blocker statements below are historical, not current
AI state. No F-03 code or cloud deployment is part of Bao's F-02 delivery.

[Latest F-02 live evidence](../../evidence/cloud/f02-lite-native-20261104/README.md):
actual3.5 Flash-Lite result, validated demo ID, native detail/fallback and FA-SVC
success event count1. Local105 Flutter/58 Rules PASS; final CI in delivery PR.
The earlier3.8 failure packet remains historical. PR stays DRAFT for owner review
of the disclosed accidental2 calls against approved1; no further calls or merge.

## Historical Bao handoff — 2026-11-03 acceptance closeout

**PDF B-03.2 COMPLETE; full Bao mission not complete because B-04 has exact
external dependencies.** Use [one consolidated evidence index](../../evidence/cloud/bao-acceptance-20261103/README.md),
[all-B audit matrix](../../evidence/cloud/bao-acceptance-20261103/audit-matrix.md)
and its hash manifest before older snapshots below. Actual sanitized artifacts
are in Git; Nguyen does not need private D: originals to review them.

Demo environment: API35 isolated AVD BeeWise_Bao_Acceptance_API35 / emulator-5562,
default lib/main.dart debug APK SHA256
`1ccb8ea3fbc1bc916c00dbf8e6ace783a9ff049e00e85a01acf96dd9dddc414c`.
Keep existing userdata/Firebase files. Boot fully and wait for settled CPU/RAM,
then Home → Search → disclosed demo → tutor detail → local PDF. Authenticate
only the consented accounts privately; use the existing A report for server
download/retry. Do not create another cloud report or impair shared networking
without scoped authorization. Real 360/412dp, three final cold PIDs/Home/no ANR,
30s UI error/recovery/hash equality, guest error and A→B late settlement are in
the packet. Release/physical/immediate API37 parity is not claimed.

Console packet: Auth Users masked; denied notification UI + actual Console test
background delivery; fresh export_report subject2/size18 parameter panes; prior
upload_report and seven-event identity evidence; actual historical Crashlytics
stacks/keys; RC before/v3/empty-v4 and same-APK app restore. RC baseline and all
temporary debug/network/display/root settings restored. Five private reports
remain; no raw UID/email/token/PDF/Base64/credentials in new evidence.

Business flow: one real parent request/chat/text has forced server readback.
AI actual error/manual recovery is verified; provider success needs owner-approved
App Check/provider setup (API read-only state DISABLED). Owner confirms no trusted
staging/backend: consultant proposals/revisions, immutable parent responses,
trusted invoice/payment verification and official schedule still need an authorized
producer/legitimate fixture per backend-contract.md. Do not fabricate paid data
or claim rules/unit tests as that live E2E.

Local full suite PASS: Flutter95/95, rules58/58, format/analyze/pub/default APK,
harness27 structure and timing tests4/4. Exact final source SHA/Actions are in
the delivery PR. No automatic merge; Nguyen ARTEMIS/review/report/slides remain
under their existing owners/statuses. Earlier sections are historical guides.

# Bao → Nguyen final handoff — 2026-11-03

Bao scope and B-03.2 remain **PARTIALLY VERIFIED**. Implementation, approved
deployment, core native PDF roundtrip and tested security are verified. Distinct
native 30-second timeout/retry and a durable `export_report` DebugView parameter
capture remain open. This is the final executable handoff for this task, not a
claim that Lab 3 or Nguyen's work is complete.

## A — Baseline and build

- Refetched main: `b45bdce4d3a68006a28ca8e587fdece0187a8660`.
  [PR #11](https://github.com/YukikoKaori/beewise-lab2/pull/11) independently
  verified MERGED at `2026-11-03T06:01:05Z`; merge SHA matches main. Baseline
  [Actions 41587263380](https://github.com/YukikoKaori/beewise-lab2/actions/runs/41587263380)
  passed all three jobs. Final delivery PR records its own exact HEAD checks.
- Firebase `beewise-lab-3`; Android `com.beewise.beewise`; default `lib/main.dart`.
- Flutter 3.47.8 / Dart 3.13.7, JDK 21. Build from repository root:

  ```powershell
  flutter pub get
  flutter build apk --debug
  Get-FileHash .\build\app\outputs\flutter-apk\app-debug.apk -Algorithm SHA256
  adb devices -l
  adb -s <authorized-device> install -r .\build\app\outputs\flutter-apk\app-debug.apk
  adb -s <authorized-device> shell am start -W -n com.beewise.beewise/.MainActivity
  ```

- Current local APK:
  `D:/CodexTemp/beewise-bao-finalization/build/app/outputs/flutter-apk/app-debug.apk`;
  SHA256 `9f24102645ef0adada294a8f1a113e21c9ad2a88a822e461c758eb6354ed47f3`.
  Rebuilds may differ in bytes: record the new hash and source SHA. APK is not in Git.
  Current APK is debug, not release certification. Use the final CI artifact if
  transferring to another machine and verify that artifact's own hash.
- Existing AVD `BeeWise_Bao_Startup_API37`, `emulator-5560`, Android 17/API37,
  412dp (824×1832 at density 320), software GPU. Requested 2 GiB was historically
  raised by the emulator to about 4 GiB effective guest RAM. Existing data and
  signing identity preserved with `install -r`; no uninstall/data clear.
- Fresh launch returned `Status: timeout`, `LaunchState: UNKNOWN`,
  `WaitTime: 14293`; Pixel Launcher ANR remained visible. Initial resumed session
  also had System UI ANR. Do not record this environment as a clean launch PASS.
  Before the fresh APK install, ordinary Wait + role-check retry recovered Home
  and the consented tutor, and normal B logout reached guest. After install, Home
  appeared after Wait, then launcher ANR recurred when navigating Account.
- No physical device was available. For recording, use an already authorized
  normal Android device or a separately provisioned settled AVD. Preserve this
  AVD; stop if dialogs recur. Record model/API/source/hash, process launch and
  real screenshots. Wait for boot completion and stable system UI before starting;
  do not add arbitrary app delays or suppress ANRs. A clean device run is still
  required before claiming repeatable demo/startup performance.

## B — Actual demo walkthrough

Accounts A/B are the two existing owner-authorized **parent** test identities.
Obtain credentials privately from Bao/owner; never put them in scripts committed
to Git, ARTEMIS prompts, screenshots, report text or recordings. Do not create
accounts or change their roles. Do not use the demo tutor as a consultant account.

1. Launch BeeWise. If **Kiểm tra tài khoản** shows a transient failure, preserve
   it and try **Thử kiểm tra lại** once on a working network. Do not bypass the
   fail-closed role check. Stop on persistent system ANRs.
2. **Tài khoản → Đăng nhập**: sign in A using the private credentials. Verify
   signed-in parent state; hide email from captures. If input drops, fix the
   environment rather than declaring authentication success.
3. **Trang chủ**: locate **Xem hồ sơ: Hoàng Quốc Bảo**. Home filters synthetic
   fixtures; if missing, check network, catalog consent flags and Remote Config
   display settings with Bao. Do not alter live catalog to make a test pass.
4. Open that card. Check exact ID `tutor_acd3824aa8734c63ac8827df` via approved
   evidence if needed. Explain **Hồ sơ demo — đã duyệt cho kiểm thử**: owner
   consent, `active=true`, `verified=false`, `demoOnly=true`; professional claims
   are not independently accredited. Do not present the profile as verified.
5. Tap **Xuất hồ sơ PDF**. Expected **PDF đã tạo trên máy. Chưa lưu cloud.**
   This is local generation and emits `export_report`; no cloud success yet.
6. For a separately authorized recording save, tap **Lưu cloud riêng** once.
   It creates one immutable private report: avoid duplicate taps/retries after
   success. Watch **Đang chờ Firestore server xác nhận…**. Only
   **Đã lưu PDF và đọc lại từ server.** proves this UI operation completed the
   acknowledgement plus forced server read. Preserve failures honestly.
7. In the same session tap **Tải lại từ server**; expect
   **Đang tải PDF từ server…**, then **Đã tải PDF từ server về máy.**
   Compare actual file hashes if asserting byte equality. There is no public URL
   and no Firebase Storage bucket. Owner path contains a UID: redact it.
8. **Mở / chia sẻ PDF** opens Android's share/print handler. Inspect the actual
   document/demo disclosure. Cancel the chooser after preview; do not send it to
   anyone without authorization. Historical native Print preview is already
   proven; do not create another cloud report just to repeat that evidence.
9. **Tài khoản → Đăng xuất**. Confirm guest UI and report/private fields clear.
   Sign in B only for an authorized isolation test; A's report must not appear.
   Retain historical server cross-owner denial evidence; do not weaken rules.

There is currently **no saved-report history picker after process restart**.
Download UI depends on this controller's successful in-memory save result.
Do not invent a picker, inject a fake saved state, or create another report only
to make the timeout test reachable. For existing-report native timeout evidence,
Bao can use a documented debugger/service driver on a stable test runtime; label
that as instrumentation rather than a UI walkthrough.

No cloud saves were performed during this finalization. The steps above describe
the existing UI for a later explicitly scoped demo; they are not new PASS claims.

## C — Firebase evidence map

Historical links below resolve to immutable merged main, not fresh test runs.
The [PR #11 package](https://github.com/YukikoKaori/beewise-lab2/tree/b45bdce4d3a68006a28ca8e587fdece0187a8660/evidence/cloud/firestore-reports/live-20261103)
contains the original hashes, screenshots and limitations.

| Service | Evidence and tested scope | Current limits |
|---|---|---|
| Email/Google Auth | [Runtime receipt](../../evidence/cloud/google-runtime-validation.json), [Auth/UID lifecycle](../../evidence/cloud/reliability-validation.json); PR #11 native A/B account flows | Fresh task observed B managed logout; no fresh successful A UI login after dropped input; Google picker not rerun |
| Firestore PDF | PR #11 `pdf-roundtrip.json`, `native-server-saved.png`, `native-server-downloaded.png`, `native-downloaded-pdf-preview.png`, `console-native-report-metadata.png` | Historical 19,315-byte original/download/server-decode SHA `8e8d5f2f2c565c45c00081afb944f69f0aa1151f754dfa6e1617aa5286ad0bfe`; current local generation has a different hash and was not uploaded |
| Owner security | PR #11 `live-client-security.json`, `final-server-inventory.json`, `native-switch-pending.json`; A=2/B=2 report inventory at that run | Authenticated real Client SDK checks, distinct from rules Emulator tests; immediate pending reset proven, impaired-network signOut completion/all eventual SDK callbacks not proven |
| Analytics | PR #11 `debugview-upload-firestore.png` and `analytics-native.json`; [fresh native observation](../../evidence/cloud/firestore-reports/finalization-20261103/native-observations.json) | Fresh genuine `export_report`, subject_count=2/file_size_kb=18, native FA-SVC logged; current Console blank, durable export parameter screenshot NOT VERIFIED. Prior upload screenshot remains valid |
| Analytics identity | [A guest native](../../evidence/cloud/startup-uid-a-guest-native.json), [B guest native](../../evidence/cloud/startup-uid-b-guest-native.json), [controlled validation](../../evidence/cloud/pr3-controlled-validation.json) | Verified tested null-clearing/event identity scope preserved; historical DebugView properties do not prove later guest attribution. No reset/dummy ID/change this task |
| FCM | [Terminated observed notification + tap route](../../evidence/android/pr3-completion/terminated-tap-sequence.json), [reliability notes](bao-reliability.md) | Real historical notification/tap → Search proof; no fresh delivery run here. Send API acceptance alone is insufficient. Registration generation/journal/cross-owner/role regression tests preserved |
| Crashlytics | [Runtime receipt](../../evidence/cloud/google-runtime-validation.json), [Console validation](../../evidence/cloud/console-runtime-validation.json) | Historical controlled fatal/nonfatal evidence retained; no new fatal crash triggered |
| Remote Config | [Roundtrip](../../evidence/cloud/remote-config-roundtrip.json) | Fresh recovered Profile showed AI enabled/max 3 before reinstall; no new publish, fetch-latency or release claim |

Approved deployed rules SHA256
`94ef6ed2594ba4c6880c2b95fbaf75cb43fdb5bdbdeb5bf743d63389aa3d4428`
and ruleset `67a6d7ce-798f-44b4-8350-fe8bea890edc` are historical PR #11 proofs.
No deployment, catalog/Auth/index/billing/App Check change in this task. Firestore
Base64 is the owner-reported mentor-approved alternative; Storage stays deferred.

## D — ARTEMIS execution readiness

Read current [test plan](../test-plan.md), `e2e_test/run-artemis.ps1`,
`e2e_test/conftest.py`, all case modules and `e2e_test/pyproject.toml` before running.
The pinned ARTEMIS revision is `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`;
use Python 3.12 and `uv sync --project e2e_test --frozen`. Do not upgrade the lock
or change Nguyen's scenarios as a workaround.

Fresh read-only probes of local `/api/status` and `/api/devices` on port 8000 were
UNREACHABLE (see cleanup receipt). No current model/quota test or ARTEMIS scenario
was executed. Historical
`evidence/artemis/n03-2026-11-03/tc01-priority-rerun/` is BLOCKED_QUOTA (Gemini
Free Tier HTTP429), not a new PASS. Check actual host/provider availability;
do not infer the historical quota wait is still current.

Setup on a stable authorized runtime:

```powershell
$env:ARTEMIS_BASE_URL = '<actual authorized ARTEMIS host URL>'
$env:ARTEMIS_DEVICE_SERIAL = '<online authorized device serial>'
# If required, set ARTEMIS_TOKEN privately; never echo or commit it.
adb devices -l
uv sync --project e2e_test --frozen
# Start with one case; preserve all three real attempts in a NEW output folder.
$env:ARTEMIS_CASE_IDS = 'TC-01'
.\e2e_test\run-artemis.ps1 -RunsPerTest 3 -OutputDirectory '.\evidence\artemis\<fresh-run-id>'
```

ADB/uv must be on PATH. Check API health AND authorized device listing, installed
APK/source/hash, boot/system UI, account state and fixtures before model calls.
The runner fails closed on an empty case selection and writes pending results;
review actual logs/JUnit/trace/screens before accepting PASS. Flash flow deadline
is 600s (individual HTTP request 60s); Pro exploration is 1800s. Preserve timeout
and quota responses; stop a quota-blocked batch rather than burning retries.

| Cases | Preconditions / readiness |
|---|---|
| TC-01,03,04,06,08,09,12,13,16 | Candidates once host/quota/device recover: guest Home; confirmed no-match search term; actual demo detail; signed-out connect auth gate without submit; blank Register validation without account creation; all five destination headings; RC/Crash action visibility without triggering; authorized signed-in logout; Google picker cancel if provider exists. Inspect each scenario's expected state first. |
| TC-07 | Requires an authorized Google test identity and functioning picker/provider, not merely the two Email/Password identities. Do not assume ready today. |
| TC-02,05 | Current assertions require an empty active catalog; the consented live demo makes that prerequisite false. Use separately approved staging fixtures or ask Nguyen to review case intent. Do not delete/deactivate live tutors to satisfy them. |
| TC-10,14,15 | Manual push setup per execution; unique notification, correct active owner/device, actual delivery and tap destination captures. Terminated means removed process without Android force-stop; force-stop blocks FCM. Historical Bao proof does not count as three ARTEMIS executions. |
| TC-11 | Native PDF flow exists, but each cloud-save run creates an immutable report. Not in the safe runner allowlist. Separate approved minimal-write plan and fixtures required. Test-plan Storage/download-URL wording is historical; current contract is private Firestore server read/download. |
| TC-17 | Deliberate fatal process crash; historical Firebase proof already sufficient for Bao. Separate explicit test plan before ARTEMIS destructive execution. |
| TC-18,19 | Approved mutable connection/chat fixtures and correct parent/consultant roles; no business writes performed here. |
| TC-20…23 | Trusted consultant/backend proposal + correct current pointer, unexpired server data, distinct revision fixture per run. No client-created proposal shortcut. |
| TC-24 | Reachable authorized invoice/class/payment-gate fixture; clients cannot manufacture paid invoices/schedules. |
| TC-25 | Separate real 15–30 minute Pro exploration with timestamps, trace, screenshots and findings. Not replaced by Flash cases. |
| TC-26 | Dedicated disposable signup/applicant identities and approved staging project; no role/account creation on this live project for this handoff. |
| TC-27 | Supplemental parser/status coverage; does not replace official required cases. |

The safe runner currently allows 01–09,12,13,16,17,27, subject to each prerequisite;
allowlisting alone is not authorization to crash/write or proof fixtures exist.
Do not relax it to run every case. Required submission remains **≥10 official
eligible cases × ≥3 actual executions**, plus a distinct 15–30 minute exploration.
27 collected functions or local harness PASS do not satisfy that matrix. Select
the tenth eligible case only after Google/push/staging prerequisites are verified.

## E — Limitations and actionable follow-up

1. **Native deadline NOT VERIFIED.** Default outer timeout is 30s. Its
   `TimeoutException` cancels the operation and maps to **Chưa xác nhận được từ
   server. Hãy kiểm tra mạng và thử lại.** SDK `unavailable` instead maps to
   **Không kết nối được dịch vụ. Hãy kiểm tra mạng rồi thử lại.** PR #11 observed
   the latter. Current unstable AVD did not support a reliable existing-report
   selection/download baseline, so no further network stress was applied.
   On a stable runtime, authenticate A, server-download the existing A report,
   induce controlled pending transport, observe >30s actual branch/error UI,
   restore network and retry the SAME report; hash the completed file. Record
   source, instrumentation/UI distinction and late-callback settlement. Stop if
   SDK returns unavailable instead; never rename it a timeout PASS.
2. Cancellation cannot abort the underlying Firestore Future. Owner/operation
   guards reject stale results after awaits; raw auth subscription clears private
   UI before telemetry. Unit tests cover deadline/retry/ownership. Eventual native
   delayed-callback behavior is not exhaustively captured; do not overstate it.
3. PR #11 JS `disableNetwork` did not prevent a transaction RPC and created one
   extra valid A-private report. It remains disclosed and retained, not an offline
   PASS. Native radio-off recovery is separately proven in that package.
4. **Export Console receipt NOT VERIFIED.** Fresh native event was logged at
   approximately 13:50:29 device/local time (06:50:29Z). Production controller was
   invoked via attached debugger using the actual loaded demo and app container,
   because launcher ANR blocked UI. It generated a real local PDF, no direct
   synthetic Analytics call and no upload. Current Analytics page/iframe became
   blank; no permission-denied message was observed. This does not prove either a
   permissions regression or current event delivery. On a working Console, enable
   debug for the authorized package, generate LOCAL ONLY via real UI, open
   `export_report`, expand `subject_count`/`file_size_kb`, capture actual values,
   time/project context, redact identity, then restore debug properties.
5. System UI/Launcher ANRs and a failed fresh launch prevent a current repeatable
   startup/demo PASS. Final BeeWise main-thread `/proc` sample was sleeping and
   its VM/controller responded; this is not an ANR-time stack and cannot exonerate
   every startup. Historical controlled BeeWise/minimal-Flutter comparisons are
   in `evidence/android/pr3-controlled/manifest.json`. No new reproducible
   BeeWise-specific root cause justified a code change. No physical/release,
   accessibility sweep, trusted payment/backend fixture or full ARTEMIS proof.

## F — Responsibilities

**Bao:** maintain Firebase/runtime support, consented demo policy, PDF/cloud
acceptance evidence and these two open native/Console follow-ups; help Nguyen
diagnose approved fixture/backend problems. No need for another preparation PR
or redeployment. Fresh finalization changed docs/evidence only.

**Nguyen:** execute actual ARTEMIS matrix/exploration on a stable host/device;
capture assigned UI/responsive/accessibility evidence; assemble report, slides,
video and validated sharing links. N-01/N-02 still need workflow screens at both
widths and accessibility/design comparison. N-03 matrix/exploration remains open.
N-04 is already COMPLETE per owner's human reviewer approval and merged PR #9
remediation; retain that approval, do not reopen based on an older review header.
Any review of this final PR is a human handoff, not automated polling. N-05 has a
9-page report PDF and 13-slide PPTX but still needs the required slides PDF export,
visual review and refreshed cloud claims/links. N-06 needs actual 5–10 minute video
and final accessible links. Bao's local tests do not complete those assignments.

## G — Before recording

- [ ] Freeze source SHA and APK hash; final exact-HEAD Actions pass; install with
  matching signer and preserve existing data. Confirm authorized device and account.
- [ ] System UI stable, working network, fresh Home/detail screenshot; disclose
  failures and stop if ANRs recur. Never hide dialogs or disable detection.
- [ ] Demo tutor visible with truthful demo/unverified disclosure; RC flags recorded.
- [ ] Generate local PDF, preview it, capture `export_report` parameters if Console
  is working. No save merely to emit this event.
- [ ] If the video requires a new save, explicitly scope one authorized private
  report; capture server-confirmed state → download → actual preview/hash.
  Otherwise use clearly dated PR #11 evidence. No duplicate reports for retakes.
- [ ] Redact email/raw UID/owner paths/notifications/token data from all exports;
  never include credentials or Base64. Sign out and show private state cleared.
- [ ] Record actual ARTEMIS ≥10×3 + exploration separately, preserving failures.
  Verify trusted workflow fixtures before filming those segments.
- [ ] Keep timeout/Console/startup limitations visible in report/slides/video.
  Export/review slides PDF and verify final sharing links before submission.

Evidence index and TC-PDF matrix:
[finalization package](../../evidence/cloud/firestore-reports/finalization-20261103/README.md).
