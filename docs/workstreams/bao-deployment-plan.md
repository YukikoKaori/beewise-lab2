# Firestore deployment preparation — NOT EXECUTED

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

Missing deployed guards: UID-bound global FCM installations; current proposal ID,
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
