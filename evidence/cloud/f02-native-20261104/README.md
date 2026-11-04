# F-02 native investigation — 2026-11-04

**BAO F-02 NOT COMPLETE — no successful Gemini JSON/result received.**
F-01 remains the existing verified cloud flow. **NGUYEN OWNS F-03 ONLY;
BAO RETAINS F-02 AI MATCHING / APP CHECK.** B-04 and Lab 3 are not complete.

## Build and environment

- Source: `c49716916e432fb6a8271d3f501c10546d65717d`.
- Default production entrypoint `lib/main.dart`, debug APK, SHA256
  `32fba1b8df142a98772c096c7e0588cc94f1f78dd57b94ae99614bba42e37223`.
- Existing `BeeWise_Bao_Acceptance_API35`, `emulator-5562`, API35,
  720×1600 px / density320 / 360×800dp. Userdata preserved.
- Firebase `beewise-lab-3`, Android package `com.beewise.beewise`.
- Real `FirebaseAI.googleAI()` / Gemini Developer API / `gemini-3.8-flash`.
  No diagnostic entrypoint, injected recommendation or mock provider on device.
- [Read-only running-service configuration](runtime-config.json) confirms
  model3.8, matching enabled, result limit3 and timeout30s in the actual process,
  rather than inferring those values only from source defaults.
- Exact timestamps/build metadata: [session receipt](native-session.json).
  Later documentation commits do not change the tested application source.

## Findings and changes

Historical `Too many attempts` and disabled App Check API observations are not
the current state. Exact owner-approved API enablement, Gemini setup/terms,
authorized development-token registration and AI-only enforcement were already
performed before this final ownership correction. Read-only
[current configuration](cloud-readback.json) at **2026-11-03T19:58:37.470Z** shows
the three required APIs enabled, `firebaseml.googleapis.com` ENFORCED, correct
Android app, configured Play Integrity, billing disabled, Agent Platform and
Cloud Functions disabled. [Console provider settings](ai-settings-public.png)
show Gemini Developer API enabled; only the nonessential account chrome was
cropped. No new cloud mutation was performed during these retry attempts.

The actual native App Check SDK returned a nonempty JWT-shaped token on the
current APK/process at **2026-11-04 02:58:40.965 device local time (UTC+07)**.
This verifies acquisition, not an independent cryptographic token audit or
release Play Integrity acceptance. Two registrations of the same approved debug
token remain after an earlier repeated registration; cleanup was proposed
separately and has **not** been performed. No token/registration secret is in Git.

