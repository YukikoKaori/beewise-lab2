# Trusted workflow and notification contract

For current client ownership handling, see the [PR #2 follow-up](pr2-lifecycle-review.md).
Foreign pending registrations quarantine delivery until their owner authorizes
cleanup. Historical unjournaled mappings need trusted migration; client code
does not delete another UID's device rows or provide that backend migration.

This is a required contract, not an implemented or deployed backend. No staging
URL, server credentials, payment provider or consultant identity was supplied.
The mobile client talks to Firestore; there are no verified HTTP endpoints.

## Consultant proposals and parent responses

Trusted staff/backend must create `chats/{chatId}/messages/{proposalId}` with
`role: consultant`, `kind: trial_proposal` or `class_revision`, and a `payload`
containing `status: pending` and a Firestore Timestamp `expiresAt`. Keep existing
screen payload fields (time, tutor, pricing, class details) as documented by the
handoff. In the same trusted transaction, set `chats/{chatId}.currentProposalId`
and `onboardingStatus: trial_proposed`, or `currentRevisionId` and
`onboardingStatus: class_revision_pending`. These pointers, pending state and
expiry are newly enforced requirements. Existing incomplete fixtures will be
denied; migrate staging fixtures before demonstrating responses.

The authenticated parent creates exactly one immutable
`chats/{chatId}/responses/{proposalId}`:

```json
{
  "parentId": "authenticated UID",
  "proposalId": "current proposal message ID in this same chat",
  "type": "trial_accepted",
  "createdAt": "serverTimestamp()"
}
```

Allowed alternatives: `trial_alternate_time` with nonempty `alternateTime`,
`class_adjustment_requested` with nonempty `reason` (both at most 500 characters),
or `class_revision_confirmed`. A new class revision must use a new message ID.
Rules validate ownership, consultant kind, current pointer, pending state,
expiry and one response per proposal. Client transaction checks provide useful
errors; rules remain authoritative against a malicious/outdated client.

## Server processing obligations

An idempotent trusted consumer must re-read the response, proposal, current chat
pointer, parent ownership, expiry and current business state in one transaction.
Deduplicate by full response document path. Reject stale/unauthorized responses;
clients never choose the consultant or advance trusted status.

1. Connection request + chat are created in one client batch with reciprocal
   `connectionRequestId`/`chatId`, matching parent/tutor, active tutor and server
   timestamps. Backend assigns a real consultant and projects chat activity.
2. Trial acceptance/alternate time produces consultant follow-up, not an invoice.
3. Class adjustment produces a new revision. Current revision confirmation may
   cause the backend to issue `invoices/{id}` with `parentId` and trusted terms.
4. `paymentVerificationRequests/{id}` is only an owner request with `pending`
   and `requestedAt`. It is not proof of payment. Server verifies invoice
   eligibility, deduplicates repeated requests, independently validates provider
   receipts and amount/currency, and alone writes verified invoice/payment state.
5. Only server creates `classes/{id}`; the parent can read it only when
   `paymentStatus: verified`. Official schedules must derive from the verified
   invoice and the accepted current revision. Admin SDK bypasses rules, so these
   checks must exist in server code and require server-side integration tests.

## Push delivery and local isolation

Every targeted push must include `data.recipientUid` equal to the authenticated
recipient. Missing/mismatched recipient IDs are deliberately dropped from local
inbox/deep-link handling, including background delivery. Guests have no inbox.
Legacy device-global v1 entries are ignored because their owner is unknowable.
New inboxes use UID-specific v2 keys, read without an isolate-local cache.
Messages with a known message ID are deduplicated; history is bounded to 100.
Concurrent foreground/background preference writes are not transactional and
may lose an entry; server-backed notification history is a future reliability
requirement if lossless delivery is required.

FCM 17 exposes installation IDs through `register`/`onRegistered`; use the
installed SDK's direct-send contract, not assumptions about older token APIs.
Normal app sign-out detaches `parents/{uid}/devices/{installationId}` while the
old UID remains authenticated. A tutor applicant may delete their own stale
device registration but cannot read/create parent data. Sender backend must
revalidate recipient/installation ownership and remove stale registrations.
Do not put personal/private content in OS-visible notification title/body:
Android can display notification payloads before application-level UID checks,
and previously delivered shade entries can outlive sign-out. Live push delivery,
OS shade behavior and cross-account installation reassignment are NOT VERIFIED.

## Integration tests required at staging

Run the proposal/revision transitions above using a designated parent and
consultant, verify duplicate delivery and concurrent revision replacement, verify
replayed/forged payment receipts fail, then verify a real authorized test receipt
alone unlocks the matching official schedule. No such integration ran here.
