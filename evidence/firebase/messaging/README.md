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
