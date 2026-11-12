# CR-05 — Production tutor approval (repetition 3)

Disposable synthetic tutor fixture **`BeeWise Test CR-05`** (`uid-sha256:4560c22f5d530e2d`; `Vật lý · Lớp 10`, `180.000đ/giờ`, `Đống Đa`, `T2 tối`, `Trực tuyến`) was submitted on Android API 35 (`BeeWise_Final_API35`, Final debug APK SHA-256 `e885a076b3a1f39e40f7cacc603ea0aec2d30e7e44028511e6f3bc06be3986b9`) against production Firebase `beewise-lab-3` at `2026-11-12T00:50:19.296Z`.

While the emulator stayed open on the pending application screen without reloading the app, the project owner approved the application on production [Web Admin](https://beewise-lab-3.web.app/) with reason `"duyệt"` at `2026-11-12T00:54:37.821Z`.

## Verified artifacts

| Artifact | Purpose | SHA-256 |
|---|---|---|
| [`android-pending.png`](android-pending.png) | Android `/tutor/pending` immediately after submission (`12/11/2026`, `Đang chờ duyệt`) | `8cd2fb45c7e53aea5bbc6896cfc4ea010c64a79df71000f730de87612ec73590` |
| [`android-approved.png`](android-approved.png) | Live no-reload Android transition to `Đã được phê duyệt` (`Chào mừng BeeWise Test CR-05!`) | `87eb008f3905e08fb4b3c26c57cd6f48a9cabcb0085b4f787655dd8feb99379b` |
| [`android-tutor-home.png`](android-tutor-home.png) | Navigation into `/tutor/home` (`Chào CR-05,`, unread notification indicator) | `459ece9b87fc509480248e3a79f82dab7c3d6cac1c6ac60baee23e8cc148c664` |
| [`android-inbox.png`](android-inbox.png) | Private `/tutor/notifications` showing `Hồ sơ gia sư đã được duyệt` (`duyệt`, `07:54 · 12/11`) | `ab2e6764a3d0cd9e6a3d34c70ba4a64aa5eb0d94b3c7a4835e8c3655d23c58c0` |
| [`firestore-readback.json`](firestore-readback.json) | Anonymized independent Firestore REST readback (`status="approved"`, `verified=true`, `active=true`, `reviews_subcollection_count=1`, `public_tutor_doc_exists=false`) | `c5b68c533e3744166ea1636ec3eea11661544312ab26185cbfaa4790758b9f73` |

## Boundaries

- Status: **VERIFIED_PRODUCTION** (Android live status + private inbox + independent Firestore readback).
- Appendix C propagation timings (write acknowledgment, listener arrival, UI frame render): **NOT_MEASURED**.
- Public tutor directory publication (`tutors/{uid}`): absent (`false`), matching separate publication design.
- Per owner explicit approval (`gate 1 đã duyệt, giữ nguyên`), the synthetic `CR-05` test record was retained cleanly for traceability without raw PII.
