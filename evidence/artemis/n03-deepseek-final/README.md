# N-03 Regression Status & Rubric Audit Checkpoint

**Current PR #18 Reviewed HEAD**: `2b3cd31d6d7d0c9a7898232a3540a03e6fc8942d`
**Checkpoint Timestamp**: 2026-11-06 03:20 UTC+7
**Authoritative Reference**: `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf` (Page 23: "ARTEMIS — Chuẩn bị kiểm thử tự động đầu cuối")

---

## Current Executive Status

| Dimension | Measured Outcome | Defensible Status against Rubric v5 |
| :--- | :--- | :--- |
| **Accepted Runs** | **30 accepted PASS** | 10 distinct scenarios × 3 independent accepted executions |
| **Retained Failures** | **14 retained FAIL** | Fully preserved for audit integrity; never deleted or relabeled |
| **Admitted Sessions** | **44 total sessions** | Exactly 30 PASS + 14 FAIL across all batches |
| **TC-27 Eligibility** | **STUDENT-AUTHORED OFFICIAL SCENARIO** | Permitted by Rubric Option A (p. 23 does not mandate fixed IDs; covers error branch; promoted by owner approval) |
| **Android-Native Interaction** | **NOT VERIFIED in 30 accepted runs** | All 30 PASS runs exercised Flutter app UI; TC-16 was observed native attempt but rejected/FAIL; requires targeted follow-up |
| **Regression Verdict** | **30/30 EXECUTIONS COMPLETE, NATIVE INTERACTION PENDING** | Core 30 test runs complete; Android-native OS interaction criterion pending targeted single-case execution |
| **Exploratory Testing** | **NOT RUN** | 15–30 min session (TC-25 Pro) deferred to separate execution per plan |
| **Overall N-03 Status** | **INCOMPLETE** | Remains incomplete until Android-native interaction is verified and exploratory session is executed |

---

## P1 Review Findings Resolution

### 1. TC-27 Eligibility Analysis
* **Authoritative Rubric Verification**: Direct review of `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf` (Page 23) confirms:
  > *"Viết ít nhất 10 ca kiểm thử: điều kiện đầu, bước thực hiện và kết quả mong đợi. Bao phủ các luồng Lab 2, một nhánh lỗi và một tương tác Android gốc."*
* **Option A vs. Option B**: The instructor rubric does **NOT** mandate fixed predesignated scenario IDs (Option A: student-authored scenarios meeting coverage criteria; not Option B: fixed predesignated IDs).
* **Team-Authored Context**: The team authored 27 candidate scenarios (`TC-01` through `TC-27`). In initial drafts of `docs/test-plan.md`, TC-27 was described as "supplemental" under the provisional assumption that the instructor might require specific predesignated IDs.
* **Promotion via Owner Approval**: When `TC-16` was blocked due to environment prerequisites (AVD lacking Google accounts), the owner explicitly approved substituting `TC-16` with `TC-27` on 2026-11-06.
* **Rubric Compliance**: TC-27 (`test_tc27_login_validation_is_local_and_does_not_authenticate`) satisfies the rubric requirement for **"một nhánh lỗi"** (error branch) by proving that submitting empty login credentials triggers local form validators ("Vui lòng nhập email", "Vui lòng nhập mật khẩu") and does not falsely authenticate or issue network requests.
* **Evidence**: 3 independent accepted runs (`completion-TC27-01`, `completion-TC27-02`, `completion-TC27-03`) with full JUnit PASS, traces (`892120dd`, `0bf400cb`, `a86c3f3c`), and independent reviews.
* **Scope Boundary**: TC-27 is approved by the project owner as a legitimate student-authored scenario; no claim is made that the instructor individually reviewed or approved TC-27 in advance.

