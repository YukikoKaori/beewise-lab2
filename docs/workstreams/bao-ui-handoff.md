# Bao → Nguyen runtime handoff — 2026-10-31

## Authenticated Profile failure — approved exception corrected

Owner explicitly authorized only this fallback plus regression/build/install.
Applied in `4b2e1ca`; six widget regressions PASS (three failed before the fix).
Same-signer APK from `9657d1b` installed with `-r`, preserving account A.
Actual restored Profile renders without the crash; managed logout returns to
guest, clears the inbox, and removes A's own device registration. No other
Nguyen UI/theme/router/ARTEMIS/review/presentation files were changed.

The failure investigation and proposed patch below are retained as history.

Actual account A Email/Password login after strict deployment created its parent
profile. After force-stop/relaunch, the SDK restored that session and registered
its Android installation. Opening Profile renders a real red error screen:
`Bad state: No element`. Evidence: private original
`D:/CodexTemp/beewise-lab3-tools/bao-runtime/auth-a-profile-after-restart.png` and
`evidence/android/logs/auth-a-profile-after-restart-*`.

Root cause in `lib/screens/beewise_screens.dart`: `user.displayName` is empty
(not null) for the provisioned/restored account. The current null-coalescing
fallback leaves `display` empty; `display.characters.first` throws. Profile and
managed logout are therefore FAIL/BLOCKED, not successful session UX.

At discovery, UI ownership was protected and no UI change had been applied.
Concrete minimal proposed replacement for the existing `final display = ...`:

```dart
final display = user.displayName?.trim().isNotEmpty == true
    ? user.displayName!.trim()
    : user.email?.trim().isNotEmpty == true
    ? user.email!.trim()
    : 'BeeWise';
```

This only makes the avatar source nonempty; no theme/router/layout changes.
If explicitly authorized, add a focused widget regression for null/empty/blank
identity fields, build/install with the same signing key without clearing data,
then rerun restored Profile and managed logout/account-switch runtime checks.

## Earlier guest runtime handoff

Latest app source `9ef5907`; authentic runtime now available on separate API37 AVD.
No UI/theme/router/ARTEMIS/review/final files were edited. Existing package/data on
original AVD preserved; no uninstall decision is needed for this separate device.

- Native 360dp and 412dp screenshots, fixture data, guest Profile, Search, matching
  disabled error and offline cached/recovered Home are in `evidence/android/`.
- Initial 2GB run: GMS SIGBUS; 4GB first boot: System UI ANR/slow startup. Stable
  rendered screens followed. These environmental failures must not be hidden.
- Profile non-fatal snackbar reports sending, but only device invocation was
  verified. Console delivery remains unverified; consider wording in UI ownership.
- Narrow 360dp labels wrap substantially; no RenderFlex overflow was observed in
  captured package logs. This is a limited smoke test, not full layout certification.
- Dedicated identity absent: login/logout/native Google picker/cancel/account
  switching and private business flows remain BLOCKED. No personal account used.
- RC live experiment/restoration passed; Console screenshots remain NOT RUN.
- ARTEMIS, external review, staging/payment and final presentation remain untouched
  and NOT RUN/BLOCKED. Reuse the per-service manifest; do not promote unit tests
  or the diagnostic snackbar to live backend proof.

Runtime follow-up: PID6589 was killed by Google Play services package update; tutor detail remains RETEST/BLOCKED. RC restored enabled/3 and guest Chats login gate have genuine screenshots. Device settings restored and isolated AVD shut down.
