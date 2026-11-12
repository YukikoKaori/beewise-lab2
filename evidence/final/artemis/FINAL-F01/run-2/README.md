# `FINAL-F01` Run 2 — `BLOCKED` (Genuine Android ANR During Run)

- **Run ID:** `fa783965-c1a0-4f58-80f8-16ccaa3e5d9a`
- **Trace ID:** `f61abd90-6671-4d1d-90b1-9f334f770a28`
- **APK SHA-256:** `e885a076b3a1f39e40f7cacc603ea0aec2d30e7e44028511e6f3bc06be3986b9`
- **Verdict / Ledger State:** **`BLOCKED`** (`accepted: false`, `junit_pass: false`, `supervisor_stop: "RuntimeError"`)
- **HTTP Attempts Charged:** `8` (`attempts 22..29`; `71,962` prompt tokens, `632` completion tokens; `$0.022347` USD)

## Observed Execution & Failure Sequence

1. **Steps 1–6 (Real Catalog Filtering Executed):** Flash navigated Guest Home -> `Tìm gia sư` (`step-01..02.jpg`), typed `Thu Trang` (`step-03..04.jpg`), selected `Toán` filter chip (`step-05..06.jpg`), pressed `ENTER`, and pressed `BACK` (`step-06-post.jpg`) dismissing Gboard and showing `1 gia sư phù hợp`.
2. **Turn 7 Surface Relaunch -> Genuine ANR (`ErrorId: bd55a9a5-5f32-458c-8fd6-d865cec57632`):** Turn 7 observed a home transition and called `manage_app(launch, "BeeWise")` while the Windows host was concurrently running `flutter test` on `mobile/` (`task-1517`). Guest CPU pressure spiked (`some avg10=54.65`, `83%–97%` total guest CPU, `87%`/`128%` `com.beewise.beewise`, `68%` `system_server`).
3. **ANR Main-Thread Blocker:** DropBox `data_app_anr` (`anr-dropbox-excerpt.txt`) shows `Reason: Input dispatching timed out (Application does not have a focused window)` with main thread PID `9640` waiting on `pthread_cond_wait` inside `io.flutter.embedding.engine.FlutterJNI.nativeSurfaceCreated` (`FlutterSurfaceView$1.surfaceCreated`), followed by `Skipped 470 frames!` and `Displayed com.beewise.beewise/.MainActivity: +24s60ms` (`anr-logcat-excerpt.txt`).
4. **Supervisor Abort & Dialog Preservation:** `final_once.py` detected `am_anr` (`during-run-anr.txt`), sent remote cancel, and recorded `BLOCKED` in `final-artemis.sqlite`. The resulting OS `"BeeWise isn't responding"` modal was captured directly on device (`screen-after-anr.png`) before recovery.

## Causal Assessment & Operational Constraint

- Both a **genuine Flutter/Android surface-creation stall under heavy contention** (`FlutterJNI.nativeSurfaceCreated`) and **concurrent host `flutter test` CPU contention** contributed to this ANR; neither alone is falsified without an idle-host repeat.
- **Process rule enforced before subsequent admissions:** zero concurrent `flutter test`, `flutter analyze`, or Gradle tasks may run on the Windows host while live ARTEMIS tests execute on `emulator-5564`.
- Per Gate 3 Option B (`retry_admissions=0`), this slot (`2/3`) is consumed as `BLOCKED` in [`budget-proposal.json`](../../budget-proposal.json) and excluded from pass credit (`0/2` so far for `FINAL-F01`).
