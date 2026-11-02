# BeeWise Lab 3 - Task tracker theo Preparation Guide v5

> Cập nhật **02/11/2026**. Mentor nhắc: **“Lab3 tập trung vào công nghệ các bạn nhé.”**
> PR #2 và #3 **đã MERGED**. Phần Bảo đã tích hợp không đồng nghĩa toàn bộ Lab 3 hoàn thành.
> **Owner-reported mentor approval (02/11/2026): Firebase Cloud Storage is replaced by Cloud Firestore Base64 PDF persistence with mentor approval. B-03.2: IMPLEMENTED — LIVE VERIFICATION PENDING. Không có written approval artifact; Storage không còn là dependency/yêu cầu triển khai hiện hành của BeeWise.**

## 1. Tổng quan và nguồn chuẩn

BeeWise chuyển thiết kế Lab 2 thành Flutter dùng dữ liệu thật, có ba luồng người dùng, xử lý lỗi và bằng chứng kiểm chứng được. Ưu tiên rubric Firebase với ngoại lệ PDF owner báo mentor duyệt, MVVM, ARTEMIS và demo; không mở rộng payment/backend vượt nhu cầu các luồng đã chọn.

- **Nguồn kỹ thuật hiện hành:** `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf`, bản mentor cung cấp ngoài repo, **25 trang đã đọc đầy đủ**. Dẫn trang v5 bên dưới; không thêm PDF vào PR này.
- **Thiết kế/phạm vi app:** [handoff Lab 2](../handoff/flutter-handoff.md), [design traceability](design-traceability.md), [architecture](architecture.md), [analytics plan](analytics-plan.md), [backend contract](backend-contract.md), [test plan](test-plan.md), [README](../README.md).
- **Kết quả hiện hành:** [E1]-[E12] ở mục 12, đọc theo SHA/thời điểm. README, design/test plan, [bao-status](workstreams/bao-status.md) và [Firebase index](../evidence/firebase/manifest.md) còn snapshot cũ; các dòng thiếu Google, 5/7 events, first-login pending hay PR đang mở không phải trạng thái hiện hành.
- Đề 18 trang cũ chỉ là lịch sử; **không tái sử dụng điểm rubric cũ** như được v5 xác nhận. V5 không nhắc lại mốc “ít nhất 8 màn”; BeeWise vẫn giữ mục tiêu **12 màn Lab 2**. V5 yêu cầu exploration 15-30 phút nhưng không ghi tier “Pro”; **Pro** là cấu hình kế hoạch repo cần giữ khi thực thi.
- Project đúng: `beewise-lab-3`; Android `com.beewise.beewise`. Chỉ dùng tài khoản/dữ liệu test được phép; không commit credentials, raw UID, token hay khóa mô hình.

## 2. Baseline repository/PR đã xác minh

Baseline migration đã fetch ngày 02/11/2026: `origin/main` **`5df96fd3df995ea12747dcd218c418327d05db4c`**. PR #3 MERGED (`55b11165...`), PR #4 MERGED (`907ced1481a9c62fd4e0c856982857fd65203f38`), PR #5 MERGED (UI/ARTEMIS; merge `5df96fd...`); không có PR mở tại audit. PR #5 flutter-android CI đã FAILURE, không dùng PR #3 CI làm PASS cho main mới. Các số liệu PR #3 bên dưới giữ nguyên lịch sử theo SHA. Xem [migration và verification](workstreams/bao-firestore-reports.md).

