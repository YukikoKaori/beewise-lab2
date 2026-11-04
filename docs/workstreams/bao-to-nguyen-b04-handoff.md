# B-04 shared ownership — precise F-03 handoff

> **Latest owner decision, 2026-11-04:** the owner accepted the disclosed
> authorized1/actual2 request deviation retrospectively. The earlier draft
> hold below is historical and resolved; ready for review is conditional on
> final-HEAD gates. No additional provider calls, cloud/billing changes or
> deployment are authorized. Bao retains F-02; Nguyen owns F-03 only.
> [Owner acceptance and existing-data DebugView inspection](../../evidence/cloud/f02-lite-native-20261104/owner-finalization.md).


Effective **2026-11-04**, final owner correction superseding the earlier full
transfer. **NGUYEN OWNS F-03 ONLY. BAO RETAINS F-02 AI MATCHING / APP CHECK.**

| Flow | Owner / status | Scope |
|---|---|---|
| F-01 | Bao existing Firebase integration — EXISTING VERIFIED CLOUD FLOW | Discovery, Auth, reciprocal connection/chat creation and parent messaging; preserve evidence |
| F-02 | **Bao — COMPLETE / LIVE VERIFIED in API35 guest/debug scope** | Firebase AI Logic/Gemini, App Check implementation, real provider response, Android validation, security and acceptance evidence |
| F-03 | **Nguyen — HANDOFF / PENDING IMPLEMENTATION** | Consultant/trial/class revision/invoice/payOS/webhook/payment/official schedule and end-to-end business tests |

B-04 overall has **SHARED OWNERSHIP**, not COMPLETE. B-01/B-02/B-03.1–6/B-05
remain COMPLETE in their existing verified scopes; expanded Bao scope includes
live-verified F-02. Lab 3 overall remains dependent on F-03, UI/ARTEMIS and final deliverables.
Bao supports approved Firebase infrastructure/configuration, security/regression
review and evidence verification. Production IAM/deployment rights are not
silently transferred to Nguyen.

## Correction and preserved WIP

The broad-transfer documentation was uncommitted. It was corrected directly;
there was no reset, revert, force-push or discarded implementation. The old dated
proposal is preserved privately for traceability and has no current authority.

Active worktree: `D:/CodexTemp/beewise-b04-final`, branch
`feat/lab3-b04-ai-trusted-workflow`, initial HEAD/base
`18bd74e1c3b7caf4c5d26ba80d2c3e195f25c9da` (merged PR13). Original checkout
`C:/Users/THIS PC/Desktop/Semester_8/prm/beewise-lab2` remains on
`feat/lab3-bao-cloud-runtime`, HEAD `b338346ce241250cbaaa4fed5c5208caa5290fde`,
with unrelated historical untracked evidence untouched. Final F-02 source/delivery
SHA and native receipts are recorded separately in its acceptance packet/PR.

The previous 15-file WIP snapshot remains intact in the machine-local archive
`D:/CodexTemp/beewise-lab3-tools/b04-handoff-private/b04-wip-before-transfer.zip`,
SHA256 `08f5d2c499a9547adde9751ee02d418821ab295f323b2d2ace6b940bd72d1080`.
Adjacent `wip-manifest.json` and `b04-wip-tracked.patch` identify exact files,
hashes, build and test times. The snapshot includes then-current F-02 material;
Bao now resumes F-02 only. Archive and original F-03 files are not deleted.
Private raw logs/credentials are not part of a public handoff.

F-03 WIP: local untracked `backend/` contains a Node24 one-shot authenticated
worker, operator, emulator HMAC payment fixture and tests; local
`firebase.backend-test.json` isolates Auth/Firestore on `demo-beewise-workflow`.
Proposed backend CI and backend node_modules exclusions also remain local WIP.
**These files/CI changes are excluded from Bao's focused F-02 PR.** Nguyen may
review/reuse selected code on his own feature branch from fresh main, after
checking schema/UI compatibility and security. Do not blindly cherry-pick/stage
the full worktree. The WIP is not payOS, not a deployed listener/webhook, not an
automatic response processor and not production-ready. No staff account was
created, no parent promoted, no provider key configured and no backend deployed.

Recorded WIP tests before the split: backend19/19 actual Auth+Firestore Emulator
integration cases,3/3 security unit tests and syntax checks PASS. Parent writes
use Client SDK under unchanged Rules; Admin worker checks its own invariants.
Emulator-signed receipts test business logic only, **not payOS or live payment**.
The recorded backend dependency audit had six moderate transitive findings;
Nguyen must review dependencies before adopting the WIP. These tests do not
close F-03 or certify his future implementation.

