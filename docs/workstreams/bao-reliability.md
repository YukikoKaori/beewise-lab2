# Bao reliability corrective pass — 2026-10-31

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
