# TC-NATIVE-01 — 3/3 accepted PASS

**N-03 evidence complete.** The original matrix remains 30 accepted PASS and 14 historical FAIL; no case was replaced or rerun. TC-NATIVE-01 is an additional student-authored case that satisfies Android-native coverage with three independent runs. TC-25 remains one continuous 925.734-second exploration PASS. Preparation Guide v5 p. 23 asks for at least ten cases, a native interaction and three executions per case; the supplement adds that coverage without changing the original matrix. No separate instructor sign-off is asserted.

| Run | ARTEMIS trace ID | Agent decision | Android user-0 grant after | Raw JUnit | Independent review |
| --- | --- | --- | --- | --- | --- |
| [run-01](run-01/manifest.json) | `ae4c4a76-8809-403d-ac3a-58cab70aec82` | Don't allow | `granted=false`, `USER_SET` | [1 PASS](run-01/result.junit.xml) | [Accepted](run-01/independent-review.json) |
| [run-02](run-02/manifest.json) | `c2edaca9-18db-451b-ba27-a210fc3b994c` | Allow | `granted=true`, `USER_SET` | [1 PASS](run-02/result.junit.xml) | [Accepted](run-02/independent-review.json) |
| [run-03](run-03/manifest.json) | `453bb8d0-4d09-4074-8b47-31dae25293bf` | Don't allow | `granted=false`, `USER_SET` | [1 PASS](run-03/result.junit.xml) | [Accepted](run-03/independent-review.json) |

In all three runs the original agent before image shows the genuine Android Permission Controller dialog, the original trace records one click inside the selected button, and the after image shows BeeWise Home. ADB prepared the permission state and measured the result; it did not tap. The case ran on the existing debug APK on a disposable API 35 AVD. No application data was cleared.

[Summary and budget](summary.json) · [Private trace provenance and hashes](trace-provenance.json) · [Owner approval](owner-approval.json). Six DeepSeek Flash HTTP 200 calls used 44,225 input and 723 output tokens (**44,948 total**) and **$0.0141351 conservative** out of $0.07. The cap was closed after the third run. The final read-only check confirmed shared balance covered the $0.50 Nexora reserve; the exact account balance and bill are not asserted. No Gemini fallback, retry or top-up.

The [original native receipt](../n03-exploration-final/native-permission-evidence.json) remains unchanged. See the [historical errata](../n03-exploration-final/STATUS.md#android-native-interaction): `85ed1fab` records an ANR **Wait** action, and `5bb907c1` records permission **Don't allow**. Neither counts toward these three PASS.
