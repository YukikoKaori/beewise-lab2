# BeeWise Tutor-Side UI (Figma T1–T8) Implementation & Traceability

## 1. Executive Summary

This document details the complete Flutter implementation of the tutor-side user interface (Figma frames T1 through T8) for the BeeWise application. The implementation was carried out on feature branch `feat/tutor-ui-t1-t8`, maintaining strict parity with the authoritative Figma design (`https://www.figma.com/design/gqbuTDuZYOyKyP8LsUwobC/BeeWise-Design?node-id=2-3&p=f`) and preserving existing parent flows, Firebase Auth/Firestore architectures, and security guardrails.

---

## 2. Figma T1–T8 Screen Traceability Matrix

| Frame ID | Figma Screen Title | Route | Flutter Component / Screen | Key Visual Elements & Variants Implemented |
|---|---|---|---|---|
| **T1** | Đăng ký gia sư (Clean) | `/tutor/apply` | `TutorApplicationScreen` | 3 numbered step cards (1. Tài khoản, 2. Chuyên môn, 3. Học phí và lịch), subject & grade filter chips, hourly fee input with VND suffix, area chips, availability toggles, consent checkbox, and submit CTA. |
| **T1** (Variant) | Đăng ký gia sư (Validation Error) | `/tutor/apply` | `TutorApplicationScreen` | Top red alert banner ("Còn X mục cần sửa"), inline error annotations ("Số điện thoại cần đủ 10 số"), red field borders, and dynamic error counter. |
| **T2** | Hồ sơ gia sư — Chờ duyệt (Pending) | `/tutor/pending` | `TutorApplicationStatusScreen` | Status header "Hồ sơ đang chờ duyệt", BeeWise Mascot (`BeeSticker.robot`), timeline callout ("Nhân viên BeeWise duyệt 1–2 ngày"), summary metadata card, and re-check button. |
| **T2** (Variant) | Hồ sơ gia sư — Đã duyệt (Approved) | `/tutor/pending` | `TutorApplicationStatusScreen` | Mascot celebration (`BeeSticker.cheer`), green success badge "ĐÃ ĐƯỢC DUYỆT", greeting "Chào mừng cô/thầy Trang!", direct navigation CTA "Vào trang gia sư", and preview public profile CTA. |
| **T2** (Variant) | Hồ sơ gia sư — Cần bổ sung (Needs Info) | `/tutor/pending` | `TutorApplicationStatusScreen` | Mascot inspection (`BeeSticker.wand`), orange warning badge "CẦN BỔ SUNG", dedicated reason box "LÝ DO TỪ BEEWISE" displaying admin review notes, and CTA "Cập nhật hồ sơ". |
| **T3** | Trang chủ gia sư — Active | `/tutor/home` | `TutorHomeScreen` | Tutor header with avatar & notification bell with unread badge; "Việc cần làm hôm nay" section; "Nhóm chat mới" card with parent avatar LN, "Mới" blue pill, and "Vào nhóm chat" CTA; "Buổi học sắp tới" card with blue "T3" calendar block; "Lớp đang dạy" card with verified payment chip; 4-tab Bottom Navigation. |
| **T3** (Variant) | Trang chủ gia sư — Empty | `/tutor/home` | `TutorHomeScreen(forceEmptyState: true)` | "Chưa có việc cần làm" empty state card with chat bubble icon, explanation text, "Xem hồ sơ công khai" CTA, and educational advisory banner. |
| **T4** | Nhóm chat gia sư | `/tutor/chats/:chatId` | `TutorChatScreen` | Multi-party chat header ("Nhóm: Chị Lan & Cô Trang"), role badges ("PHỤ HUYNH", "TƯ VẤN VIÊN"), consultant proposal card with "Chờ phụ huynh phản hồi" chip and "Xem chi tiết" CTA, right-aligned blue tutor bubbles, and bottom composer dock. |
| **T5** | Chi tiết lớp dạy | `/tutor/class/:classId` | `TutorClassDetailScreen` | 4-stage stepper (1. HỌC THỬ, 2. XÁC NHẬN LỚP, 3. THANH TOÁN, 4. LỊCH HỌC), green verified payment banner ("Chị Lan đã thanh toán cho 10 buổi học chính thức"), student América An profile card, fee & schedule summary, read-only advisory note, and "Mở nhóm chat" primary CTA. |
| **T6** | Lịch dạy | `/tutor/schedule` | `TutorScheduleScreen` | Week date selector ("Tuần 18/11 — 24/11"), 7-day pill bar with current day highlighted, lesson session tiles with weekday blocks (T3, T6) and session progress chips ("Buổi 1/10", "Buổi 2/10", "Buổi 3/10"), and 4-tab Bottom Navigation. |
| **T7** | Hồ sơ của tôi | `/tutor/profile` | `TutorSelfProfileScreen` | Top blue banner "Đây là hồ sơ phụ huynh nhìn thấy", avatar TT, name "ThS. Hoàng Thu Trang", verified badge "Đã xác thực", rating "4.9 (24)", teaching metrics, subject tags, bio section, support card "Cần sửa hồ sơ? Liên hệ BeeWise", and logout button. |
| **T8** | Trung tâm thông báo | `/tutor/notifications` | `TutorNotificationScreen` | Chronological notification stream with category icons (chat, calendar, payment, verified profile), unread indicators (blue dot), timestamps ("Vừa xong", "1 giờ trước", "Hôm qua", "05/11/2026"), and route deep-links. |

