# Firestore reviewed deployment and secure repair plan

## Owner-authorized release — 2026-10-31 (current)

Owner explicitly approved the exact frozen rules + additive chat index bundle.
All frozen hashes and live baseline were rechecked; the frozen emulator suite
passed **28/28 again before deployment**. Index deployment exited 0, its state
was observed CREATING then **READY** before rules deployment. Rules deployment
then exited 0. Post-release API read verifies:

- Active ruleset `projects/beewise-lab-3/rulesets/2aff57c1-3693-4bfa-9cd2-d77471ef08d6`.
- Normalized rules hash `759a35e408204bff48dac1f380009b76a661b39c4f649d809322643c616f6578`, matching repository/frozen rules; application match present.
- Exactly one `chats(parentId ASC, updatedAt DESC)` COLLECTION index, READY;
  Firestore's automatic `__name__ DESC` suffix is expected.

Actual CLI receipts: `evidence/cloud/authorized-deploy-indexes.json`,
`authorized-deploy-rules.json`; READY-before-rules receipt:
`authorized-pre-rules-state.json`; current post-release:
`firestore-release-state.json`. No Storage/provider/billing change was made by
these commands; no fixture deletion and no rollback. A later external Google
provider enablement was observed read-only, not performed by this deployment.

Account A login after release created its parent profile; a cold-start restored
its SDK session and registered its device. Authenticated Profile exposed an
empty-display-name UI crash; owner separately authorized only the fallback fix
and regression. Further runtime results belong in the Auth/native manifests.
Metadata alone remains insufficient to claim client authorization or live Auth.

## Reviewed preparation (historical baseline; executed as recorded above)

## 2026-10-31 Auth provisioning follow-up: concrete reviewed bundle

Two enabled Password identities now exist (metadata-only; no credentials requested
or login attempted). Live ruleset `14c0a112-21ce-4077-876b-fa6a298db91c` has **no
`tutorApplications/{uid}` match**. `auth_service.dart` authenticates, then reads
that own document before creating/reconciling a parent. Missing collection data
does not grant read access: this lookup is denied by deployed rules even when the
document does not exist. Auth state alone is therefore not successful onboarding.
Keep the client role check; do not convert permission-denied into "not applicant".

Repository rules already contain strict owner-only application reads and guarded
pending creation; no production rule weakening or client workaround is needed.
The original **27/27** emulator suite passed; new missing-document/cross-UID
bootstrap regression makes **28/28**, also PASS on the exact frozen bundle.
Three new Auth unit tests verify sequencing, role-denial fail-closed behavior and
applicant separation (6/6 focused Auth tests). These are not live Auth evidence.

Frozen directory on D:
`D:/CodexTemp/beewise-lab3-tools/bao-cloud-private/firestore-auth-bootstrap-20261031`.
Reviewable manifest: `evidence/cloud/prepared-firestore-deployment.json`.
Rules normalized SHA-256:
`759a35e408204bff48dac1f380009b76a661b39c4f649d809322643c616f6578`.
Exact-file SHA-256:
`c1dad4250814abcf0c80adb940dc612dbee133db0e80574fd0d055c5dcf86bb8`.
Baseline live hash:
`be6beebec1e872de3f89163f4623ea020af3be698482c22ae8e1049463865448`.
Fresh index inventory has no indexes or field overrides; proposed config adds only
`chats(parentId ASC, updatedAt DESC)`. Preserve the frozen file hashes; stop if
either live rules release/hash or index inventory changes before execution.

Preparation and verification commands (no shared writes):

```powershell
python scripts/prepare-bao-firestore-deployment.py
# Preparation refuses overwrite of an existing frozen bundle.
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-bao-firestore-bundle.ps1
```

**Owner authorization for this exact bundle was subsequently granted.** The reviewed execution sequence was:
recheck live release/hash/indexes and frozen hashes, then execute exactly:

```powershell
& .\firebase\node_modules\.bin\firebase.cmd deploy --only firestore:indexes --project beewise-lab-3 --config D:/CodexTemp/beewise-lab3-tools/bao-cloud-private/firestore-auth-bootstrap-20261031/firebase.deploy.json --non-interactive
if ($LASTEXITCODE -ne 0) { throw 'Index deployment failed; stop.' }
node scripts/inspect-bao-cloud-state.cjs
# Require the new chats index state READY before continuing.
& .\firebase\node_modules\.bin\firebase.cmd deploy --only firestore:rules --project beewise-lab-3 --config D:/CodexTemp/beewise-lab3-tools/bao-cloud-private/firestore-auth-bootstrap-20261031/firebase.deploy.json --non-interactive
if ($LASTEXITCODE -ne 0) { throw 'Rules deployment failed; inspect release before any retry.' }
node scripts/inspect-bao-auth-readiness.cjs
node scripts/inspect-bao-cloud-state.cjs
```

