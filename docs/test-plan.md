# Lab 3 test and evidence plan

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
| TC-01 | Home | Installed, signed out; real Firebase project configured | Open Home; report five destination labels, profile card count, setup/error notice, and confirm no fabricated cards | Happy/error | Pending |
| TC-02 | Search | Signed out; active tutor catalog available | Search configured subject; assert query, result count, visible names and data/empty/error state | Happy | Pending |
| TC-03 | Search recovery | Known no-match query and network available | Search term; assert 0 results, empty message and clear/retry action | Error | Pending |
| TC-04 | Tutor detail | Named active test tutor exists | Open exact profile; assert exact name, subjects, visible fee and connect action | Happy | Pending |
| TC-05 | AI match | AI Logic enabled and active catalog exists | Submit non-identifying grade-8 algebra request; assert shown result count/names or explicit empty/error and recovery | Happy/error | Pending |
| TC-06 | Discover/connect auth gate | Signed out on a real tutor profile | Tap connect, visit Register then Login without submitting data; assert original tutor context and no request | Alternate | Pending |
| TC-07 | Google sign-in | Signed out; dedicated test account available in native picker | Complete Google account picker with test account; assert signed-in Home and no error | Native/happy | Pending |
| TC-08 | Register | Signed out on blank registration form | Submit blank form with consent unchecked; assert validation and no account creation | Error | Pending |
| TC-09 | Top-level navigation | Signed out on Home | Visit all five bottom destinations; assert each visible and no overflow/crash | Navigation | Pending |
| TC-10 | FCM foreground | FCM test push sent while app is foreground; Android permission available | Allow permission if requested, receive message, open shade entry; assert exact title, in-app entry and safe route | Native | Pending |
| TC-11 | Export/upload | Signed in; real tutor; Storage enabled | Export tutor PDF; assert exact tutor, completion, `reports/{uid}/...pdf` path and real URL visible | Happy | Pending |
| TC-12 | Remote Config/Crashlytics | Signed in; values fetched, Crashlytics enabled | Read `ai_result_limit` and `ai_matching_enabled`; locate fatal/nonfatal actions without triggering | Happy | Pending |
| TC-13 | Sign-out | Signed in with dedicated account on Profile | Sign out; assert guest Home, private chats and stale account details absent | Happy | Pending |
| TC-14 | FCM background | Distinct test push delivered while app is backgrounded | Reopen app; assert exact title is in notification center and route is correct | Native | Pending |
| TC-15 | FCM terminated | Signed in, app fully terminated, distinct test push delivered | Tap shade notification; assert cold start, exact title and correct destination | Native | Pending |
| TC-16 | Auth cancellation | Signed out; Google sign-in enabled | Cancel native account picker; assert cancellation message, no signed-in account and usable app | Native/error | Pending |
| TC-17 | Crashlytics fatal test | Signed in; Crashlytics enabled; run separately at end of manual session | Tap test crash once, relaunch; assert termination and recovery. Console evidence must confirm issue, UID and custom key | Diagnostic | Pending |
| TC-18 | Submit connection request | Signed in on connection form for a real active tutor | Submit designated non-personal request; assert chat and system message appear once | Happy | Pending |
| TC-19 | Group chat | Signed in on staging chat with consultant participant | Send one test text; assert parent role/type and distinct participant roles | Happy | Pending |
| TC-20 | Trial accepted | Pending consultant-authored proposal exists | Accept; assert response and no client-created invoice/paid status | Happy | Pending |
| TC-21 | Trial alternate time | Separate pending proposal with alternate action | Submit alternate test time; assert response and consultant follow-up state | Alternate | Pending |
| TC-22 | Class adjustment | Pending backend-authored class revision exists | Request one change; assert response and no payment/schedule | Alternate | Pending |
| TC-23 | Class confirmation | Separate pending revision; invoice not yet issued | Confirm; assert response and client has not issued/verified invoice or schedule | Happy/trust boundary | Pending |
| TC-24 | Payment/schedule gate | Dedicated account has no invoice or verified class | Open reachable payment/schedule flow; assert no paid claim/schedule and recovery guidance | Error/trust boundary | Pending |
| TC-25 | Pro exploration | App installed; safe test account/data; no real payment or personal data | Explore freely for 20 minutes; return elapsed time, screens, issues with severity and blocked actions | Exploratory | Pending |
| TC-26 | Tutor registration | Signed out; Firebase Auth/Firestore available; dedicated disposable test identity | Submit a valid tutor application; assert pending-review and not-visible-to-parents messages, no parent navigation, then sign out | Happy/trust boundary | Pending |

