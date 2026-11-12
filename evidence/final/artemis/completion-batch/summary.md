# Final ARTEMIS Completion Batch Summary (Rebuilt PR #31 APK)

- **Status:** **`BOUNDED_COMPLETION_STOPPED_AT_BUDGET_RESERVE`** — **`0/3` (`0.00%`) accepted PASSes** across `3` executed admissions (`FINAL-F01` R1 `FAILED`, `FINAL-F02a` R1–R2 `FAILED`; `0` fabricated PASSes). Remaining `3` planned slots (`FINAL-F02a` R3, `FINAL-F01` R2–R3) marked **`NOT_RUN (BLOCKED_BUDGET_RESERVE)`**.
- **Baseline & Provenance Integrity:** Kept strictly separate from Gate 3 Option B (`4/9` PASS on pre-corrective APK `e885a076...`, PR #30 `2d14aa0`). This batch tested a freshly rebuilt Final debug APK (`BEEWISE_FINAL_FIRESTORE=true`, SHA-256 `4e38d1cac93ad30a30fae70a98c0759c674992747394c5061d2f11bbfbb9bf64`) built from PR #31 HEAD `1cbc950c04f6e1b42487dacd7d37016792aed3ec`.
- **Owner Authorization:** [`owner-approval.json`](owner-approval.json) (`owner_msg_final_completion_authorized_20261112`) approving [`budget-proposal.json`](budget-proposal.json) (`FINAL-F01` & `FINAL-F02a`, `flash_max_turns=12`, `6` max admissions, `54` HTTP requests, `$0.150` USD ceiling, `>= $0.50` USD Nexora reserve).
- **Cumulative Usage (`3/6` Admissions):**
  - **HTTP inference requests:** `36 / 54` (`18` unspent)
  - **Token usage:** `380,233` prompt tokens, `4,054` completion tokens
  - **Accounted DeepSeek spend:** `$0.1189347` USD (`118,934,700` / `150,000,000` nanodollars; `$0.0310653` uncommitted ceiling remaining)
  - **Fail-closed stop reason:** `deepseek_ledger.py` reserves worst-case input/output bounds (`~12.1M–15.0M` nanodollars/turn) before each call and settles after completion; the remaining `$0.0310653` ceiling permits at most `~6` pre-call reservations before Turn 7 exceeds `150,000,000` nanodollars, which cannot complete a `9–12` turn `FINAL-F02a` R3 or `FINAL-F01` R2 flow.
  - **Post-run Nexora reserve check:** [`post-run-balance-check.json`](post-run-balance-check.json) -> **`PASS`** (`usd_balance_covers_required: true` for `$0.50` USD, `http_status: 200`).

---

## 1. Rebuilt-APK `F-FINAL-05` & Live Level 2 Analytics Check (`4e38d1ca...`)

Before ARTEMIS execution, the rebuilt PR #31 Final APK (`4e38d1ca...`) was installed in-place on `BeeWise_Final_API35` (`emulator-5564`, App Check debug store `W0RFRkFVTFRd` preserved):

1. Verified manifest default `firebase_analytics_collection_enabled=false` on cold launch (`I FA : App measurement disabled via the manifest`).
2. Toggled Profile `Gửi thống kê sử dụng ẩn danh` OFF (`Đã tắt thu thập Firebase Analytics trên thiết bị này.`), ran `am force-stop com.beewise.beewise` + cold relaunch, and verified `checked=false` persisted in `FlutterSharedPreferences.preferences_pb` with native `setAnalyticsCollectionEnabled(false)`.
3. Re-enabled toggle and ran live Gemini Level 2 request `"Tìm gia sư Toán lớp 9 ở Cầu Giấy, học phí dưới 300k một giờ, học buổi tối."` on `/matching` -> parsed `Gợi ý AI · Kiểm tra và chỉnh sửa` (`Toán`, `9`, `Cầu Giấy`, `buổi tối`, `300000`) -> confirmed upload of `ai_request` and `ai_result_accepted` (`feature="tutor_need"`, `userIdPropertyCount=0`, `unexpectedParameterKeys=[]`, `unsafeParameterValuesOmitted=0`) at **`HTTP 204`** in [`rebuilt-apk-analytics-check.json`](rebuilt-apk-analytics-check.json).

Clean zero-PII screenshots:
- [`profile-analytics-optout-before-restart.png`](profile-analytics-optout-before-restart.png)
- [`profile-analytics-optout-after-restart.png`](profile-analytics-optout-after-restart.png)
- [`profile-analytics-optin.png`](profile-analytics-optin.png)

---

## 2. Per-Case & Per-Run ARTEMIS Results (`flash_max_turns=12`)

| Case | Run | Trace ID | Requests | Cost (Nanodollars / USD) | Pytest Exit | Verdict | Forensic Observation | Evidence |
|---|---:|---|---:|---:|---:|---|---|---|
| `FINAL-F01` | R1 | `92e0025c-d4c4-490d-945c-4cc50396d7de` | 12 | `39,631,500` (`$0.039632`) | 1 | **`FAILED`** | Opened `Tìm gia sư`, entered `Toán`, tapped `Toán` filter chip -> `2 gia sư phù hợp`, scrolled 3× toward `ThS. Hoàng Thu Trang` (taller `16`-chip `F-FINAL-04` `Khu vực` grid pushed list further down), exhausted `max_turns=12` before tapping `Xem hồ sơ`. | [`FINAL-F01/run-1`](FINAL-F01/run-1/run-receipt.json) |
| `FINAL-F01` | R2–R3 | — | — | — | — | **`NOT_RUN (BLOCKED_BUDGET_RESERVE)`** | Stopped fail-closed after R1 + `FINAL-F02a` R1–R2 left insufficient pre-call reservation headroom below `$0.150` while protecting `$0.50` Nexora reserve. | — |
| `FINAL-F02a` | R1 | `6f2e9a2c-57c7-4595-92fc-07d4a69b741f` | 12 | `39,592,200` (`$0.039592`) | 1 | **`FAILED`** | Entered need on `/matching`, triggered Gemini Level 2 -> `Gợi ý AI · Kiểm tra và chỉnh sửa`, edited `Phí tối đa mỗi giờ (VND)` `300000 -> 220000`, tapped `Xác nhận và tìm gia sư`; spinner cleared (`Chưa có hồ sơ phù hợp với bộ lọc đã xác nhận.` verified via post-run ADB scroll), but Turn 12 hit limit with numeric keypad still covering the bottom result area. | [`FINAL-F02a/run-1`](FINAL-F02a/run-1/run-receipt.json) |
| `FINAL-F02a` | R2 | `d259be26-cef7-4d18-968f-02f21c8340d5` | 12 | `39,711,000` (`$0.039711`) | 1 | **`FAILED`** | Entered need on `/matching`, parsed Gemini Level 2 -> `Gợi ý AI · Kiểm tra và chỉnh sửa`, edited `Phí tối đa mỗi giờ (VND)` `300000 -> 220000`, dismissed keypad in Turn 10 (`BACK`); Turn 11 `[500,800]` tap hit edge of focused fee field / cursor handle and reopened numeric keypad before `Xác nhận` submission completed at Turn 12. | [`FINAL-F02a/run-2`](FINAL-F02a/run-2/run-receipt.json) |
| `FINAL-F02a` | R3 | — | — | — | — | **`NOT_RUN (BLOCKED_BUDGET_RESERVE)`** | Stopped fail-closed before Turn-7 budget-reservation exhaustion under `$0.150` cap / `$0.50` Nexora reserve. | — |

---

## 3. Classification of All Other Final & Reusable Scenarios

- **Executed in Gate 3 Option B (PR #30 `2d14aa0`, pre-corrective APK `e885a076...`, kept separate):** `TC-27` (`3/3` PASS), `FINAL-F02b` (`1/3` PASS), `FINAL-F01` (`0/3` PASS).
- **`NOT_RUN (OUT_OF_BATCH_SCOPE / REQUIRES_MUTATION_FIXTURE)`:** `FINAL-F04`, `F05` (`TC-20/21`), `F06` (`TC-22/23`), `FINAL-F07`, `F09` (`T4–T7`), `FINAL-PDF`, non-superseded legacy `TC-01..TC-26`. Verified separately via `76/76` Firestore Rules emulator tests, `86/86` backend tests, `205/205` mobile unit/widget tests, `21/21` core tests, `5/5` web tests, emulator VietQR + local PDF screenshots (`94431a4...`), and Lab 3 historical suites.
- **`NOT_RUN (OUT_OF_BATCH_SCOPE / REQUIRES_PAIRED_WEB_ADMIN_SESSION)`:** `FINAL-F08` (covered live by `3/3` production cross-role approvals `CR-01`, `CR-04`, `CR-05` + `CR-02`/`CR-03` on `beewise-lab-3`).
- **`NOT_RUN (REQUIRES_DISPOSABLE_UNSET_AVD)`:** `TC-NATIVE-01` (Lab 3 historical `3/3` PASS on pre-Final APK; not re-run on Final APK `4e38d1ca...`).
