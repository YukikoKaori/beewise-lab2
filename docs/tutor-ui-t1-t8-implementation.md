# BeeWise Tutor-Side UI (Figma T1–T8) Implementation & Traceability

## 1. Executive Summary

This document details the Flutter implementation, real-data/freshness architecture, role-safety routing, and Firestore rules boundary handling of the tutor-side user interface (Figma frames T1 through T8) for the BeeWise application on feature branch `feat/tutor-ui-t1-t8` (PR #25).

The implementation preserves visual fidelity to the authoritative Figma design (`https://www.figma.com/design/gqbuTDuZYOyKyP8LsUwobC/BeeWise-Design?node-id=2-3&p=f`) while eliminating all hardcoded sample business records (`Chị Lan`, `Cô Trang`, `chat_lan_trang`, `class_toan9_lan`, static ratings/reviews, static schedules, fake notifications, and static payment verification banners) from runtime paths. All screens are driven by authenticated user state, live Firestore `.snapshots()` streams, typed workspace models, and explicit state classification (`LOADING`, `EMPTY_VERIFIED`, `POPULATED`, `RULES_BLOCKED`, `UNAUTHORIZED`, `NOT_FOUND`, `NETWORK_ERROR`, `UNKNOWN_ERROR`).

---

## 2. Figma T1–T8 Screen & Integration Status Matrix

Every screen explicitly distinguishes:
- **`UI_IMPLEMENTED`**: Complete Flutter UI matching Figma T1–T8 frames, variants, responsive widths (`360dp`, `412dp`), and `1.25x` text scaling.
- **`LIVE_BACKEND_INTEGRATED`**: Real-time Firestore `.snapshots()` / Firebase Auth integration permitted by current `firebase/firestore.rules`.
- **`READ_ONLY`**: Authorized read state where mutations are disabled by client/rules contract.
- **`FIRESTORE_RULES_BLOCKED`**: Operation or collection query currently denied by `firebase/firestore.rules` (`permission-denied`), surfaced via explicit rules-blocked UI (`TutorBackendRulesDependencyException` / `TutorDataSourceState.rulesBlocked`) and **never** misrepresented as an empty state.
- **`FUTURE_BACKEND_DEPENDENCY`**: Requires backend endpoint or Firestore security rule expansion before end-to-end tutor write/read sync can complete in production.

| Frame ID | Figma Screen Title | Route | Flutter Screen | Provider / Data Source | UI Status | Backend / Rules Integration Status |
|---|---|---|---|---|---|---|
| **T1** | Đăng ký gia sư (Clean & Error Variant) | `/tutor/apply` | `TutorApplicationScreen` | `tutorApplicationControllerProvider`, `tutorApplicationDataProvider` | `UI_IMPLEMENTED` | **Guest registration:** `LIVE_BACKEND_INTEGRATED` (`createUserWithEmailAndPassword` + `tutorApplications/{uid}.set` with `status: 'pending'`, `verified: false`, `active: false`).<br>**`needs_info` correction mode:** `FIRESTORE_RULES_BLOCKED` + `FUTURE_BACKEND_DEPENDENCY`. Prefills existing `TutorApplicationData`, hides password field, preserves existing UID/email/review metadata, and allows local field editing & validation (`"Kiểm tra hợp lệ thông tin đã sửa"`). Because `firebase/firestore.rules` sets `allow update: if false` on `tutorApplications/{uid}` and `backend/src/app.js` has no applicant resubmission endpoint, `TutorApplicationService.isResubmissionBackendAvailable` defaults to `false`: the final server submit button (`"Gửi lại hồ sơ (Chờ mở quyền máy chủ)"`) is disabled with a prominent explanation banner (`"CẦN QUYỀN MÁY CHỦ ĐỂ GỬI LẠI HỒ SƠ"`), preventing doomed Firestore writes and avoiding `updateDisplayName` drift. |
| **T2** | Hồ sơ gia sư — Trạng thái duyệt (`pending`, `needs_info`, `rejected`, `approved`) | `/tutor/pending` | `TutorApplicationStatusScreen` | `tutorApplicationDataProvider`, `tutorProfileViewProvider` | `UI_IMPLEMENTED` | `LIVE_BACKEND_INTEGRATED` (`tutorApplications/{uid}.snapshots()` allowed for owner). Distinguishes 5 states:<br>1. `pending` -> Chờ duyệt<br>2. `needs_info` -> Cần bổ sung (displays `reviewReason` + `"Cập nhật hồ sơ"` CTA to `/tutor/apply`)<br>3. `rejected` -> Từ chối duyệt (displays `reviewReason`, **no** resubmit CTA)<br>4. `approved` with `!verified || !active` -> Đã duyệt — Chờ kích hoạt (**no** `"Vào trang gia sư"` CTA until both `verified == true && active == true`)<br>5. `approved && verified && active` -> Đã được duyệt (`"Vào trang gia sư"` CTA enabled). |
| **T3** | Trang chủ gia sư (Active & Empty Variants) | `/tutor/home` | `TutorHomeScreen` | `tutorDashboardProvider` (`TutorWorkspaceService.watchDashboard(uid)`) | `UI_IMPLEMENTED` | **Live Stream + Partial/Full Rules-Block Classification (`FIRESTORE_RULES_BLOCKED` / `FUTURE_BACKEND_DEPENDENCY` under default rules):** Subscribes to real `.snapshots()` on tutor-owned `chats` and `classes` via `_guardAuthorizedTutorStream`.<br>- If **both** `chats` and `classes` queries throw `permission-denied`, emits `TutorBackendRulesDependencyException` and renders `"Chức năng này chưa được cấp quyền đồng bộ cho tài khoản gia sư. Vui lòng liên hệ BeeWise."` (never `"Chưa có việc cần làm"`).<br>- If **one** source succeeds and the other is `permission-denied`, renders the authorized source alongside a dedicated rules-blocked warning card (`_buildTutorRulesBlockedCard`) for the blocked source.<br>- Renders `"Chưa có việc cần làm"` / `"Chưa có nhóm chat nào"` **only** when `isVerifiedEmpty == true` (both sources `EMPTY_VERIFIED`).<br>- Payment verification badge (`"Phụ huynh đã thanh toán"`) renders **strictly** when `cls.isPaymentVerified` (`paymentStatus == 'verified'`). |
| **T4** | Nhóm chat gia sư | `/tutor/chats` & `/tutor/chats/:chatId` | `TutorChatScreen` | `tutorChatsProvider`, `tutorChatSessionProvider(chatId)`, `tutorChatComposerControllerProvider` | `UI_IMPLEMENTED` | **Chat list & session reads:** Live `.snapshots()` stream with strict ownership check (`tutorId == currentUid`). `permission-denied` throws `TutorBackendRulesDependencyException` (`FIRESTORE_RULES_BLOCKED`), never `"Chưa có nhóm chat nào"`.<br>**Message composer (`READ_ONLY` / `FIRESTORE_RULES_BLOCKED` under default rules):** When `session.canSendMessages == false` (current `firebase/firestore.rules` restricts `chats/{chatId}/messages` create to `canWriteAsParent`), composer input and send button are disabled and `session.sendRestrictionReason` is displayed. When `canSendMessages == true`, `TutorChatComposerController` handles `sending -> sent / failed`, duplicate-send lock, failed-send retry, and User A -> User B account-switch isolation. |
| **T5** | Chi tiết lớp dạy | `/tutor/class/:classId` | `TutorClassDetailScreen` | `tutorClassDetailProvider(classId)` | `UI_IMPLEMENTED` | **Live `.snapshots()` stream (`READ_ONLY` / `FIRESTORE_RULES_BLOCKED` under default rules):** Enforces strict ownership (`tutorId == currentUid`). Distinguishes `TutorResourceNotFoundException`, `TutorUnauthorizedException`, `TutorBackendRulesDependencyException`, and `TutorNetworkException`. Green payment banner (`"${parentName} đã thanh toán..."`) renders **only** when `paymentStatus == 'verified'`. |
| **T6** | Lịch dạy | `/tutor/schedule` | `TutorScheduleScreen` | `tutorScheduleProvider` | `UI_IMPLEMENTED` | **Live `.snapshots()` stream (`FIRESTORE_RULES_BLOCKED` under default rules):** Computes real Monday–Sunday calendar week dates from reference date. When `classes` query throws `permission-denied`, surfaces `TutorBackendRulesDependencyException` (`"Chức năng này chưa được cấp quyền đồng bộ cho tài khoản gia sư. Vui lòng liên hệ BeeWise."`) and **never** `"Chưa có lịch dạy trong tuần này"`. Shows `"Chưa có lịch dạy trong tuần này"` only on `EMPTY_VERIFIED`. |
| **T7** | Hồ sơ của tôi | `/tutor/profile` | `TutorSelfProfileScreen` | `tutorProfileViewProvider` | `UI_IMPLEMENTED` | `LIVE_BACKEND_INTEGRATED` (`tutorApplications/{uid}.snapshots()` + `tutors/{uid}.snapshots()`). Distinguishes private application approval from public catalog publication (`hasPublicListing` and `publicCatalogState`). Shows real rating/review count when `reviewCount > 0`, and `"Chưa có đánh giá"` when `reviewCount == 0` (never hardcoded `4.9 (24)`). |
| **T8** | Trung tâm thông báo | `/tutor/notifications` | `TutorNotificationScreen` | `notificationsProvider` | `UI_IMPLEMENTED` | `LIVE_BACKEND_INTEGRATED` (`users/{uid}/notifications.snapshots()`). Renders loading, error+retry, and verified empty state (`"Chưa có thông báo mới"`). Validates notification deep-link routes via `validateTutorNotificationRoute` and distinguishes `TutorBackendRulesDependencyException`, `TutorUnauthorizedException`, `TutorResourceNotFoundException`, and `TutorNetworkException`. |

---

## 3. Data Source States, Freshness & Account-Switch Safety

### 3.1 Explicit Data Source State Classification (`TutorDataSourceState`)
Defined in `lib/models/tutor_workspace_models.dart`:
- `loading`: Initial or refresh subscription awaiting snapshot.
- `emptyVerified`: Query succeeded with proper authorization and returned zero documents.
- `populated`: Query succeeded and returned one or more tutor-owned documents.
- `rulesBlocked`: Firestore returned `permission-denied` (`TutorBackendRulesDependencyException`).
- `unauthorized`: Unauthenticated user, UID mismatch, or non-approved/inactive tutor role (`TutorUnauthorizedException`).
- `notFound`: Target document does not exist (`TutorResourceNotFoundException`).
- `networkError`: Transient connectivity failure (`unavailable` / `deadline-exceeded` -> `TutorNetworkException`).
- `unknownError`: Unclassified failure.

### 3.2 Real-Time `.snapshots()` & Lifecycle Guard (`_guardAuthorizedTutorStream`)
In `lib/services/tutor_workspace_service.dart`:
- Every `watch*` method (`watchDashboard`, `watchTutorChats`, `watchTutorChatSession`, `watchTutorClass`, `watchTutorSchedule`, `watchTutorProfile`) uses real Firestore `.snapshots()` subscriptions wrapped in `_guardAuthorizedTutorStream`.
- `_guardAuthorizedTutorStream` monitors both `_auth.authStateChanges()` and `_applicationService.watchApplicationData(tutorUid)`:
  - Immediately cancels inner Firestore listeners on sign-out, account switch (`User A -> User B`), or tutor role revocation (`status != 'approved' || !verified || !active`), emitting `TutorUnauthorizedException`.
  - Prevents duplicate inner Firestore listeners while active and cleans up all subscriptions on stream cancel.
- All workspace providers in `lib/viewmodels/app_providers.dart` use `StreamProvider.autoDispose` (and `.family`), and all tutor screens configure `.when(skipLoadingOnReload: false, skipLoadingOnRefresh: false, skipError: false, ...)` with pull-to-refresh (`RefreshIndicator`) and `AppBar` refresh actions.

---

## 4. Security & Firestore Rules Boundaries

All existing security invariants in `firebase/firestore.rules` remain intact:
1. **No Client Self-Approval:** `tutorApplications/{uid}` creation forces `status == 'pending'`, `verified: false`, and `active: false`.
2. **Application Update Rule Dependency (`needs_info`):** `firebase/firestore.rules` sets `allow update: if false` on `tutorApplications/{uid}` and no backend applicant resubmission endpoint exists yet. `TutorApplicationService.isResubmissionBackendAvailable` defaults to `false`, disabling final server submission in the UI with a clear explanation banner while allowing local draft edits/validation and preventing denied Firestore writes.
3. **Tutor Workspace Rules Dependency:** `firebase/firestore.rules` scopes `chats`, `chats/{chatId}/messages`, and `classes` to `isParent(uid)` / `canWriteAsParent(uid)`. `FirebaseTutorWorkspaceService` never catches `permission-denied` to return empty lists; it surfaces `TutorBackendRulesDependencyException` so blocked sources are never mistaken for empty data.

---

## 5. Verification Results

- **Formatting (`dart format lib/ test/`):** Clean (0 unformatted files).
- **Static Analysis (`flutter analyze`):** `No issues found!`.
- **Full Repository Test Suite (`flutter test`):** All tests passing (0 failures).
- **Dedicated Tutor UI, Permission Classification & Freshness Suite (`flutter test test/tutor_ui_t1_t8_test.dart`):** **24/24 tests passing**, covering:
  - Guest, parent, `pending`, `needs_info`, `rejected`, `approved`-unverified, `authorizedTutor`, and `unresolved` routing guards.
  - Stale async role resolution protection across User A -> User B account switches.
  - T1 clean guest registration validation & `needs_info` prefill, disabled server submit when backend is unavailable, local draft validation, zero Auth account creation, and zero denied Firestore writes.
  - T2 state differentiation (`rejected` hides resubmit CTA; `approvedPendingVerification` hides workspace entry CTA).
  - T3–T8 real data rendering, zero fabricated `Chị Lan` / `Cô Trang` strings, strict `paymentStatus == 'verified'` badge gating, unauthorized/missing ID handling, and Firestore error+retry recovery.
  - Permission failures vs verified empty states (`permission-denied` on chat list, schedule, and partial/full dashboard block vs `EMPTY_VERIFIED` vs `NETWORK_ERROR`).
  - Live `.snapshots()` updates, manual refresh, account switch invalidation, and permission revocation listener cancellation without duplicate subscriptions.
  - Responsive layout & text-scale checks across all T1–T8 screens at **360dp x 800dp** and **412dp x 915dp** with `textScaleFactor = 1.25` (**0 RenderFlex overflows**).
