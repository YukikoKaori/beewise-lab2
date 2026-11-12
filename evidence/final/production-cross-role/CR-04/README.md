# CR-04 — Production tutor approval (repetition 2)

Disposable synthetic tutor fixture **`BeeWise Test CR-04`** (`uid-sha256:bf311f01d0c4c207`; `Tiếng Anh · Lớp 9`, `200.000đ/giờ`, `Thanh Xuân`, `T2 tối`, `Trực tuyến`) was submitted on Android API 35 (`BeeWise_Final_API35`, Final debug APK SHA-256 `e885a076b3a1f39e40f7cacc603ea0aec2d30e7e44028511e6f3bc06be3986b9`) against production Firebase `beewise-lab-3`.

While the emulator stayed open on the pending application screen without reloading the app, the project owner approved the application on production [Web Admin](https://beewise-lab-3.web.app/) with reason `"duyệt"` at `2026-11-12T00:41:03.609Z`.

## Verified artifacts

| Artifact | Purpose | SHA-256 |
|---|---|---|
| [`android-pending.png`](android-pending.png) | Android `/tutor/pending` immediately after submission (`12/11/2026`, `Đang chờ duyệt`) | `01b279c50bf2bcd5895dc2a4554e0d55d35b97b659480732de6eba1481ad2547` |
| [`android-approved.png`](android-approved.png) | Live no-reload Android transition to `Đã được phê duyệt` (`Chào mừng BeeWise Test CR-04!`) | `7c30f2bbc5bdcf676bdba5e4f322b09457bde1e43b0ad8cf78e6c202a06e1fb9` |
| [`android-tutor-home.png`](android-tutor-home.png) | Navigation into `/tutor/home` (`Gia sư: BeeW...`, unread notification indicator) | `23c10d3019cbd030afbb30b517199c5ab41f6fe7d538d98e5bf81287755c9c87` |
| [`android-inbox.png`](android-inbox.png) | Private `/tutor/notifications` showing `Hồ sơ gia sư đã được duyệt` (`duyệt`, `07:41 · 12/11`) | `7c795fcd1f3674e939206b0d7a93371fc6cdbd688ace932a78dd81e56b0dab52` |
| [`firestore-readback.json`](firestore-readback.json) | Anonymized independent Firestore REST readback (`status="approved"`, `verified=true`, `active=true`, `reviews_subcollection_count=1`, `public_tutor_doc_exists=false`) | `b76cc34fd2de99292407e8356bd531d8f39876353872a46858ae1be06f9da486` |

## Boundaries

- Status: **VERIFIED_PRODUCTION** (Android live status + private inbox + independent Firestore readback).
- Appendix C propagation timings (write acknowledgment, listener arrival, UI frame render): **NOT_MEASURED**.
- Public tutor directory publication (`tutors/{uid}`): absent (`false`), matching separate publication design.
- Per owner explicit approval (`gate 1 đã duyệt, giữ nguyên`), the synthetic `CR-04` test record was retained cleanly for traceability without raw PII.
