# BeeWise trusted backend (F-03)

Node 24 + Express + Firebase Admin + the official payOS SDK (`@payos/node` 2.0.5).
It implements the trusted half of Lab 2 flow 3, which the Flutter client must
never be able to fake:

```text
connection request ─► consultant claims chat ─► trial proposal ─► parent accept / alternate time
   ─► class revision ─► parent confirm / adjust ─► invoice (server-issued)
   ─► payOS checkout ─► webhook + provider re-check ─► invoice verified ─► official class
```

**Status: EMULATOR VERIFIED (45 tests) + ONE LIVE payOS PAYMENT VERIFIED
(2026-11-05, 2,000 VND, real Firebase).** Not deployed: the live run used a local
server behind a Cloudflare quick tunnel. Evidence:
[f03-payos-live-20261105](../evidence/cloud/f03-payos-live-20261105/README.md).

## Why a separate Node server

Cloud Functions require the Blaze (billing) plan, which is not approved for this
project. This server runs anywhere Node 24 runs (local + HTTPS tunnel for a demo,
or a free host such as Render) and talks to the same Firebase project with the
Admin SDK.

## Trust model

| Decision | Who decides | How |
|---|---|---|
| Who is a consultant | Admin only | Custom claim `beewiseConsultant`, re-read from the live user record on every call; `revoke` also revokes refresh tokens |
| Proposal / revision is current | Server | Transaction moves `currentProposalId` / `currentRevisionId`; old pending proposals become `superseded` |
| Parent response is valid | Rules (create) + server (consume) | Server re-checks owner, pointer, pending state and expiry, then writes one `workflowReceipts/{chat}__{proposal}` |
| Invoice terms and amount | Server | Deterministic `invoices/inv_{chatId}_{revisionId}` from the confirmed revision's `totalFee` |
| Payment happened | **payOS only** | `GET /v2/payment-requests/{orderCode}` must say `PAID` with `amount == amountPaid == invoice.amount`, VND, matching link id, unused bank references |
| Official schedule exists | Server | `classes/cls_{invoiceId}` created in the same transaction that verifies the invoice |

The return URL, the client UI and the parent's "Tôi đã thanh toán" request are
**never** proof of payment: they only trigger the same provider re-check.

The Admin SDK bypasses Security Rules, so every invariant above is enforced in
`src/*-service.js` inside Firestore transactions. Server-only ledgers
(`paymentOrders`, `payosWebhookEvents`, `payosTransactions`, `workflowReceipts`)
are unreadable and unwritable by clients (see `firebase/rules.test.cjs`).

## Payment state machine (`paymentOrders/{orderCode}`)

| Status | Meaning | Next |
|---|---|---|
| `creating` | Reserved; payOS call in flight (60 s lease blocks double taps) | `pending` / `failed` / `uncertain` |
| `uncertain` | Timeout or 5xx: payOS may have created the link | Reconciled with `GET`; still payable ⇒ cancelled at payOS before a new link |
| `pending` | Link live; reused while > 60 s from expiry | `paid` / `cancelled` / `expired` |
| `paid` | Verified; invoice + class written | terminal |
| `paid_duplicate` | Paid after the invoice was already paid | terminal, **manual refund** |
| `mismatch` | Provider data disagrees (amount, link, reference reuse…) | terminal, **manual review** |
| `cancelled` / `expired` / `failed` | Not payable; invoice released for a new checkout | terminal (a late PAID is still caught and flagged) |

Webhook handling: verify signature with the SDK (`400` if invalid) → dedupe by
signature hash → cross-check order/link/amount/currency → settle via provider
`GET`. It returns `503` (so payOS retries) only when retrying can help: provider
unreachable, provider not yet `PAID`, or the database commit failed. The payOS
webhook-URL confirmation sample (`orderCode 123`) is acknowledged with `200`.

## HTTP API

