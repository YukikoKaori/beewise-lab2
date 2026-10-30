# BeeWise Lab 3 corrective execution report

**FINAL VERDICT: PARTIALLY COMPLETE. DRAFT - runtime/cloud evidence missing.**
Execution date: 2026-10-30 (Asia/Bangkok). Initial workspace was clean; fetched
main matched HEAD `dd8b0e165039886b52b08cab81e17dd08c4af7ff`.
PR #1 base `9023547265bbe402d5aecbe54942482087bff068`, head
`6c4ff370a771375846f50e2599c2251c0eed7322`, merge equals current base.
GitHub API returned no reviews or review comments; original JSON is in evidence.
**EXTERNAL_REVIEW_NOT_AVAILABLE**. Codex self-review is internal static review.

## Implementation inventory

| Module | Classification | Verified scope / missing integration |
|---|---|---|
| 12-screen Lab 2 client | Implemented in source | Routes, Vietnamese copy, Figma theme retained; device layout unverified |
| Tutor discovery / AI | Partial | Active catalog adapter and validated AI IDs; live data/App Check/AI outcome not tested |
| Parent Auth/profile | Partial | Authenticated retry after partial registration, no account deletion; live providers not tested |
| Tutor applications | Partial | Pending/private/create-only rules tested; real Auth submission and staff approval backend unverified |
| Notification inbox | Partial | UID v2 storage and recipient gate tested; FCM delivery/OS shade/device reassignment unverified |
| Connection/chat/workflow | Partial | Atomic links, parent response gates tested; trusted consultant consumer absent |
| Invoice/payment/schedule | Blocked | Client cannot self-verify; trusted issuance/receipt verification backend absent |
| Storage PDF | Partial | PDF adapter present, owner/type/size rules tested on emulator; real bucket/upload recovery unverified |
| Analytics/Crashlytics/Remote Config/App Check | Partial | Adapters/configuration present; console/service outcomes unverified |
| Android | APK PASS / runtime blocked | CI debug APK built and inspected; no connected device/AVD |
| ARTEMIS | Ready to collect / execution blocked | 26 cases collect; no online device, host, keys or safe staging fixtures |

## Environment and reproducible results

The original machine uses Flutter 3.47.3/Dart 3.13.3 and Java 8; its first
`flutter pub get` failed SDK resolution. Android SDK exists at `D:/Android/SDK`
but was not discovered from the original environment. `adb devices -l` returned
no connected devices and `emulator -list-avds` returned no configured AVDs.
Portable Flutter 3.47.8 / Dart 3.13.7 (tag `737ba8f885...`) and Temurin
21.0.13+9 were prepared under `D:/CodexTemp/beewise-lab3-tools`. New pub,
Gradle, Firebase emulator, npm caches and build output use drive D. System
PATH/registry were not changed. Local Node 25.9.0 emits a dev-server engine
warning; CI uses supported Node 24. Python 3.12.10 collected the pinned SDK.

| Command | Result | Native exit | Evidence |
|---|---|---|---|
| `flutter pub get` (3.47.8) | PASS | 0 | `evidence/corrective/pub-get.log` |
| `dart format --output=none --set-exit-if-changed .` | PASS | 0 | `format.log` |
| `flutter analyze` | PASS, no issues | 0 | `analyze.log` |
| `flutter test --reporter expanded` | PASS, 8 tests | 0 | `flutter-test.log` |
| `npm --prefix firebase test` | PASS, 26 real emulator tests | 0 | `rules-test.log` |
| `npm audit --prefix firebase --json` | PASS, zero vulnerabilities | 0 | `npm-audit.json` |
| `python scripts/check_e2e_harness.py` | PASS, offline structure only | 0 | `harness.log` |
| `pytest ... --collect-only -q` | PASS, 26 collected; 0 executed | 0 | `e2e-collection.log` |
| `run-artemis.ps1` without prerequisites | BLOCKED as intended | 2 (rtk launcher 1) | `artemis-preflight/run-manifest.json` |
| `flutter build apk --debug` (CI) | PASS, APK downloaded and inspected | 0 | `apk-ci.json`, `ci-code-sha.log` |
| Local build on original C checkout | FAIL, Kotlin cache registration | 1 | `apk-build.log` |
| Android install/launch/360dp/412dp/screenshots | NOT RUN | n/a | No online device/AVD |
| Live Firebase/backend/ARTEMIS | NOT RUN | n/a | No authorized integration resources |

