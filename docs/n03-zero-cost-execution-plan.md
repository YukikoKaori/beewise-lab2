# Historical planning snapshot — superseded by approved regression scope

This document records the earlier zero-budget decision and its offline planning.
On 2026-11-05 the owner subsequently approved the exact .50 regression proposal
SHA256 769b22c4dac2a6736953d2ba4daaa7dd433cbc61b15288680c939b30b115a141.
Current authority: 10 official cases × 3 accepted runs, 240 inference attempts,
36 admitted sessions / 6 failures maximum, shared cumulative ledger. No exploration
or additional Firebase Gemini calls. See vidence/artemis/n03-deepseek-final/.
The observations and estimates below remain historical, not current run counts.

# N-03 — current $0 execution policy and minimal-cost plan

Effective owner decision, 2026-11-05: **paid inference budget $0; no live
DeepSeek calls authorized**. The approximately $1 shared balance belongs to
the owner's cross-project allowance; Nexora has priority. BeeWise must not
consume that balance, change Nexora, buy credit or top up automatically.
The prior $5 / 500-inference proposal was **DECLINED**, not approved or deferred
authorization. It remains preserved as an incident-free proposal history only.
No new spending authorization is requested by this plan.

## Actual baseline and offline repairs

Historical native TC-09 trace `69488a18-9d58-4249-8625-0e1682127982` remains
**FAIL**: five genuine screens visited, but `observations` was returned instead
of required `destinations`. Its 5 inference responses used 44,321 input and
848 output tokens. Initial System UI ANRs and recovery are unchanged historical
evidence, not clean-boot PASS. The corrected patch has no new Android acceptance.

- Forward the existing OutputConfig into Flash goal; no extra Outputter call.
- Keep TC-09's five ordered objects, strict boolean fields and zero visual
  overflow/crash assertions. Explain that an overflow-menu icon is not a layout
  defect. Invalid output fails; no renaming of stored JSON.
- Disable DeepSeek streaming at the adapter; avoid a rejected streaming request
  followed by a second completion. Keep non-thinking and max 2,048 output tokens.
- In isolated DeepSeek-only mode, use one attempt per model invocation, no
  automatic transient-error retry/pause-resume cycle and no identical fallback.
  Retry a failed Android case only as an explicit separately recorded attempt.
- Disable optional Flash visual summaries for short cases, video analysis and
  duplicate background concurrency. Retain required screenshot observations,
  real native interactions and the genuine Pro-engine exploration criterion.
- Persistent pre-send request/cost reservations across every role and restart;
  failed requests stay charged to the allowance. A missing ledger/default host
  allows zero egress. The checked-in owner policy now prevents enabling a live
  host or initializing a batch through the provided launchers.

## What actual TC-09 usage permits us to estimate

