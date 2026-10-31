## Google live verification follow-up — 2026-10-31 (current)

**B-01/B-03 PARTIALLY COMPLETE:** actual dedicated Google sign-in, parent
creation, signed-in Profile, process-death session restore, managed logout and
guest cold relaunch **PASS** on isolated `emulator-5558`, current same-signer
APK. Provider `google.com`, sign-in 08:17:19.108Z and parent creation
08:17:21.874249Z corroborate actual UI; Users metadata alone is not Auth proof.
Google installation appeared only under its owner after relaunch; managed logout
removed it while A/B registrations stayed empty and all parent records survived.
Initial automatic Google registration remained pending until relaunch: **OPEN**
reliability finding, consistent with earlier B retry. A transient role read after
the diagnostic crash failed closed; explicit retry restored Home/Profile.

**B-02:** exact approved SHA registration and additive Android OAuth config
verified; strict rules/index remain as previously authorized and deployed. No new
rules, provider, Storage, App Check or billing changes. Authenticated cross-UID
malicious client denial remains **NOT RUN**; IAM snapshots do not establish it.

**B-04:** new deliberate fatal received in actual Firebase Console at displayed
3:21:38 PM, Android 17 / version 0.1.0(1). Crashlytics Data > User ID hashes to
the dedicated Google UID alias; custom keys inspected. Broad browser metadata
ID matches were rejected; only the visible User ID leaf was compared. Fatal
persisted keys describe the prior nonfatal diagnostic, not its trigger. Google
Analytics method and logout UID-clear are **NOT VERIFIED**. Previously verified
five business Analytics event types remain five of seven; SDK events do not
close the gap. Native first-request spinner and stale callback failure retained;
fresh user-operated Google retry succeeded without credentials being collected.

**B-05:** formatter/analyzer PASS, Flutter **59/59**, Firebase Emulator rules
**28/28**, APK build/install PASS; application/config and prior evidence HEAD CI
3/3 PASS. Final evidence HEAD CI is checked after push. Original authenticated
screenshots are private on D; sanitized XML, metadata, screenshot hashes and
guest/error images are reviewable. Emulator debug/display/network settings restored.
No Nguyen UI/theme/router/ARTEMIS/review/final-presentation edits. Storage remains
**DEFERRED** for team discussion. App Check, trusted backend/payment/official
schedules, staging, physical device, ARTEMIS and external review remain
**BLOCKED/NOT RUN** as applicable. Overall **PARTIALLY COMPLETE**.

Primary receipt: `evidence/cloud/google-runtime-validation.json`; account
snapshots `evidence/cloud/google-user-*.json`; runtime `evidence/android/logs/google-*`.

# Analytics — actual Console follow-up 2026-10-31

**PARTIALLY COMPLETE.** Actual DebugView device `sdk_gphone64_x86_64` in
`beewise-lab-3` shows five distinct business event types across genuine flows:

| Event | Displayed Console time | Verified context/parameter |
|---|---|---|
| login | 11:01:53 AM | Prior actual B sign-in; `method=password` (method name only) |
| logout | 11:03:47 AM | Prior actual B managed logout |
| search | 11:26:03 AM | This turn guest TEST query; six labeled synthetic results |
| view_tutor | 11:27:01 AM | Actual tutor detail; `entry_source=profile_route` |
| ai_match_no_results | 11:28:37 AM | Actual guest prompt, synthetic-only catalog excluded; empty result |

Also observed SDK `screen_view`, `notification_foreground`, `notification_receive`.
These are not three additional business events. Top Events TOTAL is occurrence
count, not unique event types. Seven-business-event requirement is incomplete.
`sign_up`, `export_report`, UID set/clear and expanded search custom parameters
remain NOT RUN. Do not fabricate events to meet a count. Storage/export deferred
by user; no upload or new identity was attempted. Console times retain displayed
values without an assumed timezone. Native debug property restored after capture.

Receipts, original private PNG paths and verified hashes:
`../../cloud/console-runtime-validation.json`. Browser/account chrome makes raw
Console screenshots private on D; public native guest PNGs are under Android.
Prior mocks/privacy tests and management linkage are supporting evidence only.
