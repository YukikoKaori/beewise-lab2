# BeeWise N-03 code review remediation

Date: 2026-11-03

Branch: `codex/beewise-lab3-n03-n04-clean`

Base/HEAD before remediation: `5df96fd3df995ea12747dcd218c418327d05db4c`

Commit: **not committed**

ARTEMIS/Android E2E: one later real TC-01 attempt; **BLOCKED_QUOTA**, see follow-up

## Review provenance and status

The supplied `BeeWise_N03_Code_Review.md` lists six proposed findings and
identifies itself as “AI-assisted technical analysis; requires human reviewer
sign-off for N-04.” Each finding was checked against the current working-tree
source. All six are **Accepted** as valid defects or test-coverage gaps and have
been addressed with offline regression checks. A second AI-assisted review on
2026-11-03 confirmed F-01 through F-05 as fixed, with an F-02 provenance caveat,
and identified residual F-06 plus three new findings N-01..N-03. These were
validated against source and addressed in this working tree as detailed below.
The second review is not a human sign-off and no GitHub review was performed.

## Findings and dispositions

| Finding | Disposition | Evidence and remediation |
|---|---|---|
| F-01 — Empty case selection ran the broad Flash suite | **Accepted** | With `ARTEMIS_CASE_IDS` empty, the runner skipped `-k` and selected every non-manual case, including IDs outside its allowlist. `e2e_test/run-artemis.ps1` now fails before creating evidence or invoking `uv` unless at least one approved case is explicitly selected. `scripts/check_artemis_runner.py` verifies the empty selection is rejected and a synthetic `uv` executable is never invoked. |
| F-02 — TC-01 could report no fabrication despite a contradictory claim | **Accepted** | The parser ignored the canonical `profiles_fabricated: true` field and treated a generic Firestore confirmation plus zero cards as proof of no fabrication. `e2e_test/conftest.py` now requires an explicit false/no-fabrication observation, rejects positive or contradictory fabrication claims, and does not accept generic Firestore availability as provenance. Parser checks cover true, missing, conflicting, and valid explicit-negative observations. |
| F-03 — Combined overflow/crash signal invented a specific diagnosis | **Accepted** | A row with `overflow_or_crash: true` previously set both individual flags. The parser now requires separate `overflow_seen` and `crash_dialog_seen` booleans for positive findings; a legacy combined `false` remains interpretable as neither was observed, while combined `true` is rejected as ambiguous. Regression checks prove overflow-only remains crash-false and ambiguous input fails. |
| F-04 — TC-09 accepted duplicate, extra, missing, or reordered destinations | **Accepted** | The live test used a superset comparison, and normalization did not enforce order/cardinality. The test and parser now require exactly `Trang chủ`, `Tìm gia sư`, `Ghép AI`, `Tin nhắn`, `Tài khoản` in that order, with each title observed. Checks reject reversed, duplicated, extra, incomplete, or title-invisible reports. |
| F-05 — Boolean values passed integer validations | **Accepted** | Python treats `bool` as a subclass of `int`; count parsing and generic `require(..., int)` therefore accepted `True`/`False`. Integer observations now require `type(value) is int`; TC-12's `ai_result_limit` uses the same exact type check. Regression checks reject both booleans, floats, strings, and missing values. |
| F-06 — Quota detection searched arbitrary trace narrative | **Accepted** | Serializing the entire trace caused prompts and historical text to trigger the quota stop. `_trace_has_rate_limit` now inspects structured error/status fields and recognized provider error records only, including typed HTTP 429 and `RESOURCE_EXHAUSTED` evidence. Checks cover real structured failures and false positives in prompts, narratives, old-log text, and explicit negative error messages. |

## Independent re-review findings (2026-11-03)

| Finding | Disposition | Evidence and remediation |
|---|---|---|
| N-01 — Valid structured 429 shapes were missed | **Accepted** | `_trace_has_rate_limit` now recognizes numeric and string `429` in structured status/code fields (including nested error/exception objects) and `RESOURCE_EXHAUSTED`, without scanning arbitrary prompts or narratives. Regression checks cover nested numeric/string status, code, provider marker, exception metadata, ordinary status 500, and harmless “429” text. |
| N-02 — TC-09 accepted names without rendered title evidence | **Accepted** | `_decode_observation` now rejects bare destination-name lists and legacy prose. Each of exactly five ordered destination entries must carry `title_visible: true` and separate boolean `overflow_seen`/`crash_dialog_seen`. TC-09 instructions now request this shape. Regression checks cover no evidence, missing titles/flags, wrong count, duplicate/extra/reordered destinations. |
| N-03 — Missing ADB was not a preflight failure | **Accepted** | `run-artemis.ps1` now fails closed if ADB is missing or its daemon fails, and requires the selected serial to be in `device` state (or at least one authorized online device when no serial is specified). Synthetic PowerShell checks prove missing ADB and offline device stop before invoking `uv`. |

### Second independent review status

The review report `BeeWise_N03_N04_Independent_ReReview_2026-11-03.md`
confirmed F-01/F-03/F-04/F-05 original fixes, marked F-06 incomplete, raised
the three findings above, and noted that the F-02 negative provenance remains
self-reported by ARTEMIS. The provenance caveat is **Needs Discussion**: the
current harness can require explicit observed claims but cannot independently
prove Firestore provenance from an AI response alone. Evidence packages lack
some historical raw receipts, so historical TC-01/TC-09 totals remain
**REPORTED**, not independently verified. No previous pass totals were added.

## Files changed

