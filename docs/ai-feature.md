# Level 2 tutor matching

Final mobile mode adds an editable confirmation step to the BeeWise tutor search flow. The app projects the parent's text to a fixed educational vocabulary (recognized subjects, locations, schedule phrases, grade syntax and bounded VND budget). The raw request, tutor records, images, contact information, names, and arbitrary numbers are not sent. Unsupported input remains available for manual entry locally.

Firebase AI Logic (Gemini Developer API) receives those hints and a bounded Remote Config instruction. The default model is gemini-3.5-flash-lite; a production test must verify availability for the existing project. The generation schema requires six nullable properties: subject, grade (1–12), location, maxHourlyFee (positive bounded integer VND), schedule and teachingMode. The shared Dart decoder rejects malformed shapes, unknown enum values, and invalid numbers. The app labels the AI suggestion and allows each field to be changed. Only confirmation triggers a real Firestore catalog lookup and local filtering; the model supplies no tutor IDs. Synthetic fixtures are excluded from results.

Flags: ai_matching_enabled, gemini_model, ai_need_prompt, ai_result_limit. Firebase App Check is retained on real builds; emulator mode makes no Gemini call. No automatic retry or alternate provider. Quota, timeout, invalid JSON, configuration and connectivity failures leave manual entry and search available. Analytics event names are ai_request, ai_result_accepted and ai_error; payloads use fixed feature/error labels only.

| Proof required | Status |
|---|---|
| Three real Gemini requests with approved inputs and sanitized typed outputs | NOT RUN — no live inference authorized for this feature |
| Genuine provider failure and recovery, Remote Config switch, App Check on AI Logic | Live proof pending; offline tests verify timeout and disabled paths |
| Actual Android form and fallback | Runtime evidence tracked in the test report |
| Analytics events after live AI and confirmation | Not proven by offline tests |
