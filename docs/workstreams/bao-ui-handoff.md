# Bao → Nguyen runtime handoff — 2026-10-31

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