Require active rules hash matching the frozen repository hash, application match
present, index READY, and isolated-device live tests. Owner/user enters Password
test login directly on the emulator; never request, print or store passwords.
Do not capture the password form while credentials are entered. Parent document
creation, logout, session restore and two-account isolation each require actual
client/server observations; an Auth Users list or IAM read is insufficient.
Never roll back automatically to the current weaker rules. Secure rollback and
forward-repair policy below remains in force. No Storage/provider/billing changes
are included. The earlier generic preparation below is historical guidance;
execute the frozen config above for this reviewed deployment.

Project: `beewise-lab-3` only. Shared-project deployment requires explicit owner
authorization. No rules, indexes, provider, billing or enforcement changes were
made by this preparation. Existing production rules are weaker than the PR rules;
do not use them as an automatic rollback target.

## Preflight and review

Run from the repository in PowerShell. Keep the authenticated CLI session private.
The inspection saves the full deployed rules and Remote Config snapshot privately
under `D:/CodexTemp/beewise-lab3-tools/bao-cloud-private` and emits only allowlisted
metadata. Freeze the reviewed source SHA before deployment; stop if it changes.

```powershell
$reviewedSha = git rev-parse HEAD
node scripts/inspect-bao-cloud-state.cjs
node scripts/inspect-bao-cloud-config.cjs
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-bao-cloud.ps1 -Action rules -RunName deployment-preflight
if ($LASTEXITCODE -ne 0) { throw 'Emulator tests failed; stop.' }
git diff -- firebase/firestore.rules firebase/firestore.indexes.json
git diff --no-index -- D:/CodexTemp/beewise-lab3-tools/bao-cloud-private/deployed-firestore.rules firebase/firestore.rules
```

The last command normally exits 1 because it displays the reviewed rules diff.
Read the receipts, not just process success: all relevant inspections must PASS.
The current audit finds no composite indexes; the repository adds only
`chats(parentId ASC, updatedAt DESC)`. If the fresh list contains any other index
or field override, STOP and prepare a reviewed union with those existing entries.
Never accept a CLI index-deletion prompt or use `--force`.

Missing deployed guards: applicant separation for parent/device writes; current proposal ID,
revision, expiry and pending-kind eligibility; reciprocal atomic request/chat
creation. The repository's emulator suite covers those denials. No malicious
write was attempted against the shared project.

## Exact commands after separate deployment authorization

Re-read live rules immediately before running; compare their normalized hash with
the reviewed receipt and stop on any concurrent change. Retain the reviewed
release/ruleset ID, full rules snapshot and complete index list in the private
incident record. Coordinate a maintenance window with other project owners.

```powershell
if ((git rev-parse HEAD) -ne $reviewedSha) { throw 'Source changed; review again.' }
& .\firebase\node_modules\.bin\firebase.cmd deploy --only firestore:indexes --project beewise-lab-3 --config firebase.json --non-interactive
if ($LASTEXITCODE -ne 0) { throw 'Index deployment failed; stop.' }
& .\firebase\node_modules\.bin\firebase.cmd firestore:indexes --project beewise-lab-3 --json --non-interactive
# Wait for the new composite index to be READY in the management API/Console.
# A list of definitions alone does not establish build readiness.
& .\firebase\node_modules\.bin\firebase.cmd deploy --only firestore:rules --project beewise-lab-3 --config firebase.json --non-interactive
if ($LASTEXITCODE -ne 0) { throw 'Rules deployment failed; stop and inspect active release.' }
node scripts/inspect-bao-cloud-state.cjs
```

Require a live matching rules hash, READY index, and dedicated-account smoke tests
for owner/other-user FCM, atomic request/chat and current/stale response paths.
Auth-dependent smoke tests remain BLOCKED without a dedicated authorized account.
No Storage rules deployment is included: there is no bucket or active release.

## Failure and rollback plan

Before publishing, preserve the last **approved secure** rules file separately as
`D:/CodexTemp/beewise-lab3-tools/bao-cloud-private/approved-secure-rollback.rules`.
The currently deployed weaker snapshot is forensic evidence and does not qualify.
No secure prior release has yet been approved, so rollback execution is BLOCKED.
If validation fails, pause the rollout, preserve the index and investigate using
the captured release IDs; repair forward with tested strict rules. Never relax
ownership guards, delete records or delete indexes to make a smoke test pass.

If an owner supplies and approves a previous secure rules file, test that file
in an isolated copy with the same emulator suite. Prepare a private Firebase
config referencing that approved absolute rules path, and then, only after an
incident-specific authorization and concurrent-release check, run:

The private `approved-secure-rollback.firebase.json` must contain exactly this
path (no indexes or Storage section), after the secure rules file is supplied:

```json
{"firestore":{"rules":"D:/CodexTemp/beewise-lab3-tools/bao-cloud-private/approved-secure-rollback.rules"}}
```

```powershell
& .\firebase\node_modules\.bin\firebase.cmd deploy --only firestore:rules --project beewise-lab-3 --config D:/CodexTemp/beewise-lab3-tools/bao-cloud-private/approved-secure-rollback.firebase.json --non-interactive
node scripts/inspect-bao-cloud-state.cjs
```

Revalidate the active hash and owner/negative tests. Leave the added index intact;
index deletion is unrelated to safe rules rollback and needs separate approval.
