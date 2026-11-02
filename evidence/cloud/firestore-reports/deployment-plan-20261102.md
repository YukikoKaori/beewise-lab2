# Firestore PDF live preflight — 2026-11-02

**B-03.2 BLOCKED; implementation remains IMPLEMENTED — LIVE VERIFICATION PENDING.**
This is a reviewed proposal, not deployment authorization or live PDF acceptance.
The owner explicitly requires a new approval for the exact bundle. No deployment,
catalog modification, report write, billing/Storage or App Check change was made.
Normal app initialization retains its existing telemetry/FCM behavior.

## Verified baseline

- Fetched `origin/main`: `f4fe42d5246d36c033cec27dc76a32bb5bf97d4f`.
- PR #6 MERGED: head `2c36b750e3570758d8ccbf0877bc37a78243d619`, 29 changed files;
  its merge is this main SHA. No newer main commit or open PR at inspection.
- Main [Actions 41478805430](https://github.com/YukikoKaori/beewise-lab2/actions/runs/41478805430):
  flutter-android, firebase-rules and e2e-harness all SUCCESS at that exact SHA.
- Project `beewise-lab-3`, default Firestore database. Read-only Rules API/CLI
  inspection at `2026-11-02T16:18:49.027Z` found release ruleset
  `projects/beewise-lab-3/rulesets/2aff57c1-3693-4bfa-9cd2-d77471ef08d6`.
- Live normalized rules SHA256:
  `759a35e408204bff48dac1f380009b76a661b39c4f649d809322643c616f6578`.
  There is no live `/reports` match. Raw baseline bytes and full snapshots are
  retained privately; sanitized facts/hashes are in [the receipt](preflight-20261102.json).
- Live CLI index inventory: one chat composite, no field overrides. Actual Console
  Manual index view also shows `chats`: parentId ASC, updatedAt DESC, __name__ DESC,
  **Enabled**, one of one. No index mutation was attempted.

## Exact proposed bundle

Frozen directory (private, preserved):
`D:/CodexTemp/beewise-lab3-tools/pdf-live-private/firestore-pdf-20261102`.
The receipt contains all six file hashes, baseline and test command.

| File | Raw-byte SHA256 |
|---|---|
| firestore.rules | `efe69df620ef13f5eadc5af18c62f7ffdc7f0a861ed03f311a9dd16dd93741b5` |
| firestore.indexes.json | `f7774cfccd6108b2f2f92da3841e98701d8630d05160c425fa938fd2b49e29b5` |
| firebase.deploy.json | `858e30724765b212940de948a67e05865947e9568a52a4de1d77e22f3a1b4bfe` |
| rules.test.cjs | `70c3474f325dfcd2f579b2b9bf8092835de1a810d2de7eaeadf9b2eaf97fea6d` |

Rules are byte-for-byte the merged repository source. After LF normalization,
removing only the new immutable report block reproduces the current deployed
rules exactly. Thus parent data, applicant/existsAfter boundaries, FCM device
ownership, cross-UID protections, chats/requests, trusted consultant workflows,
invoices, payment and schedule restrictions have no proposed changes.

The report block permits only a non-anonymous parent to create/read own bounded
PDF metadata/content, requires an actual eligible tutor and server timestamp,
denies applicant piggyback batches, and denies all updates/deletes. The client
forces a server read and validates exact returned content before success/event.
Rules cannot attest the complete PDF semantics; the existing client checks remain.

[Reviewed index file](deployment-indexes-20261102.json) retains the **exact live**
chat composite, including its implicit `__name__` and `SPARSE_ALL` density. Only
`files.base64Data` receives an empty single-field index exemption. This is an
indexing change for that field in the `files` collection group, not extra read or
write permission. No collection/index deletion is proposed. The original prepare
helper is historical (expects empty indexes and October baseline); it was inspected
and deliberately not run against today's state.

## Checks and deployment procedure

Clean baseline local checks: pub get, format (41 files/zero changes), analyze,
Flutter **91/91**, rules **57/57**, default APK build and structural harness
**26 scenarios** PASS. Android harness scenarios were NOT RUN. The frozen bundle
also ran all **57/57** real Firestore Emulator tests on `demo-beewise`; this covers
A/B server-read positives and foreign read/create/update/delete negatives,
guest/anonymous/applicant denial, schema/size/corruption and existing workflows.
These are emulator results, not actual-project authorization proof.

`verify-bao-firestore-bundle.ps1 -Bundle ...` was rejected by the host's PowerShell
script policy. The same hash checks and direct Firebase CLI emulator command were
then executed successfully through Python; no execution policy was changed.
Full logs stay private and command/exit/timing receipts are committed.

Before a separately approved deploy, refresh live rules/index inventory and abort
on any baseline drift; re-hash every frozen file. Do not rebuild/overwrite the
approved bundle or infer approval of a different hash. Proposed command **NOT RUN**:

```powershell
Set-Location -LiteralPath 'D:/CodexTemp/beewise-lab3-tools/pdf-live-private/firestore-pdf-20261102'
rtk proxy node D:/CodexTemp/beewise-pdf-live-validation/firebase/node_modules/firebase-tools/lib/bin/firebase.js deploy --project beewise-lab-3 --config firebase.deploy.json --only "firestore:rules,firestore:indexes" --non-interactive
```

After approval/execution: retain exit/log receipt, reread active ruleset and compare
normalized bytes, verify existing chat index and field exemption state, and perform
safe client positive/negative controls. A successful CLI exit alone cannot close
B-03.2. If the CLI proposes any unexpected deletion or conflict, stop.

Rollback proposal requires separate authorization: restore **rules only** from
`previous-deployed-firestore.rules` (raw SHA256
`c1dad4250814abcf0c80adb940dc612dbee133db0e80574fd0d055c5dcf86bb8`).
It is today's strict baseline, not the older insecure bootstrap rules. This
disables report access again while preserving all other protections. Retain
existing report documents and the Base64 index exemption; do not delete data or
force PDF reindexing. Prepare/review a rules-only rollback config if needed;
neither rollback nor ruleset release switching has been performed.

## Permitted data prerequisite

Read-only complete tutor inventory: **6 total, 6 synthetic, 0 eligible**. Eligibility
uses the same active/verified flag, synthetic flag, fixtureNamespace and
`bao-lab3-` ID guards as the merged model/rules. Only counts and hashed eligible IDs
(none) are exported; names, IDs and document content are not published.
The default native Home independently shows the empty eligible catalog.

Safe next step: owner/trusted catalog staff selects a real, consenting tutor and
supplies validated public profile fields, qualification/verification provenance,
active/verified decision and permitted test usage. Review the exact proposed new
record and target project before any trusted write. Do not promote the six
fixtures, invent a verification claim, create an account or mutate a customer.
A separate staging project with legitimately approved catalog data is an alternative,
but its success must be labeled staging and does not prove this project's behavior.
Existing authorized A/B accounts can be used after these gates; no new credentials
are needed for this preflight and none are committed.

## Actual Android and Console scope

Existing `BeeWise_Bao_Startup_API37`, Android 17/API37, two vCPUs, 2048 MiB,
software GPU, existing effective 412dp display. Flutter 3.47.8 / Dart 3.13.7.
Default `lib/main.dart` debug APK from the baseline was installed with `adb install -r`;
installed/new signer hashes match. APK SHA256:
`da4ea48f308475eed228da76e9062dfa3aa8917deeeb15cb8dda3bacdd2378d6`.
No uninstall, userdata clear, display change, diagnostic entrypoint or ANR suppression.

Two actual cold process launches had `am start -W` timeouts, followed by Android
Displayed/Fully drawn at **32,733 ms / 13,922 ms**. Initial UI dump failed and the
[early splash](native-early-splash-20261102.png) is retained. Later direct UI dump
and [Home screenshot](native-empty-catalog-20261102.png) confirm rendered Home and
empty catalog. Both last-ANR snapshots say no ANR since boot. Guest load average
was 28.29/15.42/6.07; main wait channels were futex then epoll. `/proc` stack access
was denied. This does not establish a BeeWise defect or fast-start PASS; no new
startup fix was guessed. Full logs/dumps remain private with hashes in the receipt.
Flutter engine first-frame timestamp was not independently measured in this run.

Actual Console DebugView renders successfully, with **no missing-permission page**;
initial inspection showed zero devices/events in the preceding 30 minutes.
That proves access, not a new export/upload receipt. The Console index view and
Spark badge were inspected without changing settings. No unredacted identity or
document screenshots are published. No report document exists from this run.

| Live test | Result |
|---|---|
| TC-PDF-01 A generates from eligible tutor; native header/length/content | **BLOCKED**: no eligible tutor, no diagnostic/fixture substitution |
| TC-PDF-02 save/server ack/report ID/Console document | **BLOCKED**: deployment approval and eligible tutor |
| TC-PDF-03 server download/hash/open | **BLOCKED**: no permitted saved report |
| TC-PDF-04 live A/B read/update/delete and logout visibility | **BLOCKED**: no positive report controls; emulator result is separate |
| TC-PDF-05 no network | **NOT RUN** native; SDK-boundary coverage only |
| TC-PDF-05 permission denied | **NOT RUN** native; SDK-boundary/emulator coverage only |
| TC-PDF-05 missing auth | **NOT RUN** native; SDK-boundary/emulator coverage only |
| TC-PDF-05 account switch during operation | **NOT RUN** native; controller/service coverage only |
| TC-PDF-05 corrupt/oversized PDF | **NOT RUN** native; service/emulator coverage only |
| TC-PDF-05 timeout/retry | **NOT RUN** native; service/controller coverage only |
| New export_report / upload_report(storage_backend=firestore) in DebugView | **NOT RUN / BLOCKED**; no confirmed live generation/save |

Auth, FCM generation/journal/role checks, Analytics identity, Crashlytics, Remote
Config, existing Firebase client configuration and all app/UI source are unchanged.
The existing regression suite passed; this run does not renew every historical
native service acceptance claim. PR #3/#6 evidence and the original migration
manifest remain immutable. Whole Lab 3 is not complete.

## Approval requested, not assumed

Approve deployment to **beewise-lab-3** of the exact rules/index/config hashes above,
limited to `firestore:rules,firestore:indexes`, subject to a fresh no-drift check.
Separately identify an already authorized eligible tutor or approve review/preparation
of a concrete trusted new catalog record; this proposal authorizes no record write.
Only after both prerequisites can the genuine A/B Android PDF/Console/DebugView
acceptance sequence run. The current evidence PR is documentation/preflight only.
