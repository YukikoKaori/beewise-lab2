# Bao cloud + Android status

**PARTIALLY COMPLETE**, 2026-10-31 local (receipts use UTC 2026-10-30).
Fetched PR #3 HEAD `18bd6d47a7d9135b3054217faef2dd4835be5976` before editing;
preserved its fixes. App source tested/built: `9ef5907b2d296fcdafaa869a53e9780692f4cc56`.
Subsequent commits change validation scripts/evidence/docs only. Final full HEAD
and newest-head CI are reported in the PR handoff; PR remains open, not merged.

| Task | Actual result | Remaining work |
|---|---|---|
| B-01 | PASS latest APK install/launch on isolated API37 AVD on D; native 360dp/412dp Home/Profile, Search data, matching gate, offline cached catalog and recovery | Auth session tests BLOCKED; initial 2GB GMS SIGBUS and 4GB System UI ANR/slow boot retained as environmental findings |
| B-02 | PASS six fixed-ID fixture audits and live guest SDK/native reads; deployed rules compared again | No dedicated identity (user confirmed); Google provider absent/SHA empty; rules/index deployment requires separate authorization |
| B-03 | PASS live RC conditional publish/restore and same-APK visible changes; permission UI, handled diagnostic and deliberate crash actually exercised | FCM delivery, Storage upload, seven DebugView events and Console Crashlytics receipt NOT RUN/BLOCKED |
| B-04 | PASS existing secure client/rules gates, all 27 emulator tests; fixture-only AI path negative test | Trusted processor, staff identity, payment provider and staging absent; no live business E2E claim |
| B-05 | Updated task/status/native/six-service manifests, authentic PNGs, sanitized PID logs and deploy/rollback preparation | Console screenshots, ARTEMIS, external review and final presentation remain NOT RUN/BLOCKED; Nguyen-owned files untouched |

New fix: synthetic metadata/known fixture namespace forces `[TEST]` name and
`verified=false` in the model; synthetic tutors cannot enter AI as real profiles.
Five new regression tests cover both metadata forms, metadata removal, genuine
profile preservation, and fixture-only service execution without initializing AI.
No cloud record was changed/deactivated/deleted by this fix. No hardcoded tutor
catalog was added to the submitted app. Existing six fixtures remain active and
clearly labeled/unverified; cleanup/isolation needs explicit authorization.

## Quality gates actually executed

`evidence/cloud/checks/corrective-final/` records exact commands, SHA, exits:
locked pub get PASS; formatter PASS (31 files, 0 changes); analyzer PASS (no
issues); Flutter tests **50/50 PASS**; isolated demo-project Firebase rules
**27/27 PASS**; real Android debug APK build PASS. Build retains future Kotlin
plugin migration warnings. Source did not change after these application checks.
Final-head GitHub Actions is verified separately in the PR/final handoff.

## Actual cloud state and constraints

See `evidence/cloud/live-management-state.json` and six-service manifest.
Correct project `beewise-lab-3`; no alternate project used. Email/password enabled,
anonymous disabled, Google provider CONFIGURATION_NOT_FOUND, Android SHA list empty.
No Storage bucket/release; billing disabled. Analytics linked, not DebugView proof.
Deployed Firestore rules hash still differs: missing FCM UID ownership, current
proposal/revision/expiry guards and reciprocal request/chat creation. Composite
index audit/receipts are separate from emulator tests. No malicious live write.
`bao-deployment-plan.md` has exact commands, preflight/READY-index checks and a
secure rollback policy. No rules/index/provider/billing/enforcement deployment.

Authorized RC experiment: original empty template -> version 1 (home limit 2,
AI limit 1, matching false) -> restored empty template version 2 with conditional
ETags. Device before/after shows 3->1 and enabled->disabled; submit is blocked,
and Home ends after two tutors. API confirms restoration; Console screenshot
still NOT RUN. Offline validation disables BOTH Wi-Fi and cellular; Wi-Fi alone
was insufficient. No identity or password was used or captured.

## Native environment findings

Independent `BeeWise_Bao_PR3_API37`, emulator-5558, API37 revision 6, 4096MB RAM,
software GPU, 2 cores, on D. Original emulator was shut down to free RAM; its
package/userdata were never uninstalled/cleared/copied. First 2GB run had native
SIGBUS through GMS Dynamite/dex verification; 4GB cold boot had System UI ANR and
slow first startup before successful app rendering. Do not attribute these to a
proven Dart defect or claim they were fixed by application code.
Windows C filled during paging; only the generated `.dart_tool` cache was moved
intact to D with a junction. No personal files deleted or system configuration
changed. APK/cache/toolchain remain on D. Raw logs/private config remain there.

Runtime follow-up: PID6589 was killed by Google Play services package update; tutor detail remains RETEST/BLOCKED. RC restored enabled/3 and guest Chats login gate have genuine screenshots. Device settings restored and isolated AVD shut down.