### 2. Android-Native Interaction Audit
* **Audit of 30 Accepted Runs**: A comprehensive audit of action logs (`actions.json`), step screenshots, and independent reviews across all 30 accepted PASS runs shows that all 30 executions interacted exclusively within the Flutter view hierarchy (including standard virtual keyboard text input and hardware `BACK` key dispatching to dismiss the keyboard). None observed or interacted with an OS-owned native UI (such as a system permission dialog, notification shade, or native account picker).
* **Evaluation of TC-16 Historical Attempt**: Run `completion-TC16-01` (trace `4065fa09-e7da-4f65-a13b-b4f5bd9053b9`) triggered Google Play Services native `SignInHubActivity`. However, because the AVD had no Google accounts registered, Android displayed Google full-screen "Sign in to add an account" webflow rather than the native Account Chooser dialog. Although ARTEMIS performed a native cancellation via Android `BACK`, the run was rejected during independent review because the expected account chooser dialog was not observed. Per rubric guidelines, this run is preserved as an observed native attempt, but **cannot be counted as a PASS**.
* **Current Status**: The Android-native interaction requirement remains **NOT VERIFIED**.
* **Targeted Follow-up Proposal**:
  To satisfy "một tương tác Android gốc" without rerunning the 30 passing sessions, a single targeted 3-run execution should be performed once authorized:
  - **Option 1 (TC-16)**: Add a disposable test Google account to the AVD, launch `TC-16` to trigger the genuine native Google Account Chooser dialog, and cancel it.
  - **Option 2 (Permission prompt)**: Reset notification permission on the AVD (`adb shell pm revoke com.beewise.beewise android.permission.POST_NOTIFICATIONS`) and run a targeted case where ARTEMIS observes and grants/denies the Android OS system permission prompt (`com.google.android.permissioncontroller`).
  *Zero billable inference calls will be initiated until the owner explicitly approves the provider cost and execution plan for this targeted follow-up.*

---

## 30 Accepted Regression Executions Summary

| Case ID | Feature Scope | Rubric Dimension | Accepted Runs | Trace IDs | Retained Failures |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Home & Tutor Discovery | Lab 2 Primary Flow | 3 / 3 | `301439ee`, `e082d56b`, `3957aa8f` | 0 |
| **TC-03** | Search No-Match / Empty State | Lab 2 Flow & Empty State | 3 / 3 | `2d6ba0da`, `0feb10d3`, `240cabb2` | 4 (`tc03-attempt-01`, `02`, `04`, `06`) |
| **TC-04** | Tutor Detail & Pricing | Lab 2 Detail View | 3 / 3 | `e17441ff`, `b40b934c`, `9953bf04` | 1 (`completion-TC04-01`) |
| **TC-05** | AI Matching Zero-Catalog Fallback | Lab 2 AI / Fallback Flow | 3 / 3 | `22016c5b`, `c9eecfd2`, `552fa8c2` | 1 (`tc05-attempt-02`) |
| **TC-06** | Connection Gate / Auth Nav | Lab 2 Protected Navigation | 3 / 3 | `1a7b0559`, `65bf021d`, `3a17e0b5` | 0 |
| **TC-08** | Registration Field Validation | Input Validation & Error | 3 / 3 | `fb03cf27`, `8c607ec0`, `f129a009` | 0 |
| **TC-09** | 5 Bottom Navigation Destinations | Lab 2 Main Navigation | 3 / 3 | `c06f9d97`, `bb5e6013`, `f6d9a7e8` | 1 (`tc09-attempt-01`) |
| **TC-20** | Parent Trial Proposal Acceptance | Lab 2 Workflow (Trial) | 3 / 3 | `fc2d2aa6`, `989cf8b1`, `03565f1e` | 1 (`completion-TC20-01`) |
| **TC-22** | Parent Class Revision Adjustment | Lab 2 Workflow (Revision) | 3 / 3 | `42973812`, `ec456ba3`, `6df46bdc` | 5 (`completion-TC22-01..05`) |
| **TC-27** | Blank Login Validation | Error Branch ("nhánh lỗi") | 3 / 3 | `892120dd`, `0bf400cb`, `a86c3f3c` | 0 |
| **TC-16** | Google Sign-In Native Chooser | Android-Native / Error | 0 / 3 (Substituted) | `4065fa09` (attempt) | 1 (`completion-TC16-01` retained) |

---

## Cumulative Provider Spend & Resource Reconciliation
* **DeepSeek HTTP Attempts**: 272 / 275 approved ceiling.
* **SDK Reported Tokens**: 2,542,792 prompt + 33,161 completion = **2,575,953 total tokens**.
* **Accounted Conservative Cost**: **$0.8026308 USD** (within the approved $0.82 ceiling).
* **Nexora Account Reserve**: **>$0.50 preserved** at all times.
* **Inference Server**: Stopped (port 8001 closed, deny-by-default enforced).

---

## Historical Checkpoints (Preserved for Audit Trail)

### Historical Checkpoint: Offline Input-Envelope Correction

The failed TC-03 request was at Flash operator turn 7 after six `click` /
`input_text` actions. Flash attaches at most one observation image per turn;
those actions return text-only outcomes and no helper tool was called. There
could be at most seven inline images, so the failed bound was **non-image
bytes > 32,768**, not the eight-image cap. The exact failed byte count was not
retained. The original failure receipt and historical logs remain unchanged.

