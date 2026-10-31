# Firebase evidence index — Bao

## 2026-10-31 Auth provisioning follow-up (current)

Two enabled Password identities exist, verified through metadata-only API fields;
no passwords, emails, hashes or tokens requested or stored. This supersedes prior
"identity absent" blockers below. **Actual Auth login/profile/logout/session
restore/cross-account isolation: NOT RUN**, pending explicit owner authorization
and completion of the strict Firestore deployment, then user-entered device login.
Deployed `tutorApplications/{uid}` match is missing; repository rules are strict
and already contain it. Readiness and exact frozen deployment receipts are in
`../cloud/auth-provisioning-readiness.json` and
`../cloud/prepared-firestore-deployment.json`.

Fresh checks: original rules **27/27**, extended rules **28/28** (also exact frozen
bundle), Flutter **53/53**, formatter/analyzer PASS. These are local checks.
Read-only live service audit refreshed in `../cloud/live-management-state.json`:
Google provider/SHA absent; no Storage bucket/release; billing disabled;
Analytics linkage is not DebugView; Crashlytics Console receipt and authenticated
FCM delivery remain NOT RUN/BLOCKED. Previous RC roundtrip restored empty version
2; no new live mutation. Six existing labeled synthetic tutors re-audited and
preserved. New native guest receipts: `../android/auth-ready-runtime.json`.

## Previous corrective delivery (historical)

2026-10-31 local; project `beewise-lab-3`, package `com.beewise.beewise`.
App source `9ef5907b2d296fcdafaa869a53e9780692f4cc56`.
Local checks: `../cloud/checks/corrective-final/`. Rules use `demo-beewise` only.

| Service | Actual device/cloud verification | Remaining blocker |
|---|---|---|
| Authentication | Live management configuration read; guest app state observed; unit/rules PASS | Dedicated identity absent; Google provider/SHA absent; sign-in/out/account switching NOT RUN live |
| Storage | Real local PDF + upload mocks + owner/type/size emulator PASS | No live bucket, billing disabled, no identity; upload/URL/Console NOT RUN |
| FCM | Native Android notification permission requested and allowed; guest inbox empty; ownership/routes unit/emulator PASS | No authenticated receiver/sender; foreground/background/terminated delivery and live account switching NOT RUN |
| Analytics | Native SDK initialized; guest navigation exercised; project linked; privacy mocks PASS | Seven meaningful events in DebugView NOT RUN; no Console evidence |
| Crashlytics | Device log records handled diagnostic; intentional native SDK crash and relaunch exercised | Console receipt/user/custom-key association NOT RUN; guest diagnostic is not a real business-flow failure |
| Remote Config | LIVE_VERIFIED API publish/restore and same-APK visible gate/limits; original restored to empty version 2 | Console screenshots NOT RUN; native restore confirmation documented in Android manifest |

Actual PNG/PID evidence: `../android/README.md`; RC receipts:
`../cloud/remote-config-roundtrip.json`. Never substitute mocks or a snackbar for
server receipt. Supporting Core initialized on device; App Check management reads
are not attestation proof; no paid AI request was made.

Deployed rules still drift and composite index is missing; no deployment was
authorized. See `firestore/README.md` and
`../../docs/workstreams/bao-deployment-plan.md`. Six fixed tutor IDs were audited
from the real server, all labeled/synthetic/active/unverified. They remain preserved.
Model now enforces labels and excludes synthetic data from AI. No genuine tutor
endorsement is asserted. No Console screenshot: native browser tools fail before
control; isolated browser lacks an authenticated session. Credentials never copied.
