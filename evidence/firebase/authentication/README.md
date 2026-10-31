> **2026-10-31 provisioning follow-up (current):** Owner provisioned dedicated users. Metadata-only API confirms two enabled password identities; no credentials requested. This confirms existence, not successful Auth. Live rules lack `tutorApplications/{uid}` and block post-auth role lookup. Strict frozen rules/index bundle passed 28/28 emulator tests; deployment awaits explicit owner permission. Parent login/profile/logout/session restore/two-account isolation remain NOT RUN. Google provider/SHA remain absent. See `../../cloud/auth-provisioning-readiness.json` and `../../../docs/workstreams/bao-deployment-plan.md`.

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
