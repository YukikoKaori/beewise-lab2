# BeeWise Lab 3 - Task tracker theo Preparation Guide v5

> **Latest owner decision, 2026-11-04:** the owner accepted the disclosed
> authorized1/actual2 request deviation retrospectively. The earlier draft
> hold below is historical and resolved; ready for review is conditional on
> final-HEAD gates. No additional provider calls, cloud/billing changes or
> deployment are authorized. Bao retains F-02; Nguyen owns F-03 only.
> [Owner acceptance and existing-data DebugView inspection](../evidence/cloud/f02-lite-native-20261104/owner-finalization.md).


> **Final ownership correction — 04/11/2026 (current): B-04 SHARED OWNERSHIP.**
> **F-01: EXISTING VERIFIED CLOUD FLOW**, Bao's Firebase integrations/evidence retained.
> **F-02: BAO — COMPLETE / LIVE VERIFIED** in the tested API35 guest/debug scope.
> Real Firebase AI Logic/Gemini3.5 Flash-Lite result, App Check, validation,
> native result/detail/fallback and FA-SVC success event are evidenced.
> **F-03: NGUYEN — HANDOFF / PENDING IMPLEMENTATION**, including consultant
> backend, payOS/webhooks, verified payment, official schedule and business tests.
> The earlier full-transfer steer was too broad and is superseded. B-01/B-02/
> B-03.1–6/B-05 stay COMPLETE in verified scopes; Bao's expanded assigned scope
> includes live-verified F-02; assigned implementation scope is complete for
> tested acceptance. **Lab 3 overall: NOT YET COMPLETE.**
> [Precise F-03 handoff and preserved WIP](workstreams/bao-to-nguyen-b04-handoff.md).
> No F-03 deployment or feature delivery by Bao; Nguyen uses his own branch.
> **Latest F-02 packet:** [live3.5 acceptance](../evidence/cloud/f02-lite-native-20261104/README.md).
> Local105 Flutter/58 Rules tests PASS. PR remains DRAFT for owner review: an
> automation error caused2 calls against approved maximum1; explicitly disclosed.
> Earlier3.8 failure evidence is preserved as historical investigation.

> **Bao acceptance closeout — 03/11/2026 (historical evidence). B-03.2 COMPLETE — FIRESTORE ALTERNATIVE VERIFIED.**
> API35 default APK: three controlled cold Home/no-ANR runs, real360/412dp,
> native30s timeout/UI retry/same hash/no extra report, guest error, A→B eventual
> callback isolation and fresh export_report DebugView(subject2,size18) PASS.
> Users Console, FCM Console-send/permission-denied and RC before/after/restore
> receipts now accessible. RC baseline/debug/network/display/root restored.
> **B-04 remains PARTIALLY VERIFIED:** App Check API DISABLED/provider success
> unverified; owner confirms no trusted staging/backend for onboarding/payment.
> [All-B status, actual evidence and exact dependencies](../evidence/cloud/bao-acceptance-20261103/README.md)
> · [Complete audit matrix](../evidence/cloud/bao-acceptance-20261103/audit-matrix.md).
> Base/merged PR #12 `8c494f0780aab7c41796244ab78b5c4ffb1daff4`, refetched.
> Local full gates PASS; exact final HEAD Actions in delivery PR. No app/security
> behavior change or auto merge. Nguyen-owned statuses are unchanged.
> All older dated entries below are historical snapshots, not current blockers.

> **Final Bao handoff — 03/11/2026 (latest): Bao scope / B-03.2 PARTIALLY VERIFIED.**
> Independently verified PR #11 MERGED; current fetched main
> `b45bdce4d3a68006a28ca8e587fdece0187a8660`. Implementation/deployment/native
> PDF roundtrip/live security remain verified at their historical scope.
> Fresh local format/analyze/build, Flutter 95/95, rules 58/58 and 27-function
> harness structure PASS; ARTEMIS runtime NOT RUN. Default APK installed preserving
> data but launcher ANR/launch timeout prevents fresh stability PASS. New real
> local PDF/controller generation + native export event are instrumented evidence,
> not Console receipt/UI walkthrough. Native distinct 30s timeout/retry and durable
> export DebugView parameter screenshot remain NOT VERIFIED; no new app defect or
> speculative fix, cloud save/deployment, account/catalog mutation or auto merge.
> [Final evidence/matrix](../evidence/cloud/firestore-reports/finalization-20261103/README.md)
> · [Executable Nguyen handoff](workstreams/bao-to-nguyen-final-handoff.md).
> N-03 still needs ≥10 official cases ×3 + exploration on a stable authorized
> ARTEMIS/device/fixtures; N-04 owner-confirmed approval stays COMPLETE;
> UI/accessibility, slides PDF, video/links retain their own open work.
> Earlier dated entries below remain historical, not new test results.

