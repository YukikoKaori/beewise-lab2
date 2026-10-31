# BeeWise Lab 3 — Phân công song song: Bảo & Nguyên

> **Mục đích:** Hoàn thành PRM393 Lab 3 theo đề ngày 21/10/2026; làm song song tối đa, **không đụng file, không chờ người kia để bắt đầu**, giữ các sửa bảo mật từ PR #2 đã merge.
> **Repo:** https://github.com/YukikoKaori/beewise-lab2  
> **PR #2 đã merge:** https://github.com/YukikoKaori/beewise-lab2/pull/2
> **Trạng thái kiểm tra lại 30/10/2026:** `origin/main` = `12f5322655463fd801d64e4925572d6a3a2bbb82`, merge PR #2. Hai người tạo branch độc lập từ latest main; không tiếp tục branch PR #2.
> **Firebase:** `beewise-lab-3` / Android `com.beewise.beewise`. Bảo xác nhận có quyền Console; Computer Use hiện đã điều khiển được Chrome đã đăng nhập và xác minh Console đúng project; xem cập nhật Bảo bên dưới. Project `beewise-8ba7c` không thuộc ứng dụng này và không được sử dụng.
> **Nguồn yêu cầu:** `PRM393 - Lab 3 Cloud-Enabled Mobile App (Firebase, Patrol, AI Code Review).pdf` (18 trang); Figma Lab 2, `handoff/flutter-handoff.md`, `docs/design-traceability.md`.

## 0. Quy tắc bất di bất dịch

1. **PR #2 đã merge theo yêu cầu chủ repo.** Giữ các sửa bảo mật; Nguyên và Bảo mỗi người một feature branch/working copy từ latest main, PR riêng target main.
2. **Không thay đổi file do người kia sở hữu.** Nếu cần interface mới: ghi yêu cầu vào `docs/workstreams/<ten>-handoff.md`, giữ phần của mình chạy được với interface hiện tại, chưa sửa hộ.
3. **Không dùng chung Firebase test account, dữ liệu cá nhân hay thư mục evidence.** Có thể cùng một Firebase test project nếu cả hai đã có quyền, nhưng dùng test UID, document ID, namespace, Android emulator riêng; tránh đổi Remote Config/rules khi người kia đang ghi evidence.
4. **Không dựng mock/hard-code hồ sơ gia sư trong submitted build.** Test fixtures chỉ dùng môi trường test và phải ghi nhãn. Không tự nâng Blaze, bật billing, chấp thuận terms, deploy rules production, tạo tài khoản thật, hay công bố dữ liệu cá nhân nếu chưa được chủ project cho phép.
5. Evidence **phải là kết quả chạy thật** (SHA, thời gian, lệnh, device, screenshot/video/console/trace/JUnit). Không ghi PASS cho test mới collect, unit test không thay thế runtime, CI build APK không thay thế việc mở app trên Android.
6. **Một điểm giao bắt buộc ở cuối:** chạy chung luồng end-to-end và đưa evidence vào report/slides/video. Không thể cam kết *zero dependency* ở bước nộp cuối vì rubric đòi chứng minh cả app hoạt động; nhưng tất cả task phát triển trước bước này được tách file và owner riêng.

## 1. Chia ownership và ranh giới file

| Nhóm | **Bảo (qb) — Cloud + Android/runtime** | **Nguyên — UX + E2E + AI review** |
|---|---|---|
| Phần việc chính | 6 Firebase services, dữ liệu Firestore, quy trình tin cậy, chạy APK/thiết bị, console evidence | 12 màn/Figma + responsive, widget/accessibility, ARTEMIS, AI review, trình bày kết quả |
| Được sửa | `firebase/**`, `android/**`, `lib/services/**`, `lib/viewmodels/**`, `lib/models/**`, `lib/main.dart`, `pubspec.yaml`/lock, `docs/analytics-plan.md`, `docs/backend-contract.md` | `lib/screens/**`, `lib/widgets/**`, `lib/theme/**`, `lib/app/bee_wise_app.dart`, `e2e_test/**`, `docs/design-traceability.md`, `docs/test-plan.md`, `docs/code-review.md` |
| Evidence riêng | `evidence/firebase/**`, `evidence/android/**`, `evidence/cloud/**` | `evidence/ui/**`, `evidence/artemis/**`, `evidence/ai-review/**` |
| Notes riêng | `docs/workstreams/bao-*.md` | `docs/workstreams/nguyen-*.md` |
| Không đụng | UI screen/theme/widgets, ARTEMIS scripts và AI-review docs | Firebase rules/config, auth/messaging/storage services, viewmodels, android config, package files |
| Chung — **để cuối** | `README.md`, `docs/architecture.md`, `docs/lab3-report.md`, `report/**`, `slides/**`, `output/**`, demo video/link | **Không edit song song.** Nguyên chịu trách nhiệm bản final report/slides/video sau khi nhận bản evidence manifest đã đóng băng từ Bảo; Bảo review tính đúng của các khẳng định cloud. |

