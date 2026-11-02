# Bảo initial cloud/Android audit

Audit date: 2026-10-30. Base independently fetched from `origin/main`:
`12f5322655463fd801d64e4925572d6a3a2bbb82` (PR #2 merge). Branch:
`feat/lab3-bao-cloud-runtime`. This records the starting state before service
changes; subsequent results belong in `bao-status.md` and evidence manifests.

Read: `PRODUCT.md`, `handoff/flutter-handoff.md`, design traceability,
architecture, analytics plan, backend contract, test plan, PR #2 lifecycle
review, Lab 3 report, README and `docs/BeeWise_Lab3_Task.md`. Inspected service,
model, provider/controller, Android, rules, test and CI source. The task document
contains stale premerge instructions; Nguyên-owned/shared documents also contain
historical claims and will be handed off rather than edited.

| Module | Starting classification | Evidence and action |
|---|---|---|
| A Core/App Check | IMPLEMENTED_UNVERIFIED | `firebase_bootstrap.dart`, `main.dart`: Android Firebase options and debug/Play Integrity activation; actual initialization and attestation not yet observed. Never enable enforcement in this task. |
| B Auth | UNIT_VERIFIED | `auth_service.dart`, `auth_service_test.dart`: parent profile retry and isolation tests in PR #2. Live providers/session unknown; no dedicated test identity supplied. User explicitly keeps authenticated live cases BLOCKED. |
| C Google Sign-In | BROKEN (configuration prerequisite) | `google-services.json` contains no OAuth client entries; `AuthService` uses `GoogleSignIn.initialize()` without explicit server client ID. Android plugin requires the web OAuth entry. Need authorized provider/SHA/support-email setup and a refreshed config for the SAME project. Do not invent client IDs or replace the project. |
| D Firestore | EMULATOR_VERIFIED (inherited) | Real active-tutor query in `tutor_repository.dart`; rules and 26 Firestore/Storage cases cover ownership, applicant separation, reciprocal batches, current/unexpired immutable responses and server-only payment/schedule. Rerun locally; deployed rules/data/indexes unknown. |
| E Storage/PDF | EMULATOR_VERIFIED (rules only) | `export_service.dart` builds tutor PDF and uploads to owner path; PDF/service tests absent. Success is currently inferred from stream completion without checking final state, so cancellation may be mistaken for success if an older object URL exists. Reproduce with SDK-shaped mocks before fixing. Bucket/plan unverified live; Spark is user-supplied context, not API evidence. |
| F FCM | UNIT_VERIFIED | `notification_service.dart`, `push_installation_registration.dart`, 28 inbox/lifecycle tests: journal, owner-only cleanup, quarantine, route/recipient/chat gates. Preserve PR #2 architecture. Native permission/delivery and Console sender remain unverified. |
| G Analytics | IMPLEMENTED_UNVERIFIED | `analytics_service.dart`, controllers/providers: 17 documented events, UID set/clear, telemetry errors isolated. Found `ConnectionController.submit` sending `tutor_id`, contradicting its privacy contract. Remove and regression-test the real caller. No DebugView receipt observed. |
| H Crashlytics | IMPLEMENTED_UNVERIFIED | Global Flutter/platform fatal handlers; handled error adapter, guest/UID and custom keys exist. No native crash/relaunch or Console receipt evidence. |
| I Remote Config | IMPLEMENTED_UNVERIFIED | Defaults/fetch and 3 behavior parameters exist. Numeric cloud values are unbounded; negative `ai_result_limit` reaches `Iterable.take` and can fail. Add bounded getters and tests. Five-minute fetch interval requires waiting/relaunching for cloud before/after; no rebuild is needed. |
| J AI Logic | IMPLEMENTED_UNVERIFIED | `matching_service.dart`: real active catalog, validated result IDs, no fabricated response. Backend/API terms, App Check and live model access unknown; do not accept terms or disable protection. |
| K Trusted workflow | NOT IMPLEMENTED (backend); EMULATOR_VERIFIED (client/rules) | `workflow_service.dart`, `backend-contract.md`: parent requests/responses exist, trusted consultant assignment/proposals/invoicing/payment/schedules do not. No approved provider/staff identity or deployment environment. Keep pending; no speculative VPS or fake verification. |
| L Android | IMPLEMENTED_UNVERIFIED (runtime) | D Flutter/JDK/SDK exist; AVD `BeeWise_API_37` was offline, started without creating/deleting an AVD. It now boots as `emulator-5554`, Android x86_64, physical 720×1280 at density 320. Existing package is not proof of latest source. Install/build/capture 360dp/412dp and restore display overrides. |
| M Tests/CI | UNIT_VERIFIED / EMULATOR_VERIFIED (inherited) | PR #2: 34 Flutter tests and 26 emulator tests. Workflow builds APK on PRs. Rerun final checks and verify the new PR HEAD, not the historical runs. |

## Management access and authorization

- Correct client project is `beewise-lab-3`; package `com.beewise.beewise`.
  Both committed config files agree. `beewise-8ba7c` is excluded.
- Desktop browser discovery fails before control with `failed to write kernel
  assets: The system cannot find the path specified. (os error 3)` in both CUA
  and Node computer-use runtimes, including retry. Playwright is available but
  opens a separate unauthenticated browser: the requested project URL redirects
  to Google sign-in. No cookies/profile secrets were inspected.
- Firebase CLI 15.34.1 exists in the D-backed dependencies. `login:list` shows
  one saved account, but `projects:list` returns `Failed to authenticate, have
  you run firebase login?`. Saved credentials are not usable authorization.
  No `gcloud` executable was discovered. User will reauthenticate CLI manually.
- User authorizes labeled test fixtures and temporary Remote Config changes
  with restoration. No authenticated test identity exists; do not create one.
  Rules deployment, billing changes, resource deletion and App Check enforcement
  are not authorized. No cloud mutation has occurred during this initial audit.

## Accepted work, proportional to the lab

1. Reproduce/fix the analytics identifier, unsafe numeric Remote Config and
   upload terminal-state issues without changing UI service signatures.
2. Add focused service tests including actual local PDF generation and error
   recovery; rerun existing security regressions rather than replace them.
3. Build/install/launch the real app, preserve original screenshots and sanitized
   logs at 360dp/412dp, exercise guest/error/recovery paths and hand off UI bugs.
4. Inspect/configure only the correct cloud project if authenticated management
   access becomes usable; record exact before/after/rollback. Continue independent
   emulator/local work if it remains blocked.
5. Update B-01..B-05 facts/progress in the explicitly allowed task Markdown and
   create dedicated manifests/status/workflow/UI handoff. Do not edit Nguyên's
   files or shared final deliverables; open one PR and do not merge.

Primary configuration references:
[Google Android auth](https://firebase.google.com/docs/auth/android/google-signin),
[Flutter Android Google plugin](https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in_android/README.md),
[Storage Flutter prerequisites](https://firebase.google.com/docs/storage/flutter/start),
[Remote Config Flutter](https://firebase.google.com/docs/remote-config/flutter/get-started).
