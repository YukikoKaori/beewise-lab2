# Lab 3 AI code review record

Latest PR #2 review: [installation lifecycle and notification routes](pr2-lifecycle-review.md).
That follow-up targets PR HEAD `6ba7519` and supersedes the earlier notification
findings and test counts below. It is still an in-repository Codex review.

Historical PR #1 notes below describe the premerge work. Statements about
"working tree" or "pending commits" apply to that historical review only;
they are superseded by the 2026-10-30 corrective audit at the end of this file.

## Review context

- Reviewer: OpenAI Codex (GPT-6), in-repository static review.
- Review base: Lab 2 commit `9023547`.
- Review target: current uncommitted Lab 3 working tree.
- Method: inspect Flutter services, Firestore/Storage rules, providers, and app flows; compare each client write against the checked-in rules; run Dart analysis after fixes.
- This is a local Codex review record, not a raw transcript from a hosted pull-request review. It must not be presented as an external PR approval. A raw hosted-review output is still a submission gap.
- AI tools disclosed for this Lab 3 work: OpenAI Codex (code generation, debugging, static code review and documentation) and Google ARTEMIS (test agent, authored for E2E but not executed). No claim is made that ARTEMIS produced results before a live run.
- The user explicitly requested that changes remain uncommitted for review. The Lab asks for three finding-specific fix commits, so that evidence cannot exist until the user reviews and commits the fixes.

## Findings

| ID | Kind / severity | File:line | Finding and impact | Decision and requirement-based reason | Fix status / commit |
|---|---|---|---|---|---|
| BW-01 | Bug / P1 | `lib/services/workflow_service.dart:33-54`; `firebase/firestore.rules:54-72` | Parent class-adjustment flow attempted to update a chat status that rules deny, so its batch/workflow could fail. | **Accepted.** Lab section 5 separates business logic/external calls and the rules make chat status server-owned. Parent now appends an allowed response; only backend advances status. | Fixed in working tree; commit intentionally pending |
| BW-02 | Bug / P2 | `lib/services/matching_service.dart:68-115` | AI output was untrusted JSON; invalid root/list/IDs could escape the intended recovery state or recommend a non-catalog tutor. | **Accepted.** Lab section 3 requires real source data and visible error/recovery; service validates the response and matches IDs only to active Firestore results. | Fixed in working tree; commit intentionally pending |
| BW-03 | Security / P1 | `lib/services/notification_service.dart:170-177`; `lib/viewmodels/controllers.dart:85-95` | Device-token cleanup after Firebase sign-out loses the UID authorization required by `parents/{uid}/devices/{id}` rules. | **Accepted.** Lab section 6 requires per-user storage and sign-out that clears local user data. Controller deletes the installation association before Auth sign-out and surfaces cleanup failure without signing out. | Fixed in working tree; commit intentionally pending |
| BW-04 | Performance / P2 | `lib/services/tutor_repository.dart:18-21` | Search filters at most 100 active tutors locally, so a result beyond the cap is omitted. | **Modified.** The cap prevents an unbounded catalogue read; document the measurable 100-record boundary and require cursor/query pagination when the approved catalogue grows beyond it. This is a known product limitation, not a solved pagination feature. | Follow-up required before a large catalogue |
| BW-05 | Product contract / P2 | `lib/services/matching_service.dart:24-66`; `docs/architecture.md` | Guest one-successful-match entitlement has no defined persistence/session rule; local-only state could reset on reinstall or restrict another device. | **Rejected for this implementation.** Lab 3 does not specify this entitlement; implementing an invented quota could change Lab 2 product behavior. Owner must define a trusted persistence contract before adding it. | No code change; product decision pending |
| BW-06 | Architecture / P2 | `lib/services/chat_service.dart:97-104`; `firebase/firestore.rules:45-68` | Parent messages cannot update server-owned `chats.updatedAt`, so ordering by that field does not reflect most recent activity. | **Modified.** Client chat writes remain denied as required by the trust boundary. A trusted backend projection is needed to implement true activity order; this repository has no approved backend deployment/identity. Do not claim recent-activity ordering until it is added. | Backend follow-up required |

## Verification