**Sau PR #2:** mỗi người fetch latest main và chỉ sửa file mình sở hữu. Không còn phải chờ PR #2; giữ nguyên notification ownership/route validation và các rules đã sửa. Không chỉnh tài liệu final chung trong lượt Bảo.

## 2. BẢO — Task độc lập (Cloud + Android)

## Reliability corrective validation — 2026-10-31 (latest)

Application source: `be2b44515af637db1c7ded6b94797d1cf4adc746`.
This update supersedes the historical status entries below. Final delivery HEAD
and its CI are recorded in PR #3 description; no merge or new PR.

- **B-01 PARTIALLY COMPLETE:** same-signer default APK build/install PASS without
  data clearing. Native A first-login PASS on default entrypoint; B/Google PASS on
  explicit debug diagnostic entrypoint using the same production services/UI.
  A session restore, actual A/B foreground FCM receipt/tap and managed logout PASS.
  Role failure stays on account-check; restored network plus explicit retry returns
  Home. Final default APK reinstall hit a genuine input ANR/slow startup; subsequent
  relaunch renders Home. Failure evidence retained; clean cold-start is not PASS.
- **B-02 scoped checks COMPLETE:** actual native authenticated A→B, B→A, Google→A
  each allow own server Parent read and deny foreign Parent/application/devices
  reads: **9/9 permission-denied**, no Admin bypass. Live malicious writes NOT RUN.
  Existing strict rules/index and approved SHA configuration preserved; no deploy.
  Six labeled synthetic tutors preserved; no new tutor/request/payment records.
- **B-03 PARTIALLY COMPLETE:** FCM race reproduced and fixed with generation guards
  and acknowledgement deadline; first-login A/B/Google succeed without retry or
  restart. Exactly one owner-authorized test signup and Parent confirmed. Analytics
  **7 distinct business events** have real DebugView receipts, adding `sign_up`
  (`method=password`, `account_type=parent`) and guest `export_report`
  (`subject_count=1`, `file_size_kb=16`). Google `login(method=google)` verified.
  UID-clear acceptance remains **NOT VERIFIED**: later guest event's DebugView
  properties still show prior dedicated UID. No successful clear claim.
  Local PDF is real (16,419 bytes); Storage upload stays **DEFERRED**. Prior real
  Crashlytics and RC receipts retained; not rerun or substituted with unit tests.
- **B-04 PARTIALLY COMPLETE:** transient role reads use bounded server reads and
  fail closed; unit/native retry PASS. Trusted payments/official schedules still
  require backend/provider and are **BLOCKED**, with no client privilege changes.
- **B-05 PARTIALLY COMPLETE:** formatter/analyzer PASS; Flutter **64/64**; Firebase
  Emulator rules **28/28**; APK build PASS; application HEAD CI **3/3 PASS**.
  Final evidence HEAD checks must match newest PR SHA. Actual client negative
  probe and aliased logs are reviewable; originals private on D. ARTEMIS/external
  review/physical hardware **NOT RUN**; staging/App Check out of scope. No Nguyen
  UI/router/theme/review/presentation edits. **NOT MERGE READY** overall.

Primary current manifest: `evidence/cloud/reliability-validation.json`.
Root cause, implementation and regressions: `docs/workstreams/bao-reliability.md`.

## Google live verification follow-up — 2026-10-31 (historical)

**B-01/B-03 PARTIALLY COMPLETE:** actual dedicated Google sign-in, parent
creation, signed-in Profile, process-death session restore, managed logout and
guest cold relaunch **PASS** on isolated `emulator-5558`, current same-signer
APK. Provider `google.com`, sign-in 08:17:19.108Z and parent creation
08:17:21.874249Z corroborate actual UI; Users metadata alone is not Auth proof.
Google installation appeared only under its owner after relaunch; managed logout
removed it while A/B registrations stayed empty and all parent records survived.
Initial automatic Google registration remained pending until relaunch: **OPEN**
reliability finding, consistent with earlier B retry. A transient role read after
the diagnostic crash failed closed; explicit retry restored Home/Profile.

**B-02:** exact approved SHA registration and additive Android OAuth config
verified; strict rules/index remain as previously authorized and deployed. No new
rules, provider, Storage, App Check or billing changes. Authenticated cross-UID
malicious client denial remains **NOT RUN**; IAM snapshots do not establish it.

