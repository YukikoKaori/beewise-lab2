# Remote Config

Implementation: `remote_config_service.dart`, providers and matching/catalog
consumers. Source `db1f12e`. BAO-A02 bounds catalog limit to 1..100 and AI limit to
1..3 (handoff contract); nonpositive values use 6/3, blank model uses existing
`gemini-2.5-flash`. PASS tests cover defaults, valid changes, malicious/invalid
values, feature gate and offline fetch with defaults installed first.
Results: `../../cloud/checks/verified/flutter-test.*`.

Cloud template read: PASS, empty template with no parameters/version. Original
template/ETag saved privately on D. Temporary publish/restore and visible
two-behavior before/after: NOT RUN while latest native installation is BLOCKED.
No cloud value was changed. Native app's displayed value alone cannot distinguish a cloud
value equal to its default from actual fetch success.

External action: coordinate teammate test window; save original template/version
and ETag privately, compare before publishing only authorized test parameters in
`beewise-lab-3`; retain original and changed timestamps. Observe home count and
AI limit/gate in same APK after the 5-minute fetch interval/relaunch, plus offline
fallback. Restore only if the template still matches this test version; if another
person changed it, stop and coordinate instead of overwriting their config.
