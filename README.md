# BeeWise - Lab 2 + Lab 3

Ứng dụng Android Flutter cho phụ huynh tìm gia sư, kết nối qua tư vấn viên,
theo dõi học thử, xác nhận lớp, thanh toán được xác minh và lịch chính thức.
Gia sư có thể nộp hồ sơ riêng tư để chờ duyệt. Giữ nguyên tiếng Việt và 12 màn
hình theo [handoff](handoff/flutter-handoff.md), [PRODUCT](PRODUCT.md) và
[design traceability](docs/design-traceability.md).

## Verified corrective baseline - 2026-10-30

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

This uses only Firestore/Storage emulators and the fake `demo-beewise` project.
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
Local [design screenshots](assets/figma-screens/README.md) are references, not
Android runtime evidence. No 360dp/412dp screenshot is claimed yet.
