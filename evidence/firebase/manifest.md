# Firebase evidence index — Bảo

Correct project: `beewise-lab-3`, package `com.beewise.beewise`. App source
`db1f12e`; base `12f5322655463fd801d64e4925572d6a3a2bbb82`. Date 2026-10-30.
Full SHA and exact commands/exits are in `../cloud/checks/verified/*.json`.
The rules suite uses isolated **`demo-beewise`**, never the shared live project.

| Mandatory service | Implementation/local verification | Actual live verification | Evidence |
|---|---|---|---|
| Authentication | PASS 3 recovery/isolation unit tests; rules owner/applicant separation | BLOCKED: no dedicated identity; Google OAuth clients absent from committed Android config; Email/password enabled; Google provider absent; SHA list empty | `authentication/README.md` |
| Cloud Storage | PASS actual local PDF; success/cancel/empty-stream/error mocks; owner/type/size emulator rules | BLOCKED: live bucket list empty, billing disabled; no dedicated identity; no real upload URL obtained | `storage/README.md`, `storage/local-tutor-summary.pdf` |
| FCM | PASS existing lifecycle/route regressions; ownership journal and quarantine preserved | NOT RUN actual foreground/background/terminated delivery; BLOCKED sender access + authenticated receiver | `messaging/README.md` |
| Analytics | PASS typed privacy/UID mocks, removed tutor identifier from real connection caller | NOT RUN DebugView verification of 7 meaningful events | `analytics/README.md` |
| Crashlytics | Existing guest/UID/key + handled/fatal SDK adapters | Console receipt NOT RUN; see native attempt status in Android manifest | `crashlytics/README.md` |
| Remote Config | PASS defaults, bounded cloud values, two limits/feature gate, offline-fetch mocks | PASS template read (empty); NOT RUN publish/restore and visible same-APK behavior | `remote-config/README.md` |

Supporting Core/App Check/AI Logic are implemented; native initialization and
errors are reported separately in the Android manifest. Console attestation,
enforcement, backend/model terms/access are NOT RUN. No protection was disabled.

No Console screenshots are supplied: desktop automation failed before browser
control; the separate Playwright session is unauthenticated. CLI authentication
subsequently recovered. Read-only live management receipts are under `../cloud/`.
`../cloud/console-actions.json` records the timeline and authorized create-only
insertion of six labeled/unverified fixtures. Public guest SDK queries succeeded
from server; they do not prove native Android behavior. Remote Config original
empty template/ETag was backed up privately; no publish/rollback was performed.
Deployed Firestore rules differ from repository; the required chat index is absent.
See `firestore/README.md`. No production rules or index deployment was performed.

Do not count unit/emulator results as six working live services. Complete per-service
external steps below, using a dedicated test identity and this project only. No
production rules deployment, billing upgrade, resource deletion or global App Check
enforcement is authorized by this workstream.
