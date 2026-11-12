# Level 2 tutor matching

Final mobile mode adds an editable confirmation step to the BeeWise tutor search flow. The app projects the parent's text to a fixed educational vocabulary (recognized subjects, locations, schedule phrases, grade syntax and bounded VND budget). The raw request, tutor records, images, contact information, names, and arbitrary numbers are not sent. Unsupported input remains available for manual entry locally.

Firebase AI Logic (Gemini Developer API) receives those hints and a bounded Remote Config instruction. The default model is gemini-3.5-flash-lite; the exact model serving the observed requests was not captured. The generation schema requires six nullable properties: subject, grade (1–12), location, maxHourlyFee (positive bounded integer VND), schedule and teachingMode. The shared Dart decoder rejects malformed shapes, unknown enum values, and invalid numbers. The app labels the AI suggestion and allows each field to be changed. Only confirmation triggers a real Firestore catalog lookup and local filtering; the model supplies no tutor IDs. Synthetic fixtures are excluded from results.

Flags: ai_matching_enabled, gemini_model, ai_need_prompt, ai_result_limit. Firebase App Check is retained on real builds; emulator mode makes no Gemini call. No automatic retry or alternate provider. Quota, timeout, invalid JSON, configuration and connectivity failures leave manual entry and search available. Analytics event names are ai_request, ai_result_accepted and ai_error; payloads use fixed feature/error labels only.

Final Level 2 acceptance is separate from earlier Lab 3 AI Matching evidence. On merge SHA `d7fa5bea2ed5276c13ecd3739fa00257676c1242`, the five focused Dart tests passed: hint privacy, typed output validation, rejection of invented hints, timeout/disabled configuration without retry, and filtering against confirmed criteria. These are local tests, separate from the deployed Android observations below.

Synthetic inputs used in the live UI cases (expected criteria, not raw outputs):

| Case | Input | Expected criteria |
|---|---|---|
| AI-01 | Tìm gia sư Toán lớp 9 ở Thủ Đức, học phí dưới 200k một giờ, học buổi tối. | Toán, 9, Thủ Đức, 200000 VND, buổi tối |
| AI-02 | Mình cần gia sư tiếng Anh lớp 7, ưu tiên học online vào cuối tuần, ngân sách tối đa 150k/giờ. | Tiếng Anh, 7, online, cuối tuần, 150000 VND |
| AI-03 | Cần tìm gia sư Vật lý lớp 11, học trực tiếp tại khu vực Quận 3, học phí dưới 250k. | Vật lý, 11, in person, Quận 3, 250000 VND |

AI-03 uses Quận 3 because Bình Thạnh is outside the current pre-corrective APK allowlist (`e885a076...`); see the unified 16-region vocabulary fix below (`F-FINAL-04`). The captures do not show the transmitted payload or prove every field.

Historical preflight, before the approved debug token registration, on `BeeWise_Final_API35:5564` (Final debug APK, SHA-256 `e885a076b3a1f39e40f7cacc603ea0aec2d30e7e44028511e6f3bc06be3986b9`): billing disabled; Remote Config v4 had no model/enable override; native App Check logged HTTP 403 attestation failure followed by throttling. No Level 2 provider request was made during that preflight.

After owner approval, the emulator's debug token was registered; exchange returned HTTP 200 with 3600-second TTL. Owner-operated AI-01 on Android showed `Gợi ý AI · Kiểm tra và chỉnh sửa`, the label reached only after a provider response passes local decoding and hint validation. Screenshot visibly confirmed Thủ Đức, evening and 200000 VND/hour; the floating keyboard toolbar obscured parts of subject and grade. Confirmed search displayed no matches. Raw response, complete field readback, edit proof and Analytics receipt were not captured.

Subsequent owner screenshots completed the remaining native scenarios on the same emulator. AI-02 showed the validated AI label, English, grade 7, online and weekend. The screenshot shows the edited fee of 160000 VND/hour; the original generated fee and post-confirmation list were not captured. AI-03 showed Physics, grade 11, Quận 3, in person and 250000 VND/hour; confirmed search displayed no matches. In the controlled offline case the airplane icon and recoverable AI error were visible; the follow-up manual search rendered tutor cards, including the disclosed demo profile. Following owner Gate 2 Option 2.1 approval (`2026-11-12`), clearing stale pre-existing `measurement_enabled=false` userdata (`pm clear com.beewise.beewise` — Finding `F-FINAL-05`) and refreshing the single `BeeWise Final API35 emulator-5564` App Check debug token produced verified native Firebase Analytics `FA-SVC` protobuf upload bundles (`HTTP 204, 0`) and sanitized receipts in [`evidence/final/analytics/native-receipt.json`](../evidence/final/analytics/native-receipt.json) for `ai_request` (`feature=tutor_need`), `ai_result_accepted` (`feature=tutor_need`), and offline `ai_error` (`feature=tutor_need`, `kind=provider`), alongside [`evidence/final/analytics/`](../evidence/final/analytics/README.md) UI captures.

