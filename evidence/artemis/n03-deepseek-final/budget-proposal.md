# N-03 consolidated execution proposal — PENDING OWNER APPROVAL

Prepared 2026-11-05. This document authorizes nothing by itself.

## Scope and current account

- BeeWise base a72059ca5e07a4c1193960965dc07453efea161d; ARTEMIS baseline
  351ca8422f7b5b54e80a9c1ce03a222e02415b6b plus isolated compatibility patch.
- Official DeepSeek / `deepseek-flash`, non-thinking Chat Completions only.
  Authenticated model read confirms text + image support. `deepseek-v4-pro`
  is not selected, including for Pro orchestration.
- Fresh read-only account receipts: available, USD balance covers $1 but does
  not cover $2 or $5. Exact balance and credentials are deliberately not exported.
  No inference in this new mission. Three read-only HTTP requests are recorded
  separately from the historical 1 model read + 5 inference attempts.
- Funding is an external prerequisite for a $5 run allowance. No automatic
  top-up, purchase, billing change, or use of another account/provider.

## One proposed authorization

Authorize **at most 500 inference HTTP attempts and $5 conservative reserved
estimated spend**, whichever is reached first, for this N-03 plan. All model
roles, summaries, retries, Outputter and exploration share the same ledger.
This is a ceiling, not an instruction to spend the balance or a promise that
every case will succeed. No Firebase Gemini calls, real payments, cloud changes,
credential changes, or production data writes are included.

1. One fresh corrected TC-09 first; independently inspect native captures,
   ordered `destinations` JSON, pytest and JUnit. Stop suite admission on failure.
2. Target TC-01/03/04/05/06/08/09/16/20/22, three accepted independent runs each
   (30 accepted sessions; the first successful retest can be one TC-09 run).
   Native TC-16 requires a genuine safe Google picker and no private account
   exposure; substitute an eligible official case only with equivalent native
   coverage and documented prerequisites, never weaken an assertion.
3. Up to 10 failed/corrective regression sessions beyond those 30; at most two
   corrective retries for a case. Every failure remains in the manifest.
4. One 20-minute measured **Pro-engine** exploratory session after regression
   stability. At most one fresh retry if an earlier exploratory session ends
   early; both count against the same caps. No idle padding to fabricate duration.
5. Expected Flash calls 5–10 per regression (150–300); Pro plus optional judges,
   summaries and failed attempts approximately 100–200. Target 300–450, ceiling
   500. If prerequisites/Pro compatibility fail offline, do not spend to probe
   a known-unusable path.

## Price, pre-send enforcement and cost uncertainty

Official peak uncached Flash pricing checked 2026-11-05:
$0.30/M input and $1.20/M output. Cached/off-peak discounts are ignored.
Sources: https://api-docs.deepseek.com/quick_start/pricing/ and
https://api-docs.deepseek.com/guides/vision/ .

Historical TC-09 actual 44,321 input + 848 output over five calls implies
$0.0143139 at these conservative prices (an estimate, not a billing receipt).
300–450 similar calls would cost approximately $0.86–$1.29; Pro histories and
longer outputs can increase that substantially. The $5 reserve is intended to
allow this variability, not to imply an existing $5 account balance.

Pre-send bounds: exact endpoint/model, non-streaming/non-thinking, at most eight
inline user images, 32,768 non-image UTF-8 JSON bytes, output at most 2,048 tokens.
Reserve one text token per non-image UTF-8 byte + 4,096 framing tokens + the
documented maximum 1,024/image, at peak uncached rates. Maximum request reserve
is $0.0159744; 500 maximum-sized requests would exceed $5, so the **cost cap can
stop execution before the request cap**. No request is sent if its full reserve
would cross either ceiling. Typical reserves exceed actual reported usage.

SQLite transactions serialize all workers. Reservations are committed before
network egress and never refunded, including timeouts/HTTP errors/process death.
Only counts, timestamps, bounds, usage and status codes are stored. Successful
responses with missing/invalid usage or usage above reservation freeze the batch.
SDK retries are zero. Non-DeepSeek factories and stock Gemini warmup fail closed.

## Stop and resume policy

- Same cumulative SQLite ledger on every host restart and batch; never reset or
  create a replacement to bypass a cap. Missing/corrupt/expired state fails closed.
- Batch expires after 24h; stop and report unfinished acceptance rather than
  silently extend approval. Recheck official prices before starting; stop if rates
  increase or the account cannot support the next reserved amount.
- Before each admitted session, check a responsive API35 guest/local fixture,
  provider account availability and remaining reservation. No billable tests on
  an ANR-blocked device. Normal Wait only in already authorized operational scope.
- Stop on account insufficiency/402, auth errors, persistent quota errors, provider
  substitution, privacy risk, repeated unusable Android state or missing evidence.
- Resume from recorded attempts and already accepted sessions, using new trace IDs
  for genuine retries. No event replay, stored-JSON renaming, or acceptance inflation.
- Local Firebase Auth/Firestore + trusted backend/fake payOS only for stateful
  cases. Technical demo tutor stays active=true, verified=false, demoOnly=true.
  TC-05 uses an actually empty local catalogue and makes no Gemini invocation.
- Run all independent offline/build/fixture gates while owner approval/funding is
  pending. Do not initialize an approved ledger or submit inference beforehand.

Current proposal status: **NOT APPROVED; FUNDING NOT SUFFICIENT FOR FULL CAP**.
