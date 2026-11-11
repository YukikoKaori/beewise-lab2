# Production cross-role acceptance

Baseline: main at `d7fa5bea2ed5276c13ecd3739fa00257676c1242`. CI run 43104437452 attempt 2 passed all five jobs; attempt 1 failed the backend watcher. Project: `beewise-lab-3`, default Firestore, [Web Admin](https://beewise-lab-3.web.app/). Hosting returned HTTP 200. Live Rules matched repository source after newline normalization (SHA-256 `5d59a8a95305744a00a4c4f7397b4b255c76b297b0d654994d6cd5ae3272199a`). The production VietQR query returned 200 with the approved index; this does not establish parity for every repository index or query.

Android: Final-mode debug APK, `lib/main.dart`, `BEEWISE_FINAL_FIRESTORE=true`, Android x86_64, API 35; SHA-256 in manifest. This is Android against production Firebase, not a Firebase Emulator run and not release-device acceptance.

| Run | Expected outcome | Status |
|---|---|---|
| CR-01 | Pending → approved; live Android status and private inbox | PENDING_OWNER_APPROVAL |
| CR-02 | Pending → needs_info; reason in private inbox; same-UID correction → pending if supported | PENDING_OWNER_APPROVAL |
| CR-03 | Pending → rejected; private reason; applicant cannot self-approve or publish | PENDING_OWNER_APPROVAL |
| Extra approval repetitions | Two further independent approvals | NOT_RUN |
| Web non-staff / revocation | Disposable Google identity with role user → staff → user; existing owner unchanged | PENDING_OWNER_APPROVAL |

No timing, review write, private inbox delivery, or unauthorized client denial was observed for these cases. Prior owner screenshot showing the staff workspace is separate from these checks.

After approval: create three disposable tutor identities, one isolated Android application each, with unique run aliases and synthetic data. Review using the existing owner's staff Web session. No public catalogue publication. Keep test audit records, do not replace existing applications. For the disposable Google account, record a non-staff Web denial and an ordinary-client private read denial before temporary promotion; while signed in, restore role to user and verify workspace loss and Rules denial of a valid review attempt limited to the isolated CR-02 application after it returns to pending. If unexpectedly accepted, stop and retain that test-only receipt. No owner demotion. Credentials stay private.

For each run capture Android pending, Web queue/action, Android first updated frame without reload, and visible private inbox. Record staff click and UI observations on one host clock or a continuous recording; record actual write acknowledgment and listener arrival only if separately observable, otherwise mark unavailable. Record server timestamp separately. Never infer UI latency from server timestamps alone.

## Existing Gemini Level 2

The Android screenshots supplied by the owner show the AI-labeled confirmation UI for three cases; source defaults to Gemini Developer API / gemini-3.5-flash-lite. The screenshots do not identify the serving model or preserve raw JSON. AI-01 shows the requested evening/Thủ Đức and 200,000 VND filter with no matching catalogue result. AI-02 shows English grade 7, online/weekend, and 160,000 VND after the owner edit; the initial 150,000 is owner-reported and not visible in the saved frame. AI-03 shows physics grade 11, Quận 3, in person, 250,000 VND and no matching result. Airplane mode shows the recoverable AI error; manual search subsequently renders catalogue results with the demo label. Original image hashes identify private source captures, which are not redistributed. Source inspection found an allowlisted academic-hint payload; historical network payloads were not captured for direct comparison. No new requests or event replay.

Analytics: **ANALYTICS_EVIDENCE_PENDING** for ai_request, ai_result_accepted, ai_error. Native log search did not find these events; no historical DebugView receipt was retrieved.

## App Check

| Scope | Status | Boundary |
|---|---|---|
| Web reCAPTCHA Enterprise registration | VERIFIED_LIVE | Approved domain-scoped provider; 3600 s TTL, minimum score 0.5 |
| Web token acquisition | NOT_RUN | No token receipt captured |
| Web App Check accepted request | NOT_RUN | Hosting and staff access alone do not prove App Check |
| Android debug token | VERIFIED_LIVE | Earlier API 35 token exchange HTTP 200; token omitted |
| Release Play Integrity | NOT_RUN | Configuration visible; no release-device attestation |
| Firestore / AI Logic | VERIFIED_LIVE (configuration) | Firestore enforcement off, AI Logic enforced |

ARTEMIS Final remains DEFERRED. Local/emulator tests are documented separately.
