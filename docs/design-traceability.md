# Lab 3 design traceability — BeeWise

## Status

The Flutter app and primary client flows now exist. “Implemented” below means code exists and passes static Dart analysis; it does not mean Firebase-backed behavior has been run. Firebase project, Android app, Email/Password Auth and default Firestore database are configured. The production rules currently deployed predate the tutor application collection; the updated local rules need emulator validation and deployment. Real tutor catalogue, Google OAuth/support contact, consultant/payment backend, ARTEMIS API credentials, Figma sync for the new tutor flow, and device evidence remain external requirements. Lab 2 screenshots contain illustrative tutor data and are not used as records.

## Screen mapping

| Lab 2 screen | Flutter route | Implementation | Data and remaining validation |
|---|---|---|---|
| 01 Home | `/home` | `HomeScreen`; discovery, search entry, subject chips, tutor cards, bottom navigation; loading/empty/error | Firestore `tutors` where `active == true`; needs real catalog and visual device review |
| 02 AI Matching | `/matching` | 500-character form, progress/error/no-match/result states, manual-search alternative | Firebase AI Logic ranks only active Firestore tutors; guest success allowance persistence is not defined |
| 03 Manual Search | `/search` | text, subject, area, mode, fee, price sort and result recovery | Local filter over first 100 active Firestore docs; production pagination/query needs review for large catalogs |
| 04 Tutor Profile | `/tutors/:id` | live profile, verified status, info rows, fee, connect and PDF/upload action | Live Firestore record; screenshot review pending |
| 05 Login | `/login` | Email/password and Google options, validation, progress/error, pending tutor continuation | Firebase Auth and OAuth project setup required |
| 06 Register | `/register` | name/phone/email/password, consent and validation | Firebase Auth and parent profile document; project setup required |
| 07 Connection Request | `/connection/:tutorId` | auth gate, tutor context, validated goal/area/schedule/note, request/chat batch | Firestore parent-owned request; consultant queue/backend still needed |
| 08 Group Chat | `/chats/:chatId` | parent text stream/composer and consultant workflow cards | Firestore; consultant/tutor authoring, FCM delivery and live permissions need integration testing |
| 09 Trial Lesson Detail | `/trial/:chatId/:proposalId` | consultant-authored proposal, accept or alternate-time response | Backend-authored chat widget required |
| 10 Class Confirmation | `/class/:chatId/:revisionId` | class details, confirm or adjustment response | Backend-authored revision required; invoice remains server-gated |
| 11 Payment | `/payment/:invoiceId` | live invoice status, payment-verification request, verified-state navigation | Payment provider/backend must issue and verify invoices |
| 12 Official Schedule | `/schedule/:classId` | schedule shown only for `paymentStatus == verified` | Trusted backend must create verified class record |
| Project-added Tutor application | `/tutor/apply`, `/tutor/pending` | Account creation, profile application form, pending-status screen and status recheck | `tutorApplications/{uid}` is private; create-only rules force `pending`, `verified: false`, `active: false`; staff/backend approval and later tutor dashboard are outside this MVP |
| Lab 3 account/demo center | `/messages`, `/profile` | chat list, notification center, Remote Config, PDF/Storage and Crashlytics controls | Firebase project, tester account and evidence required |

## Flow coverage

- **Discover and connect:** Home → Search/AI → Tutor Profile → Login/Register if needed → Connection Request → Chat. Selecting a tutor ID survives auth navigation; the request does not declare a schedule confirmed.
- **Guest AI:** Matching form → Firebase AI → validated active tutor results or retry/no-match/error → manual search. The one-success guest allowance is not implemented because the Lab 2 repository does not specify a product persistence/session contract; confirm that rule before submission.
- **Onboarding:** Chat consultant proposal → Trial response → consultant class revision → parent confirmation/adjustment → trusted invoice → payment verification → official schedule. Client cannot issue consultant widgets, create/verify invoices or create official schedule data.
- **Tutor registration (project-added MVP):** Login/Register → tutor application → account and private pending application → status screen. Tutors cannot enter parent flows, upload documents, edit a submitted application, set `verified`/`active`, or appear in discovery. The project must define staff review operations before approval can be completed.
- **Empty/recovery:** Screens have loading, empty/configuration/error states, retry or alternative navigation where applicable. E2E proof is pending.

## Shared components and design system

`lib/theme/bee_wise_theme.dart` and `lib/widgets/bee_wise_widgets.dart` centralize handoff colors, Nunito/Be Vietnam Pro typography, spacing/radius, buttons, alerts, empty/error/loading states, tutor card/avatar and info rows. Screens use SafeArea/scrolling and Material targets. The layout has not yet been visually compared on a running emulator at both 360dp and 412dp; do not claim pixel-level Figma parity until that review is captured.

## Firebase service mapping

| Lab requirement | Code | Current evidence / blocker |
|---|---|---|
| Auth / Google | `auth_service.dart`, login/register screens | Firebase project, Android app and Email/Password are configured; Google sign-in still needs the user-visible support email and Android OAuth/SHA setup, and a dedicated test account is not available |
| Tutor application | `tutor_application_service.dart`, `/tutor/apply`, `/tutor/pending`, `firebase/firestore.rules` | Applicant can create/read only their own pending record; Firestore rules deny status/public-profile changes. Needs emulator/live rule tests and approved staff review workflow |
| Firestore tutor/workflow | `tutor_repository.dart`, `chat_service.dart`, `workflow_service.dart`; `firebase/firestore.rules` | Client requests are owner-scoped; real catalog and consultant/backend integration absent |
| AI matching | `matching_service.dart`, Remote Config | Firebase AI Logic client code; Console setup is paused at Gemini API terms, App Check and a successful live result remain unverified |
| Storage PDF upload | `export_service.dart`, profile/profile action | Owner path rule and upload progress; needs signed-in Firebase run |
| FCM | `notification_service.dart` | foreground/background/open handling and per-parent installation registration; needs actual send/device validation |
| Analytics | `analytics_service.dart`, `docs/analytics-plan.md` | events wired without free-text or direct identifiers; DebugView capture pending |
| Crashlytics | `crash_reporting_service.dart`, `main.dart`, profile controls | fatal/nonfatal handlers and demo control; dashboard evidence pending |
| Remote Config | `remote_config_service.dart`, app initialization | defaults and fetch; console value/before-after capture pending |
| ARTEMIS | `e2e_test/conftest.py`, pytest modules, `e2e_test/run-artemis.ps1` | 24 independent SDK tests × 3 Flash runs and a separate 20-minute Pro exploration are authored; execution pending APK, Firebase data/account, host and model key |
| AI code review | `docs/code-review.md` | Local Codex review records 6 findings and dispositions; 3 fixes are present but intentionally uncommitted; no hosted PR-review output or fix commits exists |

## Known external prerequisites

Configure a student-owned Firebase Android app with package `com.beewise.beewise`, import real tutor records, enable the Firebase products listed in [README.md](../README.md), configure App Check/OAuth, and supply a designated test account. A trusted service must handle consultant-authored widgets, invoices, payment verification and class schedule records. ARTEMIS needs a permitted model key and working Android APK/device. Capture every run/dashboard result; do not substitute screenshots of design mocks for runtime evidence.
