# N-03 evidence status — 2026-11-06

**30/30 original regression PASS, 3/3 Android-native supplement PASS, and one qualifying TC-25 PASS.** The original matrix is unchanged; the new [TC-NATIVE-01 case](../n03-native-final/STATUS.md) supplies the three independently verified Android-native executions. The historical observations below do not count toward those three.

## Accepted regression matrix

[PR #18](https://github.com/YukikoKaori/beewise-lab2/pull/18) merged at `c9086f61823808ff218db17a0458d3eb748ee1e0`. The [final completion summary](../n03-deepseek-final/completion-summary.json) indexes 44 admissions: 30 accepted PASS and 14 retained FAIL. The [17-admission run manifest](../n03-deepseek-final/run-manifest.json) is an earlier snapshot.

| Case | Accepted PASS |
| --- | ---: |
| TC-01 | 3 |
| TC-03 | 3 |
| TC-04 | 3 |
| TC-05 | 3 |
| TC-06 | 3 |
| TC-08 | 3 |
| TC-09 | 3 |
| TC-20 | 3 |
| TC-22 | 3 |
| TC-27 | 3 |

TC-16 remains excluded: Android opened the Google add-account flow rather than the expected account chooser. Owner-approved TC-27 is the student-authored blank-login **error branch**; it does not count as an Android-native case. The existing receipts, JUnit results and independent reviews are unchanged. All 44 per-run manifests, the 17 historical receipt sets and the 18 listed run-manifest hashes matched. The older aggregate artifact index’s `summary_sha256` does not match the merged `completion-summary.json` under either LF or CRLF. This is an inherited index inconsistency; the matrix was verified directly from run receipts, independent reviews and JUnit, and PR #18 evidence was not edited.

## Continuous exploration

One TC-25 session, `aa025ab2-6a51-4b34-a4c1-3ba346e4e0a4`, passed at **925.734 seconds** (about 15:26), with **23 autonomous steps**: 22 Android actions and a final structured report. It used the owner-approved Flash profile with DeepSeek `deepseek-flash`, API 35, zero Gemini fallback and the documented V6 turn pacing. [JUnit](result.junit.xml) records one pass, zero failures, errors or skips. [Trace provenance and timing](README.md#trace-and-clocks) identify the original source. Earlier interrupted/failed runs are historical and are not added to the qualifying duration.

## Android-native interaction

The [original receipt](native-permission-evidence.json) and screenshots are preserved byte for byte. **Historical errata:** this review corrects a historical label:

- `85ed1fab`, step 2: the original trace labels the tap **Wait**, and [screenshot 07](screenshots/07_native_permission_allow_trace1.jpg) shows Android's ANR dialog over the permission prompt. The next original image shows the permission dialog still visible. This is a genuine OS action; it does not establish that notification permission was granted.
- `5bb907c1`, step 1: the tap matches the lower **Don't allow** button on the Android `POST_NOTIFICATIONS` dialog ([before](screenshots/01_native_permission_dialog_pre.jpg), [after](screenshots/02_beewise_home_post_permission.jpg)). The trace and screenshots verify dismissal and return to BeeWise Home on API 35. They do not independently establish persistent permission state.

Neither attempt passed the exploratory duration gate. Both are separate from the 30 accepted regression runs.

## V6 provider accounting

The [manifest](exploration-manifest.json) exports only aggregate ledger data: **161/168** reservations, 160 HTTP 200 responses, one unsettled reservation, 1,772,840 SDK-reported tokens and **$0.5639859/$0.58** conservative accounting. The qualifying session contributed 25 HTTP 200 calls, 279,169 tokens and $0.0886278 conservative. This is not an attributed provider bill or evidence of current shared account balance.
