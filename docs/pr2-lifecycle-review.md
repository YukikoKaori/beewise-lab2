# PR #2 notification lifecycle review — 2026-10-30

Review target was the fetched PR HEAD `6ba751968c285daac443cb86e86af32185d2606a`,
on `codex/lab3-postmerge-corrective`, not the earlier Lab 3 baseline. This is
Codex's repository review, not an external reviewer approval. No deployment or
production-data mutation was performed.

## Accepted findings and fixes

| Finding | Impact | Correction |
|---|---|---|
| P1 — Installation ownership was discarded on auth change, reused across accounts, and forgotten after failed writes/deletes. Rotation left older mappings; unregister callbacks used mutable current ownership. | Old-account notifications could target an installation subsequently registered by another account; deleting an old owner's row with new credentials violates rules. | Serialize reconciliation, persist a UID/FID cleanup journal before writes, revoke delivery before managed auth mutations, delete only while authenticated as the recorded owner, and retain failed/uncertain work for retry. Generation checks invalidate stale work. Rotation removes old owned rows before binding the newest FID. Late expected unregister events cannot remove the new binding. |
| P1 — Inbox taps bypassed the FCM route filter, and neither path consistently checked recipient and actual chat ownership. | Malformed destinations or another account's saved notifications could initiate navigation. | A single strict parser accepts canonical allowlisted paths. Both consumers use `routeForNotification` immediately before navigation: same non-guest recipient, server-confirmed parent role, and existing chat whose `parentId` matches. Missing, encoded, queried, fragmented, traversing, external and unapproved paths are rejected. Server errors and intervening auth changes deny navigation. |
| P2 — Global preference clearing on sign-out erased failure recovery. | Failed cleanup could become unrecoverable after restart. | Preserve the cleanup journal and UID-scoped inbox; other accounts cannot read or navigate those items through the service. Legacy device-global notifications remain ignored. |

App-managed Google/email login, registration, tutor application and sign-out all
detach before changing Auth. Failed/cancelled operations retry reconciliation for
the actual current account. The profile exposes a registration error and retry.
Android manifest explicitly opts into installation-ID messaging and disables
automatic initialization, leaving registration under the lifecycle controller.

### Ownership recovery boundary

The installed Messaging SDK uses `register`/`unregister` and installation IDs.
`unregister` revokes message delivery but does **not** delete the Firebase
installation ID; re-registering can reuse the same FID. See the
[Firebase Messaging API contract](https://firebase.google.com/docs/reference/kotlin/com/google/firebase/messaging/FirebaseMessaging).

An unexpected external Auth change or process interruption can therefore leave
an old owner's server row. The new user cannot delete that row under existing
rules. The durable journal quarantines registration while *any foreign owner*
is pending, even after restart/retry. It never attempts that deletion under the
new UID and never revives the shared FID in this state. Signing in as the previous
owner allows authorized cleanup; subsequent managed switching works normally.
If that owner is unavailable, a future trusted ownership/migration endpoint is
required. None is implemented or deployed here. Existing rows created by older
versions without a journal cannot be inferred locally; trusted migration is
still required for those rows. Do not claim every historical server row is gone.

Failed revocation remains visible and retryable; offline clients cannot promise
immediate server-side revocation. Already delivered OS notifications cannot be
retracted by route validation. The trusted sender must still validate ownership,
remove stale installations, and avoid sensitive notification payloads as required
by the backend contract.

## Regression coverage

Mocked FirebaseMessaging/Auth/Firestore event streams cover normal switching,
external switching/sign-out, owner-only cleanup, restart recovery, failed writes
and deletes, failed registration/revocation, late acknowledgements and callbacks,
rapid rotations, guest/applicant transitions and corrupted recovery state.
Firestore mocks assert the UID at every write/delete and that the journal was
persisted before binding. Route tests cover valid and malformed paths, missing
routes, foreground/opened/cold-start messages, legacy inbox identity, cross-user
items, chat ownership, authoritative-read failure and auth changes during reads.
These are regression tests, not native SDK delivery or Android runtime proof.

## Execution record

Local logs live in `evidence/pr2-lifecycle/`. The initial analyzer failure is
retained separately from the final successful run. Build/cache/tool paths remain
on drive D; system PATH, registry and installed applications were not changed.

| Check | Result |
|---|---|
| Dart format, full repository | PASS — 29 files, 0 changes |
| Flutter analyzer | PASS — no issues |
| Flutter tests | PASS — 34 total, including 26 new lifecycle/route tests |
| Firestore + Storage Emulator rules | PASS — 26/26, `demo-beewise`, no production deployment |
| Android debug APK | PASS — exit 0, final application source `d89749f3a0740917d44f581c0961970b2efe059f`, clean D worktree, final incremental build 72.8s; APK metadata/hash recorded |
| GitHub Actions on latest PR HEAD | Verify after final push; exact final SHA/run links are recorded in the PR update and task handoff. Earlier HEAD success is not evidence for this revision. |
| Actual Android runtime / FCM delivery / screenshots | NOT RUN — an emulator appeared in the final adb inventory, but no native runtime/FCM scenario was executed; mocks and APK compilation are not runtime evidence |
| Staging backend / trusted workflow / live push | NOT RUN / BLOCKED — no supplied staging endpoint, trusted sender or test identities |
| ARTEMIS mobile execution | NOT RUN / BLOCKED — no configured ARTEMIS session/authorized staging fixtures; collection is not execution |
| External review | NOT RUN / BLOCKED — no independent review transcript or approval |

PR #2 remains the delivery branch. Do not merge or create another PR. The final
HEAD SHA and Actions run IDs are recorded in the PR update and task handoff;
this file deliberately does not embed its own eventual commit SHA.

Prior PDF/slides and `evidence/corrective/` describe the earlier snapshot. They
remain DRAFT and are not proof for this revision. This follow-up supersedes their
notification-lifecycle details and test counts.