## Existing functionality, screens and security

Preserve the [actual acceptance packet](../../evidence/cloud/bao-acceptance-20261103/README.md)
and [audit matrix](../../evidence/cloud/bao-acceptance-20261103/audit-matrix.md).
They contain real tutor discovery/detail and parent Auth, a
[native request/chat/text](../../evidence/cloud/bao-acceptance-20261103/f01-chat-message-sent.png)
with [Client SDK server readback](../../evidence/cloud/bao-acceptance-20261103/native-client-server-excerpts.txt).
F-01 evidence is retained for its tested scope, not relabelled as a fresh full
business E2E run. The allowed technical demo tutor remains active=true,
verified=false, demoOnly=true; synthetic fixtures are not genuine recommendations.

Existing screens/routes in `lib/screens/beewise_screens.dart` and the router:

| Screen | Route / integration |
|---|---|
| Chat | `/chats/:chatId`; parent stream/composer, consultant trial/revision cards |
| Trial | `/trial/:chatId/:proposalId`; accept/alternate-time response |
| Class confirmation | `/class/:chatId/:revisionId`; confirm/adjustment response |
| Payment | `/payment/:invoiceId`; owner invoice status and pending verification request |
| Official schedule | `/schedule/:classId`; verified-payment gate |

`lib/services/workflow_service.dart` supplies owner responses, invoice/schedule
streams and pending verification intent. `chat_service.dart` supplies reciprocal
intake and parent text; model/provider boundaries already exist. Known integration
gap: a trusted `payment_request` chat message currently has no invoice-opening
action. The previously approved patch was not applied; Nguyen owns implementing
and testing it with the complete F-03 UI payload contract.

Use [docs/backend-contract.md](../backend-contract.md),
`firebase/firestore.rules` and `firebase/rules.test.cjs` as the baseline.
Collections include owner-scoped `connectionRequests`, `chats`, chat `messages`
and immutable `responses`, trusted `invoices`, pending
`paymentVerificationRequests` and verified `classes`. Parent fields never confer
consultant or administrator authority. Preserve the exact current pointer,
pending status, expiry, response kind and reciprocal parent/tutor/chat checks.
Existing Rules58/58 Emulator PASS is separate from backend/provider validation.

## Nguyen's trusted state machine and payOS responsibilities

1. Validate reciprocal request/chat/tutor/parent intake; authorize a legitimate
   consultant server-side. Require authenticated, revocable staff roles with
   deny-by-default access. Never self-assign from client-written fields.
2. Transactionally publish consultant-only trial messages with `status=pending`,
   Firestore `expiresAt`, `currentProposalId` and chat status. Consume only one
   immutable owner accept/alternate response for the current unexpired proposal.
3. Publish each class revision under a new ID, atomically updating
   `currentRevisionId` and `class_revision_pending`. Handle confirm/adjustment,
   simultaneous replacement, stale responses and repeated delivery safely.
4. Create server-owned invoices from the consumed current accepted revision,
   deriving parent/tutor/amount/currency/terms. Deduplicate issuance. Flutter
   cannot select an arbitrary owner, issue an invoice or mark it paid.
5. Create payOS checkout on the server. Persist a unique orderCode/paymentLinkId
   mapping to invoice/owner/amount/currency. Return safe checkout data only;
   reconcile uncertain API outcomes instead of creating duplicate orders.
6. Accept bounded HTTPS webhook payloads and verify current payOS signatures
   using server-held secrets before trusted writes. Use the current official
   SDK/algorithm, not an emulator fixture or another provider's signing format.
7. Validate successful provider outcome and exact order/link/invoice/owner,
   amount and currency. Enforce globally unique transaction references, replay
   protection, idempotency and transactional updates under concurrent delivery.
   Redirect/callback/client success UI and a parent pending request are never
   independent payment proof. Handle cancellation, mismatches, partial/conflicting
   events, retries and missed webhooks with authenticated reconciliation.
8. Only independently verified matching payment can atomically verify the
   invoice and create one official class from accepted current terms. Preserve
   owner isolation and `paymentStatus=verified` read gate. Do not acknowledge
   durable processing as successful if the required database commit failed.

