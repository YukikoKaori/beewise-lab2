# Final ARTEMIS Wave 2 Completion Summary (Rebuilt PR #31 APK)

- **Status:** **`COMPLETED_15_OF_15_ADMISSIONS`** — **`11/15` (`73.33%`) independently accepted PASSes** across `5` cases × `3` repetitions on rebuilt Final debug APK (`4e38d1cac93ad30a30fae70a98c0759c674992747394c5061d2f11bbfbb9bf64` from PR #31 HEAD `1cbc950c04f6e1b42487dacd7d37016792aed3ec`).
- **Owner Authorization:** [`owner-approval.json`](owner-approval.json) (`owner_msg_unlock_full_balance_20261112`) approving [`budget-proposal.json`](budget-proposal.json) (`flash_max_turns=18`, `15` max admissions, `240` HTTP requests, `$0.500` USD conservative ceiling).
- **Devices & Environments (Isolated):**
  - `BeeWise_Final_API35` (`emulator-5564`, API 35): `FINAL-F02a` (live App Check + Gemini Level 2), `FINAL-F01` (read-only catalog), `FINAL-F02b` (offline Airplane mode, restored immediately afterward), `TC-27` (guest email/password validation).
  - `BeeWise_N03_Native_API35` (`emulator-5566`, disposable API 35): `TC-NATIVE-01` (real Android 15 `GrantPermissionsActivity` notification dialog).
- **Cumulative Conservative Ledger Usage (`15/15` Admissions):**
  - **HTTP inference requests:** `116 / 240`
  - **Token usage:** `1,169,806` prompt tokens, `15,143` completion tokens
  - **Accounted conservative spend:** `$0.3767076` USD (`376,707,600` / `500,000,000` nanodollars)
  - **Post-run DeepSeek `/user/balance` check:** [`post-run-balance-check.json`](post-run-balance-check.json) -> **`PASS`** (`http_status: 200`, `is_available: true`, `usd_balance_covers_required: true` for `$0.50` USD reserve).

---

## 1. Per-Case Acceptance Summary (`4e38d1ca...`)

| Case | Executed | Pytest Pass | Independent Accepted PASS | Key Outcome |
|---|---:|---:|---:|---|
| `FINAL-F02a` | 3 | 2 | **2 / 3** | R2 & R3 verified live Gemini Level 2 `Gợi ý AI · Kiểm tra và chỉnh sửa`, `300000 -> 220000`, `BACK`, `Xác nhận và tìm gia sư`, empty result text. R1 failed earlier `non_image_bytes` cap before host limit increase. |
| `FINAL-F01` | 3 | 1 | **1 / 3** | R3 verified exact `250.000đ/giờ` & `Gửi yêu cầu kết nối` on `/tutors/:id` (`ThS. Hoàng Thu Trang`). R1 & R2 reached `/tutors/:id` cleanly in frames, but `test_final_flows.py:56` strict regex rejected `'Học phí tham khảo 250.000đ/giờ'`. |
| `FINAL-F02b` | 3 | 3 | **2 / 3** | R1 & R3 verified offline error `Chưa lấy được gợi ý AI. Thử lại hoặc tự điền bộ lọc.` -> `Tự điền bộ lọc` -> manual form & search link. R2 (`pytest_exit=0`) rejected upon frame audit because `Tự điền bộ lọc` was tapped while spinner was active. |
| `TC-27` | 3 | 3 | **3 / 3** | All 3 repetitions verified guest `/login` empty-submit validation messages while `signed_in=false`. |
| `TC-NATIVE-01` | 3 | 3 | **3 / 3** | `deny` (R1) -> `allow` (R2) -> `deny` (R3) verified via `before/after` dumps, pixel click bounds inside `com.android.permissioncontroller`, `USER_SET`, and return to `MainActivity`. |

---

## 2. Per-Run Trace Ledger (`15` Admissions)

| # | Case | Run | Trace ID | Requests | Cost (USD conservative) | Pytest | Accepted | Verdict | Evidence |
|---:|---|---:|---|---:|---:|---:|---:|---|---|
| 1 | `FINAL-F02a` | R1 | `d3e0f72c-dedd-497a-9b28-6c574afb193b` | 13 | `$0.047807` | 1 | false | **`FAILED`** | [`FINAL-F02a/run-1`](FINAL-F02a/run-1/independent-review.json) |
| 2 | `FINAL-F02a` | R2 | `373d96b9-6181-4738-9028-a8cb35ecadba` | 14 | `$0.046991` | 0 | true | **`ACCEPTED PASS`** | [`FINAL-F02a/run-2`](FINAL-F02a/run-2/independent-review.json) |
| 3 | `FINAL-F02a` | R3 | `d9d78ee0-1ffd-4966-b70b-0fbdea1c1676` | 14 | `$0.046515` | 0 | true | **`ACCEPTED PASS`** | [`FINAL-F02a/run-3`](FINAL-F02a/run-3/independent-review.json) |
| 4 | `FINAL-F01` | R1 | `307ffdd1-68f3-4c54-91d6-2c0f5266b8f0` | 11 | `$0.037493` | 1 | false | **`FAILED`** | [`FINAL-F01/run-1`](FINAL-F01/run-1/independent-review.json) |
| 5 | `FINAL-F01` | R2 | `81ad66b7-593e-401d-a47f-68d5dd59c502` | 12 | `$0.041158` | 1 | false | **`FAILED`** | [`FINAL-F01/run-2`](FINAL-F01/run-2/independent-review.json) |
| 6 | `FINAL-F01` | R3 | `7f4e44d9-c661-4ac9-bf67-a3fa2e58c0e6` | 11 | `$0.037139` | 0 | true | **`ACCEPTED PASS`** | [`FINAL-F01/run-3`](FINAL-F01/run-3/independent-review.json) |
| 7 | `FINAL-F02b` | R1 | `0644fe9b-77a0-4925-a3f3-f3b3e0cfe252` | 7 | `$0.021858` | 0 | true | **`ACCEPTED PASS`** | [`FINAL-F02b/run-1`](FINAL-F02b/run-1/independent-review.json) |
| 8 | `FINAL-F02b` | R2 | `2b55f2ff-a646-4a35-b113-2907a97bc2dd` | 7 | `$0.022277` | 0 | false | **`REJECTED`** | [`FINAL-F02b/run-2`](FINAL-F02b/run-2/independent-review.json) |
| 9 | `FINAL-F02b` | R3 | `f0f3315b-5100-4a39-bcc8-ce7cd1cdc3e8` | 9 | `$0.029504` | 0 | true | **`ACCEPTED PASS`** | [`FINAL-F02b/run-3`](FINAL-F02b/run-3/independent-review.json) |
| 10 | `TC-27` | R1 | `57c5befb-01ea-48fe-8cd7-64685d484701` | 4 | `$0.010586` | 0 | true | **`ACCEPTED PASS`** | [`TC-27/run-1`](TC-27/run-1/independent-review.json) |
| 11 | `TC-27` | R2 | `9231aa26-f9bc-4df3-be9d-3debb0d21f26` | 4 | `$0.010540` | 0 | true | **`ACCEPTED PASS`** | [`TC-27/run-2`](TC-27/run-2/independent-review.json) |
| 12 | `TC-27` | R3 | `652e29dd-564c-4ceb-b611-c3783300a10e` | 4 | `$0.010563` | 0 | true | **`ACCEPTED PASS`** | [`TC-27/run-3`](TC-27/run-3/independent-review.json) |
| 13 | `TC-NATIVE-01` | R1 | `6607d397-74e6-46be-ab5c-27b0a5705965` | 2 | `$0.004735` | 0 | true | **`ACCEPTED PASS`** | [`TC-NATIVE-01/run-1`](TC-NATIVE-01/run-1/independent-review.json) |
| 14 | `TC-NATIVE-01` | R2 | `c1e21ad7-fca0-484f-9927-4622e1c75980` | 2 | `$0.004783` | 0 | true | **`ACCEPTED PASS`** | [`TC-NATIVE-01/run-2`](TC-NATIVE-01/run-2/independent-review.json) |
| 15 | `TC-NATIVE-01` | R3 | `b1b94ad3-8cb4-4f21-97d9-a24c59e989f8` | 2 | `$0.004760` | 0 | true | **`ACCEPTED PASS`** | [`TC-NATIVE-01/run-3`](TC-NATIVE-01/run-3/independent-review.json) |