Earlier model2.5 was rejected by the actual provider as unavailable to new users.
The owner separately approved model3.8; both local RC defaults/fallbacks now use
it, with **no Remote Config publication**. The current
[official model list](https://firebase.google.com/docs/ai-logic/models?api=dev)
supports that provider/model without requiring billing. The
[App Check guidance](https://firebase.google.com/docs/ai-logic/app-check)
supports retaining enforcement and the debug/release provider separation.

The first real3.8 invocation returned HTTP500 INTERNAL with a high-demand
message. The next invocation and two separately approved UI retries timed out
after30s at the provider await (`matching_service.dart:73`), after candidate
loading. [Safe native excerpts](native-safe-excerpts.txt) separate these errors
from historical App Check failures. No successful provider-response metadata,
JSON, recommendation list or `ai_match_success` event was observed. A timeout
alone does not establish provider capacity, network, SDK or model latency as
its root cause. Do not describe App Check as the sole cause of all failures.

Read-only [configured quota](quota-readback.json): model3.8 free-tier5 requests/
minute,20/day,250000 input tokens/minute; AI gateway100 requests/minute/user.
These are limits, **not usage/capacity proof**. No429 was observed, quota was not
increased, and billing remains off. All four approved3.8 requests are consumed;
no automatic retry/model substitution is authorized by this packet.

Application changes validate bounded input and allowlisted candidate fields,
apply the RC feature/count/model controls, require structured JSON, reject
unknown/inactive/synthetic/duplicate IDs and bound nonempty explanations.
Provider errors now render a recoverable localized message instead of raw
provider JSON. Timeout preserves the user's text. Native error/loading/manual
fallback are genuine; parser/ID/retry positive cases are unit tests, not live
Gemini acceptance. No mock recommendations are used by the production service.

## Acceptance matrix

| Requirement | Result / evidence |
|---|---|
| Debug App Check configuration/token | PASS tested acquisition/config scope; [readback](cloud-readback.json), [native metadata](native-safe-excerpts.txt) |
| Release Play Integrity end-to-end | NOT RUN; initialization/config preserved |
| Real provider invocation | Actual500 response previously; current timed-out awaits; **no success** |
| Actual Gemini JSON / validated recommendations | BLOCKED; absent provider result; no tutor recommendation invented |
| Unknown/duplicate/synthetic IDs, limits, malformed JSON | PASS focused unit tests only;9 MatchingService cases plus typed-error test |
| Approved catalogue unchanged | Native Client SDK `Source.server` read: exists=true, active=true, verified=false, demoOnly=true for `tutor_acd3824aa8734c63ac8827df`; [safe excerpt](native-safe-excerpts.txt) |
| Actual Android loading/error/input retention | PASS; [loading](f02-final-loading.png), [timeout](f02-extra-2-settled.png) |
| Normal UI retry | Executed twice, returned timeout; recovery-to-AI-success **not verified** |
| Manual search fallback | PASS on same final APK; [real disclosed demo card](f02-final-manual-card.png) |
| Tutor detail navigation/disclosure | PASS from manual fallback; [native detail](f02-final-manual-detail.png); AI-result-to-detail remains pending |
| Analytics success/result_count | NOT OBSERVED; cannot claim success event without actual result |
| Parent-specific AI success | NOT RUN; guest test cannot establish it |
| Privacy | No raw UID/email/token/prompt response dump in this packet; consented demo profile shown |

Every final native capture has a timestamp/source/hash JSON sidecar. XML and full
logcat remain private to avoid unrelated identities/system output. Screenshots
are authentic native captures; no generated or reconstructed result screen.
The manifest hashes Git blob bytes (LF-normalized text), so Windows checkout
line endings do not change the reviewable artifact identity.

## Quality and preserved scope

[Quality receipts](quality-receipts.json): locked pub get, format44 files/0 changes,
analyze, **105 Flutter tests**, **58 Firebase Emulator Rules tests**, debug APK
build, structural E2E harness check27 functions and startup parser tests4/4 PASS.
The harness check is structural; it is not27 executed Android E2E cases.
Build used local no-daemon/Kotlin-incremental-disabled flags to avoid a C:/D:
cache-path issue; no Android source/config workaround was committed. CI for the
delivery HEAD is recorded in the PR, not inferred from these local receipts.

Auth/Firestore/FCM/PDF/Analytics/Crashlytics/RC historical acceptance is retained
in [the prior packet](../bao-acceptance-20261103/README.md); those live suites were
not reopened or claimed freshly rerun here. No Rules, Storage, billing, backend,
Nguyen UI, ARTEMIS or report implementation is part of this change.
[F-03 WIP hashes](f03-wip-preserved.json) confirm12 files unchanged against the
private pre-transfer archive. F-03 code/CI/exclusions remain local, outside this PR.

## Actionable blocker and resumption

Keep the delivery PR **DRAFT / CORRECTIVE**, not merge-ready for F-02 acceptance.
The exact missing evidence is a successful normal-UI Gemini response followed by
validated real tutor results, AI-result detail navigation and native Analytics
success. Do not close it with unit mocks or API enablement.

After provider recovery, a separately approved bounded call budget can retest
the same APK/model/config, capturing the HTTP/provider outcome and latency.
Alternatively, propose a currently supported lighter model with exact approval
and rebuild/test; do not silently switch provider/model, extend arbitrary
timeouts, increase quota or disable App Check. If timeouts persist, investigate
the actual transport/provider latency before changing application behavior.
No pending cloud mutation is required for the currently tested debug scope.
Release/physical-device attestation remains a separate untested scope.

Nguyen's precise [F-03 handoff](../../../docs/workstreams/bao-to-nguyen-b04-handoff.md)
is ready. Finishing it is not Bao's implementation responsibility.
