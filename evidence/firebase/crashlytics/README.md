> **2026-10-31 corrective update (supersedes prior runtime status):** Native update: handled Profile diagnostic and deliberate Crashlytics SDK crash actually exercised on isolated API37; sanitized PID log `../../android/logs/corrective-deliberate-crash-logcat.log`. Console receipt, signed-in UID/custom-key association and a real business-flow failure remain NOT RUN/BLOCKED. The snackbar is not proof of delivery.

# Crashlytics

Implementation: `crash_reporting_service.dart`, `main.dart`, auth provider and
existing Profile diagnostic buttons. App source `db1f12e`. Guest identity and
`app_area=beewise_mobile` are configured in code; `demo_action` has a service API.
Runtime triggering/relaunch results are in `../../android/runtime-manifest.json`.

Console report receipt, report identity/custom-key inspection: NOT RUN / BLOCKED
latest native app installation and browser Console control. No Console receipt is inferred from a success snackbar, a
local SDK log or a process closing. Controlled test crash is allowed only on the
dedicated development emulator; no real user session is used.

External action: inspect the correct project's Crashlytics after native triggers
and relaunch, allow report upload, capture non-fatal and deliberate fatal issue
with key/guest identity; later repeat real handled workflow failure using a
dedicated identity. Preserve distinction between diagnostic sample and real
business error. Do not claim a production crash or verified authenticated UID.
