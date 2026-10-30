# Bảo cloud + Android status

**PARTIALLY COMPLETE**, 2026-10-30. Base fetched/verified:
`12f5322655463fd801d64e4925572d6a3a2bbb82`. Branch
`feat/lab3-bao-cloud-runtime`; app source/test/build commit `db1f12e`.
Later commits add only verification scripts, rules tests, evidence and documents;
the PR's latest full HEAD and CI receipts are reported in the PR/final handoff.

| Task | Status | Implementation and actual evidence | Remaining prerequisite |
|---|---|---|---|
| B-01 Android | PASS build/tool discovery; BLOCKED install; NOT RUN latest runtime | Real debug APK/hash and online API37 AVD; `evidence/android/` | Existing installed package has different signature; uninstall decision pending. Fresh D instance could not establish ADB. 360dp/412dp and runtime captures NOT RUN. |
| B-02 Auth/Firestore | PASS unit/emulator and live guest query; BLOCKED authenticated flows | Auth recovery, active-catalog server reads, role/ownership rules; `evidence/firebase/authentication/`, guest query/rules logs | No dedicated identity; Google config absent, SHA list empty; deployed rules drift and missing chat index need separate deployment authorization |
| B-03 six services | PASS local service/security regressions; BLOCKED live requirements | Three verified defects fixed; PDF + 11 new service tests, all notification protections preserved; `evidence/firebase/manifest.md` | Native delivery, real upload, 7 DebugView events, Crashlytics receipt and two visible cloud RC changes NOT RUN |
| B-04 trusted workflow | PASS client/security coverage; BLOCKED trusted end-to-end | Atomic requests/chats, current/expiring immutable responses, concurrent duplicate denial; `bao-workflow-status.md` | No trusted processor/staff identity/payment provider/deployment environment; live payment stays pending |
| B-05 evidence/handoff | PASS available evidence; incomplete live evidence explicitly BLOCKED | Initial audit, service/native manifests, honest red/green logs, UI handoff, updated task facts | Nguyên must obtain missing native/Console/E2E evidence before final submission |

## Audit disposition and changes

Initial A..M classifications and file references are in `bao-initial-audit.md`.
Core/App Check and AI Logic remain IMPLEMENTED_UNVERIFIED live. Auth/FCM are
UNIT_VERIFIED; Firestore/Storage security is EMULATOR_VERIFIED. Google Sign-In
has a BROKEN configuration prerequisite (no OAuth clients in committed JSON).
Analytics/Remote Config now have focused unit verification. Crashlytics remains
IMPLEMENTED_UNVERIFIED. Trusted backend is NOT IMPLEMENTED. Android build is
verified; latest runtime is BLOCKED. Live management reads and unauthenticated Firestore queries are now verified;
no mandatory service is claimed fully LIVE_VERIFIED on Android.

Existing integrations, Riverpod contracts and PR #2 ownership/route architecture
were retained. Changes are limited to:

- BAO-A01 `ddbdb44`: omit tutor document identifier from connection analytics.
- BAO-A02 `6c333ad`: bound cloud numeric limits, use safe defaults/model fallback.
- BAO-A03 `ae4ce9d`: require successful Storage terminal state, reject cancel/empty
  stream without returning a previous object's URL.
- `test/cloud_services_test.dart`: 11 tests, including real local PDF generation,
  mock Analytics/RC/Storage lifecycle and failure paths. Existing locked path
  provider interface promoted to a direct dev dependency; no version upgrade.
- Extra real-emulator concurrent duplicate-response test; D-drive check/native
  helpers and read-only management probe. No UI, production rules or backend
  authorization relaxation.

## Actual commands and results

PowerShell helper uses process-local D caches/temp/JDK/SDK; does not edit registry,
system PATH, billing, production data or installed tools. Logs/JSON receipts in
`evidence/cloud/checks/verified/` include exact commands/timestamps/source/exits.

| Check | Result | Exit |
|---|---|---:|
| `flutter pub get --enforce-lockfile` | PASS, pinned versions retained | 0 |
| `dart format --output=none --set-exit-if-changed .` | PASS | 0 |
| `flutter analyze` | PASS, no issues | 0 |
| `flutter test --reporter expanded` | PASS 45/45 | 0 |
| `npm --prefix firebase test` | PASS 27/27, isolated Firestore/Storage emulators | 0 |
| `flutter build apk --debug` | PASS, real APK on D | 0 |
| Latest APK install | BLOCKED signature mismatch | 1 |
| Latest launch/native/cloud/staging/ARTEMIS/external review | NOT RUN/BLOCKED as detailed in manifests | — |

The first red test attempt included a mock setup error; `corrected-red` contains
the three genuine baseline failures. An earlier analyzer run found one unnecessary
test import; fixed before `verified` passed. Early receipts identify the then-HEAD
but used uncommitted test/source changes; they are reproduction history, not clean
final-tree proof. Final app checks use clean app source `db1f12e`; the extra rules
case was uncommitted at its initial 27-case run and is committed for CI replay.
Raw logs were retained privately on D before UTF-8/newline normalization in Git.

## Console actions, external dependencies and handoff

Correct project is `beewise-lab-3`; never use `beewise-8ba7c`. Desktop browser
control remains unavailable. CLI access recovered and was verified at 16:03 UTC.
Read-only API/CLI receipts: `evidence/cloud/management-access.json`,
`config-inventory.json`, `live-management-state.json`. Email/password enabled;
Google provider returns CONFIGURATION_NOT_FOUND; no Android SHA/OAuth clients.
Firestore database is asia-southeast1, but deployed rules differ from PR #2 and
the repository's chats(parentId, updatedAt DESC) composite index is absent.
No Storage bucket; billing disabled; no active Storage rules release. Remote
Config template is empty. Analytics linked (one stream); App Check settings can
be read but this is not attestation proof. No Console screenshots/DebugView receipts.

User-authorized fixture creation succeeded: six `[TEST]` synthetic tutors, all
verified=false, namespace `bao-lab3-20261030`. Create-only development seeder cannot
overwrite or target another project. Public client SDK server queries returned 6
and 2 items without cache or IAM credentials; this is real Firestore query evidence,
not Android/Remote Config visible-behavior proof. Receipts: `fixture-actions.json`,
`guest-firestore-query.json`. Fixtures remain labeled; no automatic deletion.
No RC publish, billing change, rules/index deploy, resource deletion or enforcement
change occurred. RC original template/ETag retained privately on D; temporary
change was not executed while latest native app installation is blocked.
No account secrets were read/printed. See `console-actions.json`.

Required human/external actions: resolve test emulator install permission; finish
working Console control for receipt screenshots; provision dedicated test identities;
configure Google OAuth/support email/SHA, authorize safe rules/index deployment, resolve Storage plan blocker without automatic upgrade; capture real device
and Console behavior per service READMEs; authorize trusted staff/payment contract
and usable test deployment environment. No automated personal account login.

Task Markdown now corrects PR #2 merge/main/project facts and Bảo progress. Nguyên
ownership and task completion are untouched. `bao-ui-handoff.md` supplies reusable
paths and retest steps. Shared README/report/slides, ARTEMIS and independent review
deliverables were not edited. This branch is ready to review the three fixes and
local evidence; it is not overall Lab 3 completion or independent-review approval.
