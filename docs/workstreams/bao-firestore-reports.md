# Firestore Base64 PDF reports — 2026-11-02

## Live preflight after merged PR #6 — current

**B-03.2 BLOCKED; implementation remains IMPLEMENTED — LIVE VERIFICATION PENDING.**
Fetched main `f4fe42d5246d36c033cec27dc76a32bb5bf97d4f`; PR #6 is MERGED and
main CI is 3/3 SUCCESS. Actual project inspection found no deployed `/reports`
rules and **0 eligible tutors (6/6 synthetic)**. The current task explicitly does
not authorize deployment. No rules/index/catalog/report administrative write was
performed; no implementation defect was established and app source is unchanged.

The exact frozen bundle preserves all non-report live rules and the enabled chat
index, adds only report rules and the Base64 index exemption, and passes 57/57
Firestore Emulator tests. Clean baseline Flutter tests 91/91, format/analyze,
default APK build and structural harness pass. Actual same-signer default APK
install preserves existing API37 userdata; slow launches eventually render Home
and the empty catalog. This is not a native PDF save/download or fast-start PASS.
DebugView access works now; a new Firestore upload event remains unverified.

See [deployment proposal, approval gate, native results and per-case statuses](../../evidence/cloud/firestore-reports/deployment-plan-20261102.md)
and [fresh receipt](../../evidence/cloud/firestore-reports/preflight-20261102.json).
Historical PR #3/#6 receipts, including `manifest.json`, remain unchanged.
Owner approval of the exact bundle plus authorized eligible catalog data is needed
before live A/B generation/save/download/Console/DebugView acceptance can finish.

## PR #6 implementation record — historical baseline

**IMPLEMENTED — LIVE VERIFICATION PENDING.** Firebase Cloud Storage is replaced
by Cloud Firestore Base64 PDF persistence with mentor approval. This is
**owner-reported mentor approval** in the implementation request; no written
mentor artifact was supplied. V5 pp.8–10 originally required Cloud Storage;
that rubric remains historical context, with this approved project exception.
Do not call Cloud Storage verified or ask for Blaze/bucket provisioning.

## Baseline and scope

Fetched main `5df96fd3df995ea12747dcd218c418327d05db4c` before editing;
PR #3 and #4 were both MERGED, PR #5 also MERGED, and no open PRs were present.
PR #5's flutter-android [run](https://github.com/YukikoKaori/beewise-lab2/actions/runs/41444625946)
failed the two existing workflow semantics-handle tests. The same failure
reproduced locally. The test now releases its handle before Flutter's end-of-test
verification; assertions and workflow widgets are unchanged.

Fresh branch: `feat/lab3-firestore-pdf-reports`. Original workspace, emulator
userdata, Firebase project/client configuration and historical evidence remain
untouched. No live deploy, billing, bucket, App Check enforcement, backend,
catalog, FCM, Remote Config or Analytics identity change is included.

The old dependency chain was `firebase_storage` → `ExportService.upload` →
`exportServiceProvider` → `ReportController.exportAndUpload` → tutor detail/Profile.
SDK terminal-state tests, Storage rules/emulator configuration, the deployment
bundle helper and TC-11 also referenced it. Each active reference is replaced.
The inert bucket name in generated Firebase client options/google-services.json
is retained to preserve working client configuration; no Storage SDK uses it.
Historical docs/evidence retain their original statements and timestamps.

## Data model and limits

One immutable document: `reports/{authenticatedUid}/files/{autoId}`.

| Field | Contract |
|---|---|
| `ownerUid` | Current non-anonymous Firebase Auth UID; never a UI argument |
| `reportId` | Fresh Firestore auto ID, matching document ID |
| `tutorId` | Eligible catalog document ID, bounded ASCII identifier |
| `fileName` | `beewise-tutor-{tutorId}.pdf` |
| `contentType` / `encoding` | `application/pdf` / `base64` |
| `sizeBytes` | Original PDF bytes, 5–512,000 inclusive |
| `base64Data` | Canonical Base64, at most 682,668 ASCII characters |
| `createdAt` | `FieldValue.serverTimestamp()`; rules require `request.time` |

No email, password, token or unnecessary personal metadata is stored. The
existing PDF visual content/font/layout stays unchanged and uses the route's
Firestore `Tutor`. Local fixture exports remain local inspection only; cloud
save independently checks the actual tutor document in the transaction.
The tutor must be active, verified and non-synthetic, including namespace/ID
fixture guards. No client-created verified tutor is introduced.

