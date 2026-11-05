# Native failure receipt — TC-03 attempt 04

API35, AVD `BeeWise_Bao_Acceptance_API35`, preserved userdata, emulator APK
`e05a72de4ce063f70e7df6cd90c2fccb80e42a0c8befac0547bfdcd05b4405ed`.
Trace `a1dfdebe-5098-4c0d-a9da-022c486f0b38` is **FAIL**, not a startup PASS.

Android local time UTC+7 on 2026-11-05:

- Activity start: 22:30:34. Agent admitted at 15:30:36.572 UTC without a focused
  first-draw readiness gate. This is a harness admission gap.
- 22:30:48.324: native ANR reason **Input dispatching timed out (Application
  does not have a focused window)**.
- 22:30:50.331: ActivityTaskManager `Displayed` +15s920ms; `Fully drawn`
  +15s920ms. This is Android timing, not a separate measured Flutter-frame metric.
- Trace screenshots retain the actual “BeeWise isn't responding” dialog,
  especially `runs/tc03-attempt-04/step-04.jpg`. Agent actions include dialog
  interactions before its failed report; these do not constitute clean startup.
  The current native ANR dialog still owns focus at the final read-only probe.
- Managed main thread is in Flutter `ProcessTextPlugin.queryTextActions`,
  resolving installed package labels/resources through `ApkAssets.nativeLoad`.
  See the genuine sanitized [main-thread excerpt](native-anr-main-thread.txt).

Host snapshot after the run: CPU 65%, available memory 6.28 GiB. Guest CPU
snapshot covering 22:30:53–22:31:16: app16%, system_server11%, graphics composer
9.1%, SurfaceFlinger6.2%; guest load3.18/1.68/1.04. These snapshots do not prove
the causal load at every instant. One stack sample locates work, not its cause.
No minimal-control comparison or independently settled repeat was performed
after this failure. Neither a Flutter defect nor host-only contention is proven.

Private complete logcat, last-ANR lifecycle, CPU/memory/process snapshots,
DropBox ANR dump and native screenshot are retained outside Git. Their immutable
size/hash receipts are in `private-anr-receipts.json`. Direct `/data/anr` file
read was denied; DropBox provided the managed/native thread dump without root.
No emulator wipe, root-mode switch, security change, ANR suppression or app fix.

Paid execution stopped. New offline-tested admission checks require boot
complete, focused app window and genuine rendered content and reject native
ANR dialogs before admitting a paid session. The current native probe correctly
rejects this dialog state. This is a preflight improvement, not a claim that
the underlying startup issue is fixed.

Actionable next native work, without provider requests: preserve the dialog,
compare a settled launch/current app with a minimal control under measured host
load, collect first draw and ProcessText/resource-loading stacks, then decide
whether an app/framework correction is reproducible. Reattempting TC-03 also
requires an explicit retry-policy amendment; the existing ledger must persist.
