# Production cross-role acceptance

Baseline: main at `d7fa5bea2ed5276c13ecd3739fa00257676c1242`. CI run 43104437452 attempt 2 passed all five jobs; attempt 1 failed the backend watcher. Project: `beewise-lab-3`, default Firestore, [Web Admin](https://beewise-lab-3.web.app/). Hosting returned HTTP 200. Live Rules matched repository source after newline normalization (SHA-256 `5d59a8a95305744a00a4c4f7397b4b255c76b297b0d654994d6cd5ae3272199a`). The production VietQR query returned 200 with the approved index; this does not establish parity for every repository index or query.

Android: Final-mode debug APK, `lib/main.dart`, `BEEWISE_FINAL_FIRESTORE=true`, Android x86_64, API 35; SHA-256 in manifest. This is Android against production Firebase, not a Firebase Emulator run and not release-device acceptance.

| Run | Expected outcome | Status |
|---|---|---|
| CR-01 | Pending → approved; Android updated without reload and showed the private inbox notice, per owner observation | VERIFIED_LIVE_UI ([receipt](CR-01/README.md)); inbox OWNER_OBSERVED; independent Firestore readback not captured |
| CR-02 | Pending → needs_info with reason on Android → pending after correction | VERIFIED_LIVE_UI ([receipt](CR-02/README.md)); tutor inbox restricted by design |
| CR-03 | Pending → rejected with reason on Android, without reload per owner | VERIFIED_LIVE_UI ([receipt](CR-03/README.md)); tutor inbox not applicable by design; privileged denials NOT_RUN |
| CR-04 | Pending → approved (`2026-11-12T00:41:03.609Z`); no-reload Android transition → `/tutor/home` → `/tutor/notifications` (`duyệt`, `07:41 · 12/11`) + independent Firestore REST readback | **VERIFIED_PRODUCTION** ([receipt](CR-04/README.md), [`firestore-readback.json`](CR-04/firestore-readback.json)) |
| CR-05 | Pending → approved (`2026-11-12T00:54:37.821Z`); no-reload Android transition → `/tutor/home` → `/tutor/notifications` (`duyệt`, `07:54 · 12/11`) + independent Firestore REST readback | **VERIFIED_PRODUCTION** ([receipt](CR-05/README.md), [`firestore-readback.json`](CR-05/firestore-readback.json)) |
| Web non-staff / revocation | Disposable Google identity denied → staff Dashboard → denied automatically without reload; existing owner unchanged | VERIFIED_LIVE_UI ([receipt](authorization/README.md)); DIRECT_RULES_DENIAL_NOT_RUN |

Total verified production approvals across independent disposable synthetic accounts: **`3/3`** (`CR-01`, `CR-04`, `CR-05`). Per explicit owner approval at Gate 1 (`gate 1 đã duyệt, giữ nguyên`), synthetic `CR-04` and `CR-05` documents contain no raw PII and remain retained cleanly in `beewise-lab-3` for traceability.

The owner approved the scoped disposable test plan. CR-01 has a live status receipt and owner-observed inbox delivery; CR-04 and CR-05 additionally preserve clean zero-PII Android screenshots (`android-pending.png`, `android-approved.png`, `android-tutor-home.png`, `android-inbox.png`) and independent anonymized Firestore REST readbacks confirming `tutorApplications/{uid}` (`status="approved"`, `verified=true`, `active=true`), `reviews/{reviewId}` (`reviews_subcollection_count=1`), and `public_tutor_doc_exists=false`. CR-02 and CR-03 verified status and reason on Android. The owner confirmed no separate applicant inbox is needed. The existing tutor inbox remains limited to approved tutors: the application status page has no inbox entry, and routing limits needs_info/rejected applicants to status or eligible edit pages. Web role changes and live UI revocation are verified. Direct Rules denial probes remain unrun on production (covered by 75/75 local Firestore Security Rules tests); no Appendix C propagation timings were measured.

## Existing Gemini Level 2

The Android screenshots supplied by the owner show the AI-labeled confirmation UI for three cases; source defaults to Gemini Developer API / gemini-3.5-flash-lite. The screenshots do not identify the serving model or preserve raw JSON. AI-01 shows the requested evening/Thủ Đức and 200,000 VND filter with no matching catalogue result. AI-02 shows English grade 7, online/weekend, and 160,000 VND after the owner edit; the initial 150,000 is owner-reported and not visible in the saved frame. AI-03 shows physics grade 11, Quận 3, in person, 250,000 VND and no matching result. Airplane mode shows the recoverable AI error; manual search subsequently renders catalogue results with the demo label. Original image hashes identify private source captures, which are not redistributed. Source inspection found an allowlisted academic-hint payload; historical network payloads were not captured for direct comparison. No new requests or event replay.

Analytics: **`VERIFIED_NATIVE_UPLOAD_204`** for `ai_request`, `ai_result_accepted`, and `ai_error` (`kind=provider`) on Final APK `e885a076...` after clean `pm clear com.beewise.beewise` (clearing prior `measurement_enabled=false` userdata) and single App Check debug token refresh ([Analytics README](../analytics/README.md), [`native-receipt.json`](../analytics/native-receipt.json)); real-time Firebase Console DebugView UI screenshot remains `NOT_CAPTURED` in CLI.

## App Check

| Scope | Status | Boundary |
|---|---|---|
| Web reCAPTCHA Enterprise registration | VERIFIED_LIVE | Approved domain-scoped provider; 3600 s TTL, minimum score 0.5 |
| Web token acquisition | NOT_RUN | No token receipt captured |
| Web App Check accepted request | NOT_RUN | Hosting and staff access alone do not prove App Check |
| Android debug token | VERIFIED_LIVE | Token refreshed cleanly for `BeeWise Final API35 emulator-5564` on `2026-11-12` and verified against live Gemini Level 2 parse (`ai-need-parsed.png`); token omitted |
| Release Play Integrity | NOT_RUN | Configuration visible; no release-device attestation |
| Firestore / AI Logic | VERIFIED_LIVE (configuration) | Firestore enforcement off, AI Logic enforced |

ARTEMIS Final bounded Gate 3 Option B execution (`4/9` accepted PASS across `TC-27` `3/3`, `FINAL-F02b` `1/3`, `FINAL-F01` `0/3`; `60/60` HTTP calls; `$0.1775406`; `>= $0.50` Nexora reserve preserved; unexecuted flows `NOT_RUN`) is tracked separately in [`docs/artemis-final-matrix.md`](../../../docs/artemis-final-matrix.md) and [`evidence/final/artemis/summary.md`](../artemis/summary.md).
