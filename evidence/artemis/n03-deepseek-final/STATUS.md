# N-03 Regression Checkpoint — 2026-11-06 (UTC+7)

- **PR #18 Reviewed HEAD**: `2b3cd31d6d7d0c9a7898232a3540a03e6fc8942d`
- **Authoritative Reference**: `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf` (Page 23: "ARTEMIS — Chuẩn bị kiểm thử tự động đầu cuối")
- **VERDICT: 30/30 ACCEPTED RUNS EXECUTED; NATIVE INTERACTION NOT VERIFIED; EXPLORATION NOT RUN**
- **Overall N-03 Status**: **INCOMPLETE** pending targeted Android-native interaction execution and 15–30 min exploratory session.

## Test Matrix Breakdown (10 Scenarios × 3 PASS)
- **30/30 ACCEPTED PASS** across 10 distinct student-authored test cases (3 independent accepted PASS per case):
  - **TC-01**: 3 ACCEPTED PASS (0 FAIL) — Lab 2 Home & Discovery
  - **TC-03**: 3 ACCEPTED PASS (4 retained FAIL) — Search empty state
  - **TC-04**: 3 ACCEPTED PASS (1 retained FAIL) — Tutor profile & details
  - **TC-05**: 3 ACCEPTED PASS (1 retained FAIL) — AI matching zero-catalog fallback
  - **TC-06**: 3 ACCEPTED PASS (0 FAIL) — Protected connection gate & navigation
  - **TC-08**: 3 ACCEPTED PASS (0 FAIL) — Registration field validation
  - **TC-09**: 3 ACCEPTED PASS (1 retained FAIL) — 5 primary navigation tabs
  - **TC-20**: 3 ACCEPTED PASS (1 retained FAIL) — Trial proposal acceptance workflow
  - **TC-22**: 3 ACCEPTED PASS (5 retained FAIL) — Class revision adjustment workflow
  - **TC-27**: 3 ACCEPTED PASS (0 FAIL) — Student-authored blank login validation ("nhánh lỗi")
- **TC-16**: Retained 1 historical failure (`completion-TC16-01`, trace `4065fa09-e7da-4f65-a13b-b4f5bd9053b9`). Observed native Google `SignInHubActivity`, but AVD had 0 Google accounts, loading Add Account webflow instead of the required Account Chooser dialog; safely excluded and substituted by TC-27 per explicit owner approval.
- **TC-27 Eligibility**: Verified compliant with Rubric v5 Page 23 (Option A: student-authored scenarios; rubric does not fix scenario IDs; covers "một nhánh lỗi"). Promoted to official regression matrix by owner approval.
- **Android-Native Interaction Status**: **NOT VERIFIED**. All 30 accepted PASS runs exercised Flutter application views; none observed or interacted with an OS-owned native UI (permission dialog, notification shade, account picker). Requires a single targeted follow-up execution (e.g. TC-16 with logged-in account, or Android system permission prompt) once approved by owner.
- **Total Admitted Sessions**: 44 sessions (30 ACCEPTED PASS, 14 retained FAIL).
- **DeepSeek HTTP Attempts**: 272 / 275 approved ceiling.
- **SDK Tokens**: 2,542,792 prompt + 33,161 completion = 2,575,953 total tokens.
- **Conservative Accounted Cost**: $0.8026308 USD (within approved budget envelope).
- **Nexora Reserve**: At least $0.50 reserved at all times.
- **Exploratory 15–30 Minutes (TC-25 Pro)**: NOT RUN (separate scope, pending separate owner authorization).
