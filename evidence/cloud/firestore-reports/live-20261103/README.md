# B-03.2 live acceptance — 03/11/2026 (UTC+7)

**B-03.2 PARTIALLY VERIFIED.** Generation → actual Firestore save → forced
server download → matching PDF bytes → Android preview works on the default
production entrypoint APK. A/B ownership denials are real live Client SDK tests.
This package does not promote unit tests or Emulator tests into native proof.

## Source, cloud approval and data

- Started from main `20a5ef1b9c1bf8208ad16f3c433bab94c556bc86`, after verifying
  PR #6/#7/#8 merged. Refreshed main `47fb375eceb6f741a3a4dba27242ad17c6aaee69`
  was merged without editing Nguyen's ARTEMIS changes. Integration source
  `80aa9fde20cd8a4dfc8f9f1d4ba1ab8836645d5d` passes local gates.
- Runtime fix commit `836807fc030461d4cec35c30e83e7eb1f9ebbafe`: exact-ID demo
  eligibility with `verified=false`, disclosure in discovery/detail/PDF, and
  Home fixture filtering before Remote Config's display limit. Previously six
  synthetic records consumed the query limit, hiding the seventh real demo.
  The query remains bounded to 100; this is not unbounded catalog pagination.
- Project: **beewise-lab-3**; package: **com.beewise.beewise**. Owner consent
  approves technical testing, not professional credentials or experience.
  `demo-profile-review.md`, `published-demo-payload.json` and
  `publication-receipt.json` record one create-only tutor and unchanged original
  six records. The demo is public catalog data, not an access-restricted audience.
- Owner separately approved **the exact diff and raw SHA256
  `94ef6ed2594ba4c6880c2b95fbaf75cb43fdb5bdbdeb5bf743d63389aa3d4428`**.
  See `demo-rules.diff`, `approved-demo.rules`, `deployment-review.md` and
  `demo-deployment.json`. Rules-only deployment and live readback succeeded;
  indexes and all non-report rules stayed unchanged. No Storage, billing,
  App Check, backend, FCM, Auth or Analytics identity changes.

## Native and server evidence

`native-install.json`: existing API37/Android17 AVD, `emulator-5560`, 412dp,
same signer, `adb install -r`, no clearing. Default `lib/main.dart` debug APK:
`9bec31e6135a7607c5336973f11a52ab13f34a1caa22e81ba14e8b3c1bba2bc4`.
The refreshed integration rebuild is **byte-identical** to the installed APK.
No diagnostic probe entrypoint was used.

| Requirement | Actual evidence/result |
|---|---|
| TC-PDF-01 | PASS: `native-home-demo.png`, `native-detail-demo.png`, `native-generated.png`, `native-original-pdf.png`; actual 19,315-byte `%PDF-1.5`, supplied fields and demo disclaimer |
| TC-PDF-02 | PASS: `native-server-saved.png`; actual transaction acknowledgement + forced server read, `live-client-security.json`; Console metadata in `console-native-report-metadata.png` |
| TC-PDF-03 | PASS: `pdf-roundtrip.json`; native download and independent Client SDK server decode match original SHA256 `8e8d5f2f2c565c45c00081afb944f69f0aa1151f754dfa6e1617aa5286ad0bfe`; genuine share sheet and Print preview, no external transmission/print job |
| TC-PDF-04 | PASS in tested scope: 13 live security/recovery checks, plus four final cross-owner read denials; native ordinary A logout → B login clears private UI; real pending SDK operation cancelled/reset immediately via production controller methods |
| TC-PDF-05 | PARTIAL: actual radio-off save fails without success, restored network/retry succeeds; real guest/cross-owner/immutable/oversize/corrupt denials. Distinct native application deadline and native guest-save UI remain unverified |
| Console | PASS: genuine project/tutor/report screenshots; owner match checked with Client SDK, no raw UID/Base64 published |
| Analytics | Genuine `debugview-upload-firestore.png`: upload_report → storage_backend=firestore. `analytics-native.json`: export_report (18 KiB, 2 subjects) and upload success after server timestamp. Export was inspected in DebugView, but a separate durable parameter screenshot was not captured |