**B-04:** new deliberate fatal received in actual Firebase Console at displayed
3:21:38 PM, Android 17 / version 0.1.0(1). Crashlytics Data > User ID hashes to
the dedicated Google UID alias; custom keys inspected. Broad browser metadata
ID matches were rejected; only the visible User ID leaf was compared. Fatal
persisted keys describe the prior nonfatal diagnostic, not its trigger. Google
Analytics method and logout UID-clear are **NOT VERIFIED**. Previously verified
five business Analytics event types remain five of seven; SDK events do not
close the gap. Native first-request spinner and stale callback failure retained;
fresh user-operated Google retry succeeded without credentials being collected.

**B-05:** formatter/analyzer PASS, Flutter **59/59**, Firebase Emulator rules
**28/28**, APK build/install PASS; application/config and prior evidence HEAD CI
3/3 PASS. Final evidence HEAD CI is checked after push. Original authenticated
screenshots are private on D; sanitized XML, metadata, screenshot hashes and
guest/error images are reviewable. Emulator debug/display/network settings restored.
No Nguyen UI/theme/router/ARTEMIS/review/final-presentation edits. Storage remains
**DEFERRED** for team discussion. App Check, trusted backend/payment/official
schedules, staging, physical device, ARTEMIS and external review remain
**BLOCKED/NOT RUN** as applicable. Overall **PARTIALLY COMPLETE**.

Primary receipt: `evidence/cloud/google-runtime-validation.json`; account
snapshots `evidence/cloud/google-user-*.json`; runtime `evidence/android/logs/google-*`.




## Computer Use Console follow-up — 2026-10-31 (historical)

**PARTIALLY COMPLETE.** Computer Use now controls the existing authenticated
Chrome Firebase tab. Actual Console evidence from `beewise-lab-3` supersedes the
previous browser-unavailable and no-receipt statements below.

- **B-01:** Existing same-key APK on isolated `emulator-5558` relaunched; actual
  guest TEST search, labeled synthetic tutor detail and AI empty result captured.
  Detail retest now PASS. System UI ANR recurred on boot; retained, not fixed.
  Original display/network/Analytics debug settings restored after testing.
- **B-02:** Existing approved strict rules/Auth evidence preserved. Exact installed
  APK certificate hashes and guarded commands prepared in
  `docs/workstreams/bao-google-sha-plan.md`; owner SHA permission and a dedicated
  Google account remain pending. No Google login claim or shared OAuth mutation.
  Authenticated cross-UID Firestore client denial remains NOT RUN.
- **B-03:** DebugView shows five distinct business event types: `login` with
  `method=password`, `logout`, `search`, `view_tutor` with
  `entry_source=profile_route`, and `ai_match_no_results`. Three additional SDK
  types (`screen_view`, `notification_foreground`, `notification_receive`) do not
  complete the seven-business-event requirement. Crashlytics actually contains
  the deliberate fatal test and real matching-disabled handled failure; inspected
  keys include `app_area=beewise_mobile` and matching error reason/exception.
  Signed-in Crashlytics user association remains NOT RUN. Historical Profile
  crash and binder ANR retained. RC Console shows empty configuration landing,
  consistent with prior API restore; version number is not visible. **Storage is
  explicitly DEFERRED by user for team discussion; no bucket/billing action.**
- **B-04:** Existing 59 Flutter/28 emulator rules and secure server-trusted payment
  and official schedule gates preserved. No app/rules code change this turn;
  no paid AI invocation or backend/staging completion claimed.
- **B-05:** New actual receipts and sanitized Android logs indexed in
  `evidence/cloud/console-runtime-validation.json`. Unmodified Console screenshots
  stay private on D with public SHA-256 receipts because browser/account chrome
  contains identifying information. Nguyen UI/theme/router/ARTEMIS/review/final
  presentation untouched. ARTEMIS/external review/physical hardware NOT RUN.

Public native proof: `evidence/android/screenshots/console-search-submitted.png`,
`console-tutor-detail.png`, `console-ai-no-results.png`. Failed first taps and
System UI ANR are classified separately in the manifest. No uninstall/data clear.
Final pushed HEAD/CI are reported in the handoff; earlier checks remain historical.


## Approved deployment and actual Android follow-up — 2026-10-31

**PARTIALLY COMPLETE.** Owner approved the exact frozen strict Firestore bundle.
28/28 emulator tests rerun PASS before deploy. Additive chats index reached READY
before rules release; both deploy commands exited 0. Active ruleset
`2aff57c1-3693-4bfa-9cd2-d77471ef08d6` matches repository normalized SHA-256
`759a35e408204bff48dac1f380009b76a661b39c4f649d809322643c616f6578`.
Missing own `tutorApplications/{uid}` lookup is now present. No Storage/provider/
billing change, weak rollback, record deletion or rules weakening was performed.

