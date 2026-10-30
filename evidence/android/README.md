# Android actual verification — Bao, 2026-10-31

**PARTIALLY COMPLETE.** Latest app source `9ef5907b2d296fcdafaa869a53e9780692f4cc56`
built on D and actually installed/launched on **separate** `emulator-5558`.
APK SHA-256 `f6a66bc0d90ad68d64052b7beda0c33bc54c4f59c1da1d16561f13e1fbdc578d`,
227,800,966 bytes. Exact install/Success/hash: `logs/corrective-4gb-source-install.json`.
APK path remains `D:/CodexTemp/beewise-lab3-build/build/app/outputs/flutter-apk/app-debug.apk`.
Toolchain Flutter 3.47.8/Dart 3.13.7, JDK21, Gradle9.3.1/AGP9.1.0. Future Kotlin
plugin warnings remain; this is a debug build, not release/hardware certification.

## Native evidence actually inspected

All PNGs are original `adb exec-out screencap -p` bytes. SHA/dimensions and
VERIFIED_SCREEN vs HISTORICAL_ATTEMPT_ONLY classification are in
`runtime-manifest.json`. Failed/splash/black screenshots do not count as PASS.

| Scenario | Actual evidence/result |
|---|---|
| 360dp Home/Profile | `screenshots/corrective-360-home.png`, `corrective-360-profile.png` |
| 412dp Profile | `screenshots/corrective-412-profile-ready.png` |
| Native permission | `screenshots/corrective-360-permission.png`; Allow tap receipt |
| Firestore catalog | `screenshots/corrective-412-search-data.png`: six TEST/unverified synthetic tutors |
| Guest Chats | `screenshots/corrective-412-chats-ready.png`: login gate |
| Offline/recovery | Both Wi-Fi/cellular disabled; active default network none observed; PID log has Firestore UNAVAILABLE/DNS failure; `corrective-412-offline-error.png` renders cached Home (filename does not mean error screen). Restored network then fetched changed RC successfully |
| RC before/change/restore | `corrective-412-profile-ready.png` enabled/3 -> `corrective-412-rc-changed-profile.png` disabled/1 -> `corrective-412-rc-restored-profile.png` enabled/3 |
| Actual behavior gates | `corrective-412-matching-disabled-result.png`, `corrective-412-home-limit-two-bottom.png`; same APK, no reinstall/rebuild |
| Handled diagnostic | `logs/corrective-360-nonfatal-logcat.log`: Profile diagnostic StateError; not a business-flow failure or Console receipt |
| Intentional crash | `logs/corrective-deliberate-crash-logcat.log`: native FlutterFirebaseCrashlytics test exception, PID5565; app relaunched |

## Failures and limits

Original emulator's `INSTALL_FAILED_UPDATE_INCOMPATIBLE` was bypassed by a fully
independent AVD on D, not by removing its package/data. Original AVD only shut
down for RAM. New API37 revision6 AVD uses 4096MB, software GPU, 2 cores.
Initial 2GB run had GMS SIGBUS; that crash buffer was observed but not retained
across reboot. 4GB first boot had System UI ANR and slow initialization, followed
by successful rendering. Do not claim an app-code fix resolved those failures.
API37 minimum-memory guidance: [official emulator release notes](https://developer.android.com/studio/releases/emulator).

Tutor-detail retest interrupted: `logs/corrective-gms-package-update.log` proves
PID6589 was killed for Google Play services package update. Detail is not PASS.
Host C filled from paging and some captures could not be written; after restoring
and stopping the isolated emulator about 6.3GB returned. Generated dart cache was
moved intact to D; no personal file deleted, no registry/pagefile setting changed.
No RenderFlex overflow observed in selected package logs; not comprehensive QA.
Status-only `.xml` outputs from the first hierarchy method are not XML evidence.

Dedicated account absent: authenticated session/native Google picker/signout/
account switch/private workflows BLOCKED. FCM delivery, real Storage upload,
seven Analytics DebugView events and Crashlytics Console receipt NOT RUN/BLOCKED.
Staging, ARTEMIS, external review and physical hardware NOT RUN.

Display/network/Analytics debug restoration:
`logs/corrective-restored-device-restore.json`. Isolated AVD then shut down;
no user app uninstall, clear-data or wipe was executed. Cloud RC restored empty
version2 with ETag guards; native enabled/3 confirms refetch. Raw logs/configs
remain private on D; committed PID logs redact credential-bearing lines.

Reproduce in a coordinated test window:
`scripts/start-bao-isolated-android.ps1`, then prepare/install/resize/launch/capture
with `scripts/verify-bao-android.py --serial emulator-5558`; observe each screen
before tapping, and always restore device state. Account-dependent cases need a
dedicated authorized identity first. Never install over or clear the original AVD.
