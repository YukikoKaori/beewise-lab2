## Final responsibility split — 2026-11-04 (current)

> **Latest owner decision, 2026-11-04:** the owner accepted the disclosed
> authorized1/actual2 request deviation retrospectively. The earlier draft
> hold below is historical and resolved; ready for review is conditional on
> final-HEAD gates. No additional provider calls, cloud/billing changes or
> deployment are authorized. Bao retains F-02; Nguyen owns F-03 only.
> [Owner acceptance and existing-data DebugView inspection](../../evidence/cloud/f02-lite-native-20261104/owner-finalization.md).


**B-04 SHARED OWNERSHIP:** F-01 remains the existing verified Firebase
discovery/connection/chat/messaging integration. **F-02 belongs to BAO — COMPLETE
/ LIVE VERIFIED** in API35 guest/debug scope: actual Firebase AI Logic/Gemini3.5
Flash-Lite response, App Check, validated Firestore demo tutor, native result,
detail/manual fallback and FA-SVC ai_match_success(result_count1).
**F-03 belongs to NGUYEN — HANDOFF / PENDING IMPLEMENTATION:** consultant,
trial/revision/invoice/payOS/webhook/payment/schedule/backend and business tests.

[Current F-02 packet](../../evidence/cloud/f02-lite-native-20261104/README.md)
records source/APK/config/timestamps/actual events and105 Flutter/58 Rules PASS.
Earlier3.8 failures remain preserved, not relabelled as successes. Parent-specific
AI, release/physical attestation and general provider availability are not claimed.
**Execution deviation:** automation caused2 Flash-Lite calls against approved1;
disclosed immediately, further calls stopped, receipt truthful. PR stays DRAFT
for owner review; no automatic merge. Final-HEAD CI is reported in the PR.

The earlier broad-transfer steer was uncommitted and corrected directly. F-03
WIP remains archived/unchanged and excluded from Bao's PR; no F-03 deployment.
[Precise F-03-only handoff](bao-to-nguyen-b04-handoff.md).
B-01/B-02/B-03.1–6/B-05 remain COMPLETE scoped. Bao's expanded implementation
scope now includes live-verified F-02; **Lab3 overall is NOT YET COMPLETE**.
Bao retains approved Firebase infrastructure/security/regression/evidence support;
production access/deployment authority is not transferred.

Historical snapshots below retain dated evidence and old assignments/configuration.
They do not override this final split or reopen previously verified tasks.

> **2026-10-31 correction:** Application source `9ef5907`, Flutter 50/50 and
> Firebase Emulator 27/27 PASS. Native guest discovery/RC gate exercised; synthetic
> records cannot enter AI as real tutors. Authenticated trusted transitions remain
> BLOCKED: no test identity, trusted processor, staff/provider or staging. Payment
> verification and official schedules remain server-trusted. No new backend,
> rules/index deployment, invoice/schedule write or live payment claim.

# Bảo trusted workflow status

Base: `12f5322655463fd801d64e4925572d6a3a2bbb82`. Application source tested/built:
`db1f12e` (the later concurrency test changes no app source). Date: 2026-10-30.
Environment: local Firestore/Storage emulators, isolated `demo-beewise`; no staging
backend, live parent identity, consultant identity or payment provider is available.

| Transition | Client / trusted implementation | Actual result | Live |
|---|---|---|---|
| Discover active tutors | `tutor_repository.dart`, real Firestore query; no fixture catalog in app | PASS rules: guests can read active tutors, not inactive | PASS live guest server queries on labeled synthetic fixtures; Android NOT RUN |
| Connection request + chat | `chat_service.dart`, reciprocal atomic batch, parent ownership | PASS rules: valid batch, malformed/cross-owner/orphan batch denied | BLOCKED test identity |
| Parent chat text | `chat_service.dart`, immutable parent messages | PASS rules: owner read/write; consultant impersonation/edit denied | BLOCKED test identity |
| Consultant assignment / trial proposal | Backend contract only; no deployed trusted handler | NOT RUN backend integration | BLOCKED trusted staff identity and deployment environment |
| Accept/alternate trial | `workflow_service.dart`, deterministic response document | PASS unit + rules: eligible parent response only, expiry/current ID enforced | BLOCKED test identity and trusted proposal |
| Class revision / confirmation | Trusted revision producer absent; parent response implemented | PASS unit/rules: current revision/type required | BLOCKED trusted producer |
| Invoice | Client reads owner invoice; trusted issuer absent | PASS rules: parent cannot create invoice or mark paid | BLOCKED issuer |
| Request payment verification | Client pending request only | PASS rules: owner request/read; forged verified state/cross-owner denied | BLOCKED identity/provider |
| Verify payment / official schedule | No trusted processor/provider; verified-only schedule read gate | PASS rules: no client verification or schedule creation/update, pending schedule inaccessible | BLOCKED provider contract and trusted processor |

`firebase/rules.test.cjs` now additionally races two independent owner writes to
the same response ID: exactly one succeeds; the other receives permission-denied.
All 27 emulator tests pass. Existing tests also replace the current proposal and
reject stale responses. A race with a concurrently deployed trusted revision
transaction is NOT RUN: that processor does not exist. Do not claim full concurrent
backend integration from the duplicate-write test.

No Functions/VPS scaffolding was added without a usable authorized deployment
environment. Deployed Firestore rules were read and differ from repository security rules; the chat composite index is missing. No production rules/indexes were deployed. No client was granted consultant,
invoice, payment or schedule authority. Emulator seed data uses disabled rules
solely inside isolated tests; this is not a trusted backend implementation.

Minimum external contract before implementation: authenticated staff authorization
and allowed transitions; authoritative proposal ID/revision/expiry; idempotency key
and transaction comparing current state; provider-signed payment event with invoice,
amount, currency and dedupe/replay checks; atomic verified payment/schedule creation;
retry/audit policy. Existing `docs/backend-contract.md` remains the API contract.
Until those prerequisites exist, keep pending states and the existing denial rules.

Reproduce: `scripts/verify-bao-cloud.ps1 -Action rules -RunName workflow-retest`.
Evidence: `evidence/cloud/checks/verified/rules-test.*`; no staging or payment PASS.
