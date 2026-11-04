# Bao F-02 — live Gemini acceptance, 2026-11-04

> **Latest owner decision, 2026-11-04:** the owner accepted the disclosed
> authorized1/actual2 request deviation retrospectively. The earlier draft
> hold below is historical and resolved; ready for review is conditional on
> final-HEAD gates. No additional provider calls, cloud/billing changes or
> deployment are authorized. Bao retains F-02; Nguyen owns F-03 only.
> [Owner acceptance and existing-data DebugView inspection](owner-finalization.md).


**BAO F-02 COMPLETE — LIVE VERIFIED in the tested API35 guest/debug scope.**
**Delivery remains DRAFT for owner review:** an automation coordinate error
caused **2 actual Flash-Lite calls against an approved maximum of1**. The excess
call is disclosed below; it must not be described as authorized. No merge is
performed. F-03 belongs to Nguyen and remains pending implementation; B-04
overall and Lab3 are not complete.

## Exact tested source and configuration

- Source: `3c5961aacdd50e3490beea63578628a8dc88c61f`.
- Default `lib/main.dart` debug APK SHA256:
  `3542276a8108123056c93eaa9524490c5dfa58186115daa2381031fba1ae568f`.
- Existing API35 AVD `BeeWise_Bao_Acceptance_API35`, `emulator-5562`,
  720×1600px/density320/360×800dp; existing userdata and Firebase files preserved.
- Firebase project `beewise-lab-3`, package `com.beewise.beewise`.
- Firebase AI Logic `FirebaseAI.googleAI()` / Gemini Developer API /
  **`gemini-3.5-flash-lite`**. [Runtime getters](runtime-config.json) confirm the
  model, feature enabled and RC result limit3 in the actual app.
- [Guest-state receipt](guest-state.json) checks only Auth SDK `currentUser==null`;
  no raw UID was read/exported. Parent-specific AI and release/physical-device
  attestation are outside this native run.
- [Cloud readback](cloud-readback.json), **2026-11-03T20:19:11.395Z**:
  required APIs enabled, AI App Check ENFORCED, Android ACTIVE, Play Integrity
  configured, billing off, Agent Platform/Cloud Functions disabled. Debug and
  release initialization remain AndroidDebugProvider/AndroidPlayIntegrityProvider.
  Fresh SDK token acquisition and a successful protected provider call are
  evidenced in [safe native excerpts](native-safe-excerpts.txt).

