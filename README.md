## PRM393 Final Assignment

BeeWise keeps the Lab 3 Android package `com.beewise.beewise` and Firebase project `beewise-lab-3`. The Final adds a Flutter Web Admin and a shared Dart package. The current branch is a review candidate; no public Final admin URL has been verified. See the [rubric gap review](docs/gap-review.md), [data model](docs/data-model.md), [cross-role flow](docs/cross-role-flow.md), [AI feature](docs/ai-feature.md), and [test report](docs/test-report.md).

| Directory | Responsibility |
|---|---|
| `mobile/` | Flutter Android app, native files, tests and Lab 3 probe |
| `web/` | Google staff sign-in, tutor management/review, dashboard, announcements |
| `packages/core/` | Shared role, catalog and AI models, design tokens, Firestore reads and transactions |
| `firebase/` | Rules, indexes, defaults and tests; root `firebase.json` configures Hosting |
| `backend/` | Existing trusted Lab 3 consultant/payOS integration |
| `e2e_test/` | Existing Android E2E/ARTEMIS harness |

**Roles.** Parents and tutors use mobile. Verified Google accounts with Firestore staff/admin roles use Web. The first admin must be manually provisioned and named by the authorized operator; no production admin or credentials were added. Emulator demo identities use disposable `example.test` addresses. See [provisioning](docs/data-model.md).

**Local demo.** With Flutter 3.47.8, JDK 21, Android SDK/API 35 or 36 and Node 24:

```sh
npm ci --prefix firebase
./firebase/node_modules/.bin/firebase emulators:start --project beewise-lab-3 --only auth,firestore,hosting
# Separate terminal (launch on Android emulator):
cd mobile
flutter pub get --enforce-lockfile
flutter run --dart-define=BEEWISE_FIREBASE_EMULATOR_HOST=10.0.2.2
# Separate terminal (Web build before accessing localhost:5000):
cd web
flutter pub get --enforce-lockfile
flutter build web --release --dart-define=BEEWISE_FIREBASE_EMULATOR_HOST=127.0.0.1
```

Choose the Auth Emulator Google popup to create a disposable staff account, then provision its role using the **local** emulator operator. Restart or reload if needed. The Android app enters Final mode automatically against the emulators; manual tutor matching works there with no provider calls. The non-emulator APK uses legacy behavior unless built with `--dart-define=BEEWISE_FINAL_FIRESTORE=true` after the Final rules/indexes are approved and available. Do not use production accounts in the local demo.

**Hosting.** [Deployment gate and exact build inputs](docs/final-deployment.md). No Rules, Hosting, billing, App Check enforcement, production role assignment, or live data migration was applied during development. AI assistance: Codex for design, implementation and review; Gemini is the product provider and is not a substitute for E2E evidence.

**Final Android PDFs.** Final mode stores PDF files in app-private, account-scoped device storage. Firestore holds metadata only. The profile lists recent reports and identifies legacy Base64 entries separately. No Cloud Storage is used.

**Final payments.** New Final-mode invoices use per-invoice VietQR and manual bank review in Web Admin. Class activation is atomic with staff verification; the existing payOS flow remains available for legacy records. [Payment architecture and configuration](docs/payment-architecture.md).

## Historical Lab 3 PDF persistence — 2026-11-02

Firebase Cloud Storage is replaced by Cloud Firestore Base64 PDF persistence with mentor approval (**owner-reported**). Status: **IMPLEMENTED — LIVE VERIFICATION PENDING**. PDF ≤500 KiB, one immutable parent-owned document at `reports/{uid}/files/{reportId}`, transaction acknowledgement plus server read before success, authenticated server download and local share/open. Firebase Storage dependencies and active emulator/deployment configuration are removed. No billing upgrade, bucket or new backend. [Implementation, security, tests and live prerequisites](docs/workstreams/bao-firestore-reports.md).

Older dated validation/billing/Storage statements below are historical, not current verification of this migration. New checks/CI must match the migration HEAD.

# BeeWise - Lab 2 + Lab 3

Ứng dụng Android Flutter cho phụ huynh tìm gia sư, kết nối qua tư vấn viên,
theo dõi học thử, xác nhận lớp, thanh toán được xác minh và lịch chính thức.
Gia sư có thể nộp hồ sơ riêng tư để chờ duyệt. Giữ nguyên tiếng Việt và 12 màn
hình theo [handoff](handoff/flutter-handoff.md), [PRODUCT](PRODUCT.md) và
[design traceability](docs/design-traceability.md).

## Verified corrective baseline - 2026-10-30

Latest PR #2 follow-up: [notification ownership and route review](docs/pr2-lifecycle-review.md).
It supersedes the historical 8-test baseline below with 34 Flutter tests and
documents owner-authorized cleanup, quarantine recovery and remaining blockers.

Base main/PR #1 merge: `dd8b0e165039886b52b08cab81e17dd08c4af7ff`.
The postmerge audit replaces old machine/cloud claims: committed configuration
does not prove any live Firebase service is enabled or deployed.

