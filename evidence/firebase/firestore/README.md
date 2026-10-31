> **2026-10-31 corrective update (supersedes prior runtime status):** Current update: six fixed synthetic document IDs audited from server (not cache), all active, labeled TEST, namespace intact and unverified. Native Search rendered all six. Client enforces fixture labeling/unverified status and excludes fixtures from AI. Deployed rules hash still differs; deployment preparation and secure rollback are in docs/workstreams/bao-deployment-plan.md. No shared deployment or fixture cleanup occurred.

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

- Applicant separation for parent/device writes and applicant-safe owner device
  cleanup. Registration uses `parents/{uid}/devices/{installationId}`; the old
  description of a global `fcmInstallations` collection was incorrect. UID owner
  binding already exists in the older deployed rules; no global collection is added.
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
