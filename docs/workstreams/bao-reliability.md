## Stable API35 default-app verification — 2026-11-03 (current)

Fresh separate API35 Google APIs r9,2cores/2048MiB/software GPU/no snapshot,
old API37 userdata untouched. New default lib/main.dart APK1ccb8ea3… has three
controlled cold Home/no-ANR launches (new PIDs10296/10483/10686, am wall
7469/7391/8266ms); sampled Android main thread sleeps in do_epoll_wait. Last ANR
readback remains none since boot. Real360/412dp and native input/navigation PASS.
Warm samePID10686 wall328ms; diagnostic ADB loss prevents that dump's UI result,
with independent real Home/navigation follow-up. Do not call missing dumps PASS.

Explicit first-frame VM markers were observed on the same application tree's
earlier default APK: process→built9415.675ms/raster9862.530ms, under concurrent
host quality work, not a final-APK settled performance baseline. Large subsequent
trace transfers truncated/ADB went offline. Startup capture now makes tracing
opt-in, distinguishes engine/process clocks and generic later frames, and handles
truncation without aborting UI/ANR capture; four tests are in CI. No app bootstrap,
role/identity/FCM change, delay, ANR suppression, dialog hiding or data clear.

[Measurements, artifact hashes, actual widths and limits](../../evidence/cloud/bao-acceptance-20261103/README.md#android-startup-and-implementation).
Prior matched API37 minimal Flutter control and main-thread/ANR evidence below
remain relevant. Scoped conclusion: no reproducible BeeWise-only defect; controlled
runtime is acceptable, system/host-sensitive immediate API37 boot is not a universal
startup guarantee. Reopen with settled-device BeeWise-specific blocking/ANR trace;
release/physical parity is NOT RUN, rather than an indefinite emulator-only block.
App Check API DISABLED is separately verified and explains an AI prerequisite
failure, not a startup main-thread root cause. No service configuration changed.

# Bao reliability corrective pass

## Controlled startup comparison and PR assessment — 2026-11-01

**APPROVE_MERGE for the tested Lab 3 scope**, subject to the final exact-HEAD
GitHub Actions checks recorded in the PR. This supersedes the earlier blanket
startup merge blocker, without turning the four immediate-post-boot failures
into successful launches. Firebase/Analytics findings remain accepted for their
documented tested scope and were not reopened.

Fetched latest PR HEAD `d23bb905822a44e7003b6ae95c465f141e5caab1` and main
`12f5322655463fd801d64e4925572d6a3a2bbb82` before this continuation. Incoming
HEAD CI passed 3/3 in run `41309090759`. No production source change was needed.
The installed default `lib/main.dart` debug APK hash matches the built artifact:
`2d3ed39e8eb5a5604571e15ef20322a00058853f9f773dd92d6397af814edd65`.
The native VM reports no diagnostic probe extension.

The existing isolated API37 Play x86_64 AVD reused its userdata. Original AVD and
working Firebase configuration were untouched. WHPX, software GPU, two vCPUs and
effective 4096 MiB RAM were recorded. This controlled run used the headless
emulator GUI mode; Android still rendered real frames captured with screencap.
This is a host rendering difference from the previous visible-window boot runs,
so the comparison does not isolate one particular emulator or host component.
No background package disabling, ANR suppression, data clear or app startup
delay was introduced. Resolution was restored to 720×1600 after the 412dp check;
the AVD then shut down gracefully.

The emulator boot workload reached guest load 32.49 with host free memory falling
to about 4.1 GiB. A minimal unmodified Flutter counter app, built with the same SDK
and debug mode, took 9,173 ms to draw during that workload. Initial settling
required boot complete plus guest 1-minute load below 0.5 for three consecutive
15-second samples. Subsequent paired runs required two direct CPU samples with
at least 90% idle across both vCPUs and host available RAM above 2 GiB. Historical
load averages remained elevated after bursts despite direct CPU samples showing
idle; both measurements are retained, not silently equated.

| App / cold process run | Activity launch to draw | Process start to Android draw | Process start to first Flutter GPU raster complete |
|---|---:|---:|---:|
| BeeWise 1 | 7,145 ms | 7,070 ms | 6,875 ms |
| BeeWise 2 | 5,194 ms | 5,127 ms | 4,893 ms |
| BeeWise 3 | 4,516 ms | 4,563 ms | 4,429 ms |
| Flutter control 1 | 3,164 ms | 3,139 ms | 3,028 ms |
| Flutter control 2 | 3,526 ms | 3,449 ms | 3,297 ms |
| Flutter control 3 | 3,294 ms | 3,252 ms | 3,122 ms |

All six launches rendered the expected UI without ANR dialogs or post-marker
BeeWise/System UI/GMS ANRs in collected logs. Each had a newly started PID and
native Flutter first-frame confirmation. Android classified BeeWise run 3 WARM
because its task was retained; process lifecycle proves a new process, so it is
counted only as a **cold process** start. Android activity time, native process
time and Flutter timeline times are separate measurements. `/proc` CLK_TCK=100
and bracketed uptime/VM-clock calibration support the Flutter timing calculation.
Warm resume at 412dp reused PID 6448 and took 235 ms host wall time; no new
first-frame duration is asserted for that resume. The extra 412dp cold start
took 4,841 ms activity time and rendered Home. Genuine new 360dp/412dp screenshots,
per-run process/main-thread samples and integrity hashes are in
`evidence/android/pr3-controlled/manifest.json`.

Main-thread samples during launch show CPU execution/runnable states followed by
event-loop waits; post-launch state is S / `do_epoll_wait`. They do not establish
a permanent app lock. Kernel stack reads remain permission denied, so this is
not claimed as complete native stack attribution. The earlier complete System UI
ANR trace already documents long runnable wait during system initialization, and
the separate earlier AVD had GMS failure before BeeWise installation. Together
with the slower control boot and clean settled repeats, evidence supports
**emulator/host boot resource contention as a material cause of the remaining
startup observation**. It does not prove exclusive causality or a Flutter defect.
BeeWise has additional startup cost relative to the control; no reproducible
BeeWise-specific ANR/root-cause fix is demonstrated, so identity/bootstrap/FCM
behavior was not speculatively modified.

Actual Search-tab navigation succeeded in BeeWise runs 2 and 3 in the same PID;
the control counter visibly incremented in all three runs. The initial BeeWise
run's input helper hit promotional text instead of the tab, and the counter
helper looked for a text attribute although Flutter exposed a content-desc.
Original false heuristic receipts are preserved and distinguished from reviewed
native XML/screenshots; neither was counted as an application failure or mock PASS.

API35/36 images were not installed locally and no physical device was connected.
Release-mode and real hardware startup are NOT RUN. Immediate post-boot API37
startup remains a documented environmental limitation (earlier 36–57 second
draws/timeouts), not a claimed launch PASS or an indefinite blocker on this scoped
PR. Follow-up action: repeat these matched BeeWise/control measurements on an
already available API35/36 or physical device; reopen an application blocker if
BeeWise alone reproduces input ANR after the environment settles. No deployment
or release-wide startup guarantee is inferred from this scoped approval.

### Incoming 1010-file audit

`evidence/cloud/pr3-file-audit.json` inventories every incoming changed path,
size and hash. About 23.84 MB total, no file over 1 MiB, and 54 identical-byte
groups with 113 redundant copies (~2.27 MB). Those historical named receipts
remain linked rather than deleting unique evidence or claiming duplicate files
as independent proof. New complete native logs stay private with public hashes.
Text candidates were reviewed without exporting their values; no raw Auth UID,
private key, bearer credential or real password was found. All 104 PNGs were
visually surveyed; one historical test-email region was explicitly authorized
for local redaction. Both existing screenshot hash references were updated.
Earlier commits retain the test email; no secret-bearing history rewrite was
needed or performed. Synthetic fixture emails/passwords remain test data.

This continuation changes evidence and Bao workstream documentation only.
Verified FCM generation/journal/cross-UID/role behavior, Auth, Analytics,
Crashlytics and Remote Config remain unchanged. Storage DEFERRED. No billing,
Storage/App Check enforcement, backend expansion, Nguyen UI, ARTEMIS or report
implementation change. Final validation receipts: `evidence/cloud/checks/pr3-controlled/`.

## PR #3 continuation after Console recovery — 2026-11-01

Fetched HEAD `55b74ec201828fa6bd0cbc4260c092aed6fa34f1` and main
`12f5322655463fd801d64e4925572d6a3a2bbb82` before continuing. Production source
and the installed default APK remain unchanged. This section supersedes the
previous delivery's fresh-DebugView and terminated-tap blockers; immediate
post-boot startup still fails acceptance.

### DebugView correlation recovered

The actual Firebase DebugView is accessible again. Its timeline showed A logout
19:02:35, guest search 19:04:02, B identity assignment 19:04:51, B login 19:04:52,
B logout 19:05:50 and guest search 19:06:45 (November 1, Android local UTC+7).
Both guest search events were opened individually: their `query_length` values
4 and 3 match their exact native event timestamps/parameters. Genuine cropped
Console screenshots exclude identity values. The earlier A login was outside the
rolling 30-minute Console window and remains separately supported by its complete
native bundle; it is not claimed as a newly re-observed Console event.

**PASS tested native null clearing plus actual guest-event DebugView receipt.**
Both complete post-logout FA-SVC bundles have zero `_id` properties. Console's
Current User Properties and the selected guest event's User properties tab still
presented the last B value. That retained presentation is documented; its internal
cause and an event-level backend `user_id` export are not established. Do not infer
a new UID-bearing guest upload from that display, or claim that the display itself
cleared. No empty/dummy ID, Analytics data reset or identity behavior change.
See `evidence/cloud/pr3-debugview-correlation.json`. Firebase's
[DebugView documentation](https://firebase.google.com/docs/analytics/debugview)
distinguishes event parameters from current device properties, and the Android
[setUserId reference](https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics#setUserId(java.lang.String))
specifies that null removes the user ID. The evidence, rather than the Console
presentation alone, supports the scoped native conclusion.

### Immediate post-boot startup remains unresolved

Four fresh cold boots reused the same isolated AVD userdata and default APK, with
no low-load settle gate. The original AVD was not changed. All four activity starts
timed out; later first draws do not convert those failures into a PASS.

| Run | GPU / vCPUs | Marker after boot completed | Android first draw | System ANRs in collected log |
|---|---|---:|---:|---|
| boot-one | software / 2 | 16.52s | 52,706ms | System UI, Photos |
| boot-two | host / 2 | 12.63s | 56,541ms | System UI |
| boot-three | host / 4 | 3.85s | 36,610ms | None observed |
| boot-four | host, Vulkan disabled / 4 | 3.47s | 40,146ms | None observed |

The first two collections performed expensive dumps before launching. The new
optional `--immediate` collector mode moves those dumps after launch; the last two
therefore begin within four seconds of observed `sys.boot_completed=1`. No startup
sleep, ANR detection suppression, background-package disabling or dialog hiding
was used. The Vulkan toggle is an emulator experiment, not an application fix.

**Configuration correction:** the emulator explicitly increased requested
`-memory 2048` to **4096 MiB** in all four logs. The preceding `pr3-resume` stdout
also confirms this effective 4 GiB allocation; its manifest is corrected. Earlier
references to a 2 GB configuration describe the requested value. The obsolete
`-scale` launch flag is ignored by this emulator version; backed-up window
preferences were used to restore a fully visible window. No warning suppression
checkbox was selected.

A complete bugreport and 23 complete ANR trace artifacts were retained privately
with public hashes. The current System UI trace shows 16.93 seconds runnable wait
versus 1.22 seconds CPU on its main thread while initializing System UI. This
supports resource/scheduling pressure and is not an application deadlock trace.
No new BeeWise ANR appears in these collected boot logs; nevertheless, the app
main thread was sampled runnable and first draws took 36–57 seconds. Absence of
an app ANR does not establish acceptable startup. Kernel stack access was denied;
full logs, lifecycle, stat/wchan, and Flutter first-frame acknowledgements are
retained. Framework timing is not substituted for process-to-first-frame time.

Failed UI dumps exposed a collector defect: Android could leave a previous XML
file in place. The collector now records failure, avoids reading that file and
reports UI assertions as unknown. Earlier failed dumps in this follow-up are
explicitly marked non-authoritative; their real screenshots remain failure
evidence. No production app root cause was reproduced to justify a speculative
code change. See `evidence/cloud/pr3-completion-validation.json`.

### Terminated notification tap verified

After the user signed in A again, registration metadata showed only the expected
test installation owned by A. A normal background grace period followed by
`am kill` left PID 1724 absent in two samples before sending; no force-stop.
Unique probe `bao-pr3-terminated-1793537409160` displayed a real notification and
created native receiver PID 3796. A single tap on that observed notification body
was followed without manually navigating the app.

The first capture at 7.84 seconds still showed Home. At 12.84 seconds, the actual
Search page, search field, filters, tutor results and selected Search tab were
visible; the 18.47-second capture remained on Search in the same PID. **PASS actual
terminated delivery and tap route for this tested session.** This supersedes the
earlier initial-frame-only uncertainty; it does not assert the old capture proved
navigation or that every race is covered. Generation, journal, cross-UID and
fail-closed role checks remain unchanged. See
`evidence/android/pr3-completion/terminated-tap-sequence.json`.

Managed logout restored genuine guest UI, removed A's installation registration,
left other owners empty and preserved Parent records. Display overrides were
reset and the emulator stopped gracefully before validation. No userdata or
Analytics data was cleared. Credentials are absent from files/evidence/PR text.

Current merge readiness: **NOT MERGE READY**, because immediate post-boot startup
still fails. Fresh DebugView guest-event correlation and terminated tap route
are now verified within the limits above. No Storage/billing/bucket deployment,
App Check enforcement/backend expansion, Nguyen UI, ARTEMIS or report changes.
Local rerun receipts are under `evidence/cloud/checks/pr3-completion`; final SHA
and exact-head Actions results are recorded in existing PR #3 after push.

## PR #3 follow-up — 2026-11-01

Fetched PR HEAD `dd5be3aa7e71db62a744dc379c6de3d503a4c7a3` and main
`12f5322655463fd801d64e4925572d6a3a2bbb82` before this investigation. Work stays
on `feat/lab3-bao-cloud-runtime`; do not merge. The sections below dated October
31 are historical observations, superseded only where this follow-up supplies
stronger evidence.

The existing uncommitted October 31 startup/identity evidence was preserved and
audited against private originals. Six native Analytics receipts were rebuilt
from complete multi-process logcat; 76 private startup artifacts and 34 complete
ANR traces were checked/hashed. The older historical projection omitted the
now-allowlisted `entry_source=profile_route`; identity fields and event timing
agree. See `evidence/cloud/pr3-recovered-integrity.json`.

### Startup diagnosis

The complete original BeeWise ANR trace is now available privately, with a public
main-thread excerpt in `evidence/android/startup-uid/original-main-thread.txt`.
PID 20604 had an input focus timeout of 5,020 ms. Its main thread was sampled in
ART JNI transition / `MessageQueue.nativePollOnce` / Looper, with 21.44 seconds
scheduled CPU and 29.78 seconds runnable wait. Binding the application took
12,514 ms; activity dispatch took 32,661 ms. A later dialog referred to that old
PID after another process had started. This is not evidence of a second ANR in
the replacement process.

System-wide scheduling/ART/GMS contention is supported by the logs; a reproducible
application lock or Dart main blocking operation is not established. An idle
Looper sample can also be taken too late to reveal the original stall, so it
does not prove the application innocent. Android's diagnostic guidance explains
this limit: https://developer.android.com/topic/performance/anrs/diagnose-and-fix-anrs.
No speculative production change, startup delay, ANR suppression or dialog
masking was added.

The original isolated clean-control first launch timed out. Later settled
process launches drew in 4,604 / 4,550 / 4,837 ms; same-process resume waited
251 ms. Complete lifecycle logs also show GMS updating and killing the first
BeeWise process. A separate reboot overlapping a local build produced ANRs in
phone, System UI, GMS, keyboard and Launcher before BeeWise started. Those failed
and confounded runs remain in the manifest. Actual 360dp/412dp screenshots show
rendered Home for the scoped settled runs, not universal startup reliability.

### Analytics identity ordering and native behavior

`authStateProvider` serializes restored/auth-change users with `asyncMap`, awaits
`AnalyticsService.setUserId(uid-or-null)` and Crashlytics identity before exposing
the user. Managed logout logs `logout` while still signed in, detaches FCM, awaits
`setUserId(null)`, clears Crashlytics, then signs out of Firebase Auth. The subsequent
guest auth-state emission clears the ID again. Controllers also identify after
login/signup; their explicit login event precedes that explicit assignment, so
the observed login attribution is evidence for the tested sessions, not a proof
of every possible concurrent sign-in ordering.

The pinned firebase_analytics 13.0.1 Android Kotlin plugin passes nullable
`String?` directly to native `analytics.setUserId(userId)` on its executor. Its
Future acknowledges that call returning, not native worker execution or backend
receipt. The lifecycle tests deliberately check the Future/publication ordering;
they are not native SDK proof. Actual FA-SVC removal acknowledgements and complete
uploaded bundles supply the separate native evidence:

| Actual event on October 31 (Android local time) | Native uploaded identity |
|---|---|
| A login, 21:09:28.750 | A alias |
| A logout, 21:13:46.867 | A alias, expected pre-clear event |
| Guest search, 21:14:35.531 | No `_id` property |
| B login, 21:16:24.010 | B alias, different from A |
| B logout, 21:19:02.942 | B alias, expected pre-clear event |
| Guest view_tutor, 21:20:44.903 | No `_id` property |

FA-SVC records `User property removed: user_id(_id)` after both logouts. The
original disputed guest export at 16:24:00.283 also has no `_id` in its complete
native bundle. Thus the previously displayed DebugView User properties value
does not demonstrate that those guest events were sent with the prior UID.
App instance/session identity remains separate from optional Auth user ID.
No empty/dummy ID, Analytics reset or app-data clear was used.

The parser follows each service PID/TID and accepts absence only in a complete
bundle for this package. Tests reject truncated bundles and cross-process
identity contamination. Raw UIDs and payloads stay private; public receipts use
SHA-256 aliases. See `evidence/cloud/startup-uid-b-guest-native.json` and
`evidence/cloud/startup-uid-historical-native.json`. These show native upload
contents, not an event-level backend export. Firebase documents that identity
changes do not rewrite previously recorded events:
https://firebase.google.com/docs/analytics/userid.

### Current validation

Fresh format validation PASS; analyzer PASS; Flutter **66/66**; isolated Firebase
Emulator rules **28/28**; receipt-parser checks **4/4**. Native and mock evidence
are kept distinct. The first APK build on C failed with Kotlin incremental-cache
`different roots` errors against dependencies on D. Rebuilding the exact fetched
source in the existing clean D worktree passed. Both attempts are retained under
`evidence/cloud/checks/pr3-resume*`; no application configuration workaround was
committed. The Storage emulator tests are local only; Storage deployment remains
**DEFERRED**.

### Fresh default APK native run and remaining gates

The D build reproduced the exact default APK hash already tested on the clean
isolated control: `2d3ed39e8eb5a5604571e15ef20322a00058853f9f773dd92d6397af814edd65`.
It was installed with `adb install -r`; original and isolated AVD userdata were
preserved. The default entrypoint has no diagnostic probe VM extension.

On November 1, the immediate post-boot process start again timed out (14,328 ms
Android wait; 14,422 ms host wall). It later rendered Home. The Android system
was resource saturated before launch, with load around 35–42 on two vCPUs and
98% total CPU in the captured boot sample. These are retained failures/limitations.
They are not reclassified as a clean first-boot launch.

With the same APK, 2 GB/two-vCPU/software-GPU configuration and the system settled
(observed load 0.09 before the repeat), the controlled measurements were:

| Width | Process start → Android first draw | Warm resume host wall | Result |
|---|---:|---:|---|
| 360dp | 5,164 ms | 344 ms | Home rendered; no new ANR |
| 412dp | 5,466 ms | 422 ms | Home rendered; no new ANR |

Actual subsequent Search → Home taps changed the selected tab in the same PID
5254 without an ANR dialog. Post-marker complete logs contain no new BeeWise ANR;
`dumpsys activity lastanr` reports none since that boot. The sampled main thread
was sleeping (`S`, `do_epoll_wait`); its kernel stack was permission denied,
explicitly retained as a collection limit. Flutter acknowledged the first frame;
the 360dp framework initialization timeline spans 86.326 ms. This span is not the
full Android process-to-first-frame duration. These measurements support a
**scoped controlled startup PASS**, not a universal boot-time reliability claim.
See `evidence/android/pr3-resume/manifest.json` and its real 360dp/412dp screenshots.

The emulator window became offscreen during viewport resizing. After the user
requested recovery, only that AVD's window position/scale preferences were backed
up and adjusted; the same userdata was reopened. A host RAM compatibility warning
was observed, without selecting “never show again.” No ANR dialog or detector was
disabled. Display overrides and Analytics/FA debug properties were restored after
testing; the user-requested window position/scale is retained.

The user manually completed fresh A/B sign-ins and managed logouts, without sharing
credentials. The default APK's complete FA-SVC bundles now show:

| November 1 Android local upload time | Business event | Uploaded identity |
|---|---|---|
| 18:58:27.905 | A login | A alias |
| 19:02:35.803 | A logout | A alias, before clear |
| 19:04:03.341 | Genuine guest search | No `_id` |
| 19:04:52.657 | B login | Different B alias |
| 19:05:51.588 | B logout | B alias, before clear |
| 19:06:46.781 | Genuine guest search | No `_id` |

Native removal acknowledgements follow both logouts. New collection aliases Auth
UIDs in memory before saving, and omits credential-bearing lines. The immutable
aliased source hash and all six complete bundles are in
`evidence/cloud/pr3-identity-native-final.json`. IAM metadata separately confirms
installation ownership A → none → B → none, with Parent records preserved; it
does not replace native authentication or authorization proof.

**Native null clearing PASS for these tested sessions; fresh DebugView correlation
BLOCKED.** The embedded Firebase Analytics frame stayed blank after refresh. The
direct Analytics property page returned “Missing permissions”; the actual
screenshot is retained. This does not establish why the embedded frame failed.
No access request or permission/configuration change was made. An event-level
backend/BigQuery identity export is unavailable. No Analytics reset, empty/dummy
ID, UI-driven identity workaround or production identity change was added.

Fresh FCM background and terminated notifications both reached this actual default
APK. The first `am kill` was too early and left PID 2824 alive; its failed receipt
is retained. After the background grace period, PID 2824 was absent before the
terminated send. Delivery started receiver PID 3881 and displayed the unique test
notification. This was process termination, not Android force-stop. API HTTP 200,
notification screenshots, matching probe IDs and process lifecycle are correlated
in `evidence/cloud/pr3-followup-validation.json`. **Delivery PASS; terminated tap
route NOT VERIFIED:** the initial post-tap screenshot still shows Home/loading.
The earlier navbar-text route heuristic was discarded; it cannot establish Search
navigation. Existing generation/journal/cross-UID/fail-closed protections are
unchanged. Fresh native timeout/write-failure injection is NOT RUN.

Overall remains **NOT MERGE READY** because the required fresh DebugView correlation
is blocked. Startup sensitivity immediately after API37 boot remains documented;
no reproducible application blocking root cause was established to fix. Storage
is DEFERRED. No Nguyen UI, ARTEMIS, report, billing, bucket, enforcement or backend
expansion change was made. Final delivery SHA and exact-head Actions results are
recorded in the existing PR description after push; no new PR or merge.

Earlier APK comparison: **BLOCKED** on a separate fresh API37 AVD. Before
BeeWise was installed, GMS persistent ANR and sustained system load prevented
the controlled settle gate (240 seconds). The earlier candidate was never
installed over existing userdata; no known-working comparison is claimed. See
evidence/android/pr3-resume/earlier-comparison.json and
earlier-before-app-baseline.json. This is a separate system-resource failure,
not evidence of a Flutter defect.

## Historical corrective pass — 2026-10-31

Application source: `be2b44515af637db1c7ded6b94797d1cf4adc746`.
Main re-fetched and verified: `12f5322655463fd801d64e4925572d6a3a2bbb82`.
PR #3 remains open; no new PR or merge. Final delivery SHA/CI are in its description.

## FCM root cause and correction

The first-login regression was reproduced before the fix. An auth change starts
registration; AuthController's existing finally/retry starts another generation.
An old native `onRegistered` arrives while the current reconciliation is looking
up the role with no requested UID. Previously this queued `stopDelivery` behind
the new registration. It then revoked the current registration, leaving pending
without a Firestore ownership acknowledgement.

The corrected callback captures its generation and checks it again when queued
work executes. It revokes delivery only if that generation and guest state are
still current. Stale callbacks cannot assign an installation or revoke a newer
owner. A missing native acknowledgement now has a bounded 15-second deadline;
failure stops delivery, preserves the journal and exposes retry. No sleeps or
foreign-UID deletion were introduced. Registration method completion is not
treated as Firestore acknowledgement.

Actual native traces match the reproduced ordering:

| Authorized session | Stale callback ignored | Firestore acknowledged | Binary |
|---|---|---|---|
| Email/Password A | 16:02:30.378 | 16:02:30.624 | Default `lib/main.dart` |
| Email/Password B | 16:07:08.806 | 16:07:08.996 | Explicit debug probe entrypoint |
| Google test | 16:09:29.214 | 16:09:29.430 | Explicit debug probe entrypoint |

These are Android local log timestamps, 2026-10-31. The user completed each login
without pressing notification retry or restarting. Corresponding aliased server
snapshots show the installation only under the current owner. Actual targeted
A/B foreground notifications appeared in the inbox; A's tap navigated to Search.
Managed A/B/Google logout removed the installation; no other user's device was
deleted. The newly authorized signup also registered and cleaned up on logout.

Regression coverage includes first login during role lookup, account switches,
same-owner restart/journal reconciliation, late callbacks/writes, role-read errors,
failed registration/write retry, missing acknowledgement and sign-out cleanup.
Native timeout/write-failure injection and fresh background/terminated delivery
were NOT RUN on this source; unit coverage does not replace those scenarios.

## Fail-closed role recovery

AuthService, TutorApplicationService and push registration now request applicant
documents from `Source.server` with a bounded read. Cached nonexistence cannot
grant Parent access during an offline error. No authorization rules were changed.

The actual signed-in A session first established a server read, then both network
transports were disabled. The production role lookup returned `unavailable` with
`parentGranted=false`; Messages redirected to the account-check screen. After
network restoration, a fresh server read and the actual retry button returned to
Home. Targeted unit coverage also rejects cached-absence fallback.

## Actual authenticated authorization checks

The explicit debug-only `tool/bao_live_probe.dart` runs the normal app plus read
extensions. It is absent from the default entrypoint and cannot run outside debug.
The native Firebase Auth/Firestore SDK sessions made the authorization checks;
Firebase CLI IAM was used only to resolve approved aliases, never for the checks.

A→B, B→A and Google→A each successfully read their own Parent from the server,
then received `permission-denied` for foreign Parent, tutorApplication and device
query: **9/9 denied**. No foreign document data was exported or changed. Live
cross-UID writes are NOT RUN; the 28 local rules tests cover write negatives.

## Analytics and remaining verification failures

Seven distinct business event types now have actual DebugView receipts:
`login`, `logout`, `search`, `view_tutor`, `ai_match_no_results`, `sign_up`,
`export_report`. The first five retain their earlier receipts. This pass verifies
Google `login(method=google)` at displayed 4:09:27 PM, actual owner-authorized
Parent `sign_up(method=password, account_type=parent)` at 4:15:01 PM, and guest
`export_report(subject_count=1, file_size_kb=16)` at 4:24:01 PM. Source is the
application SHA above. Screenshots, timestamps and hashes are in the manifest;
authenticated Console originals remain private on D.

Exactly one dedicated signup was authorized and created by the user. Its labeled
Parent remains preserved. The local guest PDF is genuine, 16,419 bytes with a PDF
header. The guest auth gate runs before upload, so Storage remains DEFERRED.

**UID-clear acceptance is NOT VERIFIED:** despite managed logout reaching guest
and FCM removal, DebugView's User properties for the later guest export still
displayed the prior dedicated signup UID. This is retained as a failed acceptance
observation. The code awaits `setUserId(null)` before Auth sign-out; whether the
Console shows historical properties or collection attribution is not established.
No speculative SDK changes or successful-clear claim were made.

**Final default APK cold start is not clean:** same-signer install succeeded, but
the API37 emulator exhibited a real blank startup and input-dispatch ANR (focus
timeout 5,020 ms, displayed 16:29:15). Relaunch eventually rendered Home behind
the ANR dialog. The native main stack in DropBox was truncated; root cause is not
proven. Blank/ANR screenshots and logcat are retained. Final 360/412 captures are
failure evidence, not responsive/runtime PASS. Earlier default A runtime remains
valid within its tested session. No uninstall/data clear was used.

## Gates and handoff

Formatter 33 files/0 changes, analyzer no issues, Flutter **64/64**, isolated
Firebase Emulator rules **28/28**, default APK and explicit probe APK builds PASS.
The invocation receipts retain their precommit HEAD plus working fixes; those
fixes became the application SHA above. Initial analyzer lint failure is retained
separately from the passing final run. Application HEAD CI passed 3/3:
https://github.com/YukikoKaori/beewise-lab2/actions/runs/41186750700.
Delivery HEAD checks are verified after the evidence commit is pushed.

Existing approved strict rules/index, SHA/OAuth, actual Crashlytics and Remote
Config evidence are preserved. No shared deployment/config change occurred in
this corrective pass. Storage DEFERRED; App Check/staging/trusted payment/provider
and official schedule dependencies remain BLOCKED/out of scope. Physical hardware,
ARTEMIS runtime and external human review remain NOT RUN. CI harness collection
does not establish ARTEMIS runtime. Nguyen-owned files were not changed.

Overall: **PARTIALLY COMPLETE; NOT MERGE READY**. The remaining native startup and
Analytics identity observations need resolution/verification before claiming a
clean integration handoff. See `evidence/cloud/reliability-validation.json`.
