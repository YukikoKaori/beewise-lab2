# BeeWise — Lab 2 + Lab 3

Ứng dụng Android Flutter dành cho phụ huynh tìm gia sư, kết nối qua tư vấn viên, rồi theo dõi quy trình học thử → xác nhận lớp → thanh toán được xác minh → lịch học chính thức.

## Cấu trúc và tài liệu thiết kế

- Product brief: [PRODUCT.md](PRODUCT.md)
- 12 màn hình, hành vi và token Figma: [handoff/flutter-handoff.md](handoff/flutter-handoff.md)
- Luồng/sitemap: [ux/sitemap.md](ux/sitemap.md), [ux/user-flow.md](ux/user-flow.md)
- Quyết định kiến trúc: [docs/architecture.md](docs/architecture.md)
- Traceability thiết kế: [docs/design-traceability.md](docs/design-traceability.md)
- Kế hoạch Analytics: [docs/analytics-plan.md](docs/analytics-plan.md)
- Test/evidence: [docs/test-plan.md](docs/test-plan.md)
- AI review record: [docs/code-review.md](docs/code-review.md)
- Lab 3 review drafts: [implementation report PDF](output/pdf/BeeWise-Lab3-Implementation-Report-DRAFT.pdf), [13-slide review deck](output/presentations/BeeWise-Lab3-Review-DRAFT.pptx). They are not final submission artifacts; update after the tutor-registration addition and regenerate with real runtime evidence.
- Lab 2 AI design log, UX critique, prompt và evidence vẫn ở thư mục [ai/](ai/).
- Ảnh thiết kế màn hình và user-flow: [assets/figma-screens/README.md](assets/figma-screens/README.md), [assets/](assets/).

## Môi trường đã cài

Đã xác nhận: Flutter 3.47.8, Dart 3.13.7, JDK 17.0.20.1, Android SDK API 36 / Build Tools 36, Firebase CLI 15.34.1, FlutterFire CLI 1.4.1, ARTEMIS tại `D:\Apps\artemis` (commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`), Python 3.12 và `uv`. AVD `BeeWise_API_36` đang online trên `emulator-5554`; Gradle hiện vẫn lỗi loopback trước khi build.

## Chạy Android

Mở terminal mới sau khi cài Flutter để PATH được cập nhật:

```powershell
cd "D:\semester 8\PRM\beewise-lab2"
flutter doctor -v
flutter pub get
flutter run -d BeeWise_API_36
```

Nếu AVD chưa chạy, mở Android Studio Device Manager hoặc chạy `emulator -avd BeeWise_API_36`.

## Nối Firebase project của bạn

Firebase project `beewise-lab-3` và app Android `com.beewise.beewise` đã được tạo; file `android/app/google-services.json` cùng `lib/services/firebase_options.dart` đã được cấu hình cho project này. Email/Password Authentication đã bật. Firestore đã được tạo tại Singapore (`asia-southeast1`) ở production mode và rules trong `firebase/firestore.rules` đã publish. Google sign-in cần support email hiển thị cho người dùng và cấu hình OAuth/SHA-1. Các dịch vụ khác vẫn cần bật và kiểm thử. Không nâng cấp billing nếu chưa được chủ tài khoản chấp thuận.

```powershell
firebase login
firebase use beewise-lab-3
```

`google-services.json` là client config Android, không phải service-account private key. Không đưa service-account JSON, ARTEMIS API key, hoặc token vào repo. Firestore đã tạo ở Singapore (`asia-southeast1`) trong production mode; bản rules nền đã publish trước khi thêm collection `tutorApplications`. Rules mới trong repo chưa kiểm thử/publish, do đó không bật thử luồng đăng ký gia sư trên project production cho tới khi chúng được kiểm tra. Auth Email/Password đã bật. Tiếp tục bật/cấu hình Cloud Messaging, Analytics, Crashlytics, Remote Config và Firebase AI Logic. Google Auth đợi support email và OAuth config. App Check dùng debug provider trên debug build; đăng ký Play Integrity trước release. Cloud Storage hiện yêu cầu gói Blaze để tạo/sử dụng bucket; project đang giữ Spark nên chức năng tải PDF lên Firebase chưa khả dụng. Không nâng cấp nếu chưa chấp thuận billing. [Firebase Storage billing requirements](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024).

Tạo dữ liệu `tutors/{id}` từ hồ sơ có thật và `active: true`; các trường app đọc: `name`, `credential`, `introduction`, `subjects`, `grades`, `hourlyFee`, `areas`, `teachingModes`, `availability`, `verified`, `active`, tùy chọn `rating`, `reviewCount`, `experienceYears`, `avatarUrl`. Dữ liệu trong ảnh Lab 2 chỉ là minh họa, không được đưa vào Firestore như gia sư thật.

## Đăng ký gia sư (MVP theo yêu cầu dự án)

Gia sư tạo tài khoản Email/Password và gửi hồ sơ vào `tutorApplications/{uid}`. Hồ sơ chỉ người nộp được đọc; client chỉ được tạo trạng thái `pending`, `verified: false`, `active: false` và không được sửa/xóa sau khi gửi. App giữ tài khoản ở màn hình chờ duyệt, không mở luồng phụ huynh và không đưa hồ sơ vào tìm kiếm. Bản MVP chưa nhận giấy tờ đính kèm. Rules mới đang ở working tree, chưa publish; kiểm thử emulator bị chặn bởi lỗi Java loopback. Trước khi bật trên project, chạy kiểm thử rules và để trưởng dự án chốt người duyệt, quy trình từ chối/yêu cầu bổ sung, lưu trữ giấy tờ và bước kích hoạt hồ sơ.

Deploy rules khi đã chọn đúng Firebase project:

```powershell
firebase use YOUR_FIREBASE_PROJECT_ID
firebase deploy --only firestore:rules,storage
```

Firestore rules giới hạn dữ liệu theo UID; tutor catalog do backend/staff quản lý, invoice/lịch do backend tạo, client không thể tự ghi trạng thái đã thanh toán. Kiểm tra rules bằng Firebase Emulator Suite trước khi dùng dữ liệu thật. Backend hiện cần xử lý tạo proposal của tư vấn viên, hóa đơn và xác minh payment; repo không chứa provider/server credential.

## ARTEMIS E2E

ARTEMIS đã được cài riêng tại `D:\Apps\artemis` (commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`); phần test repo dùng `ArtemisClient` Python SDK cùng pytest 9.1.1 / pytest-asyncio 1.4.0. Regression dùng Flash; exploratory dùng Pro riêng. Không có ARTEMIS model key hoặc Firebase test account trong repo.