Actual Email/Password account A login after release created its parent profile;
force-stop/relaunch restored the SDK session. This exposed a real blank-name
Profile crash. Owner authorized exactly the fallback exception: six regressions
PASS (three failed before correction), full Flutter 59/59, format/analyzer and
debug APK build PASS. Same-signer install `-r` preserved A's data. Source APK
`9657d1b2f0c57a425298aab58fefbccb7119ac47`, SHA-256
`c963e08a7684c54bbc0893524a9a6e9168a38350b9fdfe08ff9475eeb4ef2701`.
Fixed restored Profile and managed logout PASS; A's own device registration was
removed and guest inbox emptied. B login/profile/session restore/logout PASS;
A inbox is absent under B, A profile unchanged, same installation belongs only
to B after explicit retry, and both registrations are absent after B logout.
Initial B automatic registration remained pending; manual retry recovered it.
This is a retained reliability finding, not an automatic-registration PASS.
B received its exact foreground probe; new-APK 360dp/412dp and guest offline
cache/reconnected Search were captured. Original device settings restored.

Real FCM API sends plus exact probe IDs on device establish foreground receipt,
background notification/tap and verified process-death notification/cold-start
Search routing. Malformed URL and inaccessible chat taps keep Profile visible.
An earlier terminated attempt retained its PID and is explicitly NOT counted.
API acceptance alone is never treated as delivery. Original authenticated PNGs
remain private on D; sanitized XML/logs and non-identifying screenshots are public.

Google provider became enabled externally and owner-supplied web OAuth config
was preserved separately; Android SHA registration/Google runtime remain BLOCKED.
No Storage bucket/release; billing disabled. Analytics DebugView/Crashlytics
Console receipts, staging, trusted payment/staff backend, ARTEMIS and external
review remain NOT RUN/BLOCKED. Previous live Remote Config publish/restore remains
valid; all six labeled synthetic tutor records remain preserved and unverified.

Receipts: `evidence/cloud/authorized-deploy-*.json`, `firestore-release-state.json`,
`test-users-*.json`, `fcm-*.json`, `checks/authorized-profile-final/`, and
`evidence/android/logs/auth-*`. Four real unauthenticated private reads were
denied; those and IAM snapshots are not authenticated cross-UID client tests.


**Snapshot 30/10 trước deployment (lịch sử):**
**Cập nhật Bảo 30/10/2026:** audit trước sửa tại `docs/workstreams/bao-initial-audit.md`; trạng thái thực thi và blocker tại `docs/workstreams/bao-status.md`. Đã sửa BAO-A01/A02/A03 trong ba commit riêng; 45 Flutter tests và 27 Firestore/Storage emulator tests PASS. Không đánh dấu hoàn thành các checklist live dưới đây chỉ bằng unit test. Chưa có dedicated test account: các ca cần đăng nhập giữ BLOCKED theo xác nhận của Bảo. Fixture có nhãn và Remote Config tạm đổi/có hoàn nguyên được phép, đã tạo 6 fixture Firestore có nhãn `[TEST]`, verified=false; Remote Config chưa đổi vì runtime mới đang BLOCKED bởi signing key. Live API xác nhận Google provider/SHA chưa cấu hình, chưa có Storage bucket/billing, rules đang deploy khác repo và thiếu chat index; chưa deploy thay đổi nào.

### B-01 [P0] Android runtime, APK, thiết bị và minh chứng

**2026-10-31 — PARTIALLY COMPLETE:** APK source `9657d1b`, same-signer install giữ dữ liệu PASS. A login/profile/session restore/logout đã chạy thật; crash Profile blank-name được owner cho ngoại lệ sửa đúng fallback, 6 regression PASS. Guest navigation/offline recovery 360dp/412dp có evidence trước đó; B login/profile/restore/logout, inbox isolation và viewport 360dp/412dp trên APK mới đã chạy thật; B registration ban đầu pending, retry mới PASS. Boot SystemUI ANR giữ nguyên là finding.

- [x] Toolchain/debug APK PASS từ app source `9ef5907`; cài và mở APK mới trên AVD riêng `emulator-5558` ở D. Không gỡ/xóa dữ liệu package cũ; native PNG/log tại `evidence/android/`.
- [ ] Test emulator/device tại **360dp và 412dp**; logcat, thao tác điều hướng, login/logout, lỗi mạng; ghi lại crash, overflow, thao tác không phản hồi.
- [ ] Chụp screenshot thật cho các luồng có dữ liệu và các trạng thái loading/empty/error; không chỉnh giả screenshot.
- [ ] Lưu `evidence/android/README.md` + device spec, version, SHA, APK hash, screenshots và lệnh chạy.
- [ ] Lỗi **UI thuần** ghi `docs/workstreams/bao-ui-handoff.md` để Nguyên sửa, không tự sửa `lib/screens/**`.