---

## 3. Architecture & Role Navigation Flow

### 3.1 Role-Aware Route Guarding
In `lib/app/bee_wise_app.dart`, GoRouter redirect guards inspect `appUserRoleProvider` and `tutorApplicationDataProvider`:
- **Guest Users:** Can browse discovery, search, and initiate registration. Access to `/tutor/home` or other protected tutor routes redirects to `/login`.
- **Parent Users:** Kept strictly inside the parent experience (`/home`, `/matching`, `/search`, `/chats`, `/schedule`). Attempts to access `/tutor/*` routes redirect to `/home`.
- **Pending/Correction Tutors:** Access to `/tutor/home` is intercepted and guided to `/tutor/pending`, where their actual status (`pending`, `needs_info`, `rejected`) is presented.
- **Approved Tutors (`approved` / `verified == true`):** Granted full access to `/tutor/home`, `/tutor/schedule`, `/tutor/chats/:chatId`, `/tutor/class/:classId`, `/tutor/profile`, and `/tutor/notifications`.

### 3.2 Tutor Bottom Navigation
4-tab bottom navigation (`TutorBottomNavigation`) implemented according to Material 3 NavigationBar guidelines:
1. `Trang chủ` (`/tutor/home`)
2. `Lịch dạy` (`/tutor/schedule`)
3. `Tin nhắn` (`/tutor/chats/chat_lan_trang`)
4. `Hồ sơ` (`/tutor/profile`)

---

## 4. UI/UX Tokens & Responsive Engineering

- **Design System Consistency:**
  - Strict utilization of `BeeWiseColors` (`primary: #162CD4`, `surface: #FFFFFF`, `border: #DCE8FB`, `accent: #FFFFC500`, `error: #DC2626`, `success: #1F7A1F`).
  - Strict utilization of `BeeWiseRadius` (`field: 16`, `card: 24`, `panel: 32`, `full: 999`).
  - Typography scale with `Nunito` for headings and `Be Vietnam Pro` for body/labels.
- **Responsive Layout Safeguards:**
  - Validated with explicit automated tests at both **360dp** (compact Android) and **412dp** (standard modern Android).
  - Horizontal headers, steppers, and stat bars use `Expanded` / `Flexible` with ellipsis to guarantee 0 RenderFlex overflows.

---

## 5. Security & Backend Boundaries Preserved

1. **Client Never Self-Approves:** All applicant documents submitted from `/tutor/apply` are written with `status: 'pending'`, `verified: false`, and `active: false`. Only backend administrative workflows or Cloud Functions can transition an applicant to `approved`.
2. **Consultant Proposal Integrity:** Tutor chat proposal widgets and class confirmation cards are strictly read-only for tutors; only authorized consultants can generate proposals or modify schedules.
3. **Payment Isolation:** Invoices and payment verification status are server-authoritative (`invoiceQueryProvider`). The tutor UI reflects verified status only when confirmed by the payment ledger.

---

## 6. Test Suite & Verification Results

- **Static Dart Analysis (`flutter analyze`):** `No issues found! 0 warnings, 0 errors`.
- **Formatting (`dart format`):** All files formatted according to standard Dart conventions.
- **Automated Test Suite (`flutter test`):**
  - Project total: **141 tests passing (0 failures)**.
  - Dedicated Tutor UI test suite (`test/tutor_ui_t1_t8_test.dart`): **16/16 tests passing**.
  - Responsive overflow verification at 360dp and 412dp: **PASS (0 overflows)**.
