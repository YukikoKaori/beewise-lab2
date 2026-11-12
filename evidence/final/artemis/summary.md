# Final ARTEMIS Execution Summary (Gate 3 Option B Bounded Batch)

- **Verdict:** **`BOUNDED_GATE_3_B_COMPLETE` — `4/9` (`44.44%`) independently accepted PASSes** across `9` bounded admissions (`4 ACCEPTED`, `4 FAILED`, `1 BLOCKED` Android ANR; `retry_admissions = 0`).
- **Owner Authorization:** [`owner-approval.json`](owner-approval.json) (`owner_msg_gate3_b_approved_20261112`) approving [`budget-proposal.json`](budget-proposal.json) (`9` max admissions, `3` flows × `3` repetitions, `60` HTTP request ceiling, `$0.2000` USD ceiling, `>= $0.50` USD Nexora reserve).
- **Target APK:** `e885a076b3a1f39e40f7cacc603ea0aec2d30e7e44028511e6f3bc06be3986b9` (`BEEWISE_FINAL_FIRESTORE=true`) on `BeeWise_Final_API35` (`emulator-5564`).
- **Model / Runner:** DeepSeek Flash compatibility host (`tools/artemis-deepseek/host.py`, `tools/artemis-deepseek/final_once.py`).
- **Actual Cumulative Usage (`9/9` Admissions):**
  - **HTTP inference requests:** `60 / 60` (`100%` of ceiling reached at `FINAL-F02b` R3 Turn 8 before request #61, fail-closed preflight stop)
  - **Token usage:** `567,430` prompt tokens, `6,093` completion tokens
  - **Accounted DeepSeek spend:** `$0.1775406` (`177,540,600` nanodollars <= `$0.2000` USD ceiling)
  - **Post-run Nexora reserve check:** **`PASS`** (`>= $0.50` USD preserved)

## Per-Case & Per-Run Results

| Case | Repetitions (Independent Review Verdict) | Pass Rate | Highlights & Root Causes | Evidence |
|---|---|---:|---|---|
| **`TC-27`** | **PASS** / **PASS** / **PASS** (`ACCEPTED` × 3) | **100% (`3/3`)** | All 3 clean guest runs opened `Tài khoản -> Đăng nhập`, submitted empty form, and verified local validation messages (`Nhập email hợp lệ.`, `Mật khẩu cần ít nhất 8 ký tự.`), `signed_in=false`. Traces: `c1cb72b7`, `ccc50349`, `587db39f`. | [`TC-27/run-1`](TC-27/run-1/independent-review.json), [`TC-27/run-2`](TC-27/run-2/independent-review.json), [`TC-27/run-3`](TC-27/run-3/independent-review.json) |
| **`FINAL-F01`** | **FAIL** / **BLOCKED** / **FAIL** (`FAILED`, `BLOCKED`, `FAILED`) | **0% (`0/3`)** | **R1 (`9337276b`)**: Filtered `Toán` -> `2` tutors, exhausted `max_turns=8` before opening `/tutors/:id`; `pytest` exited `0` under old conditional guard (`test_final_flows.py:41`), **rejected** on visual review. **R2 (`f61abd90`)**: Typed `Thu Trang` + `Toán` -> `1 gia sư phù hợp`, then Turn 7 hit genuine Android ANR (`ErrorId: bd55a9a5-5f32-458c-8fd6-d865cec57632`, `FlutterJNI.nativeSurfaceCreated` under `some avg10=54.65` CPU load during concurrent host `flutter test`). **R3 (`e1df3ef1`)** with idle host: zero ANR, rendered `1 gia sư phù hợp` (`ThS. Hoàng Thu Trang`), exhausted `max_turns=8` before tapping `Xem hồ sơ`; **rejected** on visual review. (`e2e_test/test_final_flows.py:41` subsequently tightened as harness defect `F-FINAL-06`). | [`FINAL-F01/run-1`](FINAL-F01/run-1/independent-review.json), [`FINAL-F01/run-2`](FINAL-F01/run-2/README.md), [`FINAL-F01/run-3`](FINAL-F01/run-3/independent-review.json) |
| **`FINAL-F02b`** | **PASS** / **FAIL** / **FAIL** (`ACCEPTED`, `FAILED`, `FAILED`) | **33.33% (`1/3`)** | **R1 (`96f137d2`)**: Cleanly entered offline prompt on `/matching`, verified `'Chưa lấy được gợi ý AI. Thử lại hoặc tự điền bộ lọc.'`, opened `'Yêu cầu học tập'`, dismissed keyboard, scrolled to verify `'Mở trang tìm kiếm gia sư'`. **R2 (`d83d1b4d`)**: Triggered AI offline error & `'Yêu cầu học tập'`, but Turn 7 swiped over open Gboard keyboard (typing `'my'`); Flash inferred `'Mở trang tìm kiếm gia sư'` from pre-tap `step-01`, **rejected** on visual review. **R3 (`c8aa757f`)**: Spent Turns 1–7 fixing Gboard clipboard paste/artifact (`35/500`), then Turn 8 hit cumulative `60/60` HTTP ceiling before tapping `'Phân tích nhu cầu bằng AI'` (`pytest_exit=1`). | [`FINAL-F02b/run-1`](FINAL-F02b/run-1/independent-review.json), [`FINAL-F02b/run-2`](FINAL-F02b/run-2/independent-review.json), [`FINAL-F02b/run-3`](FINAL-F02b/run-3/independent-review.json) |

## Unexecuted Scope & Historical Boundary

- All other Final and reusable Lab 3 ARTEMIS scenarios (`FINAL-F02a`, `FINAL-F04`, `FINAL-F07`, `FINAL-F08`, `FINAL-PDF`, `TC-01..TC-26`, `TC-NATIVE-01`) remain **`NOT_RUN`** for Final APK `e885a076...` (excluded from the `4/9` attempted denominator; deferred under the `60`-request budget boundary and verified separately through live production/emulator evidence and 260+ local unit/widget/rules checks).
- Historical Lab 3 N-03 ARTEMIS runs (`30/44` raw = `68.18%`, `3/3` Native, `1` qualifying `TC-25`) tested pre-Final Lab 3 APK builds and are kept strictly separate in [docs/artemis-final-matrix.md](../../../docs/artemis-final-matrix.md).