- `dart analyze` reports `No issues found` after the findings and lint cleanup.
- The three fixes are present in the working tree but are not separate Git commits, by explicit user instruction.
- The previous Firestore production rules were published but have not been exercised against the emulator or signed-in app. Updated local tutor-application rules are not yet compiled/published because the emulator and Gradle both hit the Windows/JDK loopback error. Storage rules remain a checked-in baseline because the Spark plan cannot provision/use Firebase Storage. Android build remains blocked; see `docs/lab3-report.md`.
- No hosted PR review tool output or external approval has been captured.


## Corrective audit - 2026-10-30

Internal Codex static/security review; not an external independent reviewer.
PR #1 reviews/comments APIs returned empty arrays (raw JSON in
`evidence/corrective/pr1-*.json`). EXTERNAL_REVIEW_NOT_AVAILABLE.

| Finding | Severity / reproduction / impact | Fix and commit | Regression evidence |
|---|---|---|---|
| BW-C01 | P1: sign in A, receive push, switch B; device-global v1 inbox exposed A entries | UID v2 keys, recipientUid gate in foreground/background/open, guest empty, auth invalidation, stale-role guard; `da73da3` notification_service.dart/app_providers.dart | notification_service_test.dart (2 tests): switching, sign-out, wrong/missing recipient, guest, duplicate |
| BW-C02 | P2: Auth account creation succeeds then Firestore fails; same-email registration previously cannot recover | Reauthenticate on duplicate email, reconcile only absent parent/non-applicant profile; preserve existing profile display name on login; `1bc63f6` auth_service.dart | auth_service_test.dart (3 tests): failed-write retry, existing roles, incorrect password, no deletion |
| BW-C03 | P1 invariant / P2 client: arbitrary proposalId accepted by responses rules, allowing out-of-chat/stale responses | Current same-chat consultant kind/status/pointer/expiry + one response per ID, client transaction; `b8f97c4` workflow_service.dart/firestore.rules | workflow_service_test.dart (3 tests), real rules proposal positive/negative tests |
| BW-C04 | P1: no executable emulator suite; same batch could create both parent and applicant under pre-write exists checks | getAfter/existsAfter role exclusion and reciprocal request/chat links; own stale installation cleanup for new applicants; `b8f97c4` firestore.rules/rules.test.cjs | 26 real Firestore/Storage emulator tests, ownership, immutability, malformed fields, state, PDF type/size |
| BW-C05 | P2: runner preflight left no machine-readable blocker and successful AI JSON could be mistaken for verified E2E | BLOCKED manifest, exact pytest exit, PENDING_VERIFICATION, source SHA/hash, fresh output guard, no passwords in TC-26 goal; `114d682` e2e_test/ | 26-case SDK collection, offline harness check, actual blocked preflight manifest |
| BW-C06 | Build: current Dart/Java incompatible, prior loopback failure had no current reproducible evidence | Pin Flutter 3.47.8/JDK21/Node24 CI; process-local D-drive tooling/caches; `114d682` workflow/scripts | pub/analyze/tests/rules logs; Gradle loopback observed; Android build has separate status |
| BW-C07 | P1: application creation batched with device/chat/message/response/payment write could use pre-write role state | All parent create/update boundaries now use post-write applicant exclusion; `865d91d` firestore.rules | Emulator regression first reproduced the unauthorized device write (25 pass / 1 fail), then all 26 passed, including mixed batches across every write boundary; rules-role-batch-red.log and rules-test.log |
| BW-C08 | P2 harness portability: missing Get-FileHash module stopped manifest creation after the first subprocess | Use built-in .NET SHA256 with disposed stream/hasher; `7afe6a3` run-artemis.ps1 | Synthetic uv process doubles preserve exit 7 across three FAIL records and exit 0 across three PENDING_VERIFICATION records, all with log hashes; no mobile test executed |
| BW-C09 | P2 harness: an absolute D-drive output directory was joined to the C-drive repo path and rejected | Resolve rooted paths directly; `567a97f` run-artemis.ps1 and reusable scripts/check_artemis_runner.py | Process-double checks with absolute D output verify exit 7/0, three records each and independently recomputed log hashes |

No review approval was fabricated. The suite uses 3 dev-only dependency overrides
for published transitive advisories; npm audit reports zero remaining findings.
No application dependency was upgraded. See backend-contract.md for remaining
server/FCM/OS/privacy limitations. New proposal fields require staging fixture
migration; old incomplete proposals deliberately fail closed.
