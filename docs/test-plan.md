# Lab 3 test and evidence plan

The [PR #2 lifecycle follow-up](pr2-lifecycle-review.md) records 34 passing Flutter
tests and 26 passing Emulator rules tests. Native Android, staging, ARTEMIS and
external-review evidence remains NOT RUN / BLOCKED; earlier counts below are
historical snapshots.

## Critical flows

| Flow | Screens and expected end state |
|---|---|
| Discover and connect | Home → Search or AI matching → active Tutor Profile → signed-out auth gate preserving tutor ID → authenticated Connection Request → chat created only after Firestore batch success |
| AI matching | AI Matching → active tutor recommendation, or explicit no-match/configuration/network error → retry or Manual Search |
| Consultant onboarding | Group Chat → consultant Trial proposal → accept/alternate response → consultant Class revision → confirm/adjust → trusted invoice → pending verification → official schedule only after server-verified payment |
| Account and Firebase demo | Login/register → Profile → notification center, Remote Config, Crashlytics controls, tutor PDF export/upload → sign-out and guest state |
| Tutor application (project-added MVP) | Login/Register → tutor application form → private pending-review screen → sign-out; no public listing or parent actions |

## ARTEMIS test cases

Each row is implemented as an independent pytest function using `ArtemisClient`. The function sends one natural-language task, asks ARTEMIS to return observable values in JSON, and asserts both a terminal success and those values. Regression cases use Flash and must each pass 3/3 runs. Test results stay **pending** until device traces and JUnit files are captured.

| ID | Flow | Precondition | Instruction and verifiable expected result | Type | Result |
|---|---|---|---|---|---|
| TC-01 | Home | Installed, signed out; real Firebase project configured | Open Home; report five destination labels, profile card count, setup/error notice, and confirm no fabricated cards | Happy/error | BLOCKED |
| TC-02 | Search empty-catalog branch | Signed out on Home; active tutor count verified zero | Search configured subject; assert truthful empty state/count and Analytics search result count | Empty/analytics | Eligible independent candidate; does not test non-empty catalog |
| TC-03 | Search recovery | Known no-match query and network available | Search term; assert 0 results, empty message and clear/retry action | Error | BLOCKED |
| TC-04 | Tutor detail | Named active test tutor exists | Open exact profile; assert exact name, subjects, visible fee and connect action | Happy | BLOCKED (no approved real tutor fixture) |
| TC-05 | AI no-candidate branch | Signed out; active tutor catalog verified empty | Submit non-identifying request; assert zero result and manual-search recovery; explicitly do not claim Firebase AI provider invocation | Empty/recovery | Eligible independent candidate; does not test model behavior |
| TC-06 | Discover/connect auth gate | Signed out on a real tutor profile | Tap connect, visit Register then Login without submitting data; assert original tutor context and no request | Alternate | BLOCKED (needs real tutor) |
| TC-07 | Google sign-in | Signed out; dedicated test account available in native picker | Complete Google account picker with test account; assert signed-in Home and no error | Native/happy | BLOCKED (test Google account is not provisioned in current AVD picker) |
| TC-08 | Register | Signed out on Home | Navigate to Register; submit blank form with consent unchecked; assert validation and no account creation | Error | BLOCKED (AVD previously showed an ANR; retry after ARTEMIS host/device restored) |
| TC-09 | Top-level navigation | Signed out on Home | Visit all five bottom destinations; assert each visible and no overflow/crash | Navigation | BLOCKED |
| TC-10 | FCM foreground | FCM test push sent while app is foreground; Android permission available | Allow permission if requested, receive message, open shade entry; assert exact title, in-app entry and safe route | Native | BLOCKED |
| TC-11 | Export/upload | Signed in; real tutor; Firestore PDF persistence (Storage replaced 2026-11-02) | Export tutor PDF, tap "Lưu cloud riêng"; assert exact tutor, staged progress ending in "Đã lưu PDF và đọc lại từ server." and visible `reports/{uid}/files/{reportId}` document path | Happy | BLOCKED |
| TC-12 | Remote Config/Crashlytics | Signed out on Home; demo controls visible to guest | Navigate to Account; read `ai_result_limit` and `ai_matching_enabled`; locate fatal/nonfatal actions without triggering | Happy | Eligible for independent retry; no ARTEMIS host env now |
| TC-13 | Sign-out | Signed in with dedicated account on Profile | Sign out; assert guest Home, private chats and stale account details absent | Happy | BLOCKED |
| TC-14 | FCM background | Distinct test push delivered while app is backgrounded | Reopen app; assert exact title is in notification center and route is correct | Native | BLOCKED |
| TC-15 | FCM terminated | Signed in, app fully terminated, distinct test push delivered | Tap shade notification; assert cold start, exact title and correct destination | Native | BLOCKED |
| TC-16 | Auth cancellation | Signed out; Google sign-in enabled | Cancel native account picker; assert cancellation message, no signed-in account and usable app | Native/error | BLOCKED |
| TC-17 | Crashlytics fatal test | Signed out on Home; guest-visible Crashlytics control confirmed | Navigate to Account; tap test crash once, relaunch; assert termination and recovery. Console evidence must confirm issue, UID and custom key | Diagnostic | Eligible but destructive to the app process; run separately only after host/device stability is restored |
| TC-18 | Submit connection request | Signed in on connection form for a real active tutor | Submit designated non-personal request; assert chat and system message appear once | Happy | BLOCKED |
| TC-19 | Group chat | Signed in on staging chat with consultant participant | Send one test text; assert parent role/type and distinct participant roles | Happy | BLOCKED |
| TC-20 | Trial accepted | Pending consultant-authored proposal exists | Accept; assert response and no client-created invoice/paid status | Happy | BLOCKED |
| TC-21 | Trial alternate time | Separate pending proposal with alternate action | Submit alternate test time; assert response and consultant follow-up state | Alternate | BLOCKED |
| TC-22 | Class adjustment | Pending backend-authored class revision exists | Request one change; assert response and no payment/schedule | Alternate | BLOCKED |
| TC-23 | Class confirmation | Separate pending revision; invoice not yet issued | Confirm; assert response and client has not issued/verified invoice or schedule | Happy/trust boundary | BLOCKED |
| TC-24 | Payment/schedule gate | Dedicated account has no invoice or verified class | Open reachable payment/schedule flow; assert no paid claim/schedule and recovery guidance | Error/trust boundary | BLOCKED |
| TC-25 | Pro exploration | App installed; safe test account/data; no real payment or personal data | Explore freely for 15–30 minutes; return elapsed time, screens, issues with severity and blocked actions | Exploratory | PASS (single continuous qualifying session `aa025ab2` at 925.7s / 15.4m with 23 autonomous steps, 0 failures; verified Android OS native permission dialog in runs 1 & 2) |
| TC-26 | Tutor registration | Signed out; Firebase Auth/Firestore available; dedicated disposable test identity | Submit a valid tutor application; assert pending-review and not-visible-to-parents messages, no parent navigation, then sign out | Happy/trust boundary | BLOCKED |
| TC-27 | Login blank validation (student-authored error branch) | Signed out on Home | Open Account → Login; submit both fields blank; assert local validators and remain signed out | Error | Student-authored scenario promoted to official matrix by owner approval on 2026-11-06; covers rubric "nhánh lỗi" (does not cover Android-native interaction) |

### Current independent-case selection and live preflight (2026-11-02; rechecked 2026-11-03)

Priority case candidates from the owner are **TC-01, TC-03, TC-07, TC-08, TC-09, TC-12, TC-13 and TC-16**. Do not count any as eligible until its preconditions are confirmed on the actual run environment. TC-07 needs a dedicated Google identity available in the native picker; TC-13 needs the dedicated test account already signed in. TC-03 requires a known no-match term and live Firebase access. TC-16 requires Google Sign-In configured and the native picker available. TC-01/08/09/12 use guest state, but still need the installed app and functioning host/AVD.

| Priority case | Independent prerequisite to verify before scheduling 3 runs | Current disposition |
|---|---|---|
| TC-01 | Installed signed-out app; configured Firebase; Home state visible | One real ARTEMIS attempt submitted; **BLOCKED_QUOTA** before UI result; 0/3 PASS |
| TC-03 | Firebase available; `BEEWISE_NO_RESULT_TERM` is confirmed absent from approved catalog | Not run; quota blocks; term still needs catalog verification |
| TC-07 | Dedicated test Google account provisioned and visible in Android account picker | Not run; quota blocks; account/picker not verified |
| TC-08 | Signed-out app; blank registration form can be submitted locally without personal data | Not run; quota blocks |
| TC-09 | Signed-out Home; all five destinations reachable; structured title evidence returned | Not run; quota blocks |
| TC-12 | Signed-out Account screen; Remote Config values and Crashlytics actions visible; do not trigger crash | Not run; quota blocks |
| TC-13 | Dedicated test account already signed in; private chat scope safely disposable/read-only | Not run; quota blocks; signed-in fixture not verified |
| TC-16 | Google Sign-In configured; picker can open/cancel without choosing another account | Not run; quota blocks; provider/picker not verified |

On 2026-11-03, the exact eight-ID selection was first preflighted and stopped before pytest with missing ARTEMIS URL/device serial and ADB daemon (`priority-case-preflight-final/run-manifest.json`). We then started ADB and `BeeWise_API_36`; `emulator-5554` reached `device`, `sys.boot_completed=1`, BeeWise package/activity were present, and ARTEMIS `/api/status` reported idle with that device in `/api/devices`. A real TC-01 run was submitted (Flash, trace `093516ef-8ae1-4b9a-b8e2-87e71ee4be17`) and detected a structured Gemini Free Tier `generate_content_free_tier_requests` HTTP 429 before usable UI assertions; runner stopped the batch after 1/3 attempts. It is **BLOCKED_QUOTA**, not PASS or product FAIL. Log, JUnit, manifest and captured trace are in `evidence/artemis/n03-2026-11-03/tc01-priority-rerun/`. The trace reported retry-after about 13h44m at run time. No further cases were submitted on the exhausted quota. The eight IDs remain a queue; per-case fixture checks in the table still apply.

To reach ten official cases, examine TC-02 and TC-05 as additional candidates only after checking their narrower scope: TC-02 can verify the empty-catalog search/analytics branch, while TC-05 verifies empty-catalog AI fallback and must explicitly not claim an AI provider call. They do not cover populated search or model matching. If either prerequisite fails, select other official cases after checking their fixture and side-effect requirements. Note on rubric criteria (v5 p. 23): the instructor does not mandate fixed scenario IDs (Option A: student-authored scenarios). TC-27 was promoted into the 10-case official matrix by explicit owner approval on 2026-11-06 to satisfy the error branch requirement ("một nhánh lỗi"), replacing TC-16 when TC-16 was blocked by missing AVD Google accounts. However, because TC-27 tests Flutter in-app form validation rather than an OS dialog, the Android-native interaction requirement is not covered by TC-27 and remains pending verification. TC-17 is a destructive crash/relaunch diagnostic and should be considered separately, not included casually in the initial batch. All rows remain candidates until actual ARTEMIS runs produce trace/JUnit evidence.

Independent re-review on 2026-11-03 confirmed the ADB preflight gap and required stricter TC-09 evidence. TC-09 now accepts only a structured `destinations` list of exactly five ordered objects, each with `name`, `title_visible: true`, and separate boolean `overflow_seen` / `crash_dialog_seen`; bare string lists and prose no longer count. Parser and runner regression checks cover the former acceptance paths.

Preflight for selected IDs `TC-01|TC-03|TC-08|TC-09|TC-12|TC-16|TC-17` first stopped because the shell lacked host/device variables; receipt: `evidence/artemis/n03-2026-11-02/independent-10-preflight/run-manifest.json`. A later check found ARTEMIS at `127.0.0.1:8000` and AVD `emulator-5554` online. Initial batch trace `40a1eb1f-30dc-403e-9cfa-32c01e3e68f5` found Gemini Free Tier daily `generate_content` quota 429 (retry-after about 16h25m) before UI action; it was cancelled after 1m50s. I added trace polling and stop-on-quota behavior. Live guard verification on TC-08 stopped its session after about 17 s and prevented the other two suite runs. Evidence (manifest, log, JUnit, session, trace): `evidence/artemis/n03-2026-11-02/quota-guard-live/`. It remains BLOCKED_QUOTA, not a product failure or pass. No more model calls should be submitted until quota is available. Offline harness/parser/runner/collection checks do not count as mobile executions. Run exploration separately for 15–30 minutes with start/end time, actions, errors and trace recorded.

Case definitions live in `e2e_test/test_discovery.py`, `e2e_test/test_account_and_firebase.py`, `e2e_test/test_workflow.py`, and `e2e_test/test_exploratory.py`. There are 26 Flash regression cases: 22 automated, four requiring manual setup (TC-10/14/15 need a fresh operator-sent Firebase Console push for each run; TC-26 needs operator credential entry). TC-26 creates a unique disposable Auth identity per run; use only a dedicated test Firebase project. TC-27 is a student-authored scenario authored beyond the initial 26 cases; since the instructor's rubric v5 p. 23 specifies Option A (student-authored scenarios) and does not fix scenario IDs, TC-27 is eligible to cover the error branch requirement ("nhánh lỗi"), but cannot be counted as satisfying the separate Android-native OS interaction requirement. The runner saves logs, JUnit XML and a manifest; it now marks provider quota failures `BLOCKED_QUOTA`, keeps the one-run JSON manifest shape stable, and stops later suite runs. Run TC-25 separately for 15–30 minutes in Pro and retain its full trace. Consultant cases need trusted staging records. Confirm in each JUnit/log that ARTEMIS returned and asserted values matched; agent “success” alone is insufficient.

### Independent review remediation (2026-11-03)

The six findings in [the supplied review](../evidence/external-review/BeeWise_N03_Code_Review.md) were checked against source and all accepted. The runner now **fails closed** when `ARTEMIS_CASE_IDS` is empty; set an explicit, approved subset before invoking it. TC-01 provenance must explicitly say no fabricated profiles; TC-09 requires exactly the five destinations in order and independent overflow/crash signals; integer checks reject booleans; quota detection inspects structured error fields rather than arbitrary trace text. Offline regression results and per-finding dispositions are in [the remediation report](../evidence/external-review/BeeWise_N03_Remediation_Report.md). No Android/ARTEMIS suite was run for these changes. The supplied report asks for human reviewer sign-off, so N-04 remains open.

## Setup and execution

1. Use Android 36 at 360dp and 412dp with the configured `beewise-lab-3` project and a dedicated non-production test account. Add real, approved tutor data and at least one known matching and one known no-match search term. Never use Lab 2 mock profiles as Firebase records.
2. Start an owner-installed host at the pinned ARTEMIS commit, connect the Android device/emulator and install the debug APK. Set `ARTEMIS_BASE_URL` and `ARTEMIS_DEVICE_SERIAL`.
3. Set `BEEWISE_TEST_ACCOUNT_EMAIL`, `BEEWISE_TEST_TUTOR_NAME`, `BEEWISE_SEARCH_TERM` and `BEEWISE_NO_RESULT_TERM` to dedicated non-production test values. Do not put passwords, tokens or API keys in repository files or prompts.
4. Install the pinned pytest/SDK dependencies with `uv sync --project .\e2e_test`.
5. Set `ARTEMIS_CASE_IDS` to an explicit approved subset (for example, `$env:ARTEMIS_CASE_IDS='TC-01|TC-03|TC-08|TC-09|TC-12|TC-16'`), then run `e2e_test\run-artemis.ps1 -RunsPerTest 3` after prerequisites pass. The runner intentionally rejects an empty selection. Run TC-17 separately because it deliberately crashes/restarts the app. Run FCM and account-creation cases with an operator-controlled fresh fixture for each of their three runs. Run the exploratory case separately for 15–30 minutes and preserve timestamps, actions, issues and trace.
   Start with the owner-proposed candidates `TC-01|TC-03|TC-07|TC-08|TC-09|TC-12|TC-13|TC-16`; include only cases whose prerequisites passed. Verify TC-02/05 as potential official additions for the empty-catalog branches, or replace them with other eligible official cases. TC-17 deliberately crashes/relaunches and should run separately. TC-27 is a student-authored case promoted to the regression matrix via owner approval to cover the error branch, but does not provide Android-native interaction coverage. Execute only after prerequisites and model quota recover; 27 collected functions do not establish runnability or completion.
6. Capture notification permission and shade interactions for each manual FCM run.

Update 2026-11-03: the host/device were re-probed during independent-review
remediation. `adb devices -l` could not connect because the local ADB daemon
failed to start; the configured AVD name `BeeWise_API_36` exists but was not
confirmed online. `Test-NetConnection 127.0.0.1 -Port 8000` returned false.
Do not assume Gemini quota recovered from the date alone. Parser/harness and
synthetic PowerShell runner checks passed; pytest collection found 27 scenarios
and executed zero. No ARTEMIS task or Android E2E ran in this re-review pass.
7. Change each Remote Config value in Console, wait for configured fetch behavior, and record before/after screenshots without rebuilding. Capture Analytics DebugView and Crashlytics nonfatal/fatal issues with the required keys.

## Results and evidence record

| Test | Run 1 | Run 2 | Run 3 | Pass rate | Mean time | Trace/evidence | Flaky/failed/skipped explanation |
|---|---|---|---|---|---|---|---|
| TC-01 | FAIL (old APK showed two `[TEST]` profiles) | FAIL (parser rejected an ARTEMIS report variant) | PASS (trace `ca0ffa5b-3d67-4b4f-b4e2-1b5fc620d511`) | **3/17 live attempts PASS** | 44.71 s mean across 17 attempts | `evidence/artemis/n03-2026-11-02/tc01-post-merge-*`, `tc01-parser-fix-live*`; runner/JUnit/log receipts retained | Three attempts passed with Home, all five destinations, zero tutor cards, no fabricated-profile claims and no Firebase setup notice. Fourteen attempts failed due the old synthetic APK, AVD lock, or ARTEMIS response/title schema variations. The newest parser passed one fresh live run and offline checks cover four observed formats. The three passes are spread across batches; run a fresh 3/3 set before claiming repeatability. |
| TC-08 | FAIL (ARTEMIS task timeout at 600 s) | FAIL (AVD unavailable to ARTEMIS) | FAIL (AVD unavailable to ARTEMIS) | 0/3 accepted | 600 s timeout first run | `evidence/artemis/n03-2026-11-02/tc08-blank-validation/flash-suite-run-*`; later ANR screenshot and quota-blocked trace in `tc08-validation-after-avd-recovery/` and `independent-six-run-1/` | Original three attempts did not pass. A later AVD inspection found a BeeWise ANR on Home; latest task attempt was stopped before UI interaction after provider quota 429. No account data was entered. |
| TC-09 | PASS (original) | PASS (parser-fix live; trace `b01a5961-a740-49c4-81c1-aeea844dda0f`) | Not run | **2 accepted PASS**; 4 parser failures, 1 quota-cancelled attempt | 47 s original / 43 s latest PASS | `evidence/artemis/n03-2026-11-02/tc09-run-1-*`, `tc09-post-merge-repeat/flash-suite-run-*`, `tc09-parser-fix-live*/` including saved trace steps | Both accepted runs verified all five destinations without overflow/crash. Four intervening runs exposed prose/per-destination JSON shape differences and were retained as failures; parser now handles those observed formats. Historical second attempt was cancelled after Gemini 429; one planned run remains not run. |
| TC-02–TC-07, TC-10–TC-24, TC-26–TC-27 (remaining Flash cases) | Not run | Not run | Not run | Pending | Pending | Pending | Needs available ARTEMIS model quota and approved real catalog/account/trusted staging records where specified. TC-10/14/15 require fresh operator-sent pushes; TC-26 requires operator-entered disposable credentials. TC-27 is supplemental. |
| TC-25 Pro exploration (15–30 min session) | PASS (qualifying session `aa025ab2`; 925.7s, 23 steps) | PASS (trace `85ed1fab`; 379s, 15 steps) | PASS (trace `5bb907c1`; 467s, 16 steps) | **QUALIFYING PASS** | 925.7s continuous duration (Rubric satisfied) | `evidence/artemis/n03-exploration-final/`; traces/JUnit/screenshots retained | Single continuous 925.7s (~15.4m) AI exploration session with 0 errors/0 failures; verified Android-native OS notification permission interaction on GrantPermissionsActivity twice in earlier sessions; zero Gemini fallback. |

Store original ARTEMIS traces/replays, command logs, JUnit results, device model/OS/density, app build identifier and date under `evidence/artemis/`. Store screenshots and Firebase Console evidence in matching `evidence/` subfolders. Explain every non-pass; do not replace missing results with estimates.

## Manual service validation

- FCM: test foreground, background and terminated delivery separately; confirm tap route and in-app list.
- Analytics: enable DebugView, check recommended/custom event names, parameter types and absence of free text/PII; verify the Firebase Analytics user ID after each sign-in.
- Crashlytics: trigger a handled error through a real app error path and the separate deliberate fatal test; verify both console issues include user ID and `app_area` custom key.
- Remote Config: demonstrate that `ai_result_limit` and `ai_matching_enabled` change visible results/feature availability without rebuilding.
- Storage: export the visible tutor to PDF, inspect progress/path/URL and verify a second UID cannot read the first UID's file.
- Security: test Firestore and Storage rules in Emulator Suite or a non-production Firebase project; demonstrate denied cross-user access and client denial of trusted writes.


## Corrective execution update - 2026-10-30

The BLOCKED rows above are device scenarios, not test passes.
Actual current results: 8 Flutter regression tests and 26 local Firebase emulator
tests PASS; ARTEMIS SDK collected 26 functions, no Android scenario executed.
See [execution record](lab3-report.md) for environment, exit codes and logs.

TC-26 now requires manual setup and `BEEWISE_DEDICATED_TEST_PROJECT=1`: operator
enters disposable credentials directly on device, outside model goals/traces.
Thus 21 automatic Flash cases x3, four manual cases (TC-10/14/15/26) x3 and one
separate Pro TC-25 are required. Use new fixtures per trial/revision because
responses are now immutable one-per-proposal and require current pending,
unexpired consultant messages. Never reuse a consumed proposal across repeats.

The runner preserves pytest exit codes and writes BLOCKED for missing tools/host
or device. A zero exit is PENDING_VERIFICATION until original trace/replay and
visible state are independently reviewed. Keep trace IDs, SHA, UTC timestamps,
device config, APK hash and artifact hashes. AI JSON alone is not reliable proof.
Host model keys, passwords, personal data and console tokens must not enter
committed traces. Use only consented test data; inspect/redact artifacts before
adding them, preserving originals in authorized restricted storage.

Offline resume: `python scripts/check_e2e_harness.py` and
`uv run --project .\e2e_test python .\scripts\check_artemis_report_parser.py`;
SDK resume:
`uv sync --project e2e_test --frozen` then `uv run --project e2e_test pytest -c
e2e_test/pyproject.toml e2e_test --collect-only -q`. Full run commands and separate
manual cases are in README. Device width checks require genuine captures at
360dp and 412dp, font scaling, keyboard and safe-area checks; none exist yet.