The new local patch meters the actual HTTP payload under the unchanged guard
definition (UTF-8 JSON with inline image URLs replaced by a fixed placeholder).
It logs only counts, limits, configured model role, Flash turn, historical
message count, growth and rejection codes. The gateway surfaces typed local
rejection separately from provider connection errors. No retry/fallback added.

On a synthetic seven/eight-turn replay using the actual Flash transcript,
serializer and HTTP guard, each oversize payload measured **33,668 bytes**
and was compacted to **32,686 bytes**, with the same five inline images.
Compaction removes only as much old action narration as needed, keeping every
tool call/argument, result, observation, screenshot and strict output contract.
If it cannot fit, the original request fails closed. Raw evidence is not edited.
See `envelope-offline-receipt.json` and its JUnit/patch references. **233 offline
tests PASS**; no provider or Android session was used for this validation.

The same ledger remains at 102 calls, 11 PASS / 6 FAIL. Live launch is explicitly
held. `safe-completion-amendment.md` proposes one TC-03 admission now for owner
review; the rest is conditional planning. The prior conservative cost per
admission projects beyond the unchanged $0.50 cap, and TC-16's actual account
chooser is still missing. No new authorization, execution, or completion PR.

## Current verdict — after the owner-approved TC-03 amendment

**N03_REGRESSION_INCOMPLETE — EXACT_BLOCKERS.** Latest `batch-summary.json`
and `run-manifest.json` supersede the historical totals below. **17 admitted,
11 accepted PASS, 6 FAIL, 0 BLOCKED or pending review.** TC-01/05/09 remain
complete at three each; TC-03 is **2 PASS / 4 FAIL**. TC-04/06/08/16/20/22 remain
NOT RUN. Completion is 11/30; admitted-session pass rate is 11/17 (64.71%).

The owner approved the exact amendment hash in `tc03-retry-approval.json`.
One authorized read-only balance check returned HTTP 200 and verified coverage
of the remaining conservative allowance; no actual balance or credential is
exported. Both additional sessions passed online/boot, real System UI round-trip,
focused rendered app, fixture/endpoints and idle-host preflight.

- `runs/tc03-attempt-05`: actual Android input, submit, empty state and recovery
  independently verified; original strict JSON and JUnit PASS. No new ANR.
- `runs/tc03-attempt-06`: Android entered text, then agent moved the cursor and
  re-entered it instead of proving submit/results. Six HTTP 200 responses.
  The next inference was rejected locally, before reservation and network:
  `Smoke input bound exceeded; stop instead of truncating evidence`. OpenAI
  SDK wrapped that local `ValueError` as `APIConnectionError`. No final JSON,
  strict JUnit FAIL, no new ANR. The guard error does not report which of its
  32 KiB non-image / eight-image thresholds was exceeded. No live service
  outage or exhausted monetary ledger is inferred. Offline SDK test reproduces
  both guarded rejection paths with network transport stubbed and uncalled.

The dedicated inference host was stopped. TC-03 used both extra admissions;
the first additional FAIL and **six cumulative failures** close the existing
policy. Raw remaining ceilings are **138 HTTP attempts, $0.1922333 and 19
sessions** until the unchanged expiry, but **zero admissions are authorized**
under the exhausted failure/retry policy. The 19 missing PASS runs would need
all 19 raw session slots and are not guaranteed to fit the remaining cost. No
automatic policy amendment or further budget request is made.

Latest ledger: **102 HTTP attempts, all 200**, 971,177 prompt + 13,678 completion
= **984,855 SDK tokens**, conservative peak **$0.3077667**. Reconstructed cache /
off-peak cost is in `provider-cost-after-amendment.json`. The owner's previous
910,823-token / ~$0.05 report applies to the earlier reconciliation snapshot,
not a new dashboard observation. Neither is a project-isolated billing receipt.

Next technical step before any new live authorization: instrument only safe
request-envelope counts, reproduce the oversized path offline, and validate
removal of redundant historical prompt context while retaining the current
screen, executable actions, raw evidence and guard limits. Do not retry a paid
case merely to measure payload size. TC-16 also needs an actual account chooser:
direct native observation reached Google's add-account screen and cancellation
message, without adding an account, and is not an ARTEMIS PASS. Local TC-20/22
fixtures and fake backend were reachable; their Android workflows are still
NOT RUN. Separate 15–30 minute Pro exploration remains outside authorization.
No completion PR, push, merge, production changes, extra Gemini or real payment.