Case definitions live in `e2e_test/test_discovery.py`, `e2e_test/test_account_and_firebase.py`, `e2e_test/test_workflow.py`, and `e2e_test/test_exploratory.py`. There are 25 Flash regression cases: 22 automated cases run by `run-artemis.ps1` three times, plus TC-10/14/15 which require a fresh operator-sent Firebase Console push for each of their three runs. TC-26 creates a unique disposable Auth identity per run; use only a dedicated test Firebase project and do not reuse a personal account. The script saves logs, JUnit XML and a manifest for its automated cases. Run TC-25 separately once in Pro and retain its full trace. Consultant cases need staging records seeded by a trusted backend before each independent run; the current repo has no consultant/payment backend. Confirm in each JUnit/log that ARTEMIS returned and the asserted JSON values matched; an agent status of “success” alone is insufficient.

## Setup and execution

1. Use Android 36 at 360dp and 412dp with the configured `beewise-lab-3` project and a dedicated non-production test account. Add real, approved tutor data and at least one known matching and one known no-match search term. Never use Lab 2 mock profiles as Firebase records.
2. Start the pinned ARTEMIS host from `D:\Apps\artemis`, connect the Android device/emulator and install the debug APK. Set `ARTEMIS_BASE_URL` and `ARTEMIS_DEVICE_SERIAL`.
3. Set `BEEWISE_TEST_ACCOUNT_EMAIL`, `BEEWISE_TEST_TUTOR_NAME`, `BEEWISE_SEARCH_TERM` and `BEEWISE_NO_RESULT_TERM` to dedicated non-production test values. Do not put passwords, tokens or API keys in repository files or prompts.
4. Install the pinned pytest/SDK dependencies with `uv sync --project .\e2e_test`.
5. Run `e2e_test\run-artemis.ps1 -RunsPerTest 3` for 22 automated regression cases. Run TC-10, TC-14 and TC-15 separately three times each, sending a new Firebase Console test push before every run. Run the exploratory case once with `uv run --project .\e2e_test pytest -c .\e2e_test\pyproject.toml .\e2e_test\test_exploratory.py -m exploratory -q -s` and capture its output.
6. Capture notification permission and shade interactions for each manual FCM run.
7. Change each Remote Config value in Console, wait for configured fetch behavior, and record before/after screenshots without rebuilding. Capture Analytics DebugView and Crashlytics nonfatal/fatal issues with the required keys.

## Results and evidence record

| Test | Run 1 | Run 2 | Run 3 | Pass rate | Mean time | Trace/evidence | Flaky/failed/skipped explanation |
|---|---|---|---|---|---|---|---|
| TC-01 through TC-24, TC-26 (Flash regression) | Not run | Not run | Not run | Pending | Pending | Pending | 22 automated + 3 manual-push cases; no APK/device/ARTEMIS host or seeded staging data evidence yet |
| TC-25 Pro exploration (single 15–30 min session) | Not run | — | — | Pending | Pending | Pending | No live session evidence yet |

Store original ARTEMIS traces/replays, command logs, JUnit results, device model/OS/density, app build identifier and date under `evidence/artemis/`. Store screenshots and Firebase Console evidence in matching `evidence/` subfolders. Explain every non-pass; do not replace missing results with estimates.

## Manual service validation

- FCM: test foreground, background and terminated delivery separately; confirm tap route and in-app list.
- Analytics: enable DebugView, check recommended/custom event names, parameter types and absence of free text/PII; verify the Firebase Analytics user ID after each sign-in.
- Crashlytics: trigger a handled error through a real app error path and the separate deliberate fatal test; verify both console issues include user ID and `app_area` custom key.
- Remote Config: demonstrate that `ai_result_limit` and `ai_matching_enabled` change visible results/feature availability without rebuilding.
- Storage: export the visible tutor to PDF, inspect progress/path/URL and verify a second UID cannot read the first UID's file.
- Security: test Firestore and Storage rules in Emulator Suite or a non-production Firebase project; demonstrate denied cross-user access and client denial of trusted writes.
