# Bao finalization evidence — actual run 2026-11-03

**Bao scope / B-03.2: PARTIALLY VERIFIED.** This final handoff preserves the
already verified cloud roundtrip/security and completes independently achievable
documentation/quality work. It does not turn emulator infrastructure failures,
unit tests or native event logging into missing native/Console PASS results.

Source tested: `b45bdce4d3a68006a28ca8e587fdece0187a8660` (PR #11 merge, current
fetched main). This branch changes only docs/evidence. Final delivery PR contains
its exact final HEAD and fresh Actions result; baseline CI is not final-HEAD CI.

## What is new

- `baseline.json`: PR #11 independently MERGED, main SHA, no open PRs before
  this delivery; baseline CI all three jobs success.
- `quality.json`: fresh pub/format/analyze, **95/95 Flutter**, **58/58 rules**,
  default APK build and **27-function harness structure** PASS. These are separate
  layers; no Android ARTEMIS scenario was run.
- `native-install.json`: default `lib/main.dart` APK built and installed `-r`,
  same signer, data preserved. SHA
  `9f24102645ef0adada294a8f1a113e21c9ad2a88a822e461c758eb6354ed47f3`.
- `baseline-environment.json`, `initial-system-ui-anr.*`, `recovered-home.*`:
  resumed System UI failure, ordinary Wait/retry recovery before APK update.
- `android-startup.json`, `fresh-apk-pixel-launcher-anr.*`,
  `final-pixel-launcher-anr.*`: real failed default launch, repeated launcher
  failure and lifecycle excerpt. `am start -W` timeout 14,293ms; later Android
  Displayed/Fully drawn +16,849ms. Flutter first frame not independently measured.
  A later sleeping main-thread sample and responsive Dart VM do not establish
  absence of an earlier app stall. No reproducible BeeWise-specific defect/fix.
- `local-pdf-generation.json`: **fresh real 19,315-byte local PDF**, header
  `%PDF-1.5`, SHA
  `65a7012cea92b52d7971558e5e14c8cae07c6e433cc3e20217aef7c7f50f1bdb`.
  Attached debugger invoked the actual production ReportController with actual
  loaded tutor/app container, without hot reload/source/entrypoint replacement.
  Guest context after B managed logout; A login input was dropped/rejected.
  No cloud save, no fake success state, no fresh UI walkthrough PASS.
- `native-observations.json`: FA-SVC actually logged `export_report` at device
  13:50:29.902, `subject_count=2`, `file_size_kb=18`; no direct synthetic event call.
- `analytics-console.json`: current durable export parameter receipt **NOT
  VERIFIED**. Initially DebugView loaded with 0 devices/stale timeline; after new
  event the refreshed iframe and its observed source URL became blank. No visible
  permission-denied error. Private genuine blank capture hashed; not published as
  an event screenshot. Historical upload receipt remains valid.
- `cleanup-and-environment.json`: final ANR is **NexusLauncher**; point-in-time
  load/memory/main-thread samples; full raw-log hash/size (raw stays private).
  Exact three debug property readbacks restored, WiFi/mobile 1/1 unchanged,
  no network impairment this run, own collector stopped, debugger detached.
  ANR still visible, no suppression/clearing. Local ARTEMIS status/device endpoints
  unreachable; no physical device available.
- `acceptance-matrix.json`: expected/actual/environment/source/status/evidence/
  limitations for TC-PDF-01…05, explicitly separated by proof layer.
- `files.json`: exact byte hashes of this small package (excluding itself).

## Historical evidence retained, not duplicated or rerun

[Immutable PR #11 package](https://github.com/YukikoKaori/beewise-lab2/tree/b45bdce4d3a68006a28ca8e587fdece0187a8660/evidence/cloud/firestore-reports/live-20261103)
contains real native generation/save/forced server read/download/Print preview,
authenticated Client SDK ownership/immutability/invalid-input checks, Console
metadata, approved demo policy and `upload_report` DebugView screenshot.
Historical original/download/server PDF hash
`8e8d5f2f2c565c45c00081afb944f69f0aa1151f754dfa6e1617aa5286ad0bfe`
is distinct from the new local-only file hash above. A=2/B=2 inventory belongs to
that historical run, not a newly executed inventory. No new cloud report,
catalog/Auth-account/rules/index/deployment or other business write was performed
by this finalization workflow.

| Case | Status and scope |
|---|---|
| TC-PDF-01 | PASS historical native UI + new instrumented local generation; fresh UI blocked |
| TC-PDF-02 | PASS historical native server acknowledgement/readback and owner security |
| TC-PDF-03 | PASS historical real download/decode/hash/preview |
| TC-PDF-04 | PASS tested historical isolation/immediate reset; eventual impaired-network settlement still limited |
| TC-PDF-05 | NOT VERIFIED as a whole: offline/error recovery proven historically, distinct native 30s timeout/retry and guest-save UX not proven |

Default timeout remains 30s. SDK `unavailable` is not `TimeoutException`. Current
unstable launcher did not allow reliable existing-report selection/baseline, and
no report history picker exists after restart. We stopped stress; did not seed
saved state, create another report or shorten the production deadline. Unit
deadline/retry coverage stays separate. The PR #11 failed JS offline simulation
and its extra valid A-private report remain disclosed and preserved.

## Execution handoff and review decision

[Complete Nguyen guide](../../../../docs/workstreams/bao-to-nguyen-final-handoff.md)
includes exact UI/build steps, accounts/roles privacy, per-service evidence,
ARTEMIS case prerequisites, stable-device fallback, two remaining evidence tasks,
ownership and video checklist. Native repeatable startup and export Console
parameters remain follow-ups with concrete procedures, not reasons to invent an
application fix or keep retrying this AVD indefinitely.

**Reviewable scoped documentation/evidence handoff; not full B-03.2 acceptance or
Lab 3 completion.** No production change was justified. Nguyen's ≥10 official
cases ×3, 15–30 minute exploration, remaining UI/accessibility, slide PDF and final
video/links retain their own statuses. N-04 owner-confirmed approval is preserved.
No Storage/billing/App Check/backend expansion, deployment or auto merge.

Privacy: images are actual ADB captures with documented rectangular redactions
where necessary; no AI reconstruction. APKs, PDFs, Base64, raw logs, credentials,
email/raw UID/token content remain outside Git. Hashes refer to bytes preserved
by this directory's `.gitattributes`; historical evidence is untouched.
