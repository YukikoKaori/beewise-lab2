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