Keep payOS Client ID/API Key/Checksum Key and Admin credentials server-side in an
approved secret facility, never Flutter/RC/Git/logs. Use least-privilege runtime
IAM and privacy-safe audit metadata. Admin SDK bypasses Rules: every server
operation must enforce authorization and business invariants itself. Do not
weaken Rules for integration or turn client-controlled flags into trusted state.

### Provider modes and approval boundary

Nguyen must verify current contracts/modes before implementation. Official
[payOS test guidance](https://payos.vn/docs/moi-truong-test/), checked2026-11-04,
states there is **no separate sandbox/staging**; trial integration runs on the
production service with owner identity verification and bank linkage. Do not
assume a sandbox, label fixtures as payOS acceptance, provide identity documents,
link banks, configure production credentials/webhooks or initiate even a small
real charge without explicit separate owner approval. Real payOS E2E is NOT RUN.

Official [Node SDK](https://payos.vn/docs/sdks/back-end/node/) documents checkout
creation and webhook verification; [webhook contract](https://payos.vn/docs/du-lieu-tra-ve/webhook/)
defines signed payment fields. Pin and test the selected current SDK. No payOS
package/adapter was installed here. Earlier MoMo/VNPAY research is superseded;
do not silently substitute either provider.

## Required F-03 tests and deployment coordination

Nguyen owns integration tests covering valid/invalid reciprocal intake, parent
and staff authorization/revocation, cross-owner denial, proposal accept/alternate/
expiry/stale/duplicate responses, revision replacement races and confirmation,
invoice terms/ownership/deduplication, checkout timeout/reconciliation,
forged/invalid signature, wrong order/link/amount/currency, replay/cross-invoice
reuse, concurrent webhook/crash retries, pending payment not unlocking schedule,
and one owner-isolated official class only after genuine verified payment.

Use isolated Emulator fixtures for local security/business tests and label them
EMULATOR. Live evidence requires actual authorized provider behavior; mocks and
Admin fixture writes cannot substitute for it. Preserve Auth fail-closed identity,
FCM generation/journal/cross-UID protections, Analytics privacy/null clearing,
Crashlytics/RC behavior, immutable private Firestore PDF and the exact demo tutor
protections. Storage remains DEFERRED; no bucket/billing deployment is implied.

Nguyen can independently review WIP, implement F-03 services/UI/contracts and
tests on his own branch, and prepare a deployment/security proposal. Bao supports
Firebase read-only preflight, strict Rules/index review, approved service access,
runtime IAM/secret design and regression/evidence review. Exact project/region/
host/API/endpoint/IAM/secrets/rules/index/billing changes need separate approval
before deployment. No staff identity, production Admin key or hosting permission
is granted by this handoff. Current live trusted backend/staff/provider remain
unavailable. Staff creation/claims, payOS account setup and real charges must not
be performed by Bao as part of F-02.

## Bao F-02 boundary and next integration handoff

Bao owns current AI/provider/model/App Check investigation and implementation;
Nguyen must not be assigned those acceptance gaps. Existing initialization keeps
debug AndroidDebugProvider versus release PlayIntegrity. Earlier disabled APIs
and `Too many attempts` are historical. Previously exact-approved API enablement,
Gemini setup and AI-only enforcement have occurred; current read-only inspection
must precede further diagnosis. No new API/token/enforcement/terms/billing/quota
mutation is automatic. After the historical3.8 failures, the owner separately
approved3.5 Flash-Lite. The same Firebase AI Logic/Gemini Developer provider
returned a genuine validated native result; no cloud RC publication occurred.

Bao's focused F-02 packet/PR will carry exact source/APK/model/configuration,
native provider result, validated recommendations, Analytics and recovery proof.
Nguyen then integrates that stable F-02 boundary with F-03 without changing
identity/security protections. Completion of F-02 does not mark F-03, B-04 overall
or Lab3 complete. Historical records remain dated evidence, not current ownership.

Current [F-02 live packet](../../evidence/cloud/f02-lite-native-20261104/README.md)
records actual3.5 provider output, valid demo tutor, native AI/detail/fallback,
FA-SVC ai_match_success count1 and105 Flutter/58 Rules PASS. Earlier3.8 failures
remain historical evidence. An automation error caused2 calls against approved1;
disclosed and stopped, PR DRAFT for owner review. Bao F-02 is functionally live
verified in the tested scope; Nguyen F-03 remains HANDOFF / PENDING IMPLEMENTATION.