> **B-03.2 live acceptance — 03/11/2026: PARTIALLY VERIFIED.** Current evidence
> supersedes the historical eligible-tutor blocker below. One consented demo
> tutor is live, professionally `verified=false`, with exact-ID eligibility and
> explicit demo disclosure. Real default-APK generation → Firestore server save
> → native download → matching SHA256 → Android preview PASS; live A/B ownership
> denials and DebugView `upload_report(storage_backend=firestore)` PASS.
> Native distinct timeout/retry and a durable export_report DebugView parameter
> screenshot remain incomplete. Invalid JS offline control and System UI ANR on
> resumed emulator are preserved, not relabeled PASS. Local Flutter 95/95, rules
> 58/58, format/analyze/pub/APK and 27-scenario structural harness PASS after
> merging main `47fb375eceb6f741a3a4dba27242ad17c6aaee69`.
> [Individual results and evidence](../evidence/cloud/firestore-reports/live-20261103/README.md).
> No Storage, billing, App Check or backend change; no automatic merge.

> Cập nhật **02/11/2026**. Mentor nhắc: **“Lab3 tập trung vào công nghệ các bạn nhé.”**
> PR #2 và #3 **đã MERGED**. Phần Bảo đã tích hợp không đồng nghĩa toàn bộ Lab 3 hoàn thành.
> **Owner-reported mentor approval (02/11/2026): Firebase Cloud Storage is replaced by Cloud Firestore Base64 PDF persistence with mentor approval. B-03.2: PARTIALLY VERIFIED (live results above). Không có written approval artifact; Storage không còn là dependency/yêu cầu triển khai hiện hành của BeeWise.**

## 1. Tổng quan và nguồn chuẩn

BeeWise chuyển thiết kế Lab 2 thành Flutter dùng dữ liệu thật, có ba luồng người dùng, xử lý lỗi và bằng chứng kiểm chứng được. Ưu tiên rubric Firebase với ngoại lệ PDF owner báo mentor duyệt, MVVM, ARTEMIS và demo; không mở rộng payment/backend vượt nhu cầu các luồng đã chọn.

- **Nguồn kỹ thuật hiện hành:** `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf`, bản mentor cung cấp ngoài repo, **25 trang đã đọc đầy đủ**. Dẫn trang v5 bên dưới; không thêm PDF vào PR này.
- **Thiết kế/phạm vi app:** [handoff Lab 2](../handoff/flutter-handoff.md), [design traceability](design-traceability.md), [architecture](architecture.md), [analytics plan](analytics-plan.md), [backend contract](backend-contract.md), [test plan](test-plan.md), [README](../README.md).
- **Kết quả hiện hành:** [E1]-[E12] ở mục 12, đọc theo SHA/thời điểm. Tracker đã được đồng bộ sau merge PR #9: N-01/N-02 còn việc runtime; N-03 còn thiếu ma trận ARTEMIS và exploration; N-04 hoàn tất theo xác nhận reviewer của owner; N-05/N-06 còn mở theo điều kiện tại từng hàng. README, design plan, [bao-status](workstreams/bao-status.md) và [Firebase index](../evidence/firebase/manifest.md) vẫn có snapshot lịch sử, nên đọc theo mốc SHA/ngày tương ứng.
- Đề 18 trang cũ chỉ là lịch sử; **không tái sử dụng điểm rubric cũ** như được v5 xác nhận. V5 không nhắc lại mốc “ít nhất 8 màn”; BeeWise vẫn giữ mục tiêu **12 màn Lab 2**. V5 yêu cầu exploration 15-30 phút nhưng không ghi tier “Pro”; **Pro** là cấu hình kế hoạch repo cần giữ khi thực thi.
- Project đúng: `beewise-lab-3`; Android `com.beewise.beewise`. Chỉ dùng tài khoản/dữ liệu test được phép; không commit credentials, raw UID, token hay khóa mô hình.

## 2. Baseline repository/PR đã xác minh

Đã fetch ngày 02/11/2026; hiện local `main` khớp `origin/main` tại merge PR #5 `5df96fd3df995ea12747dcd218c418327d05db4c`.
**Cập nhật deploy đã duyệt (02/11, 16:52Z):** qb duyệt đúng frozen bundle.
Deploy chỉ Firestore rules/indexes exit 0; readback ruleset
`34ff742c-626d-4cd5-abde-59c21cce3522` khớp bundle, index chat cùng ID vẫn READY,
exemption Base64 đã live. Client SDK thật: public query PASS, 9 private guest reads
permission-denied PASS, không dùng IAM/emulator và không ghi dữ liệu. B-03.2
**PARTIALLY VERIFIED**, live PDF vẫn **BLOCKED do chưa có tutor eligible được phép**.
Không sửa catalog, tạo report, đổi billing/Storage/App Check hay rollback.
[Receipt deploy và kiểm tra live](../evidence/cloud/firestore-reports/deployment-20261102.json).