- `e2e_test/conftest.py` — strict TC-01 provenance, TC-09 parsing, integer types, structured quota detection.
- `e2e_test/run-artemis.ps1` — fail-closed explicit case selection and unconditional case filter.
- `e2e_test/test_account_and_firebase.py` — exact ordered TC-09 assertion and strict TC-12 integer check.
- `scripts/check_artemis_runner.py` — default-selection/no-invocation regression.
- `scripts/check_artemis_report_parser.py` — parser, contradictory evidence, navigation, integer, and quota regression checks.
- `e2e_test/test_account_and_firebase.py` — TC-09 now asks ARTEMIS for structured per-screen title/issue observations.
- `scripts/check_artemis_runner.py` — added missing-ADB and offline/unauthorized-device process-double cases.

No app/business behavior was changed. Existing ARTEMIS assertions were tightened.

## Validation performed

- `uv run --project e2e_test --frozen python scripts/check_artemis_report_parser.py` — **PASS**.
- `uv run --project e2e_test --frozen python scripts/check_e2e_harness.py` — **PASS**, 27 official/supplemental ARTEMIS scenario functions structurally present; no device execution.
- `uv run --project e2e_test --frozen python scripts/check_artemis_runner.py --work-directory tmp/artemis-remediation-runner-checks` — **PASS** using synthetic process doubles; verifies empty-selection rejection, exit/status handling, quota stop, and disallowed business-mutation case rejection. No host, model, or Android execution.
- `uv run --project e2e_test --frozen python scripts/check_artemis_runner.py --work-directory tmp/runner-recheck-10` — **PASS** using Windows PowerShell and synthetic process doubles; additionally verifies missing ADB and offline device are blocked before `uv`. This is not a real device/ARTEMIS run.
- `uv run --project e2e_test --frozen pytest -c e2e_test/pyproject.toml e2e_test --collect-only -q` — **PASS**, 27 scenarios collected, 0 executed.
- Python `compileall` for E2E/checker modules — **PASS**.
- `git diff --check` — no whitespace errors; Git emitted only its existing LF-to-CRLF working-copy warning for an unrelated UI manifest.

No complete live ARTEMIS suite or successful Android E2E run was completed for this remediation. One later TC-01 ARTEMIS attempt was blocked by provider quota as recorded below. There is no remediation commit SHA because changes have not been committed. Nothing was pushed, merged, or opened as a PR.

Second-review checks (same working tree):

- `uv run --project e2e_test --frozen python scripts/check_artemis_report_parser.py` — **PASS** after F-06/N-01/N-02 updates.
- `uv run --project e2e_test --frozen python scripts/check_e2e_harness.py` — **PASS**, 27 functions structurally present; no device execution.
- `uv run --project e2e_test --frozen pytest -c e2e_test/pyproject.toml e2e_test --collect-only -q` — **PASS**, 27 collected, 0 executed.
- Python `compileall` for E2E and checkers — **PASS**.
- `git diff --check` — **PASS**, no whitespace errors (existing LF-to-CRLF warning only).
- `adb devices -l` — **BLOCKED**, local ADB daemon could not start/connect; AVD `BeeWise_API_36` is configured but no online device was confirmed.
- `Test-NetConnection 127.0.0.1 -Port 8000` — **BLOCKED**, ARTEMIS host port not reachable at check time.

## N-04 disposition

The project owner confirmed in chat on 2026-11-03 that the human reviewer has
approved the review. N-04 is therefore **HUMAN REVIEW CONFIRMED BY OWNER;
COMMIT/TRACEABILITY PENDING**. No reviewer name or standalone review artifact
was supplied in this message, and no remediation commit SHA exists yet. Record
the accepted-finding fix commit(s) in the task tracker. If the rubric requires
a durable review artifact, preserve the reviewer response or link the review
comments before marking N-04 fully complete. F-02 provenance caveat remains
documented as a discussion item.

## N-03 real execution follow-up (2026-11-03)

- Started the configured `BeeWise_API_36` AVD and ADB outside the restricted
  sandbox. `emulator-5554` reached `device`, `sys.boot_completed=1`; BeeWise
  package and `MainActivity` were present.
- ARTEMIS `GET /api/status` returned `idle` before execution and
  `GET /api/devices` listed `emulator-5554` as `device`.
- Submitted real Flash TC-01 run 1/3. Trace
  `093516ef-8ae1-4b9a-b8e2-87e71ee4be17` reported Gemini Free Tier HTTP 429 /
  `RESOURCE_EXHAUSTED`, daily `generate_content_free_tier_requests` limit
  exceeded, with retry-after about 13h44m in the trace. The runner stopped the
  batch after this attempt; runs 2/3 were not sent. Status: **BLOCKED_QUOTA**,
  not PASS and not a BeeWise product failure.
- Receipts: `evidence/artemis/n03-2026-11-03/tc01-priority-rerun/`
  (`flash-suite-run-1.log`, `flash-suite-run-1.junit.xml`, `run-manifest.json`,
  and `tc01-trace-steps.json`). Log SHA-256
  `EA44ECF3EC6427701D89561E89B561A5401E8DAD3758178B10C078C6CC120450`; JUnit
  SHA-256 `9D94CB4A8C41CC35C38A3BC0F6E9FC9DC11D18CB2131DDE963C63820D6A91BA3`;
  trace SHA-256
  `4BF4B8A999E573D862D8392E2DD8955CA2D48E55EA83BF8CD926F138736EA470`.
- No other case or Pro exploration was submitted after quota exhaustion.
  N-03 remains **PARTIALLY COMPLETE / BLOCKED_QUOTA** until quota is available
  and the required ≥10 official cases ×3 plus separate 15–30 minute Pro
  exploration have real receipts.
