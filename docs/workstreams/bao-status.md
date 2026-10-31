# Bao cloud + Android status

## Approved deployment and authenticated runtime follow-up (current)

Owner approved and the exact frozen Firestore rules/index bundle was deployed.
Preflight hashes/baseline unchanged; **28/28 frozen rules tests rerun PASS**.
Index reached READY before rules release; both CLI exits 0. Live rules now match
repository hash `759a35e...`, ruleset `2aff57c1-3693-4bfa-9cd2-d77471ef08d6`,
including the missing own-application match. Four real guest private-read denials
and public server tutor reads PASS; these are not authenticated cross-UID tests.

Account A actually signed in after deployment and created its parent profile.
Cold-start restored its Auth SDK session and registered its own Android device.
Profile then exposed `Bad state: No element` for a blank restored display name.
Owner granted an explicit exception for that fallback only; correction committed
with six widget regressions (before: 3 FAIL; after: 6 PASS). Full Flutter **59/59**,
format/analyzer and APK build PASS. Same-signer install preserved A; restored
Profile and managed logout PASS. A registration removed and guest inbox empty.
B login/profile/restore/logout and visible inbox isolation PASS; same installation
belongs only to B after explicit retry, then neither account after logout. B
automatic registration initially stalled pending; manual retry recovered it.
Keep that reliability finding open. Fresh new-APK 360dp/412dp PNGs and guest
offline cache/reconnected Search captured; device settings restored. Real foreground/background/process-death FCM
delivery and Search routing PASS; malformed/inaccessible routes rejected.
No other Nguyen UI/theme/router/ARTEMIS/review/final files changed.

The owner-supplied Google config update was preserved (same project/app/client
key; one web OAuth client). Google provider became enabled externally; Android
SHA remains absent in the latest inspection, so Google login is not verified.
Storage/billing unchanged. Console/DebugView receipts, staging, trusted
backend/provider, ARTEMIS and external review remain NOT RUN/BLOCKED.

Deployment receipts and exact scope are in `bao-deployment-plan.md` and
`evidence/cloud/authorized-deploy-*.json`; account metadata snapshots are
`evidence/cloud/test-users-*.json`. No passwords/tokens requested or exported.

## Earlier readiness snapshot (superseded by approved deployment above)

## Auth provisioning follow-up — 2026-10-31

**PARTIALLY COMPLETE.** Fetched PR #3 HEAD
`f0fd2f73c5e8aa39bb5626169d5d0c9d1ea1e882`; preserved existing fixes.
This section supersedes historical statements below about missing test users.

| Task | Current evidence | Remaining blocker |
|---|---|---|
| B-01 | Installed base APK hash matches the existing current build; fresh cold launch Status ok, Home 360dp and guest Profile 412dp PNG/XML/PID logs | System UI ANR on boot retained; parent login/logout/session restore/isolation NOT RUN |
| B-02 | Two enabled password identities verified using server-projected metadata only; six synthetic tutors re-audited; deployed rules lack tutorApplications match | Explicit owner permission for frozen rules/index deployment pending; Google provider/SHA still absent |
| B-03 | Fresh read-only six-service management audit; previous real RC publish/restore remains valid | Authenticated FCM/Storage and Console receipts remain NOT RUN/BLOCKED; no credentials used |
| B-04 | Original 27/27 rules PASS, extended 28/28 PASS in repo and exact frozen bundle; 6/6 Auth mocks and 53/53 full Flutter tests PASS | These do not prove live Auth; trusted payment/staff/backend/staging still absent |
| B-05 | Updated readiness, frozen deployment manifest, native evidence and status; formatter/analyzer PASS | Latest pushed HEAD/CI reported in handoff; ARTEMIS/external review/final presentation NOT RUN/BLOCKED |

Root cause: Auth reads its own `tutorApplications/{uid}` before parent bootstrap.
The deployed rules deny that read even for an absent document. Repository rules
already allow the strict owner lookup; retain fail-closed client behavior.
New tests cover missing-own-document bootstrap, cross-UID denial, ordered parent
creation, role lookup permission denial and applicant separation. No app source
or rules were weakened. No shared deployment or account login was performed.

Receipts: `evidence/cloud/auth-provisioning-readiness.json`,
`prepared-firestore-deployment.json`, `checks/auth-provisioned-20261031/`
(original 27), `checks/auth-bootstrap-regression/` (28),
`checks/auth-frozen-bundle/` (28), `checks/auth-bootstrap-final/` (53).
Exact commands/preflight/secure forward-repair policy: `bao-deployment-plan.md`.
Device evidence: `evidence/android/auth-ready-runtime.json`.

## Previous corrective delivery (historical)

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
Deployed Firestore rules hash still differs: missing applicant separation for parent/device writes, current
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
