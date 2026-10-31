> **2026-10-31 corrective update (supersedes prior runtime status):** Native update: notification permission requested and allowed on isolated API37; guest inbox empty. Authenticated receiver/sender unavailable, so foreground/background/terminated delivery and live account-switch protection remain NOT RUN/BLOCKED. Existing mocked lifecycle/security tests pass; these are not live delivery proof.

## Approved deployment and actual Android follow-up — 2026-10-31

**PARTIALLY COMPLETE.** Owner approved the exact frozen strict Firestore bundle.
28/28 emulator tests rerun PASS before deploy. Additive chats index reached READY
before rules release; both deploy commands exited 0. Active ruleset
`2aff57c1-3693-4bfa-9cd2-d77471ef08d6` matches repository normalized SHA-256
`759a35e408204bff48dac1f380009b76a661b39c4f649d809322643c616f6578`.
Missing own `tutorApplications/{uid}` lookup is now present. No Storage/provider/
billing change, weak rollback, record deletion or rules weakening was performed.

Actual Email/Password account A login after release created its parent profile;
force-stop/relaunch restored the SDK session. This exposed a real blank-name
Profile crash. Owner authorized exactly the fallback exception: six regressions
PASS (three failed before correction), full Flutter 59/59, format/analyzer and
debug APK build PASS. Same-signer install `-r` preserved A's data. Source APK
`9657d1b2f0c57a425298aab58fefbccb7119ac47`, SHA-256
`c963e08a7684c54bbc0893524a9a6e9168a38350b9fdfe08ff9475eeb4ef2701`.
Fixed restored Profile and managed logout PASS; A's own device registration was
removed and guest inbox emptied. B account-switch validation follows separately.

Real FCM API sends plus exact probe IDs on device establish foreground receipt,
background notification/tap and verified process-death notification/cold-start
Search routing. Malformed URL and inaccessible chat taps keep Profile visible.
An earlier terminated attempt retained its PID and is explicitly NOT counted.
API acceptance alone is never treated as delivery. Original authenticated PNGs
remain private on D; sanitized XML/logs and non-identifying screenshots are public.

Google provider became enabled externally and owner-supplied web OAuth config
was preserved separately; Android SHA registration/Google runtime remain BLOCKED.
No Storage bucket/release; billing disabled. Analytics DebugView/Crashlytics
Console receipts, staging, trusted payment/staff backend, ARTEMIS and external
review remain NOT RUN/BLOCKED. Previous live Remote Config publish/restore remains
valid; all six labeled synthetic tutor records remain preserved and unverified.

Receipts: `evidence/cloud/authorized-deploy-*.json`, `firestore-release-state.json`,
`test-users-*.json`, `fcm-*.json`, `checks/authorized-profile-final/`, and
`evidence/android/logs/auth-*`. Four real unauthenticated private reads were
denied; those and IAM snapshots are not authenticated cross-UID client tests.

## Earlier evidence (historical; superseded where stated above)

# Cloud Messaging

Implementation: `notification_service.dart`, `push_installation_registration.dart`,
shared validated route parser and UI's existing `routeForNotification` consumer.
App source `db1f12e`; PASS preserved PR #2 unit tests for sign-out/account switch,
rotation, failed writes/retry, journal recovery/quarantine, owner-only cleanup,
stale async callbacks, malformed/missing/cross-account routes and chat ownership.
Rules suite also checks FID owner bindings. Results: `../../cloud/checks/verified/`.

Android permission state and guest restart are native-only observations in
`../../android/`; they do not prove delivery. Foreground/background/terminated
push, inbox/tap from real message, live token rotation and account switch: NOT RUN /
BLOCKED (no dedicated receiver identity or authenticated Console sender).
No registration was deleted under another UID. Do not expose FCM/App Check tokens.

External action: dedicated parent identity, authorized Android permission, register
receiver successfully, send non-sensitive recipient-scoped test messages from
`beewise-lab-3`, observe each process state and tap, sign out/switch/rotate/restart,
verify Firestore ownership and retry. Keep sender credentials private.