**Done khi:** APK chạy trên thiết bị, có runtime evidence và danh sách lỗi/retest; hoặc blocker cụ thể kèm log chính xác nếu không có thiết bị.

### B-02 [P0] Firebase Auth + Firestore + nguồn dữ liệu thật

**2026-10-31 — PARTIALLY COMPLETE:** Owner cho phép đúng strict bundle; 28/28 Emulator PASS trước deploy, index READY trước rules, live hash khớp repo. A đăng nhập sau release và tạo parent profile thật; logout gỡ own device. B login/profile/restore/logout PASS; inbox A không lộ ở B, ownership chỉ ở B sau retry; authenticated cross-UID client denial vẫn NOT RUN. Bốn guest private-read denials chạy thật, không thay cho authenticated cross-UID test. Google provider enabled bên ngoài; SHA/Google runtime BLOCKED. Sáu TEST tutor giữ nguyên, unverified.

- [ ] Dùng project do chủ repo sở hữu, kiểm tra project ID khớp `google-services.json`; chuẩn bị **tài khoản test** độc lập, không đưa mật khẩu vào repo.
- [ ] Cấu hình Google Sign-In Android (OAuth/SHA/support email) nếu có quyền; kiểm thử sign-in, cancel, sign-out, session restore và profile recovery.
- [ ] Tạo dữ liệu gia sư **được phép sử dụng và có nguồn gốc rõ ràng** trong Firestore để demo tìm kiếm, chi tiết và request; không công khai dữ liệu mock của Figma như dữ liệu gia sư đã xác minh.
- [ ] Test quyền truy cập dữ liệu giữa 2 UID và role applicant/parent; kiểm tra rules hiện hành trên project test so với file repo. Chỉ deploy khi được phép.
- [ ] Lưu Firebase Auth Users screenshot, Firestore/rules evidence đã che thông tin nhạy cảm, log thao tác và test UID dạng ẩn danh.

**Done khi:** Auth và dữ liệu live hoạt động, có ảnh/log xác minh; tính năng nào bị OAuth/quyền truy cập chặn phải ghi BLOCKED, không được gọi PASS.

### B-03 [P0] 6 dịch vụ Firebase — chứng minh bằng Console + app

**2026-10-31 — PARTIALLY COMPLETE:** A Email/Password/profile/restore/logout và FCM foreground/background/process-death delivery + tap Search đã xác minh trên thiết bị, route malformed/inaccessible chat bị chặn. RC publish/restore đã chạy thật. Storage bucket không có, billing tắt; Analytics DebugView/Crashlytics Console/Google runtime NOT RUN/BLOCKED. B inbox/registration isolation quan sát thật PASS sau retry; B automatic registration pending được ghi là reliability finding.

- [ ] **Authentication:** đủ signed-in/signed-out, Google native account picker/cancel, sign-out xóa session riêng tư.
- [ ] **Cloud Storage:** tạo PDF từ tutor đang hiển thị; upload `reports/{uid}/...pdf`, progress, download URL, rules cross-user deny, console file list. Nếu Spark không có bucket thì ghi blocker và đề nghị giảng viên giải pháp được duyệt; **không tự nâng Blaze**.
- [ ] **FCM:** test foreground/background/terminated, Android 13+ permission, in-app list, tap đúng route; test account switch không lộ notification/push.
- [ ] **Analytics:** tối thiểu 7 events theo `docs/analytics-plan.md`, mỗi event có DebugView evidence; không gửi PII/free text.
- [ ] **Crashlytics:** một non-fatal của luồng lỗi thực + một deliberate crash trên test device, có user ID và custom key trên Console.
- [ ] **Remote Config:** tối thiểu 2 giá trị thay đổi **hành vi hiển thị** không cần rebuild, có trước/sau + giá trị trên Console.
- [ ] Mỗi dịch vụ có ảnh trạng thái lỗi/permission/network/cancel nếu liên quan; evidence theo `evidence/firebase/<service>/` và index `evidence/firebase/manifest.md`.

**Done khi:** mỗi yêu cầu có mã nguồn + thao tác thật + minh chứng. Không có điều kiện live thì để NOT RUN/BLOCKED minh bạch.

### B-04 [P1] Luồng tư vấn / học thử / thanh toán / lịch — đúng scope Lab 2

**2026-10-31 — PARTIALLY COMPLETE:** Frozen rules 28/28 PASS trước deploy; full Flutter 59/59, formatter/analyzer/APK PASS. Không dùng unit/emulator để khẳng định live Auth. Payment verification và official schedule giữ server-trusted; trusted backend/staff/provider/staging vẫn BLOCKED.