Public official prices checked 2026-11-05: peak uncached Flash input $0.30/M,
output $1.20/M; off-peak half those prices. Ignore cache discounts.
Historical run costs **$0.0143139 peak / $0.00715695 off-peak** by calculation;
these are estimates from SDK usage, not an actual billing receipt.
See [DeepSeek prices](https://api-docs.deepseek.com/quick_start/pricing/).

| Scenario | Inference calls | Peak estimate | Off-peak estimate | Limitation |
|---|---:|---:|---:|---|
| One corrected TC-09 | 5 if behavior repeats | $0.0143 | $0.0072 | Has not been retested |
| 30 runs identical to TC-09 | 150 | $0.4294 | $0.2147 | Arithmetic lower planning reference, **not a suite forecast** |
| Regression planning range, 5–10 calls/run | 150–300 | $0.4294–$0.8588 | $0.2147–$0.4294 | Trial/revision/auth flows can take more turns |
| 20-minute Pro planning range | 100–200 | $0.2863–$0.5726 | $0.1431–$0.2863 | Assumes TC-09 average tokens/call; Pro can be substantially higher |
| Combined reference range | 250–500 | $0.7157–$1.4314 | $0.3578–$0.7157 | **Excludes failures, higher Pro context, longer responses and other overhead** |

Therefore neither $1 sufficiency nor a fixed lowest completion cost is established.
At the retained pre-send maximum, one request reserves $0.0159744; even 250
maximum-sized calls reserve about $3.99. Request/cost limits must be respected
before egress, never justified after spending by a favorable average.
Off-peak scheduling can reduce eventual authorized cost; **it does not make
DeepSeek free**, restore a free daily quota, or override the current $0 decision.

## Legitimate zero-API-cost alternatives — investigated, NOT activated

1. **Gemini Developer API free tier on one authorized existing project.** Official
   [billing](https://ai.google.dev/gemini-api/docs/billing/) and
   [pricing](https://ai.google.dev/gemini-api/docs/pricing/) document a free tier
   for eligible models. [Rate limits](https://ai.google.dev/gemini-api/docs/rate-limits)
   depend on the project/model/tier, apply per project (not per key), and RPD
   resets at midnight Pacific. Current actual quota/model access for an ARTEMIS
   free-tier project is **NOT VERIFIED**. AI Studio's interactive UI being free
   is not proof that an automated API workload has unlimited quota.
   Switching ARTEMIS requires an explicit owner provider/model decision, a
   verified vision + tool-calling model, no billing-enabled fallback and a fresh
   zero-cost allowance. This is separate from BeeWise's Firebase AI Matching;
   no F-02 request/configuration is included. Existing Gemini 429 receipts remain.
2. **Local vision model.** It can avoid external inference billing, but no suitable
   local model/server is installed or validated here. The model must support
   images AND ARTEMIS's actual tool/structured output contracts. Installing or
   downloading one, memory/latency suitability alongside Android, and the full
   Pro path remain unverified; do not call a text-only local model equivalent.
   No installation, paid host or provider switch has been performed.
3. **Official DeepSeek API.** The published pricing bills inference against
   topped-up or granted balances; no recurring free inference quota was found
   there. A promotional/granted balance is still an owner's shared resource,
   and is not authorized for BeeWise. Waiting another day does not make the
   same API calls free. A free consumer chat page is not an ARTEMIS API allowance.

No account, project or key rotation to bypass limits. No new project, quota
increase, credit purchase, billing activation or cloud mutation is proposed.

## Daily execution plan if a legitimate free tier is later authorized

First verify actual remaining RPM, TPM and RPD in that same project. Reserve
calls for genuine retries/summary roles, and choose each day's cases whose
complete sessions fit. Honor provider Retry-After; stop the batch on quota
errors rather than repeatedly probing. Resume accepted-run counts and evidence
the following quota day with new trace IDs; never reclassify failed attempts.

Examples only, using 5–10 calls per simple case and ignoring reserve/other usage:

| Actual free RPD | Regression sessions/day | Days for 30 | Exploration constraint |
|---:|---:|---:|---|
| 20 | 2–4 | 8–15 | Insufficient for the 100–200-call Pro planning range |
| 100 | 10–20 | 2–3 | Needs its own day; 200-call session cannot fit this cap |
| 500 | 50–100 theoretical | 1 | RPM/TPM, latency and actual Pro behavior still constrain it |

These are conditional scheduling examples, not current account quotas or PASS
claims. A continuous 15–30 minute Pro exploration cannot be stitched across
days or replaced with Flash. Distributing regression alone does not resolve an
insufficient per-day exploration quota. Measure wall-clock duration separately
from the model's `elapsed_minutes` self-report.

## Exact remaining gates

- Fresh corrected TC-09 real native PASS with strict schema, JUnit and frames.
- At least 10 eligible official cases with 3 independently verified PASS each;
  current new packet has **0 accepted cases, 0 accepted runs**.
- Safe deterministic local Auth/Firestore/backend fixtures and actual native
  account-picker eligibility for the selected matrix. Existing backend tests
  are regression support, not ARTEMIS executions.
- A genuine Pro-engine continuous exploration of 15–30 minutes (target 20),
  with all model roles accounted for, screenshot/trace verification and no
  Firebase Gemini or real payment calls.
- Final evidence audit and final PR/exact-HEAD CI after acceptance. No interim
  PR or push under an incomplete N-03 completion claim.

**Current blocker:** no authorized live inference allowance. No currently
verified, authorized zero-cost provider path can satisfy these live gates.
Offline work can prepare compatibility and regression safety; it cannot make
N-03 COMPLETE. No resources in Nexora are modified or consumed by this work.
