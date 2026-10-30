# Lab 3 AI code review record

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