- [x] Đối chiếu 3 flow Figma/Handoff: search/AI → connect → consultant chat → trial → class revision → invoice → payment verified → official schedule; bảng transition tại `docs/workstreams/bao-workflow-status.md`.
- [x] Xác minh phần client/rules và phần cần server tin cậy; unit/emulator PASS, backend/staging chưa triển khai, live business flow BLOCKED.
- [ ] Nếu được phép và Firebase plan hỗ trợ, triển khai **tối thiểu** phần trusted workflow bằng Cloud Functions/Admin SDK hoặc backend test riêng; không phải dựng VPS riêng nếu không cần. Có transaction, authorization, dedupe, không cho client tự đánh dấu `paid`/`verified`.
- [ ] Nếu Cloud Functions/billing/quyền thiếu: hoàn thiện contract, negative tests + demo rõ trạng thái chờ; báo giảng viên xin cách chứng minh 3 flow end-to-end hợp lệ. **Không coi flow chưa chạy end-to-end là đạt yêu cầu.**
- [x] Viết `docs/workstreams/bao-workflow-status.md` nêu từng transition, test outcome và blocker.

**Done khi:** phân định rõ các trạng thái đã thực thi, staging/emulator evidence và những chỗ cần xác nhận với giảng viên.

### B-05 [P1] Bàn giao evidence có thể tái sử dụng

**2026-10-31 — PARTIALLY COMPLETE:** Bổ sung receipts deployment có quyền owner, profile regression, APK/hash/install, A Auth lifecycle và FCM thật. Manifest/status phân biệt attempt lỗi với proof hợp lệ. Final SHA/CI ghi tại handoff khi push. Chỉ sửa UI fallback được owner cấp ngoại lệ; không sửa theme/router/ARTEMIS/review/final presentation.

- [x] Viết `docs/workstreams/bao-status.md`: Task ID, PASS/FAIL/NOT RUN/BLOCKED, SHA, tài nguyên test, bằng chứng URL/path, lỗi, bước chạy lại.
- [x] Không sửa report/slides chung; cung cấp `evidence/firebase/manifest.md` và `evidence/android/README.md` để Nguyên dùng, giữ các ca live chưa chạy BLOCKED.

## 3. NGUYÊN — Task độc lập (UX + ARTEMIS + Review)

### N-01 [P0] Figma fidelity và 12 màn hình Lab 2

- [ ] Audit 12 màn `01 Home` → `12 Official Schedule`, so với `handoff/flutter-handoff.md`/Figma Final UI; check cả 3 flow, path thay thế, loading/empty/error/retry.
- [ ] Chỉnh **chỉ** `lib/screens/**`, `lib/widgets/**`, `lib/theme/**` và router `lib/app/bee_wise_app.dart` nếu cần; giữ nguyên service/controller APIs hiện tại.
- [ ] Dùng tokens/theme/reusable widgets; body ≥14sp, tap target ≥48dp, text scale, Vietnamese wrapping, safe area, keyboard, TalkBack semantics.
- [ ] Widget/golden/layout tests độc lập với Firebase bằng fake providers, không ghi mock vào bản build nộp. Xác minh 360dp/412dp; chụp ảnh test UI hoặc runtime riêng `evidence/ui/`.
- [ ] Ghi mọi khác biệt Figma ↔ Flutter cùng lý do vào `docs/design-traceability.md`; nếu thay thiết kế thì đồng bộ Figma khi có quyền. Không tự đổi business states/payment gates.
- [ ] Nếu thấy bug ở `lib/services`/`lib/viewmodels`, ghi `docs/workstreams/nguyen-cloud-handoff.md`, không edit hộ Bảo.

**Done khi:** mapping 12/12 màn, 3 flow, variants/states/semantics, test/UI evidence đầy đủ hoặc có explicit gaps.

### N-02 [P0] ARTEMIS test plan + harness + test execution

- [ ] Review tối thiểu 10 cases theo rubric; repo có kế hoạch TC-01..TC-26. Test coverage phải gồm từng flow Lab 2, alternative/error, Google/native/FCM, từng tab, detail, export/upload, Remote Config, sign-out.
- [ ] Hoàn thiện các test độc lập trong `e2e_test/**`: assert các giá trị quan sát được, trace IDs, isolation, self-contained preconditions; không chỉ assert `SUCCESS`.
- [ ] Pin phiên bản ARTEMIS, config bằng environment variables; không commit model API key/test password.
- [ ] Dùng **emulator/device và test account riêng**; chạy ≥3 lượt **mỗi regression test** khi Firebase/thiết bị đã sẵn sàng; riêng Pro exploratory 15–30 phút; lưu trace/replay/screenshot/JUnit/result table/pass-rate/time/flaky analysis.
- [ ] Có ít nhất 1 E2E check analytics event qua Logcat/DebugView. Các case FCM thủ công phải có push thật và log riêng từng lượt.
- [ ] Nếu test cần consultant/invoice/backend mà hiện chưa có, ghi BLOCKED **chỉ các case đó**, vẫn chạy các case độc lập; không sửa backend và không tự gắn PASS.
- [ ] `docs/test-plan.md` + `evidence/artemis/manifest.md` là phần Nguyên sở hữu. **PR #2 đã merge; tiếp tục trên branch riêng từ latest main**, giữ ownership runner/conftest của Nguyên.