## Original approved scope and evidence history

Owner approved only the exact revised proposal SHA256
`769b22c4dac2a6736953d2ba4daaa7dd433cbc61b15288680c939b30b115a141`:
USD **$0.50** estimated conservative cost, 240 inference HTTP attempts maximum,
30 accepted runs, 36 admitted sessions / 6 failed or blocked sessions maximum.
The earlier $5/500 proposal remains **REJECTED**. Nexora has priority; no top-up,
additional Gemini, exploration, production Firebase writes or real payments.

Selected official cases: **TC-01, TC-03, TC-04, TC-05, TC-06, TC-08, TC-09,
TC-16, TC-20, TC-22**. Each needs three fresh independently reviewed Android
traces plus strict pytest assertions and JUnit PASS. A model's `completed`
status is insufficient. Current authoritative outcomes are the individual
`runs/*/independent-review.json` and run receipts; no 30-run completion is claimed here.

Source baseline: `a72059ca5e07a4c1193960965dc07453efea161d`.
API35 AVD `BeeWise_Bao_Acceptance_API35`, serial `emulator-5562`, 360dp;
existing userdata retained. TC-09 used the default production-entrypoint APK
SHA256 `59a8a74ded5ba681f8ad2eed7c4d2d7874f1c0ff545e65556124c09d7f1c2eb7`.
Other cases use the unchanged application with isolated Firebase Emulator
and local backend defines: see `emulator-apk.json`. No application source
or production cloud configuration is changed for this mission.

ARTEMIS base `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`; compatibility patch
SHA256 `51f768bf8703f327301869381d54425fed91994c1ffa26102cda240a5b74e976`.
Provider: official DeepSeek `deepseek-flash`, non-thinking/non-streaming,
2,048 output tokens maximum. Persistent pre-send SQLite reservations cover
all roles and survive restarts. Errors remain reserved; response usage settles
only unused reservation. Estimates use uncached peak input/output prices and
are not provider billing receipts. Private ledger, key and raw traces stay
outside Git. Exported actions omit input text and model reasoning.

## Failures retained

- Historical TC-09 trace `69488a18-9d58-4249-8625-0e1682127982`: wrong
  `observations` schema. Flash had not received OutputConfig. Historical patch,
  ANR receipts and evidence remain in the adjacent compatibility packet.
- New TC-09 attempt 01: correct model `destinations` were discarded by the
  observation normalizer. Fixed by retaining validated original row fields;
  strict original assertions remain. Three subsequent native runs accepted.
- TC-05 attempt 02: correct visible empty state but final report was prose,
  causing strict JSON/JUnit failure. The shared goal now explicitly names
  `report_task_status.explanation` as the JSON output location. No prose-to-PASS
  conversion, extra formatting model call or retroactive result change.
- TC-03 attempts 01/02: actual input did not reach the field reliably through
  `KEYCODE_PASTE`; the clipboard workaround also produced a duplicate prefix.
  Both remain FAIL. The Android driver now reuses its existing native ASCII
  typing helper before attempting clipboard injection. 182 offline tests pass;
  direct native typing proof is `ascii-input-native.png` (not an ARTEMIS run).
  Subsequent actual ARTEMIS executions are separately evidenced below.

TC-05 deliberately exercises the zero-active-candidate branch before seeding
local fixtures. MatchingService returns before Firebase AI provider invocation
when the repository returns no candidates. This is UI recovery coverage,
**not new Gemini provider acceptance**.

TC-20/22 prerequisites must use parent Security Rules and existing authenticated
trusted backend contracts against local emulators, with a fake payOS adapter.
Fixture preparation is not an Android PASS. No paid invoice is fabricated.

## Final controlled stop, 2026-11-05

**N03_REGRESSION_INCOMPLETE.** 15 admitted real ARTEMIS sessions: **10 accepted,
5 failed, 0 pending review**. Selected cases: 10; executed distinct cases: 4;
fully verified three-run cases: 3. TC-01/05/09 have 3 PASS each; TC-03 has 1 PASS
and 3 FAIL. The other six selected cases are NOT RUN. Pass rate among admitted
sessions: 10/15 = 66.67%; target completion: 10/30 = 33.33%.

