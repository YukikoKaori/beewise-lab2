# Final ARTEMIS Wave 3A

12 admitted and reviewed: **10 accepted PASS / 2 FAIL or rejected / 0 BLOCKED**.

- APK source: PR #31 head 1cbc950c04f6e1b42487dacd7d37016792aed3ec.
- APK SHA-256: 4e38d1cac93ad30a30fae70a98c0759c674992747394c5061d2f11bbfbb9bf64.
- Harness source: 3bd52dc890aa71e1bd7f4460991355165f8f7936 (the run receipt source_sha).
- Device: BeeWise_Final_API35 / emulator-5564 / Android API 35. Existing userdata preserved.
- Provider: DeepSeek deepseek-flash. No Gemini fallback.
- Ledger: 74 HTTP inference attempts, 716048 prompt tokens, 9211 completion tokens. Conservative estimate: USD 0.2258676; this is not a billed amount.
- Policy: [proposal](budget-proposal.json), [owner authorization reference](owner-approval.json).

| Case | Repetition | Review | Trace |
|---|---|---|---|
| TC-09 | [run-1](TC-09/run-1/independent-review.json) | FAIL / rejected | cef03e61-cae8-4c1b-87c5-e4fa934980b4 |
| TC-09 | [run-2](TC-09/run-2/independent-review.json) | PASS | 971d1550-453b-46e8-9bd1-6cd409d43f0d |
| TC-09 | [run-3](TC-09/run-3/independent-review.json) | FAIL / rejected | 67908aee-6f3f-4b47-923c-a191b5678110 |
| TC-08 | [run-1](TC-08/run-1/independent-review.json) | PASS | 5919abdd-4112-4b8d-ac0e-bc697f8e38df |
| TC-08 | [run-2](TC-08/run-2/independent-review.json) | PASS | 3fb055b7-9dcb-4922-af1d-056693e34bed |
| TC-08 | [run-3](TC-08/run-3/independent-review.json) | PASS | 8e1fcec6-29bf-4884-93c6-3ccc454fff0d |
| TC-12 | [run-1](TC-12/run-1/independent-review.json) | PASS | 75b1508e-7c34-42f0-b82d-b8c6ce4ecde4 |
| TC-12 | [run-2](TC-12/run-2/independent-review.json) | PASS | e429dbfb-a3d8-4954-a888-ed60b4151a89 |
| TC-12 | [run-3](TC-12/run-3/independent-review.json) | PASS | 652a70bf-4a1a-4765-af16-93c4c1a3662a |
| TC-03 | [run-1](TC-03/run-1/independent-review.json) | PASS | 5bc7c131-c140-420a-ad4f-333a5c45972f |
| TC-03 | [run-2](TC-03/run-2/independent-review.json) | PASS | ca2cfa6c-6144-4e5c-a6be-5f66fdf996f7 |
| TC-03 | [run-3](TC-03/run-3/independent-review.json) | PASS | e5abbdf8-4303-496b-9aba-7dda8bb2babf |

TC-09 repetitions 1 and 3 terminated on Home without opening the remaining tabs. Repetition 2 reached all five destinations; the failed runs do not establish an application navigation defect.

Earlier Gate 3 B, Wave 1 and Wave 2 verdicts and files are unchanged. Wave 3B requires a separately built and hashed emulator APK; do not pool it into this APK result.