**Done khi:** số lượt, traces và manifest đối chiếu được; report tách test collect vs test chạy thực tế rõ ràng.

### N-03 [P0] AI Code Review theo đề — findings có nguồn gốc

- [ ] Chạy ít nhất **1 AI review tool trên PR**, lưu raw output/transcript/URL, tool và thời điểm (Codex nếu được giảng viên chấp nhận; đề nêu Copilot/CodeRabbit/SonarCloud/Kodus làm ví dụ).
- [ ] Tối thiểu **5 findings** gắn `file:line`, thuộc ≥2 loại (bug/security/architecture/performance/test gap/maintainability).
- [ ] Mỗi finding: Accept/Modify/Reject, lý do có căn cứ từ rubric hoặc impact; tối thiểu **3 accepted findings được sửa trong 3 commit riêng** có finding ID. Chỉ sửa findings thuộc file Nguyên sở hữu; findings Cloud đưa vào handoff để Bảo sửa (nếu chọn để tính 3 fix, ghi commit thực tế của Bảo, không nhận vơ).
- [ ] Update `docs/code-review.md`, lưu `evidence/ai-review/` và công bố tất cả AI tools đã sử dụng. Không bịa external review.

**Done khi:** 5 findings, quyết định và 3 commit minh chứng riêng đáp ứng trang 10, 15 của đề.

### N-04 [P1] Chuẩn bị report/slides/demo — chỉ **khung và script** lúc làm song song

