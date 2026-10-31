# Firebase evidence index — Bao

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
