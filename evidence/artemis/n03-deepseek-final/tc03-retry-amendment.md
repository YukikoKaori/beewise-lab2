# TC-03 retry-policy amendment — PROPOSED, NOT APPROVED

Project: BeeWise N-03. Existing approved proposal SHA256:
`769b22c4dac2a6736953d2ba4daaa7dd433cbc61b15288680c939b30b115a141`.
This amendment requests no additional spending, request ceiling, expiry, matrix
change or historical-result rewrite. The rejected $5 allowance remains rejected.

## Existing results and diagnosis

TC-03: **1 accepted PASS, 3 FAIL** across four admitted sessions. All original
trace IDs, JUnit, screenshots and independent reviews remain in `run-manifest.json`.
The first two failures concern ineffective clipboard input / duplicated prefix;
the existing ASCII-native input correction has 182 ARTEMIS offline tests and a
subsequent genuine TC-03 PASS. The fourth session failed with Android ANR.

That ANR's main thread was in ProcessTextPlugin → PackageManager resource label
loading → ApkAssets.nativeLoad, with no focused window and +15.920s first draw.
Admission preceded first draw: a verified readiness gap. This stack proves the
blocking location, not an app business-logic defect, host-resource cause or
Flutter-wide defect. No production code was changed to hide it.

Normal restart of the **same** API35 AVD, no snapshots, unchanged software GPU /
2GB / two cores and preserved userdata yielded:

| Native measurement | Android displayed | Process → first Flutter raster | Result |
|---|---:|---:|---|
| Settled cold 01 | 6.097s | 5.868s | Focused guest Home; no new ANR |
| Settled cold 02 | 7.995s | 7.326s | Focused guest Home; no new ANR |
| Settled cold 03 | 5.615s | 5.329s | Focused guest Home; no new ANR |
| Same-process warm | am-start wall 0.453s | No new first-frame claim | Focused guest Home |

Settings opened in 0.976s. System UI shade round trip was 1.578s. Main thread
after each cold measurement was sleeping in `do_epoll_wait`. The boot log retains
a Google Messages ANR before these controlled attempts; it is not concealed.
Third-attempt host samples: CPU 20.8–82.5% (mean 45.77%), available RAM minimum
8,033,308,672 bytes. These samples do not establish resource causality.

Evidence: `native-stabilization-20261105/summary.json`, genuine native captures
and hashed private full-log/timeline inventory. Installed APK SHA256:
`e05a72de4ce063f70e7df6cd90c2fccb80e42a0c8befac0547bfdcd05b4405ed`;
unchanged `lib/main.dart`, isolated local Emulator/backend defines, source
`a72059ca5e07a4c1193960965dc07453efea161d`.
This is a scoped operational workaround. Sustained stability while inference is
running and the ultimate native root cause remain unproven.

## Corrective gate

Before any admission: online ADB, boot complete, actual rendered accessibility
content and focused BeeWise window, no active ANR, responsive System UI with
observed return to app, authorized demo fixture, local Auth/Firestore/backend
endpoints, required unconsumed workflow fixture, and idle ARTEMIS checked twice.
Failed preflight saves native evidence without admitting a session or inference.
No fixed startup delay, wipe, ANR suppression, app-source workaround or assertion
weakening. Seven new offline fault-injection tests cover this gate; synthetic
tests do not count as Android E2E.

## Exact requested amendment

Allow **at most TWO additional TC-03 admitted sessions**, each independently
reviewed, solely to obtain the two missing PASS executions. Stop TC-03 on the
first additional failure, ANR, invalid preflight or authorization ceiling.
No further TC-03 retry is authorized by this proposal. Preserve its original
1 PASS / 3 FAIL history. Other case retry policies and selected matrix unchanged.

At proposal time: 15 sessions, 10 PASS / 5 FAIL, 90 HTTP attempts,
865,654 SDK-reported tokens, **$0.2705439** conservative accounted cost.
Remaining hard allowance: **150 requests, $0.2294561, 21 sessions**, expiry
**2026-11-06T14:52:19.526760+00:00**. No ledger reset or expiry extension.
20 more accepted runs require at least 20 sessions: total **35** if all pass.
The existing 36-session / 6-failure ceilings remain upper bounds, not permission
for automatic retry or to continue through another blocking failure.

Past mean is 6 calls / $0.01803626 per admitted session. Extrapolating it gives
120 calls / **$0.3607252** for 20 sessions, more than remaining conservative cost.
Successful TC-03 alone cost $0.0183177; two similar runs cost about $0.0366354.
Other six cases have no empirical cost yet. **Completion within $0.2294561 is
not guaranteed.** Remaining sessions need mean ≤ $0.011472805 to fit; the
persistent pre-send guard must stop before exceeding the original ceiling.
Actual cache/off-peak reconstruction (~$0.0531 so far) does not replenish it.

Before resuming, perform an authorized read-only balance check and full preflight.
No provider call until this exact policy amendment is approved. No extra Gemini,
exploration, real payment, production mutation, Nexora use or top-up.