**Live PDF preflight mới (02/11):** fetch main `f4fe42d5246d36c033cec27dc76a32bb5bf97d4f`,
đúng merge PR #6; Actions main 3/3 SUCCESS. B-03.2 **BLOCKED** cho live acceptance,
implementation vẫn **IMPLEMENTED — LIVE VERIFICATION PENDING**: rules live chưa có
`/reports`, 6 tutor đều synthetic, 0 eligible. Chưa được owner duyệt deploy bundle
cụ thể nên không deploy hay sửa catalog. Flutter 91/91, rules và frozen bundle mỗi
lượt 57/57; APK default cài cùng signer giữ userdata, lên Home/empty catalog sau
startup chậm. DebugView vào được, chưa có event upload Firestore mới. Xem
[bundle/hash, approval gate, evidence và từng TC-PDF](../evidence/cloud/firestore-reports/deployment-plan-20261102.md).
Không đánh dấu PDF hay toàn bộ Lab 3 COMPLETE; các baseline migration bên dưới là lịch sử.

Baseline migration đã fetch ngày 02/11/2026: `origin/main` **`5df96fd3df995ea12747dcd218c418327d05db4c`**. PR #3 MERGED (`55b11165...`), PR #4 MERGED (`907ced1481a9c62fd4e0c856982857fd65203f38`), PR #5 MERGED (UI/ARTEMIS; merge `5df96fd...`); không có PR mở tại audit. PR #5 flutter-android CI đã FAILURE, không dùng PR #3 CI làm PASS cho main mới. Các số liệu PR #3 bên dưới giữ nguyên lịch sử theo SHA. Xem [migration và verification](workstreams/bao-firestore-reports.md).

