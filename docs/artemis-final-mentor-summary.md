# BeeWise Final — ARTEMIS mentor evidence

**EXECUTED — SELECTIVE COVERAGE.** ARTEMIS controlled the BeeWise Android app on API 35 using DeepSeek Flash. A run was accepted only after the recorded interaction and the assertion result supported the same outcome. These runs demonstrate representative Android workflows; they do not establish full rubric coverage.

| Batch | Started | Accepted PASS | FAIL / rejected | BLOCKED | Interrupted |
|---|---:|---:|---:|---:|---:|
| [Antigravity Gate 3 B](../evidence/final/artemis/summary.md) | 9 | 4 | 4 | 1 | 0 |
| [Antigravity Wave 1](../evidence/final/artemis/completion-batch/batch-summary.json) | 3 | 0 | 3 | 0 | 0 |
| [Antigravity Wave 2](../evidence/final/artemis/completion-wave2/summary.md) | 15 | 11 | 4 | 0 | 0 |
| [Codex Wave 3A](../evidence/final/artemis/completion-wave3a/summary.md) | 12 | 10 | 2 | 0 | 0 |
| [Codex Wave 3B — owner stopped](../evidence/final/artemis/completion-wave3b/interrupted-receipt.json) | 1 | 0 | 0 | 0 | 1 |
| **Total** | **40** | **25** | **13** | **1** | **1** |

Of the 40 started runs, 39 have a historical PASS, FAIL or BLOCKED verdict. Wave 3A: navigation **1/3**, registration validation **3/3**, Remote Config and Crashlytics controls inspection **3/3**, empty tutor search **3/3**. The two navigation failures ended early on Home. The Wave 3B attempt entered the connection form before owner-directed shutdown; it did not verify submission, chat or account isolation.

Seven original frames, linked without copying or altering the files:

| Scenario and observation | Original frames | Trace ID (Wave 2 R3) |
|---|---|---|
| Login: submitting empty fields shows email and password validation; no successful sign-in asserted. | [Validation](../evidence/final/artemis/completion-wave2/TC-27/run-3/step-04.jpg) | `652e29dd-564c-4ceb-b611-c3783300a10e` |
| AI Matching: Gemini Level 2 produces editable filters. ARTEMIS changes the fee to 220,000 VND, confirms, and sees the explicit empty result. | [AI suggestions](../evidence/final/artemis/completion-wave2/FINAL-F02a/run-3/step-06.jpg), [confirmed empty result](../evidence/final/artemis/completion-wave2/FINAL-F02a/run-3/step-13.jpg) | `d9d78ee0-1ffd-4966-b70b-0fbdea1c1676` |
| Offline recovery: the AI error appears and manual filters are reachable. | [Offline error](../evidence/final/artemis/completion-wave2/FINAL-F02b/run-3/step-05.jpg), [manual filters](../evidence/final/artemis/completion-wave2/FINAL-F02b/run-3/step-09.jpg) | `f0f3315b-5100-4a39-bcc8-ce7cd1cdc3e8` |
| Tutor search: opens a matching profile and sees the hourly fee and connection action. | [Tutor profile](../evidence/final/artemis/completion-wave2/FINAL-F01/run-3/step-11.jpg) | `7f4e44d9-c661-4ac9-bf67-a3fa2e58c0e6` |
| Android notifications: ARTEMIS taps “Don't allow” in the system dialog. The trace records denial and return to the app; this does not prove notification delivery. | [Native permission dialog](../evidence/final/artemis/completion-wave2/TC-NATIVE-01/run-3/native-proof/before.png) | `b1b94ad3-8cb4-4f21-97d9-a24c59e989f8` |

| APK provenance | Build source SHA | APK SHA-256 |
|---|---|---|
| Gate 3 B, pre-corrective build | `d7fa5bea2ed5276c13ecd3739fa00257676c1242` | `e885a076b3a1f39e40f7cacc603ea0aec2d30e7e44028511e6f3bc06be3986b9` |
| Waves 1, 2 and 3A, PR #31 build | `1cbc950c04f6e1b42487dacd7d37016792aed3ec` | `4e38d1cac93ad30a30fae70a98c0759c674992747394c5061d2f11bbfbb9bf64` |
| Wave 3B, separate Auth/Firestore Emulator build | `1cbc950c04f6e1b42487dacd7d37016792aed3ec` | `abaa933074857765675a1994294507126ed45204f53e29d76d14ba4a3fff5368` |

Gate 3 B, Wave 1 and Wave 3A used `BeeWise_Final_API35` (`emulator-5564`); the Wave 2 permission scenario and interrupted Wave 3B used `BeeWise_N03_Native_API35` (`emulator-5566`). The Gate 3 B build source differs from its later `2d14aa03a2548c74e40f7c49e93f2205cce8da6a` merged review baseline. The Wave 3A harness checkout was `3bd52dc890aa71e1bd7f4460991355165f8f7936`; the Wave 3B harness checkout was `c918e3e3e49cf7b83078b5f4eb2a61f89dc37d90`. See the [original checkpoint](../evidence/final/artemis/codex-handoff-checkpoint.json) for the historical scope.

VietQR, private PDF, tutor cross-role, release or physical device validation, and the remaining Lab 2 scenarios were not completed by this ARTEMIS batch. Separate manual and emulator evidence remains scoped to its own tests. The owner closed the campaign after representative evidence; no further repetitions are scheduled.