| Mốc | Kết quả đã kiểm chứng |
|---|---|
| [PR #1 - Nguyên](https://github.com/YukikoKaori/beewise-lab2/pull/1) | MERGED; app/routes/harness/docs nền. Trong PR #1-#3 chưa thấy PR Nguyên mới hơn; không suy luận tiến độ ngoài repo. |
| [PR #2](https://github.com/YukikoKaori/beewise-lab2/pull/2) | MERGED; merge `12f5322655463fd801d64e4925572d6a3a2bbb82`. Giữ các sửa security/lifecycle. |
| [PR #3](https://github.com/YukikoKaori/beewise-lab2/pull/3) | MERGED 02/11/2026; final source HEAD `b338346ce241250cbaaa4fed5c5208caa5290fde`; merge `55b11165a6505810f6c66a3736609d3b75aabb34`. |
| Local checks PR #3 | Format/analyze/debug APK PASS; **Flutter 66/66**, **Firebase Emulator rules 28/28**, parser 4/4, log/receipt [E1]. Không chạy lại app/cloud trong lượt docs-only này. |
| [Actions final PR #3 HEAD](https://github.com/YukikoKaori/beewise-lab2/actions/runs/41321277718) | **3/3 SUCCESS**, API xác nhận `headSha=b338346...`; `e2e-harness` collect/check cấu trúc, không phải ARTEMIS runtime. CI docs PR là lần kiểm tra riêng. |
| [Actions main sau merge](https://github.com/YukikoKaori/beewise-lab2/actions/runs/41384595579) | **3/3 SUCCESS** tại đúng `55b11165...`: flutter-android, firebase-rules, e2e-harness. |
| Default APK | App source `be2b44515af637db1c7ded6b94797d1cf4adc746`; default `lib/main.dart`, SHA-256 `2d3ed39e8eb5a5604571e15ef20322a00058853f9f773dd92d6397af814edd65`; build/install hash khớp, không dùng probe kết luận startup [E2]. |
| Submission | **PARTIALLY COMPLETE**: Firestore PDF alternative chưa live verified; ba flow, QA và bộ nộp chưa đủ bằng chứng. Không giữ merge blocker cũ của PR #3 đã giải quyết. |

Ba cold **process** start API37 đã settle lên Home, process-to-draw **7,070 / 5,127 / 4,563 ms**, không BeeWise ANR, native Flutter first frame được xác nhận. Lần 3 Android báo `WARM` do giữ task nhưng PID mới. Có ảnh thật 360dp/412dp và navigation; warm 412dp 235 ms host wall [E2].

Giới hạn: headless emulator, chưa test release-mode/máy thật/API35-36; bốn lần ngay sau boot trước đó timeout/first draw 36-57 giây. Evidence hỗ trợ contention emulator/host, chưa chứng minh nguyên nhân độc quyền hay Flutter defect. Không gọi là “đã sửa mọi startup”.

## 3. Checklist yêu cầu mentor v5

`[x]` chỉ xác nhận phạm vi có bằng chứng ghi kèm; `[ ]` còn thiếu thực thi hoặc hồ sơ nộp. Owner/status/action ở mục 5-8.

- [ ] **App/ba flow** (v5 tr.1, 4): màn và **3 luồng Lab 2**, dữ liệu thật, loading/data/empty/error/recovery. Source có 12 màn; chưa chứng minh đủ ba flow live. Mốc ≥8 màn thuộc yêu cầu đầu vào/lịch sử, **không được v5 xác nhận lại**.
- [x] **Kiến trúc** (tr.1, 4): Riverpod/MVVM, View → ViewModel → Service → Firebase SDK; source có provider/controller/service boundary. Nguyên còn audit UI/Figma; kiến trúc không thay E2E.
- [ ] **Auth** (tr.5-7): Google, auth-state restore, cancel/logout, protected screens, lỗi mạng, ảnh app/Authentication Users Console. Runtime Email/Password + Google đã live verified [E3]; chốt ảnh Console trong gói nộp.
- [ ] **Storage** (tr.8-10): ít nhất một file (BeeWise dùng PDF), upload `reports/{uid}/...`, progress/download URL/success/error, owner-only rules, unauthorized/offline tests và tệp trong Console. **Rubric gốc (historical); owner báo mentor đã duyệt Firestore Base64 thay thế. Không cần Blaze/bucket/Storage deployment; B-03.2 chưa live verified.**
- [ ] **FCM** (tr.11-13): Android 13+ permission, foreground/background/terminated, inbox/tap; v5 yêu cầu gửi thử từ Console và kiểm tra từ chối quyền. Native delivery/tap/ownership đã verified [E4]; chốt Console-send và denial receipt.
- [x] **Analytics ≥7 business event types** (tr.14-16): DebugView thật cho `login`, `logout`, `search`, `view_tutor`, `ai_match_no_results`, `sign_up`, `export_report` [E5]. Không đếm SDK auto-events cho đủ bảy.
- [ ] **Analytics plan/evidence** (tr.15-16): trigger, kiểu tham số, câu hỏi sản phẩm, bước flow, ảnh từng event trong kế hoạch. Plan nhiều hơn bảy event; `upload_report`/workflow events chưa chạy không được gọi verified. Bảo/Nguyên chốt plan theo scope ba flow.
- [x] **Crashlytics** (tr.17-19): non-fatal từ lỗi Matching thực tế, deliberate fatal, custom keys và signed-in fatal User ID có Console receipts [E6]. Không suy rộng identity của mọi non-fatal hay logout clearing chưa kiểm tra.
- [ ] **Remote Config** (tr.20-22): ≥2 params đổi hành vi nhìn thấy trên cùng APK; defaults/offline/cache. Thay đổi thực tế và restore verified [E7]; chưa đủ ảnh Console giá trị trước/sau.
- [ ] **ARTEMIS** (tr.23): ≥10 ca có điều kiện/bước/kết quả; **mỗi ca ≥3 executions**; bao phủ Lab 2, một nhánh lỗi, một tương tác Android native; trace/JUnit/pass rate và kết quả quan sát. Harness 26 ca không thay thực thi [E8].
- [ ] **Exploration** (tr.23): một session **15-30 phút**, log thời lượng/issue. Repo chọn TC-25 **Pro 20 phút**; chưa có runtime receipt.
- [ ] **AI Code Review** (tr.24): review PR bằng Copilot/CodeRabbit/tương đương; **≥5 findings thuộc ≥2 nhóm**, file/line, quyết định/lý do; **sửa ≥3 findings accepted**, commit truy vết. V5 không ghi ba commit riêng; self-review hiện có không phải external approval [E9].
- [ ] **Nộp bài** (tr.25): GitHub, Console/test evidence, design/architecture/analytics docs; **report PDF 8-12 trang, slides PDF 12-15 trang, video 5-10 phút**. Có report PDF/slides PPTX **DRAFT**, chưa verified final/video [E10].
- [ ] **Ràng buộc BeeWise/Lab 2:** Firestore + strict rules, không submit hard-coded mocks, Figma/responsive **360dp/412dp**. V5 không ghi riêng hai bề rộng hoặc liệt kê Firestore trong sáu dịch vụ.

**Sáu dịch vụ:** Authentication, Storage, FCM, Analytics, Crashlytics, Remote Config. **Firestore là data store và nay kiêm PDF persistence theo ngoại lệ owner báo mentor duyệt**. Danh sách sáu dịch vụ ở đây là rubric gốc; không claim Firebase Storage đã verified hay dựng thêm dịch vụ bắt buộc.

## 4. Ownership và ranh giới file

| Phạm vi | Bảo | Nguyên |
|---|---|---|
| Chính | Cloud/data, Android/runtime, secure contracts, Console receipts | UI/Figma/responsive, ARTEMIS/E2E, AI review, report/slides/video |
| Source | `firebase/**`, `android/**`, `lib/services/**`, `lib/viewmodels/**`, `lib/models/**`, `lib/main.dart`, `pubspec.*` | `lib/screens/**`, `lib/widgets/**`, `lib/theme/**`, `lib/app/bee_wise_app.dart`, `e2e_test/**` |
| Docs/evidence | `docs/analytics-plan.md`, `docs/backend-contract.md`, `docs/workstreams/bao-*.md`; `evidence/firebase/**`, `evidence/android/**`, `evidence/cloud/**` | `docs/design-traceability.md`, `docs/test-plan.md`, `docs/code-review.md`, `docs/workstreams/nguyen-*.md`; `evidence/ui/**`, `evidence/artemis/**`, `evidence/ai-review/**` |
| Final integration | Bàn giao/duyệt đúng các claim cloud | Chốt `README.md`, `docs/architecture.md`, `docs/lab3-report.md`, `report/**`, `slides/**`, `output/**`, video sau handoff |

Mỗi người fetch latest main, branch/working copy riêng; không tiếp tục PR #2/#3 đã merge. Không sửa file owner khác nếu chưa thống nhất; interface chéo ghi handoff trước. Docs chung không edit song song. Phối hợp cửa sổ rules/RC, namespace/account/device test riêng; giữ privacy, strict rules, generation/journal/cross-UID/fail-closed protections. Lượt này thực hiện các sửa responsive nhỏ trong UI owner scope, bổ sung widget regression coverage và lưu runtime smoke evidence; không thay đổi cloud/config.

## 5. Bảng task Bảo (B-01 đến B-05)

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| B-01 | Bảo | Default Android APK; startup/runtime 360dp/412dp | PARTIALLY COMPLETE | Build + ba settled cold-process starts + native UI/navigation [E1] [E2] | Handoff receipts; kiểm tra máy thật/release/API35-36 khi có; giữ immediate-boot limitation | Device/toolchain; không clear userdata/suppress ANR |
| B-02 | Bảo | Auth + Firestore/role/data thật | PARTIALLY COMPLETE | Email/Password/Google/cancel/restore/logout, role recovery; strict rules/index deployed; **9/9 foreign authenticated reads denied** [E3] [E11] | Chốt Users Console receipt; catalog thật có quyền sử dụng; không gọi fixtures là real product data | Chủ dữ liệu/consent; Nguyên cùng chạy flow |
| B-03 | Bảo | Sáu Firebase services, nhánh lỗi | PARTIALLY COMPLETE | Năm dịch vụ có scoped runtime/Console proof; PDF Firestore alternative IMPLEMENTED — LIVE VERIFICATION PENDING | Chốt rules release được owner duyệt, catalog được phép và live receipts; không lặp test đã verified khi chưa có lý do | Rules deployment authorization; dữ liệu hợp lệ; cửa sổ Console |
| B-04 | Bảo | Trusted business workflows | PARTIALLY COMPLETE; trusted live E2E BLOCKED | Client/rules/unit boundaries có, contract [E12]; trusted producer/payment/schedule chưa live | Chốt ba flow; chỉ trusted staging tối thiểu nếu cần và được phép; không ưu tiên full processor trước Firebase/QA | Mentor/team chốt flow; staff/provider khi cần |
| B-05 | Bảo | Evidence/integration handoff | PARTIALLY COMPLETE | [E1]-[E7], [E11], hashes/audit; scope probe/default rõ | Bàn giao service → thao tác → SHA/APK/device/time → app/log/Console; bản che PII truy cập được, freeze trước demo | Nguyên nhận; private originals không tự là public link |

**B-02 đã đạt trong scope:** own Parent positive controls; A→B, B→A, Google→A đều bị deny foreign Parent/application/devices qua native SDK. Đây là **read negatives trên debug-only probe**, không Admin bypass hay live malicious-write test. Sáu catalog records là `[TEST]`/synthetic/unverified: đọc từ server nhưng **chưa đủ catalog thật**, AI loại chúng khỏi recommendations.

## 6. Bảng task Nguyên

Đã kiểm tra PR #1-#3, source/routes/docs/artifacts trên latest main. Không có tracked `evidence/artemis/`/`evidence/ai-review/`; API reviews/inline comments ba PR đều rỗng tại lần audit. Chỉ mô tả evidence repo, **không kết luận Nguyên chưa làm ở nơi khác**.

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| N-01 | Nguyên | 12 màn Lab 2, Figma/widgets/theme/router | PARTIALLY COMPLETE | All 12 supplied Figma PNGs exist in repo and were reviewed; updated Group Chat/Trial/Class/Payment/Schedule source to reflect layout/colors/progress while keeping trusted fields data-backed [N1]; Home/Search/AI and Login/Register captured at 360/412dp, Tutor Profile/Connection at 412dp, Messages/Profile support routes and authenticated Messages empty state at both widths [N1]; Home raster/frame parity unresolved | Build/install latest source and capture/compare 5 workflow screens at 360/412dp; capture Tutor Profile/Connection 360dp; reconcile Home raster dimensions | Current emulator ADB unavailable; populated workflow screens need trusted fixtures; Home source-frame reconciliation |
| N-02 | Nguyên | Responsive 360dp/412dp; loading/empty/error/recovery | PARTIALLY COMPLETE | Existing 69 earlier Flutter tests; new test covers stepper semantics and empty Chat/Trial/Class/Payment/Schedule layouts at 360/412dp with 1.8 text scale [N1]; Messages empty captured signed-in at both widths; source routes expose loading/empty/error guards | Run new widget suite and inspect keyboard/safe-area/TalkBack on Android, include data/error states | Current Flutter analyzer/test invocation stalls; Android ADB unavailable; data/error states require controlled fixtures |
| N-03 | Nguyên | ARTEMIS ≥10 ca ×3 + Pro 15-30 phút | BLOCKED (runtime PARTIAL; matrix NOT VERIFIED) | 26 cases authored/collected. Android 36 AVD `emulator-5554` online; ARTEMIS host healthy with isolated `gemini-3.5-flash-lite` config. TC-09 passed one live run, verifying all five destinations and no reported overflow/crash (`evidence/artemis/n03-2026-11-02/tc09-run-1-*`). TC-01 initially exposed two synthetic `[TEST]` tutor cards. Source now filters those fixtures from Home/Search; repository unit test and analyzer pass; debug APK build succeeded and was installed. Post-install screenshots show Home's genuine empty state with zero tutor cards. A later live TC-01 trace also observed zero cards, all five tabs, and no Firebase notice, but its harness assertion failed because ARTEMIS used alternate JSON field names and a longer fabrication statement. The parser now normalizes this report shape and the saved observation passes an offline parser check; a subsequent live run stalled before producing a log, so TC-01 is not yet runner-verified. `gemini-2.5-flash` previously returned 429 with a 74032-second retry delay; switching to Lite allowed one TC-01 trace, but quota/runner availability is still uncertain. Approved catalog and trusted workflow fixtures remain unavailable | Re-run TC-01 against the installed APK and preserve successful trace/JUnit/log; execute ≥10 suitable cases ×3 and verify traces, then run TC-25 Pro separately. Obtain approved real catalog and trusted staging records for data-dependent cases | ARTEMIS/Gemini run availability + approved catalog/staging records |
| N-04 | Nguyên | External AI review ≥5 findings/≥2 nhóm, ≥3 fixes | NEEDS VERIFICATION (external NOT VERIFIED) | Historical internal findings/fix commits [E9]; no current target PR or external transcript in repo | Trên PR implementation được mở, request external review; record raw findings/dispositions and fix commits. Static in-repo audit cannot satisfy external-review requirement | Implementation PR target/tool access; do not fabricate external approval |
| N-05 | Nguyên | Final report PDF 8-12 trang, slides PDF 12-15 trang | PARTIALLY COMPLETE | Draft PDF/PPTX/report source [E10]; chưa verified final | Nhận handoff, sửa claim cũ, xuất hai PDF đúng số trang, kiểm tra links | Ba flow, Firestore PDF alternative, QA/review thật |
| N-06 | Nguyên | Demo video 5-10 phút và final links | NEEDS VERIFICATION | [Demo script](demo-script.md); chưa thấy video final/link trong repo | Xác nhận artifact ngoài repo nếu có; quay thật, kiểm tra quyền xem, ghi SHA/giới hạn | App/services sẵn sàng, evidence freeze |

### N-01/N-02 source audit (2026-11-02)

Source-to-Figma audit: [N1](../evidence/ui/source-audit-20261102.md). It maps all 12 canonical screens and routes, records acceptance checks and source-level observations, and separates checks that need an Android capture from issues that can be confirmed from source. The 12 primary supplied frames plus AI results state are indexed in [Figma evidence](../assets/figma-screens/README.md); 11 primary raster captures are 2x their listed 360px frames, while Home is 804x2400 against a 402x874 inspector frame, so Home pixel parity remains unresolved. No runtime visual parity is claimed.

Responsive/accessibility source review found scrollable form/detail layouts, safe-area handling for chat and tutor-profile footers, wrapped home subject chips, and 14sp body text. Three layout constraints were corrected: navigation height now matches the 72dp handoff, loading placeholders no longer force 178dp height, and chat bubbles derive maximum width from screen width. `responsive_layout_test.dart` covers 72dp navigation and TutorCard at 360/412dp with 1.8 text scale. `OnboardingStepper` follows the supplied four-step consultant flow, uses BeeWise state colors and exposes one progress label to accessibility. `workflow_empty_state_test.dart` adds 360/412dp large-text coverage for stepper and Chat/Trial/Class/Payment/Schedule empty states; analyzer found no issues in an earlier iteration, but the latest full test/analyze run has not completed because the current SDK invocation stalls. Earlier 69 Flutter tests and the debug APK build passed before this turn; those results do not include the latest UI/widget-test edits. Runtime captures/hierarchies cover Home/Search/AI at both widths; Login/Register at both widths; Tutor Profile/Connection at 412dp; Messages/Profile at 412dp; Login/Register keyboard/scroll; and Home/Search/AI at font scale 1.3. Signed-in Messages empty state is captured at both widths. Five canonical screens remain without runtime capture; full Figma, state, keyboard and accessibility validation is outstanding. Offline harness checks pass (26 unique cases and synthetic exit/status/hash handling only); ARTEMIS host/device/key and trusted workflow data are not operationally available.

## 7. Ma trận kiểm chứng sáu Firebase services

Mỗi hàng là subtask B-03 riêng. Status xét **đủ receipt v5**, không phủ nhận runtime PASS trong Evidence.

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| B-03.1 Auth | Bảo | Google/Email, restore/cancel/logout, protected/error states, Users Console | PARTIALLY COMPLETE (runtime COMPLETE trong scope) | Native A/B/Google + role/account-check recovery [E3] | Đính kèm/kiểm tra Users Console đã che PII cho gói nộp; không ghi thiếu Google Sign-In | Console access, private handoff |
| B-03.2 Firestore PDF alternative | Bảo | Một PDF/document `reports/{uid}/files/{reportId}`, Base64 ≤500 KiB, owner-only parent rules, server ack/read, authenticated download; không public URL | **IMPLEMENTED — LIVE VERIFICATION PENDING** | [Migration / local test manifest](workstreams/bao-firestore-reports.md); giữ PDF/Storage evidence cũ [E1] [E5] như history | Owner duyệt rules/index release đã review; live A/B server upload/download/hash, denied writes/offline, app + Console evidence | Owner-reported mentor approval; chưa có written artifact. Không Blaze/bucket. Emulator/mock không thay live proof |
| B-03.3 FCM | Bảo | Android 13+ permission/inbox, foreground/background/terminated, tap/ownership | PARTIALLY COMPLETE (delivery/lifecycle scoped COMPLETE) | First-login race fixed; native A/B/Google ownership, 3 states và terminated tap Search [E3] [E4] | Chốt riêng Console-send và permission-denied receipts theo tr.13; giữ generation/journal/quarantine | Account/device, phối hợp sender/Console |
| B-03.4 Analytics | Bảo | ≥7 business events, DebugView, typed non-PII params/identity | COMPLETE cho minimum bảy loại đã test | Bảy events mục 3; Google method; A→logout→guest→B→logout→guest, guest không `_id`, Console correlation [E5] | Handoff per-event receipts; đối chiếu plan/flow, không gọi mọi planned event verified | Nguyên ghép demo; events PDF/workflow theo task tương ứng |
| B-03.5 Crashlytics | Bảo | Real non-fatal, deliberate fatal, identity/keys, app recovery | COMPLETE cho scoped Console checks | Matching failure, fatal/custom keys, Google fatal User ID match [E6] | Bản che UID; ghi persisted keys không xác định fatal trigger; không suy rộng non-fatal identity/logout clear | Private originals + handoff |
| B-03.6 Remote Config | Bảo | ≥2 params đổi UI không rebuild; defaults/offline/cache; Console trước/sau | PARTIALLY COMPLETE (same-APK behavior COMPLETE) | Apply/restore `ai_matching_enabled`, `ai_result_limit`, `home_tutor_limit`; visible gate/limits + tests [E7] | Chốt ảnh Console giá trị trước/sau cùng ảnh app, giải thích fetch/cache; restore sau experiment | Owner authorization, coordinated RC window |

Analytics null clearing đã đủ native FA-SVC removal + complete guest bundles không `_id`, hai guest search tới DebugView. Console có thể giữ property lịch sử; **không tái mở blocker thiếu quyền/UID clearing cũ**, không đổi identity theo stale display. Không có event-level backend export; không suy rộng ngoài scope [E5].

**Firestore riêng:** các collection trước migration có strict rules/index deployed/verified [E11], native read negatives 9/9 [E3], unit/rules write negatives PASS; live malicious writes chưa chạy. Rules `reports/.../files/...` và index exemption mới chưa deploy; xem B-03.2. Client không tự tạo verified tutor, paid invoice hay official schedule. Catalog thật và trusted workflow data còn mở ở B-02/B-04.

## 8. Ba flow và evidence công nghệ

Ba flow dưới đây từ traceability/test plan hiện có; không thay bằng ba demo Firebase rời rạc. Nếu thu hẹp flow thứ ba, team xin mentor xác nhận và cập nhật traceability; không tự gọi payment/schedule thành công.

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| F-01 | Nguyên + Bảo | Home → Search/AI → Tutor detail → auth gate → Request → Chat | PARTIALLY COMPLETE | Discovery/Auth native; request/chat source + rules; [test plan](test-plan.md) | Chạy trọn trên catalog thật, kiểm tra Firestore side effects/error/recovery, giữ tutor context qua login | Catalog + safe test parent |
| F-02 | Nguyên + Bảo | AI matching → tutor thật hoặc no-match/error → retry/Manual Search | PARTIALLY COMPLETE | Empty/disabled recovery + Analytics verified; [matching source](../lib/services/matching_service.dart) loại synthetic data | Nếu giữ AI success, chốt provider/terms/config được phép và catalog thật; ghi output thật | Owner/provider; không tự bật billing/App Check enforcement |
| F-03 | Nguyên + Bảo | Chat → trial → class revision → invoice → verified payment → official schedule | BLOCKED cho live E2E | Client/rules giữ trust boundary [E12]; chưa trusted producer/provider | Chốt scope công nghệ với mentor; full flow cần staging tối thiểu được phép/receipt-driven state, không tự dựng full processor | Trusted staff/proposals/issuer/provider hoặc scope được mentor duyệt |

Mỗi flow/service cần **source SHA, APK hash/entrypoint, device/OS/viewport, thời gian/lệnh, expected/observed, screenshot/video/log/trace, failure/recovery, Console/data link khi cần**. Không ghi PASS từ `SUCCESS`, mock, toast, API acceptance hay JUnit collection đơn lẻ. Không đưa credentials/PII vào model/trace. PDF local và `export_report` **không chứng minh cloud persistence**.

## 9. Blockers và quyết định còn mở

1. **Firestore PDF alternative:** owner báo mentor duyệt thay Cloud Storage; implementation/local gates có, live upload/download/A/B/Console chưa chạy. Cần owner duyệt rules deployment và tutor active/verified/non-synthetic được phép. Không yêu cầu Blaze/bucket hay deploy Storage.
2. **Catalog/ba flow:** chưa có catalog thật được phép; synthetic records không đủ. Chốt scope Lab 2/trusted staging khi cần; không nới rules demo payment/schedule.
3. **QA:** ARTEMIS host, Gemini credential and Android 36 emulator đã hoạt động cho smoke runs; xem kết quả và giới hạn mới nhất ở N-03/test plan. Ma trận ≥10 ca ×3, phiên Pro và external review vẫn chưa đủ evidence. Các ca cần catalog/staging phải có fixtures riêng được duyệt. N-04 cần reviewer ngoài trên implementation PR sau khi mở PR; không suy diễn private evidence ngoài repo.
4. **Gói nộp:** Users Console, FCM Console-send/denied permission, RC parameter before/after; chuyển private receipts thành bản chia sẻ đã che PII. DRAFT/PPTX không thay final PDFs/video.
5. **Android:** immediate-boot API37 và physical/release/API35-36 chưa kiểm tra toàn diện. Giới hạn sau scoped startup PASS, không giữ PR #3 đã merge chờ sửa vô hạn.

## 10. Thứ tự tiếp theo P0/P1/P2

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| P0-1 | Chủ project + Bảo | Firestore PDF live verification | IMPLEMENTED — LIVE VERIFICATION PENDING | B-03.2, [migration](workstreams/bao-firestore-reports.md) | Duyệt frozen rules/index diff, cho phép tutor test phù hợp và live A/B test; không cần Blaze | Owner rules-release authorization; catalog, device |
| P0-2 | Bảo + Nguyên | Catalog/ba flow và evidence handoff | PARTIALLY COMPLETE | B-02/B-04/B-05, [E3] [E12] | Chốt data thật, ba flow và ma trận receipts còn thiếu; bàn giao kết quả đã chốt | Chủ dữ liệu, mentor nếu đổi scope |
| P0-3 | Nguyên | ARTEMIS/Pro và external review | NEEDS VERIFICATION | N-03/N-04, [E8] [E9] | Xác nhận host/key/device; ≥10 ca ×3 + Pro 15-30 phút; ≥5 findings/≥2 nhóm, ≥3 fixes và commits | Host/key, device/data, review tool |
| P1-1 | Bảo | Firestore PDF live và Console packet | PARTIALLY COMPLETE | B-03.1-6 | Sau authorization: server save/download/hash/ownership/offline; chốt Auth/FCM/RC receipts | P0-1/P0-2, cửa sổ Console |
| P1-2 | Nguyên; Bảo review cloud | UI/responsive, final PDFs/video/links | PARTIALLY COMPLETE | N-01/N-02/N-05/N-06, [E10] | Audit UI, integration freeze và đóng gói bản nộp thật | P0-2/P0-3, Firestore PDF live |
| P2-1 | Bảo + Nguyên | Mở rộng validation/product nếu scope cần | NEEDS VERIFICATION | B-01/B-04, [E2] [E12] | Physical/release/API35-36 khi có; pagination >100, quota/inbox/backend projection khi cần; không để full payment/backend lấn mandatory Firebase/ARTEMIS/demo | Device hoặc product contract được duyệt |

## 11. Git handoff (2026-11-02)

Firestore PDF migration nằm trên branch **`feat/lab3-firestore-pdf-reports`**, tạo từ main `5df96fd...`, qua PR riêng; **không commit trực tiếp main hoặc tự merge**. Diff gồm service/provider/controller, rules/tests/config, docs và integration PDF tối thiểu trong UI/TC-11 owner Nguyên. [Handoff hiện hành](workstreams/bao-firestore-reports.md) ghi rõ trạng thái/local-vs-live và PR sẽ ghi exact HEAD/CI.

Giữ nguyên các sửa responsive/ARTEMIS đã merge ở PR #5, evidence cũ và working copy khác. Review `git status --short`, stage đúng file migration; không stage credentials, private PDF, raw UID/token, build output hoặc local ARTEMIS config. Git instructions từ PR #5 trước đây là lịch sử đã superseded, không hướng dẫn push thẳng main trong task này.

## 12. Checklist tích hợp và nộp cuối

- [x] PR #2/#3 đã merge; baseline main/source/SHA/CI ghi đúng.
- [ ] Workstreams cập nhật newest main; checks trên integration HEAD, không dùng PR #3 CI thay kiểm tra code mới.
- [ ] 12 màn audit Figma, responsive 360dp/412dp đủ scope, loading/empty/error/recovery.
- [ ] Ba flow Lab 2 chạy E2E thật; không hard-coded submitted catalog/giả payment/schedule.
- [ ] Rubric Firebase với **owner-reported mentor-approved Firestore PDF alternative**: save/download/server/hash/ownership live evidence; không claim Cloud Storage verified.
- [ ] Analytics plan/receipts khớp; Auth/FCM/Crashlytics/RC có gói Console/app/log reviewable, không lộ PII.
- [ ] ARTEMIS ≥10 ca ×3, Pro exploration 15-30 phút, traces/JUnit/pass rates, phân loại flaky/fail/blocked thật.
- [ ] External review ≥5 findings/≥2 nhóm; dispositions/lý do và ≥3 accepted fixes có commit truy vết.
- [ ] Report PDF 8-12 trang, slides PDF 12-15 trang, video 5-10 phút; Bảo duyệt cloud claims, hai người kiểm tra quyền xem links.
- [ ] Repo/design/architecture/analytics/test docs/evidence index khớp final SHA; không dùng DRAFT/PPTX thay final PDF. Không tự merge implementation PR này.

## 13. Evidence references và status conventions

| Ref | Nguồn audit | Phạm vi / cách đọc |
|---|---|---|
| [E1] | [Controlled validation](../evidence/cloud/pr3-controlled-validation.json), [check logs](../evidence/cloud/checks/pr3-controlled/) | 66 Flutter / 28 emulator rules / build; không là live Storage/ARTEMIS. |
| [E2] | [Native manifest](../evidence/android/pr3-controlled/manifest.json), [diagnosis](workstreams/bao-reliability.md) | Default APK/control, widths/first frame/limitations; đọc section mới nhất trước history. |
| [E3] | [Google runtime](../evidence/cloud/google-runtime-validation.json), [reliability](../evidence/cloud/reliability-validation.json) | Auth, role/FCM fix, 9/9 probe read denials; verdict UID/startup cũ được E2/E5 supersede. |
| [E4] | [Terminated tap](../evidence/android/pr3-completion/terminated-tap-sequence.json), [follow-up](../evidence/cloud/pr3-followup-validation.json) | Background; terminated PID absent trước send, receiver PID, actual Search 12.84s/18.47s; Home-only cũ không là route proof. |
| [E5] | [Seven events](../evidence/cloud/reliability-validation.json), [native identity](../evidence/cloud/pr3-identity-native-final.json), [DebugView](../evidence/cloud/pr3-debugview-correlation.json) | Bảy loại là union receipts cũ/mới; null clearing + guest events verified, stale properties không là blocker mới. |
| [E6] | [Console fatal/non-fatal](../evidence/cloud/console-runtime-validation.json), [fatal identity](../evidence/cloud/google-runtime-validation.json) | Matching failure + deliberate fatal/keys/Google UID; private originals có hashes; không suy rộng non-fatal/logout identity. |
| [E7] | [RC roundtrip](../evidence/cloud/remote-config-roundtrip.json), [native before/after](../evidence/firebase/remote-config/README.md) | Same-APK gate/limits, defaults và restore; thiếu Console values receipt, không thiếu thay đổi hành vi thật. |
| [E8] | [Test plan](test-plan.md), [harness](../e2e_test/), [blocked preflight](../evidence/corrective/artemis-latest-blocked.json) | Authored/collect/preflight; chưa committed execution traces/JUnit. Hỏi Nguyên về evidence ngoài repo. |
| [E9] | [Review record](code-review.md), [PR #2 lifecycle review](pr2-lifecycle-review.md) | Internal Codex findings/fix commits có; external transcript/approval NOT VERIFIED. |
| [E10] | [Report source](lab3-report.md), [draft PDF](../output/pdf/BeeWise-Lab3-Implementation-Report-DRAFT.pdf), [draft PPTX](../output/presentations/BeeWise-Lab3-Review-DRAFT.pptx), [demo plan](demo-script.md) | History/DRAFT, không phải final submission hay current service baseline. |
| [E11] | [Rules deploy](../evidence/cloud/authorized-deploy-rules.json), [index deploy](../evidence/cloud/authorized-deploy-indexes.json), [release state](../evidence/cloud/firestore-release-state.json) | Authorized strict bundle, index READY trước rules release; khác local rules tests. |
| [E12] | [Trusted contract](backend-contract.md), [workflow status](workstreams/bao-workflow-status.md), [UI handoff](workstreams/bao-ui-handoff.md) | Boundaries/history; account/rules blocker cũ superseded E3/E11; trusted live processor chưa proof. |
| [N1] | [UI source audit](../evidence/ui/source-audit-20261102.md), [runtime manifest](../evidence/ui/runtime-manifest-20261102.md) | 12-screen route/Figma/source review plus partial Android 36 runtime screenshots/UI hierarchies; not a complete visual/accessibility matrix. |

[E1]: ../evidence/cloud/pr3-controlled-validation.json
[E2]: ../evidence/android/pr3-controlled/manifest.json
[E3]: ../evidence/cloud/reliability-validation.json
[E4]: ../evidence/android/pr3-completion/terminated-tap-sequence.json
[E5]: ../evidence/cloud/pr3-debugview-correlation.json
[E6]: ../evidence/cloud/google-runtime-validation.json
[E7]: ../evidence/cloud/remote-config-roundtrip.json
[E8]: test-plan.md
[E9]: code-review.md
[E10]: lab3-report.md
[E11]: ../evidence/cloud/firestore-release-state.json
[E12]: backend-contract.md
[N1]: ../evidence/ui/source-audit-20261102.md

**COMPLETE:** hàng có evidence đủ trong scope nêu. **PARTIALLY COMPLETE:** có code/kết quả, thiếu bước/receipt bắt buộc. **NOT STARTED:** đã xác nhận chưa bắt đầu. **BLOCKED:** thiếu dependency cụ thể. **DEFERRED:** owner hoãn, không miễn yêu cầu. **NEEDS VERIFICATION / NOT VERIFIED:** thiếu evidence kết luận, không đồng nghĩa owner chưa làm.

**PASS/FAIL/NOT RUN** mô tả từng phép kiểm tra, không thay status cả task. Phân biệt source, mock/unit, Firebase Emulator rules, CI APK, native emulator, physical device, live Console/service. Giữ evidence gốc/lịch sử tại link; tracker chỉ giữ trạng thái hiện hành, không chép nối snapshots mâu thuẫn.
