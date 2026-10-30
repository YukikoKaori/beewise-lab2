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
