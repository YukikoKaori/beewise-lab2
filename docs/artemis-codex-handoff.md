# BeeWise PRM393 Final — Complete ARTEMIS Handoff Guide for Codex

**Handoff Timestamp (UTC):** `2026-11-12T06:00Z` | **Status:** `PAUSED_CLEAN_AFTER_WAVE_2_TC_NATIVE_01`
**Machine-Readable Auditable Checkpoint:** [`evidence/final/artemis/codex-handoff-checkpoint.json`](../evidence/final/artemis/codex-handoff-checkpoint.json)

---

## 1. Non-Negotiable Baseline & Safety Rules

1. **Git Lineage & Scope Lock:**
   - Active evidence branch: `test/final-artemis-completion` (tracks `origin/test/final-artemis-completion`, stacked on PR #31 HEAD).
   - PR #31 branch (OPEN — do **not** merge): `fix/final-corrective-acceptance` @ `1cbc950c04f6e1b42487dacd7d37016792aed3ec` ([PR #31](https://github.com/YukikoKaori/beewise-lab2/pull/31)).
   - Merged Gate 3 Option B baseline (PR #30, untouched): `main` @ `2d14aa03a2548c74e40f7c49e93f2205cce8da6a` (over pre-corrective `d7fa5bea2ed5276c13ecd3739fa00257676c1242`).
   - Wave 1 commit on this branch: `a3abc406074dcdde49f62e9538f4d9b65976cdd9`.
   - **Never modify** application code or harness assertions relative to PR #31 HEAD (`mobile/`, `packages/`, `web/`, `firebase/`, `e2e_test/`) unless separately authorized by the owner.
   - **Never modify or overwrite** historical evidence:
     - Gate 3 Option B (`evidence/final/artemis/{FINAL-F01,FINAL-F02b,TC-27,budget-proposal.json,owner-approval.json,matrix.json,summary.md}`)
     - Wave 1 (`evidence/final/artemis/completion-batch/`)
     - Lab 3 N-03 (`evidence/artemis/`)
   - **Never auto-merge PRs or deploy Firebase (`firebase deploy`)**; production Web Hosting (`https://beewise-lab-3.web.app/`, bundle `1955bade...`) remains frozen until owner deploys PR #31 separately.
2. **Truthfulness & Independent Frame Review:**
   - Never treat `pytest_exit=0` alone as PASS. Inspect every exported `step-*.jpg` and trace step in `data_engine.db` before running `tools/artemis-deepseek/export_run.py --accept` or `--reject`.
   - Never mark partial or unexecuted flows (`FINAL-F01` `1/3`, `FINAL-F02a` `2/3`, `FINAL-F02b` `2/3`, or `NOT_RUN` Wave 3 flows) as complete `PASS`.
   - Never copy raw `pre-ui.xml` dumps, `pytest-private.log`, SQLite ledgers, or `.env` keys into Git.
3. **Concurrent Workstation Lockouts (DO NOT TOUCH):**
   - Another active session owns **`emulator-5562`** (`BeeWise_Tutor_PR25_API35`) and local ports **`4400`, `8080`, `8087`, `8088`, `9099`, `9150`, `9151`, `9152`**.
   - Never kill those processes, connect ADB/ARTEMIS to `emulator-5562`, or bind Firebase/ARTEMIS emulators to any of those ports.

---

## 2. Builds, Emulator Devices & ARTEMIS Runtime Config

### 2.1 APK & Emulator Matrix

| Artifact / Device | Identifier / Path | Purpose & Critical Constraints | Current State |
|---|---|---|---|
| **PR #31 Rebuilt Final APK** | `mobile/build/app/outputs/flutter-apk/app-debug.apk`<br>SHA-256: `4e38d1cac93ad30a30fae70a98c0759c674992747394c5061d2f11bbfbb9bf64` | Built from `1cbc950c...` with `BEEWISE_FINAL_FIRESTORE=true`. Target for Wave 1, Wave 2, and Wave 3A. | Built & installed on both API 35 AVDs |
| **Gate 3 B Historical APK** | SHA-256: `e885a076b3a1f39e40f7cacc603ea0aec2d30e7e44028511e6f3bc06be3986b9` | Historical PR #30 baseline only; keep strictly segregated. | Archived baseline |
| **Wave 3B Isolated Emulator APK** | Build outside repo e.g. `D:\CodexTemp\tmp\wave3b-emu-apk\app-debug.apk` | Must be built from `1cbc950c...` with `--dart-define=BEEWISE_FINAL_FIRESTORE=true`, `--dart-define=BEEWISE_FIREBASE_EMULATOR_HOST=10.0.2.2`, `--dart-define=BEEWISE_FIREBASE_AUTH_PORT=9199`, `--dart-define=BEEWISE_FIRESTORE_PORT=8180`. Install **only** on `BeeWise_N03_Native_API35`. | **NOT_YET_BUILT** |
| **Primary Final AVD** | `BeeWise_Final_API35` (`emulator-5564`, `-port 5564`, API 35)<br>`ANDROID_AVD_HOME=D:\CodexTemp\prm393-avd` | Holds App Check debug store `W0RFRkFVTFRd`. **NEVER run `adb shell pm clear com.beewise.beewise`** on this AVD. Restore Wi-Fi + Data after `FINAL-F02b`. | **STOPPED** (clean, guest baseline) |
| **Disposable Native / Isolated AVD** | `BeeWise_N03_Native_API35` (`emulator-5566`, `-port 5566`, API 35)<br>`ANDROID_AVD_HOME=D:\CodexTemp\n03-native-disposable-avd` | Used for `TC-NATIVE-01` (`3/3` complete) and safe for **Wave 3B** isolated Firebase Emulator tests. Ended R3 with `POST_NOTIFICATIONS` `granted=false, USER_SET`. | **STOPPED** |

### 2.2 ARTEMIS Host & Provider Configuration (Zero Credentials Stored)

- **Host entrypoint:** `tools/artemis-deepseek/host.py` on `http://127.0.0.1:8001` (currently **STOPPED**; port `8001` free).
- **ARTEMIS Python runtime:** `D:\CodexTemp\artemis-deepseek-audit\.venv\Scripts\python.exe` (ARTEMIS root: `D:\CodexTemp\artemis-deepseek-audit`).
- **Model config (`tools/artemis-deepseek/artemis.deepseek.jsonc`):**
  - `provider: "openai"`, `model: "deepseek-flash"`, `temperature: 0`
  - `step_summarizer.enabled: false`, `video_analyzer.enabled: false`
  - `explorer.default_version: "pro"`, `memory.runtime.max_concurrency: 1`
- **Provider environment enforced by `host.py`:**
  - `OPENAI_BASE_URL=https://api.deepseek.com`
  - `ARTEMIS_DEEPSEEK_ONLY=1`
  - `ARTEMIS_FLASH_MAX_TURNS` read from proposal JSON (`18` in Wave 2; valid up to `20`)
  - `ARTEMIS_DEEPSEEK_MAX_NON_IMAGE_BYTES=131072` auto-set by `host.py` when `flash_max_turns > 12`
  - Private credential file reference only (never read into logs/commits): `D:\CodexTemp\beewise-deepseek-compat\tools\artemis-deepseek\.env`
- **Active sessions right now:** `0` (`RUNNING`: `0`, `REVIEW_REQUIRED`: `0` in both Wave 1 & Wave 2 ledgers; all runs exported and reviewed).

---

## 3. Completed ARTEMIS Results & Provenance Inventory

> Every individual run's `traceId`, `runId`, `apkSha256`, `pytestExit`, `accepted`, screenshots, JUnit XML, `independent-review.json`, `manifest.json`, and local private log path is indexed in [`evidence/final/artemis/codex-handoff-checkpoint.json`](../evidence/final/artemis/codex-handoff-checkpoint.json).

### 3.1 Batch Totals & Cumulative DeepSeek Usage

| Batch / Scope | APK SHA-256 | Admissions | Accepted PASS | Failed / Rejected | Blocked | HTTP Calls | Prompt Tokens | Completion Tokens | Accounted Cost (USD Conservative) |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| **Gate 3 Option B (PR #30, historical)** | `e885a076...` | 9 | **4** (`44.44%`) | 4 | 1 (`ANR`) | 60 | 567,430 | 6,093 | `$0.1775406` |
| **Wave 1 (`completion-batch/`, PR #31)** | `4e38d1ca...` | 3 *(of 6)* | **0** (`0.00%`) | 3 | 0 *(3 stopped at reserve)* | 36 | 380,233 | 4,054 | `$0.1189347` |
| **Wave 2 (`completion-wave2/`, PR #31)** | `4e38d1ca...` | 15 *(of 15)* | **11** (`73.33%`) | 4 *(3 FAIL, 1 `--reject`)* | 0 | 116 | 1,169,806 | 15,143 | `$0.3767076` |
| **Subtotal Rebuilt PR #31 APK (`Wave 1 + 2`)** | `4e38d1ca...` | **18** | **11 (`61.11%`)** | **7** | **0** | **152** | **1,550,039** | **19,197** | **`$0.4956423`** |
| **Combined All Final ARTEMIS** | `e885a076` + `4e38d1ca` | **27** | **15** | **11** | **1** | **212** | **2,117,469** | **25,290** | **`$0.6731829`** |

*(Note: Conservative SQLite ledger pricing overestimates actual cache-hit charges on DeepSeek; actual live USD balance dropped `~$0.07` during Wave 2, leaving live balance > `$0.50` per [`completion-wave2/post-run-balance-check.json`](../evidence/final/artemis/completion-wave2/post-run-balance-check.json).)*

### 3.2 Rebuilt PR #31 APK (`4e38d1ca...`) Per-Case Results

| Case ID | Wave 1 (`flash_max_turns=12`) | Wave 2 (`flash_max_turns=18`) | Combined on `4e38d1ca...` | Wave 2 Trace IDs & Verdicts | Evidence Dir |
|---|---|---|---|---|---|
| **`FINAL-F02a`** | `R1 FAIL`, `R2 FAIL` (`0/2`) | `R1 FAIL`, `R2 PASS`, `R3 PASS` (`2/3`) | **2 / 5** | `d3e0f72c` (`FAIL`, payload cap), `373d96b9` (`PASS`), `d9d78ee0` (`PASS`) | [`completion-wave2/FINAL-F02a`](../evidence/final/artemis/completion-wave2/FINAL-F02a) |
| **`FINAL-F01`** | `R1 FAIL` (`0/1`) | `R1 FAIL`, `R2 FAIL`, `R3 PASS` (`1/3`) | **1 / 4** | `307ffdd1` (`FAIL`, fee regex), `81ad66b7` (`FAIL`, fee regex), `7f4e44d9` (`PASS`) | [`completion-wave2/FINAL-F01`](../evidence/final/artemis/completion-wave2/FINAL-F01) |
| **`FINAL-F02b`** | — | `R1 PASS`, `R2 REJECT`, `R3 PASS` (`2/3`) | **2 / 3** | `0644fe9b` (`PASS`), `2b55f2ff` (`REJECT` early tap), `f0f3315b` (`PASS`) | [`completion-wave2/FINAL-F02b`](../evidence/final/artemis/completion-wave2/FINAL-F02b) |
| **`TC-27`** | — | `R1 PASS`, `R2 PASS`, `R3 PASS` (`3/3`) | **3 / 3** | `57c5befb` (`PASS`), `9231aa26` (`PASS`), `652e29dd` (`PASS`) | [`completion-wave2/TC-27`](../evidence/final/artemis/completion-wave2/TC-27) |
| **`TC-NATIVE-01`** | — | `R1 deny`, `R2 allow`, `R3 deny` (`3/3`) | **3 / 3** | `6607d397` (`PASS`), `c1e21ad7` (`PASS`), `b1b94ad3` (`PASS`) | [`completion-wave2/TC-NATIVE-01`](../evidence/final/artemis/completion-wave2/TC-NATIVE-01) |

- Non-ARTEMIS Rebuilt-APK `F-FINAL-05` + Level 2 Analytics (`4e38d1ca...`): [`rebuilt-apk-analytics-check.json`](../evidence/final/artemis/completion-batch/rebuilt-apk-analytics-check.json) (manifest default `false`, opt-out cold-restart persistence, `HTTP 204` `ai_request` & `ai_result_accepted`, `userIdPropertyCount=0`).
- Local unexported logs/traces/raw XML dumps remain outside Git in:
  - `D:\CodexTemp\tmp\final-artemis-runs\` (Gate 3 B)
  - `D:\CodexTemp\tmp\final-completion-runs\` (Wave 1 ledger `completion-ledger.sqlite3` — **CLOSED at reserve boundary**)
  - `D:\CodexTemp\tmp\final-completion-wave2\` (Wave 2 ledger `wave2-ledger.sqlite3` — **`15/15` exhausted, DO NOT REUSE**)

---

## 4. Exact Remaining Test Matrix

All `35` collected ARTEMIS E2E cases (`27` Lab 3 `test_tc*` + `7` Final `test_final_*` + `TC-NATIVE-01`) minus the `5` cases run in Wave 1–2 (`TC-27`, `TC-NATIVE-01`, `FINAL-F01`, `FINAL-F02a`, `FINAL-F02b`) leave **`30` unrun cases**:

### 4.1 Priority Executable Remaining Waves (Recommended Next Scope)

| Wave | Case ID | Reps Remaining | Target AVD & Build | Required Setup / Fixtures |
|---|---|---:|---|---|
| **Wave 3A** *(Read-only / Guest)* | **`TC-09`** | **3** (`R1–R3`) | `BeeWise_Final_API35` (`emulator-5564`, `4e38d1ca...`) | Guest Home, 5 bottom tabs visible, no AI calls |
| **Wave 3A** *(Read-only / Guest)* | **`TC-08`** | **3** (`R1–R3`) | `BeeWise_Final_API35` (`emulator-5564`, `4e38d1ca...`) | Guest Home -> `Tài khoản` -> `Đăng ký`, blank submit only |
| **Wave 3A** *(Read-only / Guest)* | **`TC-12`** | **3** (`R1–R3`) | `BeeWise_Final_API35` (`emulator-5564`, `4e38d1ca...`) | Guest Profile inspecting Remote Config + Crashlytics buttons (no trigger) |
| **Wave 3A** *(Read-only / Guest)* | **`TC-03`** | **3** (`R1–R3`) | `BeeWise_Final_API35` (`emulator-5564`, `4e38d1ca...`) | Live catalog, `BEEWISE_NO_RESULT_TERM=zz-no-tutor-match-393-2026` |
| **Wave 3B** *(Isolated Emulator)* | **`FINAL-F04`** | **3** (`R1–R3`) | `BeeWise_N03_Native_API35` (`emulator-5566`, isolated APK) | Auth `9199` + Firestore `8180` (`Hub 4410`), seeded active `ThS. Hoàng Thu Trang`, signed-in synthetic Parent A + second Parent B isolation data |
| **Wave 3B** *(Isolated Emulator)* | **`FINAL-F07`** | **3** (`R1–R3`) | `BeeWise_N03_Native_API35` (`emulator-5566`, isolated APK) | `BEEWISE_FINAL_TEST_ENV=emulator`, `settings/paymentRecipient` test fixture, chat + staff-offered `finalPayments/{chatId}` (zero real transfer) |
| **Wave 3B** *(Isolated Emulator)* | **`FINAL-PDF`** | **3** (`R1–R3`) | `BeeWise_N03_Native_API35` (`emulator-5566`, isolated APK) | Signed-in Parent A viewing `ThS. Hoàng Thu Trang` -> save local PDF -> sign in as Parent B to verify `/reports/{uid}/localFiles` isolation |

### 4.2 Remaining Conditional, Superseded & Blocked Cases (`23` Cases)

- **Cross-role paired session (`1` case × 3 reps):** `FINAL-F08` (`REQUIRES_PAIRED_WEB_ADMIN_SESSION` + `BEEWISE_DEDICATED_TEST_PROJECT=1` + operator-supplied disposable tutor credentials outside model traces + synchronized Web approval; production manual cross-role `3/3` `CR-01`/`CR-04`/`CR-05` already verified on `e885a076...` in PR #30).
- **Supplemental guest/isolated (`6` cases):** `TC-01` (`×3`, guest Home — note `_decode_tc01_prose` only matches `count==0`, so Flash must emit JSON when live tutors `>0`), `TC-04` (`×3`, largely covered by `FINAL-F01`), `TC-06` (`×3`, auth gate roundtrip), `TC-02` (`×3`, requires empty catalog + Logcat Analytics enabled), `TC-17` (`×3`, triggers deliberate Crashlytics process crash + relaunch), `TC-24` (`×3`, extended by `FINAL-F07`, needs signed-in zero-invoice user).
- **Blocked by Play Account / GMS (`3` cases × 3 reps = `9`):** `TC-07`, `TC-13`, `TC-16` require a real signed-in test Google account in Android's Google picker (`BEEWISE_TEST_ACCOUNT_EMAIL`), unavailable on headless AOSP AVDs.
- **Blocked by External FCM Dispatch (`3` cases × 3 reps = `9`):** `TC-10`, `TC-14`, `TC-15` require live FCM notifications matching `BEEWISE_TEST_PUSH_*`.
- **Legacy Backend Workflow (`6` cases × 3 reps = `18`):** `TC-18`, `TC-19` (superseded by `FINAL-F04`), `TC-20`, `TC-21`, `TC-22`, `TC-23` (require legacy `backend/` at `http://10.0.2.2:8787` + `tools/artemis-deepseek/local_fixture.mjs` seeding `n03-tc20/tc22` fixtures).
- **Exploratory (`1` case):** `TC-25` (Pro exploration; requires dedicated `~25+` turn / `900s` proposal).
- **Explicitly Superseded in Final (`3` cases):** `TC-05` (`FINAL-F02a`/`FINAL-F02b`), `TC-11` (`FINAL-PDF`), `TC-26` (`FINAL-F08`).
- **Already-Attempted Partial Final Cases (`4e38d1ca...`):** `FINAL-F01` (`1/3` Wave 2), `FINAL-F02a` (`2/3` Wave 2), `FINAL-F02b` (`2/3` Wave 2) exhausted their 3 Wave 2 admissions (`retry_admissions=0`); do not rerun unless owner specifically authorizes another pass.

---

## 5. Known Defects & Critical Gotchas

1. **`FINAL-F01` Regex Prefix Sensitivity:** `e2e_test/test_final_flows.py:56` expects `[0-9][0-9., ]*\s*đ/giờ`, while Flutter's `_InfoRow` combines label+value (`'Học phí tham khảo\n250.000đ/giờ'`). Wave 2 `FINAL-F01` R1 & R2 visually opened `ThS. Hoàng Thu Trang` `/tutors/:id` cleanly but failed regex validation when DeepSeek included `'Học phí tham khảo '`; R3 emitted `'250.000đ/giờ'` (`PASS`). Keep `test_final_flows.py` unchanged unless owner directs otherwise.
2. **`FINAL-F02a` Turn Count & Payload Limit:** Needs `flash_max_turns=18` and `ARTEMIS_DEEPSEEK_MAX_NON_IMAGE_BYTES=131072` (enabled automatically by `host.py` whenever `flash_max_turns > 12`) plus dismissing numeric IME with `BACK` after editing `Phí tối đa mỗi giờ (VND)`.
3. **`FINAL-F02b` Spinner Early Tap (`--reject` needed):** DeepSeek may tap `Tự điền bộ lọc` while the offline spinner is active (`pytest_exit=0` false positive in Wave 2 R2). Mandatory frame audit catches this.
4. **Always Reset `PermissionController` Before `TC-NATIVE-01`:** Always force-stop both `com.beewise.beewise` and `com.google.android.permissioncontroller` cleanly on `BeeWise_N03_Native_API35`.
5. **Host CPU Pressure Causes Flutter ANR:** Keep Flutter tests/builds idle while running any ARTEMIS Android session.
6. **`balance_gate.py` Formula:** `completion_once.py` checks `live_usd_balance >= minimum_nexora_reserve_nanodollars + (cap - spent_nanodollars)`. Note `--approval` and `--proposal` must ALWAYS be passed explicitly to `completion_once.py` (otherwise it defaults to `evidence/final/artemis/completion-batch/*`!).

---

## 6. Exact Step-by-Step Instructions for Codex to Resume Safely

### Step 1: Verify Clean Baseline & Live DeepSeek Balance
```powershell
cd "C:\Users\THIS PC\.gemini\antigravity\worktrees\beewise-lab2\greeting_handler_t1"
git status -sb
git log -n 3 --oneline
adb devices
Get-NetTCPConnection -LocalPort 8001 -ErrorAction SilentlyContinue
```
Query `/user/balance` via `httpx` + `dotenv_values("D:\CodexTemp\beewise-deepseek-compat\tools\artemis-deepseek\.env")` (without printing keys or logging account balance to Git) before creating any Wave 3 budget proposal.

### Step 2: Create a Brand-New Proposal, Owner Approval & Fresh SQLite Ledger for Wave 3
Because `wave2-ledger.sqlite3` is at `15/15` `max_admissions`, **never reuse Wave 1 or Wave 2 ledgers**:
1. Pick a clean decision string allowed by `tools/artemis-deepseek/host.py` & `completion_once.py`:
   - `OWNER_APPROVED_FINAL_COMPLETION_WAVE_3` (Wave 3A)
   - `OWNER_APPROVED_FINAL_COMPLETION_WAVE_3_EMU` (Wave 3B)
2. Write `evidence/final/artemis/completion-wave3a/budget-proposal.json` (remember LF normalization for SHA-256!) ensuring `max_conservative_nanodollars <= 500000000`, `max_inference_requests <= 240`, `flash_max_turns <= 20`, and `minimum_nexora_reserve_nanodollars + max_conservative_nanodollars <= live_usd_balance_nanodollars` (confirm `owner_approval_ref` from owner conversation or `owner_msg_unlock_full_balance_20261112`).
3. Compute `proposal_sha256` with `\r\n -> \n` and write matching `owner-approval.json`.
4. Add unit test coverage in `scripts/test_final_artemis_policy.py` for the new Wave 3 proposal/approval.
5. Initialize fresh SQLite ledger in `D:\CodexTemp\tmp\final-completion-wave3a\wave3a-ledger.sqlite3`:
   ```python
   sys.path.insert(0, r"D:\CodexTemp\artemis-deepseek-audit")
   from artemis.llm.deepseek_ledger import initialize
   ```
   passing exact `max_requests`, `max_nanodollars`, `expires_utc` (+24h), and `approval_ref = f"{owner_approval_ref}:{proposal_sha256}"`.

### Step 3: Execute Wave 3A (`TC-09`, `TC-08`, `TC-12`, `TC-03` on `BeeWise_Final_API35`)
1. Boot **only** `BeeWise_Final_API35` on `-port 5564` (`$env:ANDROID_AVD_HOME = "D:\CodexTemp\prm393-avd"`). Never touch `emulator-5562`.
2. Start `host.py` pointing to Wave 3A `--ledger`, `--completion-approval`, `--completion-proposal`, and `--state-dir "D:\CodexTemp\tmp\final-completion-wave3a\host-state"`.
3. Before **each** admission, verify signed-out clean state (`am force-stop com.beewise.beewise` -> `am start -W -n com.beewise.beewise/.MainActivity`, verify `Home` renders via screencap; **never run `pm clear`!**).
4. Run `completion_once.py` with explicit `--approval` & `--proposal` for each case (`TC-09` R1–R3, `TC-08` R1–R3, `TC-12` R1–R3, `TC-03` R1–R3).
5. After each admission (`REVIEW_REQUIRED` or `FAILED`), inspect every step image & trace in `data_engine.db`, then run `export_run.py --accept` or `--reject` before starting the next admission.
6. Shut down `emulator-5564` (`adb -s emulator-5564 emu kill`) and stop Wave 3A `host.py` cleanly before Wave 3B.

### Step 4: Execute Wave 3B (`FINAL-F04`, `FINAL-F07`, `FINAL-PDF` Isolated)
1. Start an isolated Firebase Auth + Firestore Emulator outside repo (`D:\CodexTemp\tmp\wave3b-firebase.json`) on non-colliding ports **`hub: 4410`**, **`auth: 9199`**, **`firestore: 8180`**. Confirm `8080`/`9099`/`4400` are untouched!
2. Build an isolated debug APK from PR #31 HEAD (`1cbc950c...`, clean working tree in `mobile/`):
   ```powershell
   flutter build apk --debug `
     --dart-define=BEEWISE_FINAL_FIRESTORE=true `
     --dart-define=BEEWISE_FIREBASE_EMULATOR_HOST=10.0.2.2 `
     --dart-define=BEEWISE_FIREBASE_AUTH_PORT=9199 `
     --dart-define=BEEWISE_FIRESTORE_PORT=8180
   ```
   Copy APK to `D:\CodexTemp\tmp\wave3b-emu-apk\app-debug.apk`, compute its exact SHA-256 for Wave 3B `budget-proposal.json`, then restore/keep `mobile/` clean.
3. Boot `BeeWise_N03_Native_API35` on `-port 5566` (`$env:ANDROID_AVD_HOME = "D:\CodexTemp\n03-native-disposable-avd"`), install the isolated APK (`adb -s emulator-5566 install -r ...`), seed isolated fixtures on `127.0.0.1:8180` / `9199`, initialize `wave3b-ledger.sqlite3`, start Wave 3B `host.py` (`OWNER_APPROVED_FINAL_COMPLETION_WAVE_3_EMU`), run `FINAL-F04` (`--tutor-name "ThS. Hoàng Thu Trang"`), `FINAL-F07` (`--final-test-env emulator`), and `FINAL-PDF` (`×3` each) with per-run frame inspection and `export_run.py`.
4. Shut down `emulator-5566`, stop Wave 3B Firebase Emulators & `host.py`.

### Step 5: Finalize Evidence Docs, Offline Gates, & Push
1. Update `docs/artemis-final-matrix.md`, `docs/test-report.md`, and `evidence/final/artemis/codex-handoff-checkpoint.json`.
2. Run all offline validations cleanly:
   - `python -m unittest scripts/test_final_artemis_policy.py`
   - `python scripts/check_e2e_harness.py`
   - `python scripts/test_measure_bao_startup.py`
   - `pytest -c e2e_test/pyproject.toml e2e_test/test_final_flow_assertions.py -q`
   - `pytest -c e2e_test/pyproject.toml e2e_test --collect-only -q`
   - `git diff --check`
   - `git diff --stat 1cbc950c04f6e1b42487dacd7d37016792aed3ec -- mobile packages web firebase e2e_test` (must be empty)
3. Push `test/final-artemis-completion` and open/update its PR targeting `fix/final-corrective-acceptance`, checking all 5 CI jobs pass (`validate.yml`), without merging PRs or deploying Firebase.