Ledger: **90 inference HTTP attempts**, 853,601 prompt + 12,053 completion =
**865,654 reported tokens**. Conservative peak estimate **$0.2705439** of $0.50;
**$0.2294561 unspent**. This is not a claim of provider-billed cost. Historical
five-call compatibility run is separate and remains unchanged.

TC-03 attempt 04 was interrupted by genuine BeeWise ANR dialogs. Android reports
`Input dispatching timed out (Application does not have a focused window)`;
first draw was +15.920s. The captured managed main stack runs through
`ProcessTextPlugin.queryTextActions` → package label/resource loading →
`ApkAssets.nativeLoad`; it does not establish a Dart business-logic defect or
prove host contention. See [native diagnosis](native-anr.md). Inference host
was stopped, dialog/evidence preserved, no userdata cleared, no detection disabled.
No further paid execution is admitted: TC-03 exhausted its initial failed attempt
plus two corrective retries. Remaining money is not authority to exceed that
retry gate. The batch runner now enforces it. No replacement case is silently
substituted to hide TC-03 failures.

The new pre-send native gate requires boot complete, actual app window focus,
rendered accessibility content and absence of ANR. Its read-only native probe
rejects the current ANR state before inference. Synthetic rejection tests verify
the gate, not an Android case PASS. No arbitrary app delay or dialog suppression.

Local trial and revision prerequisites were created through parent Rules and
authenticated existing backend endpoints. They have zero invoices. Neither
workflow Android case nor native Google picker is accepted or claimed tested.

All independent offline checks are retained in `quality-gates.json` and
`offline-final.junit.xml`. Clean baseline patch application plus 182 offline
tests PASS. Source app remains unchanged. No completion PR, push, merge or
deployment was performed while required runtime evidence is incomplete.

To resume: independently establish a stable native environment and focused first
draw without provider calls, review the ProcessText/resource-loading ANR against
host/control evidence, then obtain an explicit retry-policy amendment if retaining
TC-03. Reuse the same ledger; do not extend its expiry/reset counts. A future
approval must account for the remaining 20 accepted runs and actual variability;
there is no guarantee the unspent balance covers them. This report does not
request more spending.

Separate 15–30 minute Pro exploration remains NOT RUN and outside this authority.
Its new execution plan is deferred until regression completion, as instructed.

## Native stabilization and cost reconciliation — before the amendment

The historical controlled-stop section above remains intact. The same API35 AVD
was subsequently shut down normally and relaunched without snapshots, preserving
userdata and the installed default-entrypoint local-emulator APK. Three settled
cold starts reached actual focused Home without new ANR: Android draw
6.097 / 7.995 / 5.615s; process-to-Flutter-raster 5.868 / 7.326 / 5.329s.
A same-process warm start returned Home with 0.453s am-start wall time.
Settings and native notification shade navigation were responsive. A separate
Google Messages ANR occurred during boot, before the controlled launch markers.
All failures remain preserved. This demonstrates a scoped restart/settling
workaround, **not a proven host-only root cause or permanent application fix**.
See `native-stabilization-20261105/summary.json` and native screenshots.

The native gate now also requires online device, a real System UI round trip,
local endpoint health, authorized catalogue/workflow prerequisites and idle
ARTEMIS. Seven offline fault-injection tests pass. The paid host remains stopped;
full admission is intentionally blocked by the unchanged TC-03 retry policy.
The missing aggregate `run-manifest.json` was created from the existing fifteen
receipts/reviews, without adding accepted runs or changing historical outcomes.

Structured per-call `llm_usage` receipts include **559,232 cached input tokens**
out of 853,601 input; 294,369 cache misses and 12,053 output tokens. All ninety
timestamps are off-peak. At the official published flash rates, reconstructed
cost is **$0.053064846**, consistent with the owner's approximate $0.05 report,
but not an independently attributed billing receipt. 865,654 current tokens +
45,169 historical compatibility tokens = 910,823, matching the owner's reported
total arithmetically; shared Nexora/account scope remains unverified.
See `provider-cost-reconciliation.json` and
[official DeepSeek pricing](https://api-docs.deepseek.com/quick_start/pricing/).
The $0.2705439 conservative ledger estimate and all authorization ceilings are
**unchanged**; no cache/off-peak refund is granted to the test budget.

`tc03-retry-amendment.md` proposes exactly two further TC-03 admissions, pending
owner approval. No additional provider calls occurred during stabilization.
20 accepted executions still remain; past average cost projects more than the
remaining conservative allowance. Completion is not promised under that cap.
No PR is opened while regression acceptance remains incomplete.
