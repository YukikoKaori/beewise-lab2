> **2026-10-31 corrective update (supersedes prior runtime status):** Current update: six fixed synthetic document IDs audited from server (not cache), all active, labeled TEST, namespace intact and unverified. Native Search rendered all six. Client enforces fixture labeling/unverified status and excludes fixtures from AI. Deployed rules hash still differs; deployment preparation and secure rollback are in docs/workstreams/bao-deployment-plan.md. No shared deployment or fixture cleanup occurred.

# Firestore live deployment audit

## 2026-10-31 provisioning blocker (current)

Live release is still ruleset `14c0a112-21ce-4077-876b-fa6a298db91c`, normalized
hash `be6beebec1e872de3f89163f4623ea020af3be698482c22ae8e1049463865448`.
It also lacks `tutorApplications/{uid}`: post-auth own role lookup is denied even
when the application is absent. Repository already contains the strict owner
read; retain the client check. Two enabled Password users do not establish live
login success. Readiness: `../../cloud/auth-provisioning-readiness.json`.
Original 27 tests PASS; added bootstrap/cross-UID regression yields 28/28 PASS,
including the frozen deployment bundle. No shared deployment was authorized or
performed. Hashes, index-preserving preflight and exact commands/secure repair
policy: `../../cloud/prepared-firestore-deployment.json` and
`../../../docs/workstreams/bao-deployment-plan.md`.

## Previous drift audit

Read-only API/CLI inspection on 2026-10-30, `beewise-lab-3`. Default database is
Firestore Native Standard, asia-southeast1. Receipt timestamps/commands are in
`../../cloud/config-inventory.json`, `live-management-state.json`.

**BAO-C01 — deployment drift (BLOCKED remediation):** actual deployed rules do
not match repository PR #2 rules. `deployed-2026-10-30.rules` is the actual read
snapshot, not a proposed replacement. Normalized SHA-256:
`be6beebec1e872de3f89163f4623ea020af3be698482c22ae8e1049463865448`.
Compared with `firebase/firestore.rules`, the deployed version lacks:

- Global `fcmInstallations` UID binding and applicant separation; the new FCM
  registration transaction needs this collection and would be denied live.
- Current proposal/revision ID, expiry, kind/status checks for parent responses.
  Existing deployed checks only constrain owner/type/field names, so they do not
  enforce PR #2 stale/replay/expiry protection for a parent writing another ID.
- Reciprocal request→chat `getAfter` validation on connection request creation;
  one direction exists on chat creation, but request alone remains possible.

No malicious live write/probe was performed. Findings follow the actual retrieved
rules source. Local emulator tests verify repository rules, not these deployed
rules. Production deployment was **not authorized**; no rules were deployed.
The owner should review the repository/deployed diff and authorize a coordinated
test deployment after the 27-case suite passes. Do not relax repository rules.

Live composite-index list is empty; repository declares chats(parentId ASC,
updatedAt DESC), required by `watchParentChats`. This index deployment also remains
unexecuted pending authorization. No active Storage rules release exists.

Before seeding, expected top-level collections were absent. User explicitly
authorized labeled separate fixtures: six create-only tutor documents now exist,
namespace `bao-lab3-20261030`, names `[TEST]`, synthetic metadata and verified=false.
No genuine tutor endorsement or personal data is asserted. Seeder refuses other
projects and overwrite; it is separate from submitted app code.
`../../cloud/fixture-actions.json` records each real HTTP 200 create.

`../../cloud/guest-firestore-query.json` proves actual public client SDK server
reads (no Firebase Auth or CLI IAM identity) with active=true at limits 6 and 2.
This is LIVE_VERIFIED guest data access only; neither Android visible behavior nor
Remote Config changing behavior is claimed. No authenticated parent/consultant/
payment live flow was run. Nested personal chat records were not inspected.

Reproduce safe reads: `node scripts/inspect-bao-cloud-state.cjs`,
`node scripts/verify-bao-guest-firestore.cjs`. Do not rerun the create-only seeder
against existing IDs expecting overwrite; a conflict is intentional. Fixtures
remain clearly labeled. Their deletion requires a separate explicit instruction.
