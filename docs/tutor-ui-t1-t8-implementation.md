# BeeWise Tutor-Side UI (Figma T1–T8) Implementation & Traceability

## 1. Executive Summary

This document details the Flutter implementation and real-data/role-safety architecture of the tutor-side user interface (Figma frames T1 through T8) for the BeeWise application on feature branch `feat/tutor-ui-t1-t8` (PR #25).

The implementation preserves visual fidelity to the authoritative Figma design (`https://www.figma.com/design/gqbuTDuZYOyKyP8LsUwobC/BeeWise-Design?node-id=2-3&p=f`) while eliminating all hardcoded sample business records (`Chị Lan`, `Cô Trang`, `chat_lan_trang`, `class_toan9_lan`, static ratings/reviews, static schedules, fake notifications, and static payment verification banners) from runtime paths. All screens are driven by authenticated user state, typed workspace models, and real providers.

---

## 2. Figma T1–T8 Screen & Integration Status Matrix

Each screen separates **UI Implementation Status** (`UI_IMPLEMENTED`) from **Backend / Firestore Integration Status** (`LIVE_BACKEND_INTEGRATED` vs `RULES_GATED_HONEST_STATE`) so reviewers can verify what works end-to-end against current `firebase/firestore.rules` versus what requires backend/admin rules expansion.

| Frame ID | Figma Screen Title | Route | Flutter Screen | Provider / Data Source | UI Status | Backend / Rules Integration Status |
|---|---|---|---|---|---|---|
| **T1** | Đăng ký gia sư (Clean & Error Variant) | `/tutor/apply` | `TutorApplicationScreen` | `tutorApplicationControllerProvider`, `tutorApplicationDataProvider` | `UI_IMPLEMENTED` | **Guest registration:** `LIVE_BACKEND_INTEGRATED` (`createUserWithEmailAndPassword` + `tutorApplications/{uid}.set` with `status: 'pending'`, `verified: false`, `active: false`).<br>**`needs_info` resubmission:** Prefills existing `TutorApplicationData`, hides password field, preserves existing UID and review metadata via `TutorApplicationService.resubmit(...)`. Current `firebase/firestore.rules` sets `allow update: if false` on `tutorApplications/{uid}`; client surfaces `TutorApplicationException.ruleBlocked` (`permission-denied`) honestly without faking success. |
| **T2** | Hồ sơ gia sư — Trạng thái duyệt (`pending`, `needs_info`, `rejected`, `approved`) | `/tutor/pending` | `TutorApplicationStatusScreen` | `tutorApplicationDataProvider`, `tutorProfileViewProvider` | `UI_IMPLEMENTED` | `LIVE_BACKEND_INTEGRATED` (`tutorApplications/{uid}.get` allowed for owner). Distinguishes 5 states:<br>1. `pending` -> Chờ duyệt<br>2. `needs_info` -> Cần bổ sung (displays `reviewReason` + `"Cập nhật hồ sơ"` CTA to `/tutor/apply`)<br>3. `rejected` -> Chưa phù hợp (displays `reviewReason`, **no** resubmit CTA)<br>4. `approved` with `!verified || !active` -> Đã duyệt — Chờ kích hoạt (**no** `"Vào trang gia sư"` CTA until both `verified == true && active == true`)<br>5. `approved && verified && active` -> Đã được duyệt (`"Vào trang gia sư"` CTA enabled). |
| **T3** | Trang chủ gia sư (Active & Empty Variants) | `/tutor/home` | `TutorHomeScreen` | `tutorDashboardProvider` (`TutorWorkspaceService.watchDashboard(uid)`) | `UI_IMPLEMENTED` | Driven by `tutorDashboardProvider` for the authenticated tutor UID. Renders real loading, error+retry, empty state (`"Chưa có việc cần làm"` when `isEmpty`), or active cards (`newChats`, `upcomingSessions`, `activeClasses`). Payment verification chip (`"Phụ huynh đã thanh toán"`) renders **only** when `cls.isPaymentVerified` (`paymentStatus == 'verified'`). Under current `firebase/firestore.rules` (where `chats` and `classes` queries are scoped to `isParent`), Firestore `permission-denied` is surfaced honestly via `TutorBackendRulesDependencyException` or empty/error state without fabricating sample data. |
| **T4** | Nhóm chat gia sư | `/tutor/chats` & `/tutor/chats/:chatId` | `TutorChatScreen` | `tutorChatsProvider`, `tutorChatSessionProvider(chatId)`, `tutorChatComposerControllerProvider` | `UI_IMPLEMENTED` | Driven by `tutorChatSessionProvider(chatId)` with strict ownership check (`tutorUid == currentUid`). No local `_messages` list or fake local append on send.<br>- When `session.canSendMessages == false` (current `firebase/firestore.rules` restricts `chats/{chatId}/messages` create to `canWriteAsParent`), composer input and send button are disabled and `session.sendRestrictionReason` is displayed.<br>- When `canSendMessages == true` via an authorized `TutorWorkspaceService`, `TutorChatComposerController` handles `sending -> sent / failed`, duplicate-send prevention, failed-send retry restoring draft text, and User A -> User B account-switch isolation. |
| **T5** | Chi tiết lớp dạy | `/tutor/class/:classId` | `TutorClassDetailScreen` | `tutorClassDetailProvider(classId)` | `UI_IMPLEMENTED` | Driven by `tutorClassDetailProvider(classId)` with strict ownership validation (`tutorUid == currentUid`). Unknown or unauthorized `classId` renders explicit not-found / unauthorized state. Green payment banner (`"${parentName} đã thanh toán..."`) is rendered **strictly** when `paymentStatus == 'verified'`; pending/unpaid classes render amber pending status. |
| **T6** | Lịch dạy | `/tutor/schedule` | `TutorScheduleScreen` | `tutorScheduleProvider` | `UI_IMPLEMENTED` | Driven by `tutorScheduleProvider`. Computes real Monday–Sunday calendar week dates from reference date (no hardcoded `"Tuần 18/11 — 24/11"`). Filters sessions by selected day or full week; renders real empty state when no official sessions exist. |
| **T7** | Hồ sơ của tôi | `/tutor/profile` | `TutorSelfProfileScreen` | `tutorProfileViewProvider` | `UI_IMPLEMENTED` | `LIVE_BACKEND_INTEGRATED` (`tutorApplications/{uid}` + `tutors/{uid}`). Distinguishes private application approval from public catalog publication (`hasPublicListing`). Shows real rating/review count when `reviewCount > 0`, and `"Chưa có đánh giá"` when `reviewCount == 0` (never hardcoded `4.9 (24)`). |
| **T8** | Trung tâm thông báo | `/tutor/notifications` | `TutorNotificationScreen` | `notificationsProvider` | `UI_IMPLEMENTED` | `LIVE_BACKEND_INTEGRATED` (`users/{uid}/notifications`). Renders loading, error+retry, and empty state (`"Chưa có thông báo mới"`). Validates notification deep-link routes against authorized tutor routes before navigation. |

---

## 3. Role-Aware Routing & Async Account-Switch Safety

### 3.1 8-State Account Role Resolution (`AccountRoleKind`)
Implemented in `TutorApplicationService.resolveAccountRole(uid)` and enforced in `lib/app/bee_wise_app.dart`:

1. **`guest`** (`user == null`):
   - Allowed on public routes and `/tutor/apply`.
   - Redirected to `/login` when accessing `/tutor/pending`, `/tutor/home`, `/tutor/schedule`, `/tutor/chats*`, `/tutor/class/*`, `/tutor/profile`, or `/tutor/notifications`.
2. **`parent`** (`users/{uid}.role == 'parent'` or no tutor application):
   - Confined to parent routes (`/home`, `/matching`, `/search`, `/chats`, `/schedule`, etc.).
   - Redirected to `/home` if attempting to access any `/tutor/*` route.
3. **`pendingApplicant`** (`status == 'pending'`):
   - Confined to `/tutor/pending` (and `/tutors/:id` public preview).
4. **`needsInfoApplicant`** (`status == 'needs_info'`):
   - Allowed on `/tutor/pending` and `/tutor/apply` (to prefill and resubmit). Blocked from `/tutor/home` and tutor workspace routes.
5. **`rejectedApplicant`** (`status == 'rejected'`):
   - Confined to `/tutor/pending` (`"Cập nhật hồ sơ"` button is hidden; `/tutor/apply` redirects back to `/tutor/pending`).
6. **`approvedPendingVerification`** (`status == 'approved'` with `!verified || !active`):
   - Confined to `/tutor/pending` (displays `"Đã duyệt — Chờ kích hoạt"` until backend sets both `verified == true` and `active == true`).
7. **`authorizedTutor`** (`status == 'approved' && verified == true && active == true`):
   - Granted access to `/tutor/home`, `/tutor/schedule`, `/tutor/chats`, `/tutor/chats/:chatId`, `/tutor/class/:classId`, `/tutor/profile`, and `/tutor/notifications`.
   - Redirected away from parent-only discovery/workflow routes to `/tutor/home`.
8. **`unresolved`** (Firestore read failure or unexpected error during role check):
   - Fails closed to `/account/check` with retry and sign-out actions. Never falls back to parent `/home` or tutor `/tutor/home`.

### 3.2 Stale Async Redirect Prevention (User A -> User B)
In `lib/app/bee_wise_app.dart`, `_checkTutorRedirect(String expectedUid)` captures the UID before awaiting `resolveAccountRole(expectedUid)` and verifies `FirebaseAuth.instance.currentUser?.uid == expectedUid` upon completion. If a user signs out or switches accounts while role resolution is in flight, the stale result is discarded. Additionally, `ref.listen<AsyncValue<TutorApplicationData?>>(tutorApplicationDataProvider, ...)` triggers `_router?.refresh()` whenever application status transitions.

---

## 4. Security & Firestore Rules Boundaries

All existing security invariants in `firebase/firestore.rules` remain intact:
1. **No Client Self-Approval:** `tutorApplications/{uid}` creation forces `status == 'pending'`, `verified == false`, and `active == false`.
2. **Application Update Rule Dependency:** `firebase/firestore.rules` currently sets `allow update: if false` on `tutorApplications/{uid}`. `TutorApplicationService.resubmit(...)` attempts an owner-scoped update of editable fields only (preserving `uid`, `email`, `status: 'pending'`, `verified: false`, `active: false`, `reviewReason`, and `submittedAt`) and translates `permission-denied` into `TutorApplicationException.ruleBlocked` so the UI informs the user honestly.
3. **Tutor Workspace Rules Dependency:** `firebase/firestore.rules` currently scopes `chats`, `chats/{chatId}/messages`, and `classes` to `isParent(uid)` / `canWriteAsParent(uid)`. `FirebaseTutorWorkspaceService` queries tutor-owned documents (`where('tutorId', isEqualTo: uid)`) and translates `permission-denied` into `TutorBackendRulesDependencyException` while marking `canSendMessages: false` on live Firestore sessions until backend rules grant tutor read/message permissions.

---

## 5. Verification Results

- **Formatting (`dart format lib/ test/`):** Clean (0 unformatted files).
- **Static Analysis (`flutter analyze`):** `No issues found!`.
- **Full Repository Test Suite (`flutter test`):** **144/144 tests passing (0 failures)**.
- **Dedicated Tutor UI & Role Safety Suite (`flutter test test/tutor_ui_t1_t8_test.dart`):** **19/19 tests passing**, covering:
  - Guest, parent, `pending`, `needs_info`, `rejected`, `approved`-unverified, `authorizedTutor`, and `unresolved` routing guards.
  - Stale async role resolution protection across User A -> User B account switches.
  - T1 clean guest registration validation & `needs_info` prefill/resubmission + `permission-denied` rule handling.
  - T2 state differentiation (`rejected` hides resubmit CTA; `approvedPendingVerification` hides workspace entry CTA).
  - T3–T8 real data rendering, zero fabricated `Chị Lan` / `Cô Trang` strings, strict `paymentStatus == 'verified'` badge gating, unauthorized/missing ID handling, and Firestore error+retry recovery.
  - T4 disabled composer when `canSendMessages == false`, full send/fail/retry/duplicate-lock when permitted, and User A -> User B composer isolation.
  - Responsive layout & text-scale checks across all T1–T8 screens at **360dp x 800dp** and **412dp x 915dp** with `textScaleFactor = 1.25` (**0 RenderFlex overflows**).
