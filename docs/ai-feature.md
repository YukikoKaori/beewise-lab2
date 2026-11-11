# Level 2 tutor matching

Final mobile mode adds an editable confirmation step to the BeeWise tutor search flow. The app projects the parent's text to a fixed educational vocabulary (recognized subjects, locations, schedule phrases, grade syntax and bounded VND budget). The raw request, tutor records, images, contact information, names, and arbitrary numbers are not sent. Unsupported input remains available for manual entry locally.

Firebase AI Logic (Gemini Developer API) receives those hints and a bounded Remote Config instruction. The default model is gemini-3.5-flash-lite; a production test must verify availability for the existing project. The generation schema requires six nullable properties: subject, grade (1–12), location, maxHourlyFee (positive bounded integer VND), schedule and teachingMode. The shared Dart decoder rejects malformed shapes, unknown enum values, and invalid numbers. The app labels the AI suggestion and allows each field to be changed. Only confirmation triggers a real Firestore catalog lookup and local filtering; the model supplies no tutor IDs. Synthetic fixtures are excluded from results.

Flags: ai_matching_enabled, gemini_model, ai_need_prompt, ai_result_limit. Firebase App Check is retained on real builds; emulator mode makes no Gemini call. No automatic retry or alternate provider. Quota, timeout, invalid JSON, configuration and connectivity failures leave manual entry and search available. Analytics event names are ai_request, ai_result_accepted and ai_error; payloads use fixed feature/error labels only.

Final Level 2 acceptance is separate from earlier Lab 3 AI Matching evidence. On merge SHA `d7fa5bea2ed5276c13ecd3739fa00257676c1242`, the five focused Dart tests passed: hint privacy, typed output validation, rejection of invented hints, timeout/disabled configuration without retry, and filtering against confirmed criteria. These are local tests; no Final provider responses or Analytics events were captured. Use the [production preflight](final-deployment.md) before invoking the three live cases.

Planned synthetic live cases (not run):

| Case | Input | Expected criteria |
|---|---|---|
| AI-01 | Tìm gia sư Toán lớp 9 ở Thủ Đức, học phí dưới 200k một giờ, học buổi tối. | Toán, 9, Thủ Đức, 200000 VND, buổi tối |
| AI-02 | Mình cần gia sư tiếng Anh lớp 7, ưu tiên học online vào cuối tuần, ngân sách tối đa 150k/giờ. | Tiếng Anh, 7, online, cuối tuần, 150000 VND |
| AI-03 | Cần tìm gia sư Vật lý lớp 11, học trực tiếp tại khu vực Quận 3, học phí dưới 250k. | Vật lý, 11, in person, Quận 3, 250000 VND |

AI-03 uses Quận 3 because Bình Thạnh is outside the current location allowlist. For each case capture projected hints, actual model and structured response, edited confirmation, resulting Firestore search, and Analytics. Do not rerun merely to obtain a preferred response.

Live preflight on `BeeWise_Final_API35:5564` (Final debug APK, SHA-256 `e885a076b3a1f39e40f7cacc603ea0aec2d30e7e44028511e6f3bc06be3986b9`): billing disabled; Remote Config v4 had no model/enable override; native App Check logged HTTP 403 attestation failure followed by throttling. No Level 2 provider request was made. Proposed next step: register only this emulator installation's debug token on the existing Android App Check app, after separate owner approval; keep enforcement and billing unchanged. Verify attestation before running the three synthetic cases.

After owner approval, the emulator's debug token was registered; exchange returned HTTP 200 with 3600-second TTL. Owner-operated AI-01 on Android showed `Gợi ý AI · Kiểm tra và chỉnh sửa`, the label reached only after a provider response passes local decoding and hint validation. Screenshot visibly confirmed Thủ Đức, evening and 200000 VND/hour; the floating keyboard toolbar obscured parts of subject and grade. Confirmed search displayed no matches. Raw response, complete field readback, edit proof and Analytics receipt were not captured. AI-02/03 and the controlled native failure remain pending.

Subsequent owner screenshots completed the remaining native scenarios on the same emulator. AI-02 showed the validated AI label, English, grade 7, online and weekend. The screenshot shows the edited fee of 160000 VND/hour; the original generated fee and post-confirmation list were not captured. AI-03 showed Physics, grade 11, Quận 3, in person and 250000 VND/hour; confirmed search displayed no matches. In the controlled offline case the airplane icon and recoverable AI error were visible; the follow-up manual search rendered tutor cards, including the disclosed demo profile. These screenshots verify three live UI responses and the native error/recovery flow. No raw provider payload or Analytics receipt was captured, and tutor detail navigation was not shown.

| Proof required | Status |
|---|---|
| Three real Gemini requests with approved inputs and sanitized typed outputs | NOT RUN — no live inference authorized for this feature |
| Genuine provider failure and recovery, Remote Config switch, App Check on AI Logic | Live proof pending; offline tests verify timeout and disabled paths |
| Actual Android form and fallback | Runtime evidence tracked in the test report |
| Analytics events after live AI and confirmation | Not proven by offline tests |

See [Production cross-role evidence and run plan](../evidence/final/production-cross-role/README.md) for the current deployed scope, evidence and pending gates.
