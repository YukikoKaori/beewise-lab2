# N-03 regression — INCOMPLETE, controlled stop

## Offline input-envelope correction — subsequent update

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