- [ ] Chuẩn bị outline PDF report **8–12 trang**, slide deck **12–15 slide và xuất PDF**, demo script/video **5–10 phút**, theo đề. Dùng đường dẫn riêng `docs/workstreams/nguyen-submission-outline.md` trong giai đoạn làm song song; PR #2 đã merge, ownership `output/**` không đổi.
- [ ] Tạo bảng `CLAIM → evidence path/console/screenshot/test run`; chừa **MISSING / BLOCKED** nếu Bảo chưa có minh chứng.
- [ ] Chỉ khi các task chuyên môn đã đóng băng, Nguyên mới là owner tạo **report/**, **slides/** và dựng video thật; Bảo chỉ review phần Firebase, không chỉnh chung file.
- [ ] Tên file theo đề: `report/Lab03_<StudentID>.pdf`, `slides/Lab03_<StudentID>_slides.pdf`; README có video link. `<StudentID>` phải là mã thật được chủ bài cung cấp, không tự đoán.

**Done khi:** khung nộp đã đầy đủ; bản final chỉ chốt khi nội dung có evidence thật.

### N-05 [P1] Bàn giao QA rõ lỗi không vượt ownership

- [ ] `docs/workstreams/nguyen-status.md`: task checklist, screenshot/trace URLs, SHA, PASS/FAIL/BLOCKED, open bugs, việc cần retest.
- [ ] Không sửa Firebase hoặc build script; nếu gặp lỗi ở dịch vụ thì báo Bảo bằng issue/handoff có repro.

## 4. Việc được làm NGAY sau khi PR #2 đã merge

**Bảo (branch riêng từ latest main):**
- Kiểm tra quyền project Firebase và các giới hạn Spark/Storage/Google OAuth; tạo/chọn test account phù hợp nếu được phép.
- Chuẩn bị Android emulator/device độc lập; build/cài APK đúng SHA, chạy thử và lưu evidence/log dưới `evidence/android/`.
- Lập `docs/workstreams/bao-status.md` và checklist Firebase Console; sửa lỗi đã xác minh trong ownership Bảo, không deploy rules production khi chưa được phép.

**Nguyên (branch riêng từ latest main; ownership không đổi):**
- Audit 12 màn và Figma, sửa UI/theme/widgets/router trên feature branch riêng.
- Chuẩn bị ARTEMIS host/model key local, thiết bị riêng; tiếp tục harness/test files trong ownership Nguyên sau khi cập nhật main đã merge PR #2.
- Thu thập review transcript thật nếu AI review tool cho phép, chuẩn bị test matrix, report/slides outline và UI evidence ở file riêng.

## 5. Cách làm Git không conflict

```bash
# Cả hai tự chạy trên clone riêng; không đẩy commit vào PR #2.
git fetch origin
# Kiểm tra latest main đã có merge PR #2, GHI SHA đã dùng.
git rev-parse origin/main

# Máy của Bảo
git switch -c feat/lab3-bao-cloud-runtime origin/main

# Máy của Nguyên (ở clone riêng)
git switch -c feat/lab3-nguyen-ux-qa origin/main
```

- **PR #2 đã merge:** đẩy feature branch riêng, mở PR target `main`; không mở stacked PR vào branch cũ của PR #2.
- **Trước tích hợp:** mỗi người fetch `main`, cập nhật branch riêng và test lại; review độc lập từng PR rồi mới merge. PR của lượt Bảo này chỉ mở để review, không tự merge.
- **Không có 2 người cùng chỉnh** `README.md`, `docs/architecture.md`, `docs/lab3-report.md`, `report/**`, `slides/**`, `output/**`. Tài liệu tổng hợp thuộc giai đoạn đóng gói cuối, **Nguyên làm, Bảo duyệt thông tin thuộc scope Bảo**.
- Những chỉnh sửa liên quan `firebase/**`/`android/**`/`pubspec.*` chỉ Bảo làm; `e2e_test/**`/`lib/screens/**`/`lib/theme/**` chỉ Nguyên làm. Nếu cần thay đổi API chéo, tạo issue với signature dự kiến, không commit file của người kia.

## 6. Giao điểm duy nhất: final integration & submission (không làm song song)

1. **Gate 1 — đã merge:** PR #2 nằm trong `main` tại SHA trên. CI cho feature PR mới vẫn phải kiểm tra theo newest HEAD, không dùng kết quả PR #2 thay thế.
2. **Gate 2:** PR Bảo + PR Nguyên merge riêng; không có conflict ownership; retest Flutter/Firestore rules/Android.
3. **Gate 3:** Có Firebase project, device/test account, dữ liệu được phép sử dụng, ARTEMIS key và các flow cần backend; chạy end-to-end thật. Bảo xác nhận cloud/runtime, Nguyên xác nhận UI/E2E. Ghi rõ blocker nào cần giảng viên phê duyệt.
4. **Gate 4:** Nguyên chốt `docs/lab3-report.md`, `report/Lab03_<StudentID>.pdf`, `slides/Lab03_<StudentID>_slides.pdf`, video 5–10 phút, README link; Bảo kiểm tra tính chính xác của evidence Firebase; kiểm tra mọi link mở được.
5. **Gate 5:** Nộp repo + report PDF + slides PDF + video link. **Không nộp các DRAFT/PPTX thay thế bản PDF nếu chưa hoàn tất**.

## 7. Đối chiếu rubric để không làm lệch mục tiêu

| Hạng mục theo đề | Điểm | Owner thực thi | Min evidence |
|---|---:|---|---|
| Functional: 12 màn, 3 flows, real data + errors | 2.5 | Nguyên (UI/flow), Bảo (data/trusted operations) | Video/screenshot + Firestore records + error paths |
| Firebase 6 services | 2.0 | **Bảo** | Auth/Storage/FCM/DebugView/Crashlytics/Remote Config Console + app |
| MVVM / Riverpod | 0.75 | Nguyên audit UI; Bảo giữ service/VM separation | Architecture review + source/tests |
| UI/UX + 360dp/412dp | 0.75 | **Nguyên** | Figma–app compare + responsive/semantics |
| ARTEMIS ≥10 cases, ≥3 runs/test + 1 Pro session | 1.5 | **Nguyên** | Real traces, JUnit, pass-rate, exploratory log |
| AI review ≥5 findings, ≥3 fix commits | 0.5 | **Nguyên** | Raw review, decision table, linked commits |
| Slides + demo video | 2.0 | **Nguyên** (đóng gói cuối) | PDF slides và video thực tế |

### Tiêu chí báo cáo trạng thái chung

Mọi task cập nhật theo định dạng: `ID | Owner | PASS/FAIL/NOT RUN/BLOCKED | SHA | Evidence link | Blocker/next action`.
Không dùng `Implemented = PASS`: code hiện diện, CI xanh và end-to-end trên Android là ba cấp chứng minh khác nhau.

---

### Kết luận phân công

- **Bảo:** đảm bảo *cloud/data + Android chạy thật + console evidence*.
- **Nguyên:** đảm bảo *UI/Figma + ARTEMIS chạy thật + AI review + đóng gói nộp bài*.
- **Không có dependency phát triển trực tiếp** nếu giữ đúng boundary file và API hiện có. Dependency khó tránh duy nhất là **final E2E + report/demo tích hợp**; cần hoàn tất sau khi cả hai workstream có kết quả.