| Route | Auth | Purpose |
|---|---|---|
| `POST /v1/payments/checkout` `{invoiceId}` | Parent ID token | Create or reuse a payOS checkout link for the caller's own invoice |
| `POST /v1/payments/reconcile` `{invoiceId}` | Parent ID token | Re-check payOS (missed/late webhook) |
| `POST /v1/payos/webhook` | payOS signature | Payment notification |
| `GET /v1/payos/return`, `/v1/payos/cancel` | none | Informational pages only |
| `POST /v1/tutor-applications/resubmit` `{name, phone, qualification, introduction, subjects, grades, hourlyFee, areas, teachingModes, availability}` | Applicant ID token | Fix a `needs_info` application; it returns to `pending`. Owner, email and status are never read from the body |
| `POST /v1/staff/tutor-applications/:uid/publish` | Consultant ID token | Publish a fully approved application (`approved` + `verified` + `active`) to the public `tutors/{uid}` catalog |
| `POST /v1/staff/chats/:chatId/claim` | Consultant ID token | Assign yourself to a valid waiting chat |
| `POST /v1/staff/chats/:chatId/trial-proposals` `{payload, ttlHours?}` | Consultant | Publish trial proposal |
| `POST /v1/staff/chats/:chatId/class-revisions` `{payload, ttlHours?}` | Consultant | Publish class revision |
| `POST /v1/staff/chats/:chatId/responses/:proposalId/process` | Consultant | Consume a parent response |