```powershell
cd D:\Apps\artemis
uv run python -m artemis --help
```

Cấu hình ARTEMIS theo `D:\Apps\artemis\README.md` (API key chỉ nhập local, không lưu vào repo), bật host, kết nối emulator và cài APK. Trên terminal chạy test:

```powershell
$env:ARTEMIS_BASE_URL = 'http://127.0.0.1:8000'
$env:ARTEMIS_DEVICE_SERIAL = 'emulator-5554'
$env:BEEWISE_TEST_ACCOUNT_EMAIL = 'your-dedicated-test-account@example.test'
$env:BEEWISE_TEST_TUTOR_NAME = 'A real active tutor name'
uv sync --project .\e2e_test
.\e2e_test\run-artemis.ps1 -RunsPerTest 3
uv run --project .\e2e_test pytest -c .\e2e_test\pyproject.toml .\e2e_test\test_exploratory.py -m exploratory -q -s
```

Có 25 ca Flash regression: 22 ca chạy tự động trong script và 3 ca FCM (TC-10/14/15) cần người vận hành gửi push riêng cho từng lượt. Script chạy 22 ca tự động ba lượt, lưu log, JUnit XML và `run-manifest.json` dưới `evidence/artemis/`; chạy từng ca FCM riêng ba lượt với push mới mỗi lần. TC-26 tạo một tài khoản gia sư dùng một lần mỗi lượt, chỉ chạy trên Firebase test project. Phiên khám phá Pro 20 phút chạy riêng một lần. Các ca tư vấn/thanh toán yêu cầu staging data từ backend tin cậy. Cấu hình title FCM/query qua biến `BEEWISE_TEST_*` theo [test plan](docs/test-plan.md). Dùng test project/account và chỉ lưu bằng chứng của lượt thực sự chạy.

Theo [kế hoạch test](docs/test-plan.md), chạy mỗi kịch bản tối thiểu ba lượt và lưu nguyên trạng traces/replays vào `evidence/`. Không ghi nhận các lượt chưa chạy, test giả, hoặc số liệu không quan sát được.

## Trạng thái Lab 3

Đã có Android app Flutter/Riverpod, Firebase project `beewise-lab-3`, Email/Password Auth và Firestore database tại Singapore. `dart analyze` báo `No issues found`, formatter sạch; ARTEMIS collection hiện có 26 kịch bản (25 regression, gồm một test gia sư, và một test khám phá Pro). AVD Android 16/API 36 đã online. Test thật vẫn chờ APK, dữ liệu tutor/tester, API contract staging và ARTEMIS host. Firebase AI Logic đang chờ account owner quyết định Gemini API terms; Google Auth chờ support email/OAuth. Storage upload không dùng được ở Spark và cần Blaze billing. Rules mới cho hồ sơ gia sư chưa kiểm thử/publish.

APK chưa được build xác nhận. `flutter build apk --debug` và Gradle trực tiếp vẫn báo `Unable to establish loopback connection` trước khi biên dịch, dù ADB và emulator đang chạy. Build cần thử lại từ terminal Windows thường.

AI tools được khai báo trong [AI review record](docs/code-review.md): OpenAI Codex hỗ trợ code, debug, review tĩnh và tài liệu; Google ARTEMIS SDK được dùng để viết kịch bản E2E nhưng chưa thực thi. Để hoàn tất phần chạy thật và nộp evidence còn cần build APK, cấu hình AI Logic sau khi owner xử lý terms, chọn support email/OAuth, thêm dữ liệu tutor/tester, nhận contract backend staging, cấu hình ARTEMIS host/model key, rồi chạy/capture các scenario theo [test plan](docs/test-plan.md). Cloud Storage upload cần Blaze; hiện project giữ Spark. Đã có Codex review nội bộ 6 findings; 3 sửa lỗi nằm trong working tree và chưa commit theo yêu cầu của bạn. Chưa có transcript từ PR review service bên ngoài. Không tạo hồ sơ giả, API credential hay bằng chứng test/review thay cho chạy thực tế; xem [docs/lab3-report.md](docs/lab3-report.md) để biết trạng thái bằng chứng.

## Design source of truth

- Figma: [BeeWise-Design](https://www.figma.com/design/gqbuTDuZYOyKyP8LsUwobC/BeeWise-Design?node-id=2-3&t=XLL8PoLbIdyZCOIC-1)
- Google Stitch: [BeeWise_Lab2](https://stitch.withgoogle.com/projects/11519656942239142615)
- Full UI/flows/design token references: see [handoff/flutter-handoff.md](handoff/flutter-handoff.md).
