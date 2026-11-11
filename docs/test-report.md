# Final validation report

Baseline: `9b669b47b95909a308d9221ca74b2e22e3fda92f`. The rubric is the owner-supplied nine-page PRM393 Final Assignment PDF. Lab 3 evidence remains historical.

| Gate | Actual result | Boundary |
|---|---|---|
| Mobile build and native startup | Runtime APK built and ran on API 35, 360 × 800 dp | Local emulator build precedes the final chat-link and stepper copy adjustments. Local rebuild with those adjustments ran out of host disk space; candidate Android build still requires exact-HEAD CI. |
| Mobile analyzer / tests | Clean; 180 tests passed | Includes offline typed AI contract tests, not provider proof |
| Core and Web analyzer / tests | Clean; 3 core and 1 web test passed | Web release build also ran in Chrome on local Hosting |
| Firestore Emulator | 75 passed | Role and ownership isolation, review/receipt coupling, listings, announcements, metadata-only PDF, VietQR and legacy compatibility |
| Legacy backend on Auth/Firestore Emulators | 86 passed | Uses test provider doubles, no real charge |
| ARTEMIS harness and startup scripts | 27 unique scenario definitions validated; 4 startup-script tests passed | No new ARTEMIS device suite; prior results retain their original scope |
| Web Google authorization | Emulator Google popup; denial without role, then staff Dashboard with three server counts and chart | Google OAuth, staff assignment and App Check on live Web not validated |
| Cross-role mobile ↔ Web | One local Android-originated application, genuine Web approval, Android status changed while session remained open; private receipt and common announcement both rendered | 0/3 deployed runs; do not infer latency SLA from UI polling |
| Native PDF | Android saved, opened in the system PDF viewer, and exposed one attachment in the share chooser. The app-private file matched the Firestore byte count; the server record contained only the seven metadata fields. A second parent had empty history after A signed out. | Synthetic parents and Firebase Emulator; no recipient selected in the share sheet |
| Gemini Level 2 | Typed schema, invalid output handling, confirmation/filtering and offline fallback tested | No authorized provider call; live outputs, config switches and live analytics pending |
| Deployment | NOT RUN | No production mutations or billing changes |

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

## Next verification

Confirm project/site, Google OAuth and App Check through read-only preflight. Obtain exact authorization for each cloud mutation and for the minimum genuine Gemini cases, then retain sanitized outputs and three independently timed deployed cross-role receipts. Run new ARTEMIS coverage with its own authorized scope.