Set `WORKFLOW_WATCHER=1` to consume parent responses and "I paid" requests
automatically (as the chat's assigned consultant, re-verified per event). The
watcher also keeps the public tutor catalog in step with tutor applications: staff
approve an application by hand in the Firebase console (`status: approved`,
`verified: true`, `active: true`) and the profile is published to `tutors/{uid}`;
if approval is later revoked the profile is hidden (`active: false`). Without the
watcher run `node scripts/staff.js publish-tutor <applicationUid>`.

## Data the tutor workspace (T3/T4) reads

Clients create a chat with only its structural fields and can never update it, so the
watcher (`WORKFLOW_WATCHER=1`) fills in what the tutor screens list, all idempotently:

| Where | Fields | Source |
|---|---|---|
| `chats/{id}` | `parentName`, `subjectSummary`, `areaSummary` | `parents/{id}.displayName`, the connection request's `learningGoal` / `area` (filled once, never overwritten) |
| `chats/{id}` | `consultantName` | The consultant who claims the chat |
| `chats/{id}` | `lastMessageText`, `lastMessageAt`, `lastMessageBy` | Newest message only (strictly newer wins, so replays are ignored) |
| `chats/{id}` | `classId` | Set when a payment is verified |
| `classes/{id}` | `parentName`, `consultantName`, `hourlyFee`, `hoursPerSession`, `totalSessions`, `totalAmount` | The confirmed class revision and invoice |
| `classes/{id}` | `sessions[]` (dated lessons) | Generated from `startDate`, the `schedule` weekdays, `time` and `sessions` of the revision, in Vietnam time. If the terms cannot be turned into dates reliably (e.g. no `sessions` count) the array is empty: sessions are never invented and a verified payment is never blocked |

For dated sessions, publish the class revision with the billing breakdown
(`hoursPerSession`, `sessions`, e.g. see `examples/class-revision.json`).

Security Rules let a fully approved tutor (`tutorApplications/{uid}`: `approved` +
`verified` + `active`) **read** only the chats, messages and classes whose `tutorId` is
their own UID. Tutors cannot write any of them.

## Run the tests (EMULATOR)

Requires JDK 21+ for the Firestore emulator.

```powershell
npm ci --prefix backend --ignore-scripts
npm --prefix backend test        # Auth + Firestore emulators, 45 tests
npm --prefix backend run test:unit
```

On Windows, if the Firestore emulator exits with `Unable to establish loopback
connection`, the user TEMP path contains a space. Point the JDK socket directory
elsewhere for that shell: `$env:JAVA_TOOL_OPTIONS='-Djdk.net.unixdomain.tmpdir=D:\tmp\jdk-uds'`.

payOS in tests is `test/support/fake-payos.js`, injected as the SDK's `fetch`,
so the official SDK's request signing, response signature checks and webhook
verification run unchanged. **These are EMULATOR results, not payOS acceptance.**

## EMULATOR demo on an Android emulator (for the video)

Everything runs locally: Firebase Auth + Firestore emulators (project id
`beewise-lab-3` so the app's config matches), the real backend services, a fake
payOS behind the official SDK, and a local checkout page. The app shows an
**EMULATOR** ribbon; the checkout page says it is simulated.

```powershell
# 1. Emulators (repository root)
backend\node_modules\.bin\firebase emulators:start --config firebase.json --project beewise-lab-3 --only auth,firestore
# 2. In backend/, with emulator env set:
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'; $env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'; $env:FIREBASE_PROJECT_ID='beewise-lab-3'
node scripts/demo-seed.js      # demo-parent@beewise.test / demo-consultant@beewise.test (emulator-only)
node scripts/demo-server.js    # backend + watcher + /demo/payos checkout page on :8787
# 3. App (repository root)
flutter run --dart-define=BEEWISE_API_BASE_URL=http://10.0.2.2:8787 --dart-define=BEEWISE_FIREBASE_EMULATOR_HOST=10.0.2.2
```

Then: sign in as the demo parent → open the demo tutor → send a connection
request. As consultant (same env, in `backend/`):
`node scripts/staff.js claim demo-consultant@beewise.test <chatId>`, then
`trial ... examples/trial.json`. Parent accepts in the app; the watcher consumes
it. Then `revision ... examples/class-revision.json`; parent confirms → invoice
card in chat → "Thanh toán qua payOS" → "Xác nhận đã chuyển khoản (giả lập)" →
the signed webhook is verified against the fake provider → invoice verified →
"Xem lịch học chính thức". `BEEWISE_FIREBASE_EMULATOR_HOST` is ignored in
release builds.

## Run locally against Firebase

1. Copy `.env.example` to `.env` (never commit it). Point
   `GOOGLE_APPLICATION_CREDENTIALS` at a service-account JSON stored outside the
   repository, with least-privilege access to Firestore and Auth.
2. `npm --prefix backend start` — without payOS keys, checkout fails closed with
   `503 payos_not_configured`.
3. Build the app against it:
   `flutter run --dart-define=BEEWISE_API_BASE_URL=http://10.0.2.2:8787` (emulator;
   debug builds only allow cleartext) or an HTTPS tunnel URL.
   On Windows with the pub cache on C: and the project on D:, Kotlin's
   incremental cache fails with "different roots"; build with
   `flutter build apk --debug --android-project-arg=kotlin.incremental=false`.

Consultant operations from a trusted operator machine:

```powershell
cd backend
node scripts/staff.js grant consultant@example.com      # then that user signs in again
node scripts/staff.js claim consultant@example.com <chatId>
node scripts/staff.js trial consultant@example.com <chatId> examples/trial.json
node scripts/staff.js process consultant@example.com <chatId> <proposalId>
node scripts/staff.js revision consultant@example.com <chatId> examples/class-revision.json
node scripts/staff.js revoke consultant@example.com
```

`revision` takes the amount from the catalog, so the invoice always equals the fee
the app shows: `fee` defaults to the tutor's `hourlyFee` and
`totalFee = fee × hoursPerSession × sessions` (set `hoursPerSession` and `sessions`
in the JSON file; `examples/class-revision.json` is 1,5 h × 8 sessions). The server
rejects a `totalFee` that disagrees with that breakdown. For a cheap real-payment
test use `examples/class-revision-test-2000.json` (fee 2.000 đ × 1 h × 1 session
= 2.000 đ).

## Going live with payOS (owner approval required)

Not done in this repository. Each step needs explicit owner approval:

1. Owner creates and verifies a payOS account and links a bank account
   (payOS: no separate sandbox; tests run on production with small amounts).
2. Put Client ID / API Key / Checksum Key into the server's secret store or
   `.env` on the server only — never in Flutter, Remote Config, Git or logs.
3. Expose the server over HTTPS and run
   `node scripts/staff.js confirm-webhook https://<host>/v1/payos/webhook`.
4. Pay one small invoice (`examples/class-revision-test-2000.json` issues 2.000 đ), then capture:
   payOS dashboard transaction, `paymentOrders` → `paid`, invoice `verified`,
   the class document, and the Schedule screen in the app.

## Known limits

- Single region/process; no rate limiting on public routes (put the server
  behind a proxy or host with request limits before real traffic).
- Refunds for `paid_duplicate` and investigation of `mismatch` are manual.
- Push notifications for new proposals/invoices are not sent yet (in-app chat
  stream updates live).