Client security checks use normal Firebase JS Client SDK authentication with
in-memory persistence and actual live endpoints, never Admin SDK or an emulator.
For each identity, `getDocFromServer`/`getDocsFromServer` must report
`fromCache=false`, no pending writes, correct owner, timestamp, size and hash.
Foreign references, update/delete, guest reads and malformed creates must reject
with `permission-denied`. No raw credentials, UID, Base64 or signed URL is in the
public receipt. `final-server-inventory.json` is an additional **read-only** check.

## Failed controls and limits — preserved, not relabeled

1. JS `disableNetwork()` did **not** stop the transaction's direct RPC. The
   expected offline denial **FAILED**, creating one extra valid A-private report.
   It was preserved. Physical Android radio-off supplies the valid offline test.
   Final counts are **A=2/B=2**: A native + this control; B SDK isolation + native
   slow-network exercise. No pre-existing report was modified or deleted.
2. A 40-second emulator cellular latency control produced a native SDK
   `unavailable` error, not proof of the service's distinct timeout branch.
   `native-timeout-pending.png` proves only an actual pending download.
   Unit timeout/retry tests PASS; **native deadline/retry NOT VERIFIED**.
   Follow-up: on a settled device, preserve data, stall a real native server read
   beyond the existing 30-second deadline, capture the distinct timeout state,
   restore connectivity and retry the same owned report without creating another.
3. The first logout race sample ran before Android handled the logout tap;
   `native-switch-input-queue-observation.json` retains that preliminary FAIL.
   The controlled follow-up `native-switch-pending.json` observes the real future
   pending before/after production `AuthController.signOut`, operation cancelled,
   all private ReportController fields cleared. It does **not** prove completion
   of impaired-network signOut or inspection of every eventual callback.
4. On resume, existing AVD boot + host build activity showed a genuine **System
   UI** ANR dialog and high guest load (`resume-system-ui-anr.png`,
   `resume-environment.json`). ActivityManager's last-ANR buffer was empty.
   Neither suppression nor data clearing was used. Additional VM deadline
   instrumentation could not connect reliably. This is not a demonstrated
   BeeWise-specific main-thread defect or a fresh clean-start PASS.
5. Historical DebugView events expired before the later resumed session; the
   existing genuine screenshot is the durable upload receipt. Do not infer a new
   current Console permission check or export screenshot from that receipt.
6. Emulator-only debug APK; physical hardware, release performance and fresh
   ARTEMIS execution were NOT RUN here. Structural harness now has 27 scenarios.

## Quality and privacy

`quality.json`: pub get, format (42 files, zero changes), analyze, Flutter
**95/95**, rules **58/58**, debug APK build PASS on refreshed integration source.
Harness structural validation PASS; final HEAD Actions are linked in the PR.
Existing Flutter KGP migration warnings remain; no dependency upgrade was made.

Native screenshots are original ADB captures; Console/DebugView captures are
actual Chrome UI. Solid masks remove email, raw owner identifiers, Base64 and
Google avatar only. Some private report-path areas are masked; surrounding status
and buttons remain visible. No AI-generated or reconstructed UI evidence.
Private original PDFs/screenshots/full logs are retained locally outside Git.
`analytics-native.json` explicitly records interleaving from two log collectors;
its event facts are whitelisted, not a fabricated clean log bundle.

`files.json` hashes the published artifacts (excluding itself). No large generated
logs, duplicate APK, original PDF/Base64 or credentials are committed. Existing
historical evidence and Nguyen-owned files are preserved.

The implementation and separately approved rules are ready for scoped code
review; **do not mark B-03.2 COMPLETE** while the native deadline/recovery and
durable export DebugView evidence above remain incomplete. No automatic merge.
