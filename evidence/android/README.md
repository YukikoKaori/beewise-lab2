# Android verification — Bảo

Date: 2026-10-30. Application source `db1f12e`; base `12f5322` (PR #2 merge).
Full source SHA in `../cloud/checks/verified/apk-build.json`.

PASS: D-drive Flutter 3.47.8 / Dart 3.13.7, JDK 21.0.13+9, Android SDK
`D:\Android\SDK`, API 37 x86_64 AVD online, debug APK build (exit 0).
Gradle 9.3.1 / AGP 9.1.0. Doctor exits 0 but has warnings about local Flutter
channel, Android command-line tools/licenses, and unrelated Windows C++ tools;
it is not an all-green doctor. Build also reports future Flutter/Kotlin plugin
migration warnings; no unsupported package upgrade was attempted.

APK retained on D:
`D:\CodexTemp\beewise-lab3-build\build\app\outputs\flutter-apk\app-debug.apk`
(227,799,947 bytes). SHA-256:
`b3fa9f9d3b596d240cb24fe8dd4c422cc8d0376dd92cf42b2be6c3cf2483c9db`.
No large APK/toolchain/cache is added to Git or installed on C.

**Latest installation BLOCKED:** `adb install -r` returns
`INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package com.beewise.beewise signatures do not match newer version; ignoring!`.
The installed older APK is not evidence for this source. Do not clear/uninstall
without permission: user AGENTS.md explicitly requires asking before uninstall.
A decision is pending. Original app data was preserved.

Alternative fresh D data images were attempted, without deleting original AVD
data. Shared read-only launch was rejected by the emulator; fresh headless boot
did not establish ADB, and an attempted boot property was reported unsupported.
Those instances were stopped. Original AVD was restarted and is online again.
Original display/network/Analytics debug setting restoration is recorded in
`logs/original-restored-restore.json`. No screenshot of an earlier APK is supplied.

Latest launch, Firebase native initialization, navigation, offline/recovery,
360dp/412dp, native notification permission/delivery and Crashlytics triggering:
**NOT RUN**. Authenticated session cases: **BLOCKED**, no dedicated test identity.
Device/package inspection is in `logs/initial-device-inspect.json`; requested
permissions in a package dump do not prove the latest APK's granted permissions.

Reproduce after approved install resolution:

```powershell
scripts/verify-bao-cloud.ps1 -Action toolchain -RunName retest
scripts/verify-bao-cloud.ps1 -Action build -BuildDirectory D:/CodexTemp/beewise-lab3-build -RunName retest
python scripts/verify-bao-android.py prepare --serial emulator-5554 --label retest-original
python scripts/verify-bao-android.py install --serial emulator-5554 --apk D:/CodexTemp/beewise-lab3-build/build/app/outputs/flutter-apk/app-debug.apk --label retest-apk
python scripts/verify-bao-android.py resize --serial emulator-5554 --width 360 --label retest-360
python scripts/verify-bao-android.py launch --serial emulator-5554 --label retest-start
python scripts/verify-bao-android.py capture --serial emulator-5554 --label retest-home-360
# Observe screenshots/XML before choosing tap coordinates; repeat at 412dp.
python scripts/verify-bao-android.py restore --serial emulator-5554 --label retest-restored
```

The capture helper preserves PNG bytes from `adb exec-out screencap -p` and
captures package PID logs. Raw logs remain private on D; committed copies omit
credential-bearing lines. Do not infer Console receipt from device logs.