| Mốc | Kết quả đã kiểm chứng |
|---|---|
| [PR #1 - Nguyên](https://github.com/YukikoKaori/beewise-lab2/pull/1) | MERGED; app/routes/harness/docs nền. |
| [PR #2](https://github.com/YukikoKaori/beewise-lab2/pull/2) | MERGED; merge `12f5322655463fd801d64e4925572d6a3a2bbb82`. Giữ các sửa security/lifecycle. |
| [PR #3](https://github.com/YukikoKaori/beewise-lab2/pull/3) | MERGED 02/11/2026; final source HEAD `b338346ce241250cbaaa4fed5c5208caa5290fde`; merge `55b11165a6505810f6c66a3736609d3b75aabb34`. |
| [PR #5 - N-01/N-02/N-03](https://github.com/YukikoKaori/beewise-lab2/pull/5) | MERGED 02/11/2026; head `a3e0252bf30be982a0a9164a2fba4c2ba2332a74`; merge `5df96fd3df995ea12747dcd218c418327d05db4c`. GitHub review submissions and review comments were empty when checked; this PR does not satisfy N-04 external review. |
| Local checks PR #3 | Format/analyze/debug APK PASS; **Flutter 66/66**, **Firebase Emulator rules 28/28**, parser 4/4, log/receipt [E1]. Không chạy lại app/cloud trong lượt docs-only này. |
| [Actions final PR #3 HEAD](https://github.com/YukikoKaori/beewise-lab2/actions/runs/41321277718) | **3/3 SUCCESS**, API xác nhận `headSha=b338346...`; `e2e-harness` collect/check cấu trúc, không phải ARTEMIS runtime. CI docs PR là lần kiểm tra riêng. |
| [Actions main sau merge](https://github.com/YukikoKaori/beewise-lab2/actions/runs/41384595579) | **3/3 SUCCESS** tại đúng `55b11165...`: flutter-android, firebase-rules, e2e-harness. |
| Default APK | App source `be2b44515af637db1c7ded6b94797d1cf4adc746`; default `lib/main.dart`, SHA-256 `2d3ed39e8eb5a5604571e15ef20322a00058853f9f773dd92d6397af814edd65`; build/install hash khớp, không dùng probe kết luận startup [E2]. |
| Submission | **PARTIALLY COMPLETE**: Firestore PDF core roundtrip đã live verified, còn native deadline/Console receipt nêu ở đầu tài liệu; ba flow, QA và bộ nộp chưa đủ bằng chứng. Không giữ merge blocker cũ của PR #3 đã giải quyết. |

Ba cold **process** start API37 đã settle lên Home, process-to-draw **7,070 / 5,127 / 4,563 ms**, không BeeWise ANR, native Flutter first frame được xác nhận. Lần 3 Android báo `WARM` do giữ task nhưng PID mới. Có ảnh thật 360dp/412dp và navigation; warm 412dp 235 ms host wall [E2].

Giới hạn: headless emulator, chưa test release-mode/máy thật/API35-36; bốn lần ngay sau boot trước đó timeout/first draw 36-57 giây. Evidence hỗ trợ contention emulator/host, chưa chứng minh nguyên nhân độc quyền hay Flutter defect. Không gọi là “đã sửa mọi startup”.

## 3. Checklist yêu cầu mentor v5

`[x]` chỉ xác nhận phạm vi có bằng chứng ghi kèm; `[ ]` còn thiếu thực thi hoặc hồ sơ nộp. Owner/status/action ở mục 5-8.

- [ ] **App/ba flow** (v5 tr.1, 4): màn và **3 luồng Lab 2**, dữ liệu thật, loading/data/empty/error/recovery. Source có 12 màn; chưa chứng minh đủ ba flow live. Mốc ≥8 màn thuộc yêu cầu đầu vào/lịch sử, **không được v5 xác nhận lại**.
- [x] **Kiến trúc** (tr.1, 4): Riverpod/MVVM, View → ViewModel → Service → Firebase SDK; source có provider/controller/service boundary. Nguyên còn audit UI/Figma; kiến trúc không thay E2E.
- [ ] **Auth** (tr.5-7): Google, auth-state restore, cancel/logout, protected screens, lỗi mạng, ảnh app/Authentication Users Console. Runtime Email/Password + Google đã live verified [E3]; chốt ảnh Console trong gói nộp.
- [ ] **Storage** (tr.8-10): ít nhất một file (BeeWise dùng PDF), upload `reports/{uid}/...`, progress/download URL/success/error, owner-only rules, unauthorized/offline tests và tệp trong Console. **Rubric gốc (historical); owner báo mentor đã duyệt Firestore Base64 thay thế. Không cần Blaze/bucket/Storage deployment; B-03.2 Firestore alternative COMPLETE; Storage remains DEFERRED.**
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
| Chính | Firebase/Android scope; **F-02 AI Matching/App Check/native acceptance**; F-01 existing cloud integrations; approved config/security support | **F-03 consultant/backend/payOS/webhooks/payment/schedule/tests**; existing UI/Figma/ARTEMIS/review/report scope |
| Source | F-02 matching/AI config/controllers/tests and Firebase infrastructure/security; no F-03 implementation | F-03 services/backend/workflow tests and existing UI/theme/router/E2E, coordinated at shared boundaries |
| Docs/evidence | `docs/analytics-plan.md`, `docs/backend-contract.md`, `docs/workstreams/bao-*.md`; `evidence/firebase/**`, `evidence/android/**`, `evidence/cloud/**` | `docs/design-traceability.md`, `docs/test-plan.md`, `docs/code-review.md`, `docs/workstreams/nguyen-*.md`; `evidence/ui/**`, `evidence/artemis/**`, `evidence/ai-review/**` |
| Final integration | Bàn giao/duyệt đúng các claim cloud | Chốt `README.md`, `docs/architecture.md`, `docs/lab3-report.md`, `report/**`, `slides/**`, `output/**`, video sau handoff |

Mỗi người fetch latest main, branch/working copy riêng; không tiếp tục PR #2/#3 đã merge. Không sửa file owner khác nếu chưa thống nhất; interface chéo ghi handoff trước. Docs chung không edit song song. Phối hợp cửa sổ rules/RC, namespace/account/device test riêng; giữ privacy, strict rules, generation/journal/cross-UID/fail-closed protections. Final split ngày04/11: Bao resumes F-02 only and may deliver one focused F-02 PR after validation. F-03 WIP stays preserved/excluded; Nguyen implements F-03 on his own branch. Firebase production/deployment still requires exact approval.

## 5. Bảng task Bảo (B-01 đến B-05)

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| B-01 | Bảo | Default Android APK; startup/runtime360dp/412dp | COMPLETE controlled environment | Three final API35 cold PIDs/Home/no ANR; warm timing/actual follow-up, real widths [E13] | Release/physical/immediate API37 parity not claimed; diagnostic ADB instability documented | Preserve userdata/detection; reopen on reproducible settled BeeWise-only ANR |
| B-02 | Bảo | Auth + Firestore/role/approved data | COMPLETE approved scope | Users Console + real A/B native owner/foreign server checks, disclosed consented demo, current rules/index match [E13] | Demo professionally unverified; no general production catalog claim | Approved data only; no Admin bypass |
| B-03 | Bảo | Six Firebase services and tested error branches | COMPLETE tested scope | B-03.1–6 below; actual native/Console receipts [E13] | Future workflow events outside verified minimum remain mapped, not claimed | Storage DEFERRED; Firestore PDF alternative verified |
| B-04 | **SHARED: F-01 Bao existing; F-02 Bao; F-03 Nguyen** | Three business flows | **F-01 EXISTING VERIFIED CLOUD FLOW; F-02 COMPLETE tested native scope; F-03 HANDOFF / PENDING IMPLEMENTATION** | Scoped F-01 [E13]; [current split/handoff](workstreams/bao-to-nguyen-b04-handoff.md); no full B-04 completion | Bao preserves live-verified F-02; Nguyen owns F-03 on own branch | Exact cloud approvals remain gated; no client-controlled verified payment |
| B-05 | Bảo | Bao evidence/integration handoff | COMPLETE Bao evidence package | All-B audit matrix, source/APK/time/hash receipts, actual redacted Console/native images and Nguyen guide [E13] | B-04 and Nguyen-owned deliverables explicitly remain open; exact final CI in delivery PR | Historical evidence immutable; privacy/link/hash audit |

**Historical B-02 scope before consented demo/Console closeout [E13]:** own Parent positive controls; A→B, B→A, Google→A đều bị deny foreign Parent/application/devices qua native SDK. Đây là **read negatives trên debug-only probe**, không Admin bypass hay live malicious-write test. Sáu catalog records là `[TEST]`/synthetic/unverified: đọc từ server nhưng **chưa đủ catalog thật**, AI loại chúng khỏi recommendations.

## 6. Bảng task Nguyên

Đã kiểm tra PR #1-#9 và source/routes/docs/artifacts trên latest `main`. PR #5 thêm `evidence/artemis/` và `evidence/ui/`; lần kiểm tra PR #5 không thấy review submission/comment trên GitHub. N-04 sau đó đã được owner xác nhận người review duyệt; remediation được merge qua PR #9 (implementation commit `a212e5f94c7998b8ce749be859d41409558e327e`). Các trạng thái bên dưới phản ánh main sau merge ngày 2026-11-03.

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| N-01 | Nguyên | 12 màn Lab 2, Figma/widgets/theme/router | PARTIALLY COMPLETE | All 12 supplied Figma PNGs exist and source audit covers all canonical routes. Existing runtime evidence covers Home/Search/AI and Login/Register at 360/412dp, Tutor Profile/Connection at 412dp, Messages/Profile and signed-in Messages empty state at both widths. Fresh post-merge Home at 360dp is recorded in `runtime-home-post-merge-360dp.png/.xml`; it shows all five tabs and a genuine empty state with zero cards. Home raster/frame parity remains unresolved. | Capture/compare Group Chat, Trial, Class, Payment and Schedule at 360/412dp; add Tutor Profile/Connection at 360dp; resolve Home frame dimensions when design reference is supplied | Five workflow screens need approved/trusted workflow data; final Figma comparison awaits design reference; ADB capture capability should be rechecked |
| N-02 | Nguyên | Responsive 360dp/412dp; loading/empty/error/recovery | PARTIALLY COMPLETE | `flutter test --no-pub` PASS **76/76** including new Chat empty-state coverage at 360/412dp and 1.8 text scale; `flutter analyze --no-pub` reports no issues; Dart format check reports 0 changed. Android 36 runtime Home smoke is captured at 360dp. Existing evidence covers several form keyboard/scroll and empty states. | Capture Android keyboard/safe-area/TalkBack behavior and data/loading/recoverable-error states at both widths using approved fixtures | Trusted workflow fixtures and Android accessibility review remain |
| N-03 | Nguyên | ARTEMIS ≥10 ca ×3 + exploration 15-30 phút | PARTIALLY COMPLETE (matrix NOT VERIFIED) | Test plan lists 27 functions, which is collection/structure only. Historical TC-01 **3 accepted PASS/17 attempts** and TC-09 **2 accepted PASS** are **REPORTED, not independently verified**: second AI re-review did not receive all original logs/JUnit/traces. In a fresh 2026-11-03 attempt, ADB and AVD were started; `emulator-5554` reached `device`, boot completed, BeeWise package/activity were present, and ARTEMIS health/device listing passed. Real TC-01 run 1/3 was **BLOCKED_QUOTA** by Gemini Free Tier HTTP 429 before UI assertions (trace `093516ef-8ae1-4b9a-b8e2-87e71ee4be17`); runner stopped the batch and preserved log/JUnit/manifest/trace at `evidence/artemis/n03-2026-11-03/tc01-priority-rerun/`. No other new cases or exploration were run. ARTEMIS/Android E2E not run during this remediation. See [remediation report](../evidence/external-review/BeeWise_N03_Remediation_Report.md). | Wait for ARTEMIS provider quota recovery under the authorized plan, recheck host/device/app preflight, verify case fixtures; execute ≥10 official eligible cases ×3 with raw logs/JUnit/trace; separately record 15–30 minute exploration. Keep failures/blocked/not-run distinct. | Available ARTEMIS host/quota; stable online AVD; approved staging catalog/account/workflow fixtures |
| N-04 | Nguyên | External AI review ≥5 findings/≥2 nhóm, ≥3 fixes | **COMPLETE** (human reviewer approval confirmed by owner; remediation merged) | Review records F-01..F-06 and N-01..N-03 with accepted fixes and regression checks in [remediation report](../evidence/external-review/BeeWise_N03_Remediation_Report.md). Owner confirmed human reviewer approval in chat on 2026-11-03. Fixes are in commit `a212e5f94c7998b8ce749be859d41409558e327e`, merged to `main` by PR #9. | No implementation work remains for N-04. Keep the owner-confirmed approval and report available; attach written reviewer response only if the instructor requires a durable artifact. | Human approval confirmed by owner; optional written reviewer artifact if required by rubric |
| N-05 | Nguyên | Final report PDF 8-12 trang, slides PDF 12-15 trang | PARTIALLY COMPLETE | Report PDF FINAL 9 trang đã render/kiểm tra; deck FINAL PPTX 13 slide đã qua structural validation (0 lỗi/cảnh báo); slide PDF chưa export được do lỗi thiếu alias font `#standard-fonts/Helvetica` trong Artifact Tool; alias hook cô lập cũng không tương thích metric format (`Invalid standard font data`). Nội dung ghi giới hạn N-01..N-06 theo evidence hiện tại. | Sửa/khắc phục export PDF slide trong runtime được hỗ trợ; kiểm tra trực quan toàn bộ 13 trang; Bảo rà soát cloud claims và links trước nộp | Xuất được slide PDF; review nội dung bởi Bảo |
| N-06 | Nguyên | Demo video 5-10 phút và final links | NOT COMPLETE | [Demo script](demo-script.md); chưa có video final 5-10 phút hoặc link chia sẻ đã kiểm tra trong repo. Không ghi hình thành công dịch vụ/flow đang blocked. | Sau khi chốt fixtures và evidence, quay demo thật 5-10 phút; kiểm tra link bằng hai tài khoản/quyền xem và lưu SHA/giới hạn | App/services/fixtures đủ cho các đoạn demo; evidence freeze |

### N-01/N-02 source audit (2026-11-02)

Source-to-Figma audit: [N1](../evidence/ui/source-audit-20261102.md). It maps all 12 canonical screens and routes, records acceptance checks and source-level observations, and separates checks that need an Android capture from issues that can be confirmed from source. The 12 primary supplied frames plus AI results state are indexed in [Figma evidence](../assets/figma-screens/README.md); 11 primary raster captures are 2x their listed 360px frames, while Home is 804x2400 against a 402x874 inspector frame, so Home pixel parity remains unresolved. No runtime visual parity is claimed.

Responsive/accessibility source review found scrollable form/detail layouts, safe-area handling for chat and tutor-profile footers, wrapped home subject chips, and 14sp body text. Three layout constraints were corrected: navigation height now matches the 72dp handoff, loading placeholders no longer force 178dp height, and chat bubbles derive maximum width from screen width. `responsive_layout_test.dart` covers 72dp navigation and TutorCard at 360/412dp with 1.8 text scale. `OnboardingStepper` follows the supplied four-step consultant flow, uses BeeWise state colors and exposes one progress label to accessibility. `workflow_empty_state_test.dart` covers stepper and Chat/Trial/Class/Payment/Schedule empty states at 360/412dp with 1.8 text scale. Latest verification: `flutter test --no-pub` **76/76 PASS**, `flutter analyze --no-pub` reports no issues, and format check reports 0 changed. Runtime captures/hierarchies cover Home/Search/AI at both widths; Login/Register at both widths; Tutor Profile/Connection at 412dp; Messages/Profile at 412dp; Login/Register keyboard/scroll; Home/Search/AI at font scale 1.3; and signed-in Messages empty state at both widths. A new post-merge Home 360dp screenshot/hierarchy is recorded in the runtime manifest. Five canonical screens (Group Chat, Trial, Class, Payment, Schedule) remain without runtime capture; Tutor Profile/Connection still need 360dp captures; full Figma, loading/data/error/recovery, keyboard and accessibility validation remains outstanding. Trusted workflow data is needed for data-dependent states.

## 7. Ma trận kiểm chứng sáu Firebase services

Mỗi hàng là subtask B-03 riêng. Status xét **đủ receipt v5**, không phủ nhận runtime PASS trong Evidence.

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| B-03.1 Auth | Bảo | Google/Email, restore/cancel/logout, protected/error states, Users Console | COMPLETE tested scope | Actual masked Users Console plus prior valid native Google/email/cancel/restore and fresh managed A/B flows [E13] | No new account creation; historical scope retained | Consented accounts only |
| B-03.2 Firestore PDF alternative | Bảo | Private Firestore PDF, server ack/read, download/hash/preview, errors/isolation, Console | **COMPLETE — FIRESTORE ALTERNATIVE VERIFIED** | TC-PDF01–05: actual native30s/error/retry, missing-auth UI, B-before-old-settle isolation; actual export DebugView subject2/size18; prior upload/immutable proof [E13] | Instrumented raw Auth SDK race scope distinguished from managed logout; no private PDF in Git | Exactly one separately approved extra A report; four old preserved; no new deploy/Storage |
| B-03.3 FCM | Bảo | Permission/inbox, foreground/background/terminated, tap/ownership, Console-send | COMPLETE tested scope | Actual denied permission + Console test background receipt/tap Home; prior guarded three-state Search tap/lifecycle proof [E13] | Console notification is not recipient-scoped deep-link proof; prior proof retained | Generation/journal/quarantine/fail-closed unchanged |
| B-03.4 Analytics | Bảo | ≥7 business events, DebugView, typed non-PII params/identity | COMPLETE verified minimum | Seven historical types/identity preserved, actual artifacts now in Git; fresh export parameters [E13] | Planned/provider/trusted workflow events individually mapped, not all verified | No identity reset/workaround based on stale presentation |
| B-03.5 Crashlytics | Bảo | Real fatal/nonfatal, keys/stack/recovery | COMPLETE scoped Console checks | Hash-matched historical actual screenshots with UID/browser PII masked [E13] | Persisted keys do not establish fatal trigger; no new nonfatal identity/logout claim | No new deliberate crash |
| B-03.6 Remote Config | Bảo | ≥2 parameter effects without rebuild; defaults/cache; Console before/after | COMPLETE tested scope | Prior same-APK binding Home cap + gate; fresh exact-approved Console v3 false/1/2 and empty-v4 restore, app disabled1→enabled3 [E13] | Fresh single eligible record cannot independently bind Home cap; prior valid evidence reused | ETag guarded apply/restore; normal5min cache; no pending restore |

Analytics null clearing đã đủ native FA-SVC removal + complete guest bundles không `_id`, hai guest search tới DebugView. Console có thể giữ property lịch sử; **không tái mở blocker thiếu quyền/UID clearing cũ**, không đổi identity theo stale display. Không có event-level backend export; không suy rộng ngoài scope [E5].

**Firestore riêng:** các collection trước migration giữ strict rules/index [E11]. Report rules và Base64 index exemption đã live; exact-ID demo amendment được duyệt riêng và deploy, không sửa index/non-report rules. Report live Client SDK ownership/immutable/malformed denials PASS; không suy rộng sang mọi collection. Client không tự tạo verified tutor, paid invoice hay official schedule. Catalog/trusted workflow rộng hơn vẫn mở ở B-02/B-04.

## 8. Ba flow và evidence công nghệ

Ba flow dưới đây từ traceability/test plan hiện có; không thay bằng ba demo Firebase rời rạc. Nếu thu hẹp flow thứ ba, team xin mentor xác nhận và cập nhật traceability; không tự gọi payment/schedule thành công.

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| F-01 | Bao existing Firebase integration; Nguyen preserves integration in F-03 | Discovery → parent Auth → connection → chat/text | EXISTING VERIFIED CLOUD FLOW | Genuine native request/chat/text + Client SDK server readback [E13] | Preserve evidence and ownership boundaries | Approved catalog/test identities only |
| F-02 | **BAO** | Guest/Parent → Firebase AI Logic/Gemini → validated result → detail/manual fallback | **COMPLETE — LIVE VERIFIED, API35 guest/debug scope** | [Latest packet](../evidence/cloud/f02-lite-native-20261104/README.md): actual3.5 response, valid demo ID, result/detail/fallback and FA-SVC ai_match_success count1;105 Flutter/58 Rules PASS | Preserve scoped acceptance; owner review of accidental excess call; final delivery-HEAD CI in PR | Parent-specific/release/physical AI outside run; no further live calls authorized; no overall B-04 completion |
| F-03 | **NGUYEN**; Bao Firebase/security support | Consultant → trial/revision → invoice/payOS → verified payment → official schedule | **IMPLEMENTED — EMULATOR VERIFIED; LIVE payOS VERIFIED ONCE; NOT DEPLOYED** | [`backend/`](../backend/README.md): 45 emulator tests, 59 Rules, 130 Flutter; [live 2,000 VND payment](../evidence/cloud/f03-payos-live-20261105/README.md): payOS PAID → signed webhook → provider re-check → invoice verified → official class, real Firebase, API36 emulator | Deploy backend (e.g. Render) for a stable webhook URL; owner captures payOS dashboard transaction (masked) for the report | Stable HTTPS host; keep secrets server-side |

Mỗi flow/service cần **source SHA, APK hash/entrypoint, device/OS/viewport, thời gian/lệnh, expected/observed, screenshot/video/log/trace, failure/recovery, Console/data link khi cần**. Không ghi PASS từ `SUCCESS`, mock, toast, API acceptance hay JUnit collection đơn lẻ. Không đưa credentials/PII vào model/trace. PDF local và `export_report` **không chứng minh cloud persistence**.

## 9. Blockers và quyết định còn mở

1. **Firestore PDF alternative:** core native roundtrip/live A-B/Console/upload DebugView đã có bằng chứng; còn deadline/retry native và durable export DebugView receipt. Owner đã duyệt exact rules diff và một demo tutor, không còn blocker thiếu tutor/approval. Không yêu cầu Blaze/bucket hay deploy Storage.
2. **Catalog/ba flow:** chưa có catalog thật được phép; synthetic records không đủ. Chốt scope Lab 2/trusted staging khi cần; không nới rules demo payment/schedule.
3. **QA:** ARTEMIS host, Gemini credential and Android 36 emulator đã hoạt động cho smoke runs; xem kết quả và giới hạn mới nhất ở N-03/test plan. Ma trận ≥10 ca ×3 và exploration 15-30 phút vẫn chưa đủ evidence. Các ca cần catalog/staging phải có fixtures riêng được duyệt. N-04 đã được owner xác nhận reviewer duyệt và remediation đã merge qua PR #9; không suy diễn trạng thái N-03 từ kết quả review.
4. **Gói Bao đã có [E13]:** Users Console, FCM Console-send/denied permission, RC parameter before/after/restore và bản chia sẻ đã che PII. DRAFT/PPTX không thay final PDFs/video.
5. **Android:** immediate-boot API37 và physical/release/API35-36 chưa kiểm tra toàn diện. Giới hạn sau scoped startup PASS, không giữ PR #3 đã merge chờ sửa vô hạn.

## 10. Thứ tự tiếp theo P0/P1/P2

| ID | Owner | Requirement | Status | Evidence | Next action | Dependency |
|---|---|---|---|---|---|---|
| P0-1 | Bảo | Firestore PDF live verification | COMPLETE | B-03.2 [E13] | Native timeout/retry/guest/switch and fresh export Console closed | Keep actual receipts/approved data |
| P0-2 | Bao F-02; Nguyen F-03 | Shared B-04; Bao evidence scope separate | F-02 LIVE VERIFIED; F-03 HANDOFF / PENDING IMPLEMENTATION | [Split/handoff](workstreams/bao-to-nguyen-b04-handoff.md), existing [E13] | Bao preserves AI/native evidence; Nguyen owns consultant/payOS/backend E2E | Exact cloud/deployment/payment approvals; no full B-04 COMPLETE claim |
| P0-3 | Nguyên | ARTEMIS/Pro execution | BLOCKED / PARTIALLY COMPLETE | N-03, [E8] | Xác nhận host/key/device; chạy ≥10 ca ×3 và exploration 15-30 phút, lưu receipts và phân loại kết quả trung thực | Host/credential quota, device, catalog/staging fixtures được duyệt |
| P1-1 | Bảo | Firebase Console packet | COMPLETE tested scope | B-03.1–6 [E13] | Actual Users/FCM/RC/PDF panes available, prior Crashlytics/identity retained | No new deployment needed |
| P1-2 | Nguyên; Bảo review cloud | UI/responsive, final PDFs/video/links | PARTIALLY COMPLETE | N-01/N-02/N-05/N-06, [E10] | Audit UI, integration freeze và đóng gói bản nộp thật | P0-2/P0-3, Firestore PDF live |
| P2-1 | Bảo + Nguyên | Mở rộng validation/product nếu scope cần | NEEDS VERIFICATION | B-01/B-04, [E2] [E12] | Physical/release/API35-36 khi có; pagination >100, quota/inbox/backend projection khi cần; không để full payment/backend lấn mandatory Firebase/ARTEMIS/demo | Device hoặc product contract được duyệt |

## 11. Git handoff (2026-11-03)

PR #5 (`a3e0252`) containing earlier N-01/N-02 and partial N-03 work was merged into `main` at `5df96fd`. This follow-up is on `codex/beewise-lab3-nguyen-followup`; UI captures, widget-test fix, ARTEMIS parser/runner improvements, follow-up evidence, refreshed report PDF and validated review PPTX are local changes and have not been committed or pushed. Slide PDF export remains incomplete due the bundled Artifact Tool font-alias error and incompatible packaged metric data. Review `git status` and `git diff --check` before handoff. N-03 remains PARTIALLY COMPLETE until its matrix and Pro exploration are verified.

For the next implementation change, start a new branch from the updated `main`:

```powershell
git status --short
git diff --check
git switch main
git pull --ff-only origin main
git switch -c codex/<next-task>
```

Do not stage local secrets, `.env`, generated build output, or temporary ARTEMIS configuration. Commit and push task changes on the new branch, then open a PR into `main`.
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
- [x] Report PDF 8-12 trang: FINAL 9 pages, rendered and visually inspected.
- [ ] Slides PDF 12-15 trang: 13-slide PPTX validated, but required PDF export is still blocked; video 5-10 phút and verified final links are also outstanding. Bảo must review cloud claims and two viewers must check link permissions.
- [ ] Repo/design/architecture/analytics/test docs/evidence index khớp final SHA; không dùng DRAFT/PPTX thay final PDF. Không tự merge PR docs này.
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
| [E7] | [RC roundtrip](../evidence/cloud/remote-config-roundtrip.json), [native behavior](../evidence/firebase/remote-config/README.md), [new Console/app packet](../evidence/cloud/bao-acceptance-20261103/README.md) | Historical same-APK binding cap plus current exact-approved Console apply/restore; cache/defaults preserved. |
| [E8] | [Test plan](test-plan.md), [harness](../e2e_test/), [blocked preflight](../evidence/corrective/artemis-latest-blocked.json) | Authored/collect/preflight; chưa committed execution traces/JUnit. Hỏi Nguyên về evidence ngoài repo. |
| [E9] | [Review record](code-review.md), [PR #2 lifecycle review](pr2-lifecycle-review.md) | Internal Codex findings/fix commits có; external transcript/approval NOT VERIFIED. |
| [E10] | [Report source](lab3-report.md), [FINAL report PDF](../output/pdf/BeeWise-Lab3-Implementation-Report-FINAL.pdf), [FINAL 13-slide PPTX](../output/presentations/BeeWise-Lab3-Review-FINAL.pptx), [historical draft PDF](../output/pdf/BeeWise-Lab3-Implementation-Report-DRAFT.pdf), [historical draft PPTX](../output/presentations/BeeWise-Lab3-Review-DRAFT.pptx), [demo plan](demo-script.md) | Report PDF final has 9 rendered pages. PPTX passes structural/layout checks; mandatory slide PDF export remains unavailable in current Artifact Tool runtime. Neither final artifact closes N-05 until the slide PDF is produced/reviewed and Bảo signs off claims/links. |
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

[E13]: ../evidence/cloud/bao-acceptance-20261103/README.md "Current Bao native and Console acceptance packet"
