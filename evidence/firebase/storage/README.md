# Cloud Storage / PDF

Implementation: `lib/services/export_service.dart`; source `db1f12e`.
BAO-A03 now requires terminal `TaskState.success` before asking for a URL.
PASS: real PDF generation with bundled Vietnamese fonts (15,919 bytes, PDF 1.5),
success/progress/owner path, cancelled/empty stream rejection, permission/network
error propagation; owner/cross-owner/guest/type/extension/10MiB rules tests.
Commands/results: `../../cloud/checks/verified/flutter-test.*`, `rules-test.*`.

`local-tutor-summary.pdf` is the unmodified output of the actual service test,
using explicitly synthetic **local-only** tutor data. It is not a displayed live
tutor, verified tutor, screenshot, bucket object or proof of an Android upload.
Download URL assertions use SDK mocks and do not prove a real accessible URL.

Live management API now confirms an empty bucket list, billingEnabled=false,
and no active Storage rules release. Real upload remains BLOCKED. Current Storage setup requires Blaze:
https://firebase.google.com/docs/storage/flutter/start . Do not upgrade billing.
External action: inspect existing bucket and approved lab alternative with project
owner/lecturer; if available, use dedicated identity and displayed authorized tutor,
capture progress, actual object path/URL and cross-account denial without exposing
bearer download links in public screenshots. No live files were created/deleted.