| Proof required | Status |
|---|---|
| AI-01 / AI-02 / AI-03 | VERIFIED_LIVE_UI (pre-corrective APK `e885a076...`) & `VERIFIED_FUNCTIONAL` (post-fix suite) — three provider-backed confirmation screens (`AI-01` re-verified live on `2026-11-12` during Analytics capture). AI-02 shows the user-edited 160,000 VND/hour, not verified raw model output. |
| Network failure and recovery | VERIFIED_LIVE_UI & `FINAL-F02b` ARTEMIS `1/3` ACCEPTED (`e885a076...`) + `VERIFIED_FUNCTIONAL` unit/widget suite — airplane/offline error and manual recovery verified without crash. |
| Raw JSON and exact serving-model metadata | NOT CAPTURED |
| Remote Config live enable/disable | Verified functionally (`mobile/test/gemini_level2_functional_test.dart`); live Firebase Console RC toggle `NOT_VERIFIED` |
| Actual Android form and fallback | Runtime evidence tracked in the test report and [`docs/artemis-final-matrix.md`](artemis-final-matrix.md) |
| Analytics Telemetry (`ai_request`, `ai_result_accepted`, `ai_error`) | **VERIFIED_NATIVE_UPLOAD_204** (`HTTP 204, 0` complete `FA-SVC` upload bundles via [`scripts/inspect-bao-analytics.py`](../scripts/inspect-bao-analytics.py) on `e885a076...`); bootstrap restoration & opt-out `VERIFIED_LOCAL_BEHAVIOR`; real-time Firebase Console DebugView UI screenshot `NOT_CAPTURED` separately in CLI |

See [Production cross-role evidence and run plan](../evidence/final/production-cross-role/README.md) for the current deployed scope, evidence and pending gates.

## Corrective functional fixes & test coverage (2026-11-12)

Fixes landed on branch `fix/final-corrective-acceptance` (Commit `595616d` over `main` `2d14aa0`):

1. **Deduplicated AI acceptance telemetry (`F-FINAL-02`):** [`ConfirmTutorNeedScreen`](../mobile/lib/screens/confirm_tutor_need_screen.dart) tracks the current parse generation so confirming after a transient catalog failure, adjusting search filters, or retrying never emits duplicate `ai_result_accepted` events for the same AI parse; a fresh AI parse resets the flag and manual confirmation never emits `ai_result_accepted`.
2. **Unified location contract (`F-FINAL-04`):** [`NormalizedTutorNeed`](../packages/core/lib/src/tutor_need.dart) defines a shared 16-region canonical vocabulary used identically by T1 tutor registration ([`tutor_application_screens.dart`](../mobile/lib/screens/tutor_application_screens.dart)), [`SearchScreen`](../mobile/lib/screens/beewise_screens.dart), [`providerSafeNeed`](../mobile/lib/services/need_normalizer.dart), `filterTutors`, and `matchConfirmedNeed`. [`tutorMatchesLocation`](../packages/core/lib/src/tutor_need.dart) resolves aliases (`Thành phố Hồ Chí Minh` / `Sài Gòn` ↔ `TP.HCM`, `Ha Noi` ↔ `Hà Nội`, `q1` ↔ `Quận 1`, etc.) and symmetric city/district matching without breaking legacy Firestore tutor records. Updated `TutorApplicationService.resubmissionServerBlockMessage` to match Final Rules (`BEEWISE_FINAL_FIRESTORE=true`).
3. **Analytics bootstrap persistence & opt-out (`F-FINAL-05`):** [`FirebaseBootstrap`](../mobile/lib/services/firebase_bootstrap.dart), [`AnalyticsService`](../mobile/lib/services/analytics_service.dart), `app_providers.dart`, and `ProfileScreen` explicitly restore native `setAnalyticsCollectionEnabled(true)` for non-emulator Final runs unless prohibited by privacy policy or user opt-out (replacing emulator-persisted `false`).

**Current status split:**

- Functional matching, schema validation, alias compatibility, Remote Config `ai_matching_enabled=false` & `ai_result_limit <= 3` clamping, typed `ai_error` fallback (`timeout`, `invalid_response`, `unavailable`, `provider`), duplicate-event prevention, account-switch reset, and Analytics opt-out/bootstrap gating: **`VERIFIED_FUNCTIONAL`** (`packages/core` 21/21, `mobile` 197/197).
- Live Android UI screens (`AI-01`..`AI-03` + airplane recovery) and native `HTTP 204` Analytics upload receipts (`evidence/final/analytics/native-receipt.json`) were recorded on pre-corrective APK `e885a076...` (PR #30); live verification on a freshly rebuilt APK incorporating these Dart fixes remains **pending post-merge rebuild & device run**.
