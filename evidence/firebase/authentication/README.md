> **2026-10-31 provisioning follow-up (current):** Owner provisioned dedicated users. Metadata-only API confirms two enabled password identities; no credentials requested. This confirms existence, not successful Auth. Live rules lack `tutorApplications/{uid}` and block post-auth role lookup. Strict frozen rules/index bundle passed 28/28 emulator tests; deployment awaits explicit owner permission. Parent login/profile/logout/session restore/two-account isolation remain NOT RUN. Google provider/SHA remain absent. See `../../cloud/auth-provisioning-readiness.json` and `../../../docs/workstreams/bao-deployment-plan.md`.

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

Current regressions: 6/6 focused Auth mocks, 53/53 full Flutter tests, original
27/27 and extended 28/28 rules tests PASS. Client preserves role-check denial;
no permission-denied bypass or account deletion was introduced. Current device
remains a guest; no Users-list result is counted as a live login.

Historical evidence below predates provisioning.

# Authentication

Implementation: `lib/services/auth_service.dart`, `tutor_application_service.dart`,
`lib/viewmodels/controllers.dart`, `app_providers.dart`.
Source: `db1f12e`; commands/results: `../../cloud/checks/verified/flutter-test.*`
and `rules-test.*`. PASS: 3 Auth unit recovery/isolation tests plus owner/applicant
rules. Live register/login/logout/session/profile recovery: BLOCKED because user
explicitly has no dedicated test identity. Do not use a personal Google account.

Live API: Email/password enabled; anonymous disabled; Google provider GET returns
404 CONFIGURATION_NOT_FOUND. Registered Android SHA list is empty and refreshed
SDK config still has no OAuth clients. Users/Console screenshots: NOT RUN. Committed
`android/app/google-services.json` has no OAuth clients; do not claim Google login
works. External action: use authenticated CLI/working Console; inspect only
`beewise-lab-3`, confirm Email/Password and Google provider/support email, compare
debug/release SHA-1/SHA-256 with registered app, download refreshed config for the
same app if needed. Then rerun native Google picker/cancel and dedicated identity
flows, including cross-account private state. No credentials belong in evidence.