- Flutter 3.47.8 / Dart 3.13.7 and portable Temurin JDK 21 are usable on drive D.
- Local formatter, Flutter analyzer and 8 regression tests pass.
- Real Firestore + Storage emulator suite: 26 tests pass against `demo-beewise`.
- ARTEMIS SDK collection: 26 cases; mobile execution BLOCKED, not 26 passes.
- Android build/runtime: see the current [execution record](docs/lab3-report.md).
- No Firebase deployment, billing upgrade, live account creation or production
  data upload was performed. No hosted AI review transcript exists.

Evidence and exact commands are in [evidence/corrective](evidence/corrective/).
Draft [PDF](output/pdf/BeeWise-Lab3-Implementation-Report-DRAFT.pdf) and
[slides](output/presentations/BeeWise-Lab3-Review-DRAFT.pptx) retain DRAFT until
the missing runtime/integration evidence is captured.

## Reproduce local checks

Use Flutter **3.47.8**, JDK **21**, Node **24** (CI) and Python **3.12**.
The machine's default Flutter 3.47.3 / Dart 3.13.3 cannot resolve this project;
the default Java 8 cannot run its Android toolchain. Use process-local paths;
the script does not change system PATH or registry.

```powershell
$env:JAVA_HOME = 'D:\CodexTemp\beewise-lab3-tools\jdk\jdk-21.0.13+9'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$env:ANDROID_HOME = 'D:\Android\SDK'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
.\scripts\verify-lab3.ps1 -Flutter 'D:\CodexTemp\beewise-lab3-tools\flutter\bin\flutter.bat' -Rules -Android
```

Caches default to `D:\CodexTemp\beewise-lab3-cache`. For other machines pass
`-CacheRoot` and the installed Flutter path. An Android SDK requires the platform,
build tools and NDK requested by Gradle; obtain licenses through the owner.
The Android wrapper is Gradle 9.3.1 with AGP 9.1.0. CI pins Flutter and Java and
builds a debug APK; a workflow file or in-progress run is not a passing build.

Rules only, from the repository root:

```powershell
npm.cmd ci --prefix firebase --ignore-scripts
npm.cmd --prefix firebase test
```

This uses only the Firestore emulator and the fake `demo-beewise` project.
No Firebase login or production deploy is needed. The dev-only lockfile overrides
three vulnerable transitive packages; `npm audit --prefix firebase` currently
reports zero vulnerabilities. Production rules remain unmodified remotely.

## Firebase and backend requirements

Android client config names `beewise-lab-3` / `com.beewise.beewise`. It is client
configuration, not proof of Auth providers, Firestore data, Storage availability,
App Check, OAuth, AI terms, Analytics, FCM or Crashlytics functionality. The cloud
project was not inspected or changed in this execution.

Use an explicitly authorized dedicated test project and controlled tutor records
for integration. Do not copy illustrative Lab 2 tutor identities into a real
catalog. Do not upgrade billing or accept provider terms automatically.

[Backend contract](docs/backend-contract.md) defines proposal IDs, expiry/current
state, trusted invoice/payment/schedule processing and UID-targeted push payloads.
New rules deny proposals lacking this contract. Live backend integrations are
absent, not simulated as successful. [Architecture](docs/architecture.md),
[analytics](docs/analytics-plan.md), [review audit](docs/code-review.md),
[test plan](docs/test-plan.md), [demo](docs/demo-script.md).

## ARTEMIS readiness

The pinned SDK commit is `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`.
Install/start the host separately with locally supplied keys; never commit keys.
Supply `ARTEMIS_BASE_URL`, `ARTEMIS_DEVICE_SERIAL`, a dedicated account, safe
staging fixtures and an installed APK. No host, key or test identity is supplied
by this repository. Do not transmit passwords in model goals/traces.

```powershell
uv sync --project .\e2e_test --frozen
uv run --project .\e2e_test pytest -c .\e2e_test\pyproject.toml .\e2e_test --collect-only -q
python scripts/check_e2e_harness.py
python scripts/check_artemis_runner.py # Windows synthetic process checks, no mobile execution
.\e2e_test\run-artemis.ps1 -RunsPerTest 3 -OutputDirectory evidence/artemis/NEW-RUN
```

21 automatic Flash cases run three times. TC-10/14/15 need a fresh manual push
each repetition. TC-26 is manual setup: the operator enters disposable credentials
directly on an authorized test device and sets `BEEWISE_DEDICATED_TEST_PROJECT=1`.
TC-25 is a separate 20-minute Pro exploration. Run manual cases three times with
fresh fixtures using `uv run --project e2e_test pytest -c e2e_test/pyproject.toml
e2e_test/test_account_and_firebase.py -k tc26 -q -s` (substitute each case ID).
The runner records BLOCKED/FAIL/PENDING_VERIFICATION, SHA, exit codes and log
hashes. Export original host traces/replays and independently verify visible
state before marking any mobile case PASS. Collection is harness validation only.

## Design sources

[Figma](https://www.figma.com/design/gqbuTDuZYOyKyP8LsUwobC/BeeWise-Design?node-id=2-3)
and [Stitch](https://stitch.withgoogle.com/projects/11519656942239142615).
Local [design screenshots](mobile/assets/figma-screens/README.md) are references, not
Android runtime evidence. No 360dp/412dp screenshot is claimed yet.
