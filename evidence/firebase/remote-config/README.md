# Remote Config â€” actual integration

PASS local defaults/bounds/offline-fetch tests. PASS live conditional experiment
against `beewise-lab-3`, with the user's prior permission for temporary changes
and restoration. `../../cloud/remote-config-roundtrip.json` has actual API times:
empty original -> version 1 (home_tutor_limit=2, ai_result_limit=1,
ai_matching_enabled=false) -> original empty restored as version 2. ETag guards
reject concurrent changes; original template/ETag remain private on D.

Same APK, no rebuild/reinstall between before and after. Native screenshots:
`../../android/screenshots/corrective-412-profile-ready.png` (enabled, 3),
`corrective-412-rc-changed-profile.png` (disabled, 1),
`corrective-412-matching-disabled-result.png` (actual blocked submit),
`corrective-412-home-limit-two-bottom.png` (Home ends after second tutor).
Search remains independent (100-query limit) and is not claimed as Home limit proof.
Five-minute fetch interval respected by relaunch; no app data was cleared.

Device restored-default confirmation, if captured, is listed in the Android
manifest; API restoration is independently confirmed in live-management-state.
Console template screenshots remain NOT RUN. SDK unit tests alone do not establish
this live result. Reproduce only in an authorized coordinated test window using
`scripts/bao-remote-config-roundtrip.cjs` with the explicit experiment flag; always
restore, and stop rather than overwrite if the server template changed meanwhile.

Native restoration confirmed: `../../android/screenshots/corrective-412-rc-restored-profile.png` shows enabled/3 after refetch.
