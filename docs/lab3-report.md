# BeeWise Lab 3 implementation report (evidence draft)

**State: implementation/evidence draft, not a submission-ready report.** App code, security-rule baseline and ARTEMIS pytest scenarios are present. Firebase project `beewise-lab-3`, its Android app, Spark-plan Email/Password Auth and the default Singapore Firestore database with production rules are configured. An Android 16/API 36 emulator is online. This run still has no APK, test account/data, ARTEMIS host/key, staging API contract or app runtime evidence. Do not represent pending sections as completed validation.

Review artifacts: [9-page draft report PDF](../output/pdf/BeeWise-Lab3-Implementation-Report-DRAFT.pdf) and [13-slide draft deck](../output/presentations/BeeWise-Lab3-Review-DRAFT.pptx). Both state that runtime evidence is pending and must be revised after real runs.

## Product and architecture

BeeWise is a Vietnamese tutoring app for parents and tutors. It implements the 12 Lab 2 screen routes plus account, message, Firebase demo and the project-added tutor application/pending-review flow. Flutter/Riverpod provides screen state, Firebase adapters isolate external calls, GoRouter maps the flows, and the Figma-derived Nunito/Be Vietnam Pro theme is centralized. See [design traceability](design-traceability.md) and [architecture](architecture.md).

## Firebase and trust boundaries

Client code is prepared for Authentication, Firestore, Firebase AI Logic, Storage/PDF, FCM, Analytics, Crashlytics, Remote Config and App Check. Firestore/Storage rules restrict parent records and report files by UID. Tutor applications are private, create-only records that remain pending, unverified and inactive; applicants cannot publish a tutor profile. Consultant proposals, invoices, payment verification and official class records are trusted-backend operations; the client cannot declare a transfer paid.

Firebase project `beewise-lab-3` (Spark plan) and Android app `com.beewise.beewise` are registered. `android/app/google-services.json` and `lib/services/firebase_options.dart` match that project; Google Services and Crashlytics Gradle plugins are applied. Email/Password Authentication is enabled. The default Firestore database was created in Singapore (`asia-southeast1`) in production mode; the baseline Firestore rules were published from Firebase Console before the tutor-application change. Updated local rules add the private application collection but have not been compiled in the emulator or published. Google sign-in remains disabled pending a user-visible support email and Android OAuth/SHA configuration. Firebase AI Logic setup is paused at the Gemini API Additional Terms; the account owner must accept or decline before enabling APIs and App Check enforcement. Firebase Storage is not provisioned because the Spark plan cannot access Storage; enabling it now requires a Blaze billing upgrade. Tutor catalog, tester account, consultant/payment backend and live runtime evidence remain pending. No billing upgrade was performed.

## Static validation performed

- `flutter pub get` completed successfully.
- `dart format lib` completed successfully.
- `dart analyze` reported `No issues found` after the tutor-registration addition. `dart format --output=none --set-exit-if-changed lib` is clean.
- Flutter's unit-test command could not run because the repository currently has no `test/` directory; coverage is defined as ARTEMIS device scenarios instead.
- `e2e_test/` contains 25 Flash pytest cases using the pinned `ArtemisClient` SDK (22 automated suite cases and three operator-driven FCM cases), plus one separate 20-minute Pro exploratory case. Pytest collection with the project config collected all 26 cases after the tutor-flow addition; no mobile scenario was executed. The regression script passes the project config explicitly so pytest markers are recognized.
- Android APK build remains unverified. `flutter build apk --debug` and direct Gradle invocation both fail before compilation with `java.io.IOException: Unable to establish loopback connection` from JDK 17's Windows NIO pipe/selector setup, including an out-of-sandbox retry. The Firestore emulator also fails while opening the same Windows loopback selector; updated rules have not been compiled/published.
- AVD `BeeWise_API_36` now boots and `flutter devices` detects Android 16/API 36 on `emulator-5554`. APK compilation is still blocked at Gradle startup by the loopback error, so the app cannot yet be installed. Firebase Console access is available in the signed-in browser, but Firebase CLI is not authenticated. ARTEMIS `D:\Apps\artemis\.env` is absent and no ARTEMIS host/key environment variables are set; the host is not running.

## Evidence still to attach

| Evidence | Status |
|---|---|
| Android debug APK and emulator screenshots at 360dp/412dp | Emulator is detected; APK build still fails at Gradle startup with loopback error |
| Firebase Auth/Firestore/Storage/FCM/Analytics/Crashlytics/Remote Config/App Check captures | Email/Password enabled, Firestore database provisioned; new tutor rules not compiled/published; Storage needs Blaze, remaining service setup/data/runtime captures pending |
| AI match from real active tutor records | Pending: App Check and real catalog |
| Tutor application submission and private pending-review status | Code and restrictive Firestore rules are authored; emulator/live rule tests and Firebase project publishing remain pending |
| 25 ARTEMIS Flash cases × 3 runs (22 automated, 3 manual FCM), one Pro exploratory session, traces and replay result table | Collection succeeds; execution pending APK, connected device, ARTEMIS host/model key and staging data |
| Six AI-review findings and at least three finding-specific fix commits | Local Codex review and decisions are in [docs/code-review.md](code-review.md); no hosted PR output; fixes remain uncommitted per user instruction |
| Final PDF/slides/demo recording | Pending actual runtime evidence; no screenshots or results are fabricated |

Use [test plan](test-plan.md) and [README setup steps](../README.md) to complete evidence after the external prerequisites are configured.
