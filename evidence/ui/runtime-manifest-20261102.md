# BeeWise runtime UI evidence manifest

Date: 2026-11-02 (Asia/Saigon)
Device: Android 36 AVD `BeeWise_API_36`, serial `emulator-5554`, 1080×2400 physical pixels.
App: `com.beewise.beewise`, default `MainActivity`; debug APK launched from Home.
System font scale: 1.0. Notification permission was denied on this disposable test AVD.

## Captures

Each screenshot has a corresponding Android UIAutomator XML hierarchy. Selected bottom navigation destinations in XML verify Home, Search, and AI routes. Captures were taken at density 480 (360dp) and density 420 (approximately 411dp, referred to by the project as 412dp).

| Screen | 360dp | 412dp |
|---|---|---|
| Home | `runtime-home-360dp.png` / `.xml` | `runtime-home-412dp.png` / `.xml` |
| Search | `runtime-search-360dp.png` / `.xml` | `runtime-search-412dp.png` / `.xml` |
| AI matching | `runtime-ai-360dp.png` / `.xml` | `runtime-ai-412dp.png` / `.xml` |
| Tutor Profile | — | `runtime-tutor-412dp.png` / `.xml` |
| Login | `runtime-login-360dp.png` / `.xml` | `runtime-login-412dp.png` / `.xml` |
| Register | `runtime-register-360dp.png` / `.xml` | `runtime-register-412dp.png` / `.xml` |
| Connection Request (signed-in test session) | — | `runtime-connection-412dp.png` / `.xml` |
| Messages (support route) | — | `runtime-messages-412dp.png` / `.xml` |
| Messages, signed-in empty state | — | `runtime-messages-empty-auth-412dp.png` / `.xml` |
| Messages, signed-in empty state | `runtime-messages-empty-auth-360dp.png` / `.xml` | — |
| Profile (support route) | — | `runtime-profile-412dp.png` / `.xml` |
| Connect action while signed out | — | `runtime-connect-auth-gate-412dp.png` / `.xml` |

Home, Search and AI matching were also captured with Android font scale 1.3 at 360dp: `runtime-home-360dp-font130.*`, `runtime-search-360dp-font130.*` and `runtime-ai-360dp-font130.*`. Their content wraps/scrolls; no horizontal overflow was visible. This is a targeted enlarged-text smoke test, not a complete accessibility audit.

These are smoke captures, not full design comparisons. Data visible on Home/Search/Connection is marked `[TEST]` in the app and is not presented as real tutor data. The supplied test account was used for sign-in and the app may have performed normal auth/device-registration writes; no connection, chat, or trusted workflow request was submitted or created by this check. No credential, UID, or signed-in profile screenshot was retained.

Login and Register form checks used blank fields only. At 360dp the focused-field keyboard and post-scroll states are saved as `runtime-login-keyboard-360dp.*`, `runtime-login-keyboard-scroll-360dp.png`, `runtime-register-keyboard-360dp.*` and `runtime-register-keyboard-scroll-360dp.*`. At approximately 412dp, Register focus/scroll evidence is saved as `runtime-register-keyboard-412dp.*` and `runtime-register-keyboard-scroll-412dp.*`. The primary actions are fully visible after scrolling; no credentials were entered. The tutor's connect action routes to Login while signed out; no connection request was submitted.

## Build identity

Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
SHA-256: `536872469D22AF355A323F7C8C28D14C24C1110E34C54F31B74202206B34D181`

Local source file SHA-256 values at capture time:

| File | SHA-256 |
|---|---|
| `lib/screens/beewise_screens.dart` | `3F6AA93E415627DFD3ABFEEF12C5229DD0B00EF0B3A3D38F306A3B3B364D074D` |
| `lib/theme/bee_wise_theme.dart` | `586454FD47083E2C04757BD91ACC578FD48825E36BCC77CD8A6DE6293826CE7F` |
| `lib/widgets/bee_wise_widgets.dart` | `75105897334FF52D6BDC045B5F74D7609250C79D490FB3BB52E4E3454703F329` |
| `test/responsive_layout_test.dart` | `38874197B87929D1FD752DD56D81C0D2872F78C5D73DBC861C7A869B073674B6` |

The APK is a local build artifact and is not tracked. The command-line Gradle workarounds were needed only for this host environment: JDK 21, a workspace Unix-domain socket temp directory, and Kotlin incremental compilation disabled because the Pub cache and project reside on different drives.
