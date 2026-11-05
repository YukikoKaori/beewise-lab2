# Revised N-03 regression proposal — NOT APPROVED

2026-11-05 owner steer supersedes the rejected $5 / 500-call plan. Current
authorization remains **$0, zero live inference**. Nexora retains priority over
the shared balance. No purchase, top-up, credit request or other project change.

## Exact requested scope

**At most $0.50 conservative estimated provider spend for exactly 30 accepted
ARTEMIS regression executions: 10 official cases × 3 independently verified
PASS each.** Stop immediately when all 30 are accepted. This does not authorize
300 tests or an exploratory session. Inference calls are a separate measure.

Proposed safety ceiling: **240 inference HTTP attempts**, not a usage target;
the $0.50 cost guard can stop much earlier. Up to six failed/corrective sessions
beyond the 30 successful sessions; at most two corrective retries of a case.
Stop and report INCOMPLETE when any limit is reached. No promise that $0.50 will
cover the suite. No inference until this exact scope is separately approved.

| Official case | Coverage / real prerequisite |
|---|---|
| TC-09 | Five native-observed destinations; strict ordered `destinations` contract |
| TC-01 | Guest Home / actual visible catalogue state |
| TC-03 | Search no-match and genuine recovery |
| TC-04 | Approved technical demo tutor detail / visible fees and connection action |
| TC-05 | AI UI no-candidate branch using an actually empty local catalogue; **no Gemini invocation** |
| TC-06 | Guest connection/auth gate and preserved tutor context |
| TC-08 | Registration required-field/consent validation; no identity created |
| TC-16 | Genuine native Google picker cancellation and recoverable UI; preflight must exclude private account exposure |
| TC-20 | Parent accepts trusted trial; isolated local Auth/Firestore/backend only; no paid claim |
| TC-22 | Parent requests revision adjustment; no client invoice or official schedule |

These are exactly ten selected official cases, not ten verified cases. TC-27
is excluded. If a prerequisite is ineligible, document it and revise the selected
matrix before spending on a known-blocked session; do not weaken assertions.

Sequential API35 sessions, one AVD only, preserved userdata. No production
records, live payOS, bank transfers, production configuration or application
implementation changes. Technical tutor remains active=true, verified=false,
demoOnly=true. Stateful setup uses legitimate isolated service contracts;
Admin seeding cannot manufacture an assertion success. Fixtures and safe native
picker eligibility remain preflight gates, not presumed PASS.

## First admission gate

Retest corrected TC-09 first, then obtain three real PASS for that case before
other cases. Check each trace, actual screens/actions, exact output, pytest and
JUnit independently. Historical trace `69488a18-9d58-4249-8625-0e1682127982`
stays FAIL. If a new attempt fails, retain it, diagnose/fix the actual layer,
rerun relevant offline gates, and retry only inside the same limits.

## Cost basis and enforcement

Observed TC-09: 5 inference calls, 44,321 prompt + 848 completion = 45,169 total
tokens. Peak uncached estimate $0.0143139; repeating that exact usage 30 times
would be $0.429417. This **does not establish** that 30 different executions fit
$0.50: auth/workflow cases, failures and longer context/output can exceed it.
At 150–240 calls with the historical mean, the reference estimate is about
$0.429–$0.687 before such variability. Never assume the shared $1 covers N-03.

Use official DeepSeek `deepseek-flash`, non-thinking, no Gemini fallback, no
hidden SDK/wrapper retry or identical-endpoint fallback. Peak uncached prices
checked 2026-11-05: input $0.30/M, output $1.20/M; ignore cache/off-peak discounts
for hard-cap accounting. Sources:
https://api-docs.deepseek.com/quick_start/pricing/ and
https://api-docs.deepseek.com/guides/vision/ . Recheck before an authorized run;
stop if prices increase. No new authenticated provider reads while approval is
pending; existing available-model receipt is from before the $0 correction.

Persistent SQLite ledger, same file for all sessions/restarts/roles. Reserve
before every network send: one input token per non-image UTF-8 JSON byte + 4096
framing tokens + 1024 per image, at most eight images/32768 text bytes and 2048
output tokens. Max single reservation $0.0159744. Refuse the next request if its
full reservation would cross $0.50 or the 240-attempt ceiling.

After a complete successful response, preserve its original reservation and
settle the charged estimate from validated native SDK token usage at peak rates.
This releases only unused reservation, **never deletes/restarts the ledger or
resets HTTP counts**. Errors, missing receipts and process death retain the full
reservation. Missing/invalid or unexpectedly excessive successful usage freezes
the batch. Already recorded usage cannot be replayed to lower cost. Output
errors still consume their real token cost and keep their failed case receipt.
Batch state expires after 24h; do not extend/reset authorization silently.

No automatic purchase/top-up; stop on insufficiency, auth/quota errors, unsafe
device state, unexpected provider/model, privacy risk or inability to account
for usage. Read-only account checks, if later necessary, are non-generative and
must be counted separately (at most one initial read and one per resumed batch,
maximum six); no new model probe or inference outside the approved ledger.

## Evidence and delivery

Distinct trace ID per attempt, source SHA, APK hash, model/provider, timestamps,
native observations/screens, strict schema, pytest exit and JUnit. Track real
accepted/failed/blocked runs separately from HTTP calls/tokens/cost. Exactly
three accepted runs per case; never rerun an already accepted run unnecessarily.

No automatic push/merge/deploy. One focused review PR only after evidence is
complete and final checks pass; exact-HEAD CI afterward. N-03 regression remains
INCOMPLETE if the cap or another gate prevents 30 accepted runs. Exploration
remains a separate unmet requirement; prepare its new plan after regression.

**Decision pending: this is a concrete request for approval, not permission.**
