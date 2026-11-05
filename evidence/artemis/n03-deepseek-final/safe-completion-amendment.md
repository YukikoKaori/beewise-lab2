# N-03 continuation amendment — PROPOSED, NOT AUTHORIZED

Approval of this document by exact SHA256 would release **Stage 1 only**. No
session is approved or started by preparation of this packet. The active live
hold remains in place. No ledger replacement, reset, expiry extension, credit
purchase, quota change, provider switch, or use of Nexora resources is proposed.

## Existing ledger and acceptance

17 admitted / 11 PASS / 6 FAIL. TC-01/05/09 already have three PASS each and
must not rerun. TC-03 has 2 PASS / 4 FAIL. The six unrun cases are
TC-04/06/08/16/20/22. Nineteen additional accepted sessions are needed.
All failures and accepted evidence remain immutable.

Same ledger: 102 HTTP attempts, 984,855 tokens, $0.3077667 conservative,
leaving 138 requests and $0.1922333 of the original cap. The separate
cache/off-peak reconstruction is $0.059483478, not a charge receipt or
balance. The current shared account balance and Nexora's reserve are unknown.
The old expiry is 2026-11-06T14:52:19.526760Z and will not be extended.

## Stage 1 — exact approval requested

Allow **one additional admission for TC-03 only**, with **zero further TC-03
retries**. Run the unchanged strict Android case with the offline-tested
input-envelope patch and complete native preflight. This stage can bring the
cumulative admitted count to 18, PASS to 12 or FAIL to 7. Hard cumulative
provider limits remain **240 HTTP attempts and $0.50 conservative** across all
roles and all historical sessions. The operator remains limited to eight turns;
the persistent guard can stop earlier. No additional spending ceiling is
requested. The raw worst-case remaining authorized cost under that ledger is
$0.1922333; it is not a prediction of the cost of one session.

Before admission, use at most one existing read-only balance check under the
prior read allowance. Proceed only if funds available for BeeWise, after
respecting any owner-designated Nexora reserve, cover the remaining $0.1922333
conservative ceiling. If the reserve or available funds cannot be confirmed,
leave the run blocked; do not spend to test account availability.

Recent TC-03 conservative mean: $0.0186114 across the two amended admissions.
Expected remaining ledger allowance after one similar run: **$0.1736219**.
This is a projection, not an exact account balance. Stop after the one admitted
session, or earlier for failed preflight, ANR, local envelope rejection,
provider error, strict output/JUnit failure, or a request, cost or expiry cap.
Save original evidence; no replacement attempt is allowed.

## Stage 2 — planning only, separate release required

After a verified Stage 1 PASS, 18 accepted sessions remain. Allow a planning
buffer of at most **two additional failed admissions** across the six
remaining cases, with at most one corrective retry per affected case after
diagnosis and fresh preflight. That means **19–21 additional admissions total**
across both stages, cumulative maximum **38 sessions / 8 failures**. The buffer
does not apply to TC-03. The matrix stays exactly as approved.

No Stage 2 release until an actual Google account chooser is verified for
TC-16, each local fixture is ready, and a conservative per-case forecast fits
the remaining request and cost caps. Existing add-account and cancellation
screens do not satisfy the chooser requirement. Stage 2 does not authorize
adding a device account, changing the matrix, or any production writes.

Historical mean over 17 admissions is $0.01810392/session. At that rate,
19 remaining successes imply **$0.65174 cumulative** even without new failures;
21 admissions imply **$0.68795 cumulative**. Staying within $0.50 needs at most
$0.01011754 per remaining admission with no failures, or $0.00915397 with both
buffer slots. The offline compaction proves request fit for the replay, not
enough cost savings for that forecast. After the projected Stage 1 result,
the 18 remaining successes need an average at most $0.00964566. If the actual
forecast cannot fit, stop and document the shortfall instead of consuming the
rest of the shared balance. This document requests neither figure above $0.50.

Each future accepted session requires real Android UI actions, a unique trace,
strict structured JSON, pytest/JUnit PASS, and independent review. Keep the
native cold/warm/ANR evidence and full preflight. Use isolated fixtures only;
no payOS transaction, production Firebase writes, Gemini, exploration, merge,
or completion PR before 30 accepted results. Exploration requires its own scope.
