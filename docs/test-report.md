# Final validation report

Baseline: `9b669b47b95909a308d9221ca74b2e22e3fda92f`. The rubric is the owner-supplied nine-page PRM393 Final Assignment PDF. Lab 3 evidence remains historical.

| Gate | Actual result | Boundary |
|---|---|---|
| Mobile build and native startup | EMULATOR_VERIFIED on API 35, 360 × 800 dp; prior [Android CI_PASS](https://github.com/YukikoKaori/beewise-lab2/actions/runs/43098665150/job/130784131580) on `62a4ba75ea271f99d142af40a9f900c31442cde4` | Emulator evidence uses the APK identified in the manifest, before this corrective. The earlier local rebuild ran out of disk; verify the corrective build on the exact PR HEAD. |
| Mobile analyzer / tests | LOCAL_TEST_PASS; 181 tests | Includes offline typed AI contract tests, not provider proof |
| Core and Web analyzer / tests | Clean; 3 core and 1 web test passed | Web release build also ran in Chrome on local Hosting |
| Firestore Emulator | 75 passed | Role and ownership isolation, review/receipt coupling, listings, announcements, metadata-only PDF, VietQR and legacy compatibility |
| Legacy backend on Auth/Firestore Emulators | 86 passed | Uses test provider doubles, no real charge |
| ARTEMIS harness and startup scripts | ARTEMIS_FINAL_DEFERRED; static harness and startup script checks only | No Final ARTEMIS execution, spend or new PASS evidence. Deferred submission requirement; not a code merge gate. |
| Web Google authorization | Emulator Google popup; denial without role, then staff Dashboard with three server counts and chart | Production Google sign-in and live Web UI revocation verified separately; direct Rules denial and Web App Check token path unverified |
| Cross-role mobile ↔ Web | One local Android-originated application, genuine Web approval, Android status changed while session remained open; private receipt and common announcement both rendered | Production: three distinct UI outcomes, not three approval repetitions; only CR-01 inbox owner-observed. Appendix C timing not measured. |
| Native PDF | EMULATOR_VERIFIED: Android saved, opened in the system PDF viewer, and exposed one attachment in the share chooser. The app-private file matched the metadata byte count; a second parent had empty history after A signed out. Corrective smoke reopened A's existing PDF after process restart. | Synthetic parents and Firebase Emulator; existing runtime APK and unchanged PDF code; no recipient selected in the share sheet |
| Gemini Level 2 | Typed schema, invalid output handling, confirmation/filtering and offline fallback tested | Three provider-backed Android confirmation screens and controlled offline recovery observed; raw JSON, serving-model metadata, live RC switch and Analytics receipts not verified |
| Deployment | Production Hosting and approved Firestore Rules deployed; VietQR index READY | Debug APK connected to production; release-device and App Check boundaries remain |

See the [local evidence manifest](../evidence/final/emulator/manifest.json) for receipt scope, runtime identities and hashes. Retest gates for production are in [final-deployment.md](final-deployment.md). Exact candidate CI is linked from the PR because CI observes a committed SHA.

## VietQR scenarios

| Scenario | Evidence |
|---|---|
| A. Confirm, claim and staff verify | Real Android created the chat and accepted the Web staff proposal; the class was absent after the claim. Web staff submitted a synthetic statement match, the invoice/review/bank reservation/class were verified together, and Android observed the update and opened the official schedule. The same verified invoice reopened after process restart. No real transfer or bank verification. |
| B. Unpaid/rejected claim | Emulator rejected with a reason, kept the class inaccessible, and allowed a new claim on the same invoice before expiry. |
| C. Unauthorized verification | Emulator denied parent, tutor, unrelated and revoked identities; also denied financial-field mutation and partial class activation. |
| D. Concurrent verification | Two emulator staff attempts yielded one valid transition and one class; reusing a bank transaction for another invoice was denied. |
| E. Legacy payOS | Existing verified invoice/class fixture remained readable; 86 legacy backend regression tests passed. No live provider call or charge. |
| F. QR correctness | Published NAPAS CRC/vector and two different invoice payloads passed. ZXing-C++ decoded the QR from the actual Android screenshot and independently matched the recipient, VND amount, transfer reference and CRC. The dummy recipient is not usable in banking; a bank app scan and real transfer remain unverified. |

## Review findings addressed

1. Approval without a notice could strand the applicant. One Firestore transaction writes the status and immutable receipt; Rules validate both final documents together and refuse forged, standalone or concurrent competing decisions.
2. Cached staff data could outlast role removal. The Web waits for a server role snapshot and uses a role-owned navigator so dialogs disappear when access is revoked. Firestore remains authoritative for writes.
3. Sending raw free text could disclose contact information to the model. The app extracts allowlisted academic hints, rejects invalid structured output, and routes to editable manual filters if AI cannot run.
4. Real emulator validation found that a label dropped the title of a general announcement and that approved status copy implied a public listing. Final labels now include the title and distinguish tutor access from public publication.
5. Corrective audit: direct-write regressions reject acceptance without the exact amount, verification with the wrong transfer reference, and verification with a missing or mismatched recipient. The staff-issued first class offer supplies the price; parent confirmation explicitly binds that price before QR display. Actual posted credit remains a staff decision, never a Rules assertion.
6. Corrective audit: the Level 2 parser rejects even schema-valid output values absent from the projected educational hints. Regression tests cover all six fields. No provider call was made.

## Next verification

See the [production receipt](../evidence/final/live-preflight/README.md) for the exact merge SHA, CI rerun, Hosting release, signed-out browser smoke, App Check configuration, and remaining live gates. That receipt describes earlier preflight stages. The later production UI results are linked below; bank-app scan evidence was not captured. The [VietQR owner guide](vietqr-owner-guide.md) explains scan-only testing.

See [Production cross-role evidence and run plan](../evidence/final/production-cross-role/README.md) for the current deployed scope, evidence and pending gates.