The owner explicitly approved [this exact model proposal](approved-model-proposal.json),
SHA256 `54d1644b6169665bc0d0fbbeae2912024eefc53dbb5aaef4bea15212551262ef`.
Only the app's model default/empty fallback and corresponding tests changed;
configured RC overrides still work. No RC publication, API/token/enforcement/
billing/quota mutation, backend or F-03 implementation occurred. Current
[official Firebase model guidance](https://firebase.google.com/docs/ai-logic/models?api=dev)
lists this model/provider without requiring billing. Read-only
[project quota metadata](model-quota-readback.json) shows15 requests/minute and
500/day; this is configured capacity, not measured usage or a quota increase.

## Actual provider, parser and native result

The first normal-UI submit occurred at **2026-11-03T20:14:33.008516Z**.
The SDK recorded model3.5 Flash-Lite, finish `stop`, totalTokens387 at device
**2026-11-04 03:14:37.986 UTC+07** — approximately5s later, comparing host/device
clocks rather than claiming calibrated network timing. No mock or VM-injected
recommendation was used. [Input](f02-lite-input.png) and
[actual AI card](f02-lite-result-card.png) are authentic Android captures.

The actual JSON passed the strict production parser. Read-only
[recommendation/controller inspection](recommendation-validation.json) found
exactly1 result, ID `tutor_acd3824aa8734c63ac8827df`, active=true, verified=false,
demoOnly=true, syntheticFixture=false, nonempty reason102 Unicode code points,
no duplicate IDs and count1<=RC limit3. A separate native Client SDK
`Source.server` read confirmed the same document exists and those three stored
flags remain unchanged. No professional verification state was elevated.
The screenshot's explanation matches Maths/grade10/TP.HCM/in-person/budget and
does not claim professional verification. Full model response prose is not
exported as a log; the visible technical explanation is part of the native UI.

The AI card opened the real [tutor detail](f02-lite-ai-detail.png), including
explicit demo/unverified-professional disclosure. The normal manual-fallback
button subsequently opened [Search with the real demo record](f02-lite-fallback-verified.png).
That verified fallback capture follows a fresh state inspection; earlier
mis-targeted captures remain private and are not labelled as fallback success.

## Analytics and error/recovery proof

FA-SVC's real native upload bundle contains **`ai_match_success`, result_count1**
at event timestamp **2026-11-03T20:14:37.994Z** and the second event described
below. [Sanitized receipt](analytics-native-receipt.json) exports only event
timestamps/counts, without UID, screen/session IDs or user properties. No event
was manually re-logged to manufacture this proof. The actual AI-detail visit
also logged `view_tutor`, subject_count2, entry_source=profile_route.

Verbose FA/FA-SVC and the debug package property were enabled after the first
provider call to inspect its queued real event, then restored to their original
empty values. The debugger detached without hot reload. Fresh Console DebugView
UI capture was **NOT RUN** because the browser bridge was unavailable; native
upload-bundle evidence is not presented as a fresh Console receipt. Historical
Analytics identity/logout findings remain unchanged and were not reopened.

The preserved [earlier3.8 packet](../f02-native-20261104/README.md) contains genuine
500/high-demand and30s timeout/input-retention/normal-UI retry/manual recovery.
Only the model default changed for this final APK; error handling did not.
Typed500/quota/config/timeout messages and retry-to-success are covered by
focused tests. No additional live fault request was generated on3.5 to fill a
test matrix, and native3.5 retry-after-fault success is not claimed.

## Root causes and limits

The actual provider rejected historical2.5 for this new project. Current
App Check APIs/provider/token/enforcement are configured and a protected3.5
request succeeds. Historical disabled-API/Too-many-attempts observations are
not evidence that every later failure had the same cause.

Model3.8 produced a real high-demand500 and later provider-await timeouts. Their
complete latency/transport root cause remains unproven; a timeout is not an
emulator ANR or proven Flutter defect. The approved lighter model is a verified
working choice in this controlled environment, not proof that it alone explains
every3.8 timeout. No arbitrary startup/AI delay, timeout extension, security
bypass, paid billing or quota increase was introduced.

The service sends bounded allowlisted catalogue fields, requires structured
JSON, rejects unknown/inactive/synthetic/duplicate IDs and bounds explanations.
Focused unit tests deliberately exercise hostile/malformed/empty/limit/error/
retry cases; those tests are labelled unit coverage, not live provider proof.
The live catalogue contains one consented technical demo, not a professionally
verified production tutor supply. No Parent-specific/release/physical-device
or general availability/load claim is made.

## Execution-budget deviation

The proposal authorized at most1 live Flash-Lite call. The first was intentionally
submitted and fully evidenced. While returning from AI detail to manual fallback,
keyboard/layout reflow changed the button coordinates. A stale coordinate hit
AI submit, causing a **second actual call**, response at **03:17:39.039 UTC+07**,
also stop/387 tokens/result1. Its exact submit timestamp was not separately
recorded. Later keyboard gesture input added a short suffix to the text after
submission; do not confuse that later input with the first request.

This was an automation error, **not owner authorization or an app root cause**.
It was disclosed immediately, further AI calls stopped, and fallback was then
verified from fresh bounds. [Session receipt](native-session.json) records
authorized1/actual2; both real Analytics events are retained. Billing remains
disabled, no configuration scope expanded, and no retroactive authorization is
implied. Keep the PR draft for owner review of this deviation; do not silently
mark the execution as conforming to its request budget.

## Quality and handoff

[Final-source local gates](quality-receipts.json): locked pub get, format44/0,
analyze, **105 Flutter tests**, **58 Firebase Emulator Rules tests**, debug APK,
structural harness27 functions and startup-parser4/4 PASS. Harness validation
is structural, not27 executed Android E2E cases. Final delivery-HEAD Actions are
linked in the PR; an earlier successful run is not substituted for them.
The manifest uses Git blob bytes/LF-normalized text and excludes itself.

F-01 and previously completed B-01/B-02/B-03.1–6/B-05 evidence is preserved.
Auth/FCM/PDF/Analytics/Crashlytics/RC protections and strict Rules remain intact.
No Nguyen UI, ARTEMIS, reports, billing, Storage or trusted-backend change is
included. **Storage remains DEFERRED.**
[Nguyen's F-03-only handoff](../../../docs/workstreams/bao-to-nguyen-b04-handoff.md)
defines the backend/payOS/security/state/tests and Firebase coordination.
F-03 WIP stays private/local and excluded from this PR. Bao retains approved
Firebase infrastructure/security support. B-04 overall/Lab3 remain incomplete.
