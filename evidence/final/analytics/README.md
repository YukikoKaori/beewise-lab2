# Final Firebase Analytics Verification (`ai_request`, `ai_result_accepted`, `ai_error`)

- **Scope & Approval:** Executed on `BeeWise_Final_API35` (`emulator-5564`) with Final debug APK (`e885a076b3a1f39e40f7cacc603ea0aec2d30e7e44028511e6f3bc06be3986b9`) against production Firebase project `beewise-lab-3` under Owner Gate 2 Option 2.1.
- **Root Cause Cleared Before Capture (`F-FINAL-05`):** Previous in-place upgrade over emulator-mode userdata left `shared_prefs/com.google.android.gms.measurement.prefs.xml` with `measurement_enabled=false` / `measurement_enabled_from_api=false`. Clearing app data via `adb -s emulator-5564 shell pm clear com.beewise.beewise` restored `App measurement collection enabled` cleanly.
- **App Check Hygiene:** Refreshed the single existing `BeeWise Final API35 emulator-5564` debug token entry on Firebase App `1:840483888286:android:50c11fbb460437ed6a2f8f` (1 stale deleted, 1 active created; no raw token UUID committed or printed).
- **Capture Configuration:** Temporarily set `debug.firebase.analytics.app=com.beewise.beewise`, `log.tag.FA=VERBOSE`, and `log.tag.FA-SVC=VERBOSE`, captured complete `adb logcat -v threadtime` output during real UI triggers on `/matching`, then verified complete bundle projection via [`scripts/inspect-bao-analytics.py`](../../../scripts/inspect-bao-analytics.py).

## Verified Native Upload Bundles (`HTTP 204, 0`)

| Bundle (Local UTC+7) | Trigger Flow on `/matching` | Events Logged & Uploaded | Sanitized Parameters | Transport / Privacy Check | UI Capture |
|---|---|---|---|---|---|
| `11-12 08:42:56.972` | Online Gemini Level 2 request (`Tìm gia sư Toán lớp 9 ở Thủ Đức...`) | `ai_request` | `feature="tutor_need"` | `204, 0` (`userIdPropertyCount=0`, guest mode) | [`ai-need-parsed.png`](ai-need-parsed.png) |
| `11-12 08:43:55.368` | Confirm parsed AI filters (`Xác nhận và tìm gia sư`) | `ai_result_accepted` | `feature="tutor_need"` | `204, 0` (`userIdPropertyCount=0`, guest mode) | [`ai-result-accepted.png`](ai-result-accepted.png) |
| `11-12 08:44:48.106` | Offline AI fallback (`Tìm gia sư Vật lý lớp 11 ở Quận 3` with Wi-Fi & Data disabled, then restored) | `ai_request`, `ai_error` | `feature="tutor_need"`, `kind="provider"` | `204, 0` (`userIdPropertyCount=0`, guest mode) | [`ai-offline-error.png`](ai-offline-error.png) |

## Receipt & Restoration Summary

- **Sanitized native upload receipt:** [`native-receipt.json`](native-receipt.json) (`completeBusinessBundles: 3`, `nativeUserIdRemovalAcknowledgements: 1`, `incompleteUploadsIgnored: 0`, `successfulUploadCount: 5`, `unexpectedParameterKeys: []`, `unsafeParameterValuesOmitted: 0`, `rawIdentityOrPayloadExported: false`).
- **Emulator cleanup verified:** `debug.firebase.analytics.app == ""`, `log.tag.FA == ""`, `log.tag.FA-SVC == ""`, Wi-Fi and cellular data restored.
- **Explicit boundary:** Native SDK protobuf upload payloads and `HTTP 204, 0` server upload acknowledgements are verified (`VERIFIED_NATIVE_UPLOAD_204`). A real-time Firebase Console DebugView UI screenshot for the `08:42–08:44` window on Analytics property `560584336` requires interactive browser authentication and is recorded honestly as `NOT_CAPTURED` in CLI (historical `export_report` Console captures from `2026-11-03` remain separate in `evidence/cloud/bao-acceptance-20261103/`).