All short evidence paths above are relative to `evidence/corrective/`. The
execution manifest records tested source SHA and hashes. Earlier failing
iterations included SDK mismatch, external node_modules analyzer discovery and
incorrect test mock generic stubs; these were corrected, not ignored.

## Loopback/build diagnosis

The prior run's JDK 17 loopback error is a historical claim, not reproduced
here. With portable JDK 21, Gradle 9.3.1 opens a real 127.0.0.1 daemon connection,
and both Firebase emulators start and execute tests. No firewall, registry,
App Check or security policy was disabled. A thread dump locates the quiet
Android build in `LegacyDownloader.downloadFully` while installing the required
NDK 28.2.13676358. The original C/junction build later failed with Kotlin cache registration errors;
a separate clean checkout on D is recorded in `apk-build-drive-d.log`. CI built
the APK successfully on Linux. This evidence
does not prove the original machine's historical root cause.

## Verified CI and APK provenance

All three jobs passed at source `114d682c17098f7b96255c42eb3b8aa4ffeb66fc`:
[Actions run 41016040254](https://github.com/YukikoKaori/beewise-lab2/actions/runs/41016040254).
The downloaded APK is `com.beewise.beewise`, version 0.1.0 (1), minSdk 24,
targetSdk 36, 187241891 bytes. SHA256:
`873135f99155add93bbb4711a2adf09dec60c6331083e2106a0482ea25f914e3`.
It is saved on D; binary output is not committed. Final documentation/artifact
commits do not change tested application source. The final PR check must also
be green at its actual head SHA.

## Security corrections and audit

See [review traceability](code-review.md), [backend contract](backend-contract.md)
and the checked-in regression tests. Local notification storage rejects other
UIDs and ownerless pushes, ignores ownerless legacy history and bypasses stale
preference caches. Android OS-visible notification payloads still require
non-sensitive content and backend installation ownership checks.

Registration retries authenticate the same email/password and only reconcile a
missing parent profile; existing parent/applicant records are not overwritten.
No existing account is deleted. Proposal rules validate same-chat consultant
message, pending status, current pointer, expiry, ownership and one immutable
response; trusted state remains server-owned. Reciprocal connection batches and
batched role exclusion are exercised with getAfter-aware tests.

Emulator tests are not production deployments or App Check integration tests.
Storage rules enforce metadata, not cryptographic PDF validation. Admin SDK
code bypasses rules and must implement the contract itself. Parent/applicant
role and payment invariants must be enforced in that server code before release.

## Evidence still required and exact resume actions

1. Use JDK 21 + Flutter 3.47.8; run `scripts/verify-lab3.ps1 -Flutter <path>
   -Rules -Android`. Inspect CI linked to the latest corrective SHA.
2. Owner supplies an already licensed/configured test Android emulator or device.
   Confirm `adb devices -l` is online; install built APK, record SHA256 and test
   all 12 screens at 360dp and 412dp, font scaling and keyboard insets.
3. Owner supplies a dedicated Firebase test project/accounts, permitted provider
   configuration, controlled tutor data, OAuth/App Check settings and a Storage
   bucket if already authorized. Do not change billing or accept terms here.
4. Staging team implements [trusted contract](backend-contract.md), including
   proposal expiry/current pointers, idempotent consumers, real verified receipt
   handling and schedule creation. No staging endpoint is available in this repo.
5. Start ARTEMIS with local keys and authorized device/data; run 21 automatic
   Flash cases x3, four manual-setup cases x3, and TC-25 Pro separately. Preserve
   original traces/replays and verify JUnit against observable state.
6. Obtain human/external review if required by the lab. No polling or synthetic
   transcript substitutes for external review. Finalize the DRAFT PDF/slides
   and capture the [demo](demo-script.md) only after actual evidence exists.

No production resource, billing, provider terms or user data was changed.
Release readiness: **NOT READY** until Android runtime, cloud integrations,
trusted backend, external review and device evidence are verified.