Client checks the original file length, `%PDF-` header, encoded length and a
conservative document estimate (bounded strings/scalars plus 4 KiB overhead),
with a 768 KiB budget. This remains below Firestore's
[1 MiB document limit](https://firebase.google.com/docs/firestore/quotas).
No chunking is used. `files.base64Data` has a single-field index exemption,
following the [large-string guidance](https://firebase.google.com/docs/firestore/best-practices).
The proposed exemption is not yet deployed.

## Acknowledgement, download and cancellation

`saveReport` derives the current owner, encodes the local file and creates a
fresh document using a transaction: read absence, read eligible tutor, then set
with server timestamp. Existing IDs are rejected; create-only rules independently
prevent overwrite. [Transactions fail offline](https://firebase.google.com/docs/firestore/manage-data/transactions),
so this path does not queue a normal local-only document write.

After transaction acknowledgement, the service forces `Source.server`, rejects
cache/pending-write metadata, validates owner/ID/resolved timestamp, decodes and
compares exact Base64 with the original. Only then can `upload_report` or SAVED
appear. A successful local PDF/cache snapshot/toast is insufficient.

`getReport` and `downloadReport` accept only a report ID and derive the owner
again. Downloads force server reads, check canonical Base64, decoded byte length,
MIME/encoding/header, then write the exact bytes to an app-private temporary
directory. Each export/download has a unique directory to avoid stale writes
overwriting a later operation's file. The UI offers the native share/open sheet;
there is no fabricated public URL or Console-as-PDF link.

Network/permission failures expose retryable errors; the 30-second deadline
cancels further callbacks/retries. Operation identity plus raw Auth-stream
invalidation protects logout, account switch (including A→B→A), cancellation,
disposal and Auth stream errors. Explicit login/logout clears report state before
the existing auth/telemetry lifecycle proceeds. No FCM generation/journal or
Analytics ID ordering is changed.

Cancellation/timeouts cannot recall a server commit already in flight. Such a
document remains private to its original owner; the cancelled action never
publishes it under a new session. A retry after an ambiguous server response may
create a separate immutable report; no overwrite/delete is attempted. Reports
are not auto-deleted and no history/list screen is added to the existing flow.
Local files use app-private temporary storage; exporting via share is an explicit
user action, not a cloud public link.

## Rules and observability

Existing parent/applicant boundaries remain. Only the non-anonymous owner may
read; create uses `canWriteAsParent`, including `existsAfter` to reject an
application/report piggyback batch. Updates/deletes are denied even for the owner.
Rules validate exact fields, owner/ID, bounded identifier/filename, MIME, encoding,
positive integer size, Base64 length/alphabet/PDF prefix, eligible tutor and server
timestamp. No catch-all allow is added. Rules cannot decode a PDF or attest its
semantic correspondence to the catalog; full decoding/integrity validation is
client-side, while server bounds and access control are independently enforced.

`export_report` still means local generation. `upload_report` follows confirmed
server persistence and carries only `storage_backend=firestore`, integer
`file_size_kb`, `result=success`. No IDs, paths, names, PDF/Base64 or tokens enter
Analytics. Crashlytics gets a sanitized handled error and stack, not the SDK
exception which could contain a private document path. Seven previously verified
event types and Auth/FCM/Crashlytics/Remote Config behavior remain preserved for
their existing tested scope.

## Minimum Nguyen integration

Only the report controls in `beewise_screens.dart` change: tutor detail generates
locally, then offers explicit private cloud save; the same inline actions appear
in the existing Profile area. Stages are IDLE, GENERATING, GENERATED (local only),
ENCODING, SAVING, SAVED, DOWNLOADING, DOWNLOADED, ERROR. SAVING/DOWNLOADING use
indeterminate indicators, never invented percentages. Theme/router and unrelated
screens stay unchanged. TC-11 now checks server-save/download states and share
availability, without recording raw UID/path/PDF into its trace. No ARTEMIS
runtime success is claimed from harness collection.

## Verification and remaining live work

Local checks and source/artifact hashes are indexed in
[the migration manifest](../../evidence/cloud/firestore-reports/manifest.json).
The PR description records final HEAD, clean-tree reruns, exact CI and APK hash;
earlier dirty-tree development runs are not promoted to final-HEAD checks.

| Check | Evidence level / status |
|---|---|
| Real PDF generation with bundled fonts | Flutter test, synthetic local-only input |
| Byte-exact Base64 encode/decode/download | Dart service tests and real Firestore Emulator read/write |
| Server ack/cache/pending-write/timeout/error handling | SDK-boundary tests, not a live Firebase claim |
| Concurrent action, logout/switch/cancel/stale callbacks, telemetry | Controller/service tests |
| A/B owner positives and cross-UID read/create/update/delete negatives | Real `demo-beewise` Firestore Emulator rules tests |
| Anonymous/guest/applicant, schema/bounds, eligible tutor, duplicate ID | Emulator rules; existing workflow rules retained |
| Android default-entrypoint debug APK | Build gate; native report UI execution NOT RUN |
| Live upload/download/server hash/Console/new upload event | **NOT RUN** |
| Live A/B report isolation, offline/permission denial | **NOT RUN** |

Live prerequisites: explicitly approved reviewed Firestore rules/index release,
an authorized active/verified/non-synthetic tutor and dedicated test accounts,
an online Android device/emulator. No ADB device was online at audit. No live
rules deployment is authorized by this request; existing tutor fixtures cannot
be promoted to verified merely to obtain a PASS. No permanent users/catalog
records were created. Existing credentials are never committed or exported.

After approval: install the exact default APK preserving userdata; record SHA,
APK hash/device/time; A saves a permitted tutor PDF, confirm document in Console,
force server download, compare original/download SHA-256 and size, repeat under B,
verify both cross-UID reads and denied modification, test offline/permission
failure and retry. Keep private PDF/UIDs out of committed receipts; publish hashes,
redacted app/Console captures and outcomes. Do not upgrade B-03.2 to
**COMPLETE — FIRESTORE ALTERNATIVE VERIFIED** before those actual receipts exist.

The original v5 Storage task moved from owner-DEFERRED to
**APPROVED ALTERNATIVE — IMPLEMENTATION PENDING** on this owner instruction, then
to **IMPLEMENTED — LIVE VERIFICATION PENDING** after the implementation/local gates.
No written approval or live verification artifact is invented.
