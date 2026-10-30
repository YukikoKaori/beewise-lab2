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
