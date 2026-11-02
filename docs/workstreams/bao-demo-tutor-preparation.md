# One owner-consented demo tutor — preparation only

Prepared **03/11/2026 (Asia/Bangkok)**. **LOCAL PROPOSAL ONLY — NOT PUBLISHED.**
No live Firestore write, import, deployment, account creation or catalog approval
is authorized by this task. No PDF live test is claimed.

## Baseline and existing catalog

Fetched latest `origin/main`: `a5d2a5ec9f949d7a3d247a30198b2fcdb5da935c`.
PR #6 is the merged Firestore PDF implementation. PR #7 is MERGED, head
`219a8981d286236d78dff6cd580247fe53197fc2`, merge equal to this main SHA.
Its [deployment receipt](../../evidence/cloud/firestore-reports/deployment-20261102.json)
records the separately approved rules/index deployment; that permission does not
authorize any tutor write in this run.

Fresh read-only inventory at `2026-11-02T17:14:24.363Z`
(03/11, 00:14:24 Asia/Bangkok): **6 tutor documents, all 6 synthetic, 0 eligible**.
The proposed ID was absent across the complete inventory. The public receipt
exports only counts, the new random ID and a hash of document names/update times;
no existing document data, raw UID or credential. Existing fixtures are unchanged.
See [local preparation validation receipt](../preparation/demo-tutor/validation.json).

Inspected the actual Tutor model/repository, providers, tutor UI/card consumers,
ExportService, ReportData, Firestore rules, design traceability, backend contract,
Firestore workstream, fixture seeder source and relevant tests. No seeder was run.
`design-traceability.md` contains older deployment/Storage status; it is used for
screen mapping, not as current live-release evidence. Nguyen-owned files are unchanged.

## Exact proposed document

Proposed path: **`tutors/tutor_acd3824aa8734c63ac8827df`**.
The ID is an opaque random catalog identifier, not an Auth UID or personal ID.
It matches the report tutor-ID bound `[A-Za-z0-9_-]{1,128}`, does not use the
reserved `bao-lab3-` prefix, and must be checked again immediately before any
later create-only write. It is proposed, not reserved or published.

The only document payload is
[the JSON proposal](../preparation/demo-tutor/tutor_acd3824aa8734c63ac8827df.proposal.json):

Raw file SHA256: `b3d203fc495d92fa347a2ebb7efd37355965142872d0b479cfc28ca3011b690a`.
Canonical UTF-8 JSON SHA256 (sorted keys, compact, Unicode preserved):
`51f3d67b68f04c5b7cb22c2e15df5f6fca711cfd574e7a6e14a01230390ee3dc`.
These identify the proposal, not authorization; changing flags/content changes the
approved input and requires a new review.

```json
{
  "name": "Hoàng Quốc Bảo",
  "subjects": ["Toán", "Tin học"],
  "grades": ["6", "7", "8", "9", "10", "11", "12"],
  "hourlyFee": 150000,
  "areas": ["TP.HCM"],
  "experienceYears": 3,
  "teachingModes": ["in_person"],
  "introduction": "Sinh viên Công nghệ thông tin, nhận hỗ trợ học sinh lớp 6–12 học Toán và Tin học. Hình thức dạy trực tiếp tại TP.HCM. Nội dung và lịch học được trao đổi trước khi bắt đầu.",
  "credential": "",
  "availability": "",
  "verified": false,
  "active": false
}
```

The eight substantive profile values are copied exactly from the owner's request.
Fee is an integer, interpreted by the existing app as VND/hour. Grades are strings;
`in_person` is the existing mode token, not a newly inferred teaching format.
Name, student status and three years' experience are **owner-provided claims**.
They are not independently verified qualifications or a staff endorsement.
No longer introduction is needed by the public Tutor model or PDF generator;
the supplied text is preserved without a draft expansion.

| Field or omission | Actual application expectation / preparation choice |
|---|---|
| `name`, `introduction`, `credential`, `availability` | Strings; model permits empty strings. Owner text used for first two; latter two empty, unresolved. |
| `subjects`, `grades`, `areas`, `teachingModes` | Lists of strings; copied exactly. No new subject/area is inferred. |
| `hourlyFee`, `experienceYears` | Integer values 150000 and 3, supplied claims. |
| `active`, `verified` | Booleans, both false. Consent does not enable either flag. |
| `rating`, `reviewCount` | Both omitted. Model returns null rating/default zero count; this is a rendering default, not evidence of zero reviews. No rating UI appears without a rating. |
| `avatarUrl` | Omitted; existing app fallback applies. No photo generated. |
| `syntheticTestFixture`, `fixtureNamespace` | Both omitted because this is real owner-supplied information, not fabricated fixture content. Their absence grants no validation/approval. |
| `id`, UID, email, phone, university, degree, timestamps, consent/approval flags | Not added to the catalog payload. Document ID is supplied by its path; no account or unprovided personal/qualification details inferred. Consent/review provenance belongs in a separately controlled review record. |

This is the **public catalog** model, not `tutorApplications/{uid}`. The private
application schema separately requires contact, qualification, availability,
consent and pending-state fields. This proposal does not satisfy that onboarding
contract, bypass it, create an application/account, or invent its missing values.
Public tutor writes are always denied to mobile clients; only an explicitly
authorized trusted publishing operation could create a catalog document later.

## Visibility and PDF eligibility

| Surface | Actual conditions and outcome for this proposal |
|---|---|
| Home | Repository queries `active == true`, then provider removes synthetic profiles. This inactive proposal is not returned. Verification is not itself a Home query condition. Remote Config limits results. |
| Search | Same active query, at most 100, excludes synthetic profiles, then filters query/subject/area/mode/fee locally. Supplied strings/fee are compatible; inactive proposal remains absent. |
| Tutor Detail | Public rules read only `active == true`; `tutorById` also rejects inactive/missing docs. Proposal cannot be opened through the normal live route while inactive. |
| Local PDF generation | `buildTutorSummary` can format a supplied Tutor; it does not independently establish eligibility. Empty availability becomes the existing PDF placeholder; Detail uses “Chưa cập nhật”. Local generation is not live cloud acceptance. No PDF generated from this proposal in this run. |
| Firestore PDF save | Current non-anonymous parent and valid report required; actual tutor must be active, verified and non-synthetic. This proposal fails both active and verified gates. |

`Tutor.fromMap` marks a profile synthetic when the flag is true, a trimmed
nonempty `fixtureNamespace` exists, or the ID starts `bao-lab3-`. It forces
verified false and a visible `[TEST]` name; provider/matching filters exclude it.
Report rules independently require active/verified true, a non-reserved ID, a
missing-or-false synthetic flag and missing-or-exactly-empty namespace. Whitespace
namespace values are not a safe workaround: rules require exactly empty when set.
Do not remove/alter the six existing fixtures' markers or weaken any guard.

`ReportData` remains unchanged: original PDF 5–512000 bytes, canonical Base64
bounded to 682668 characters, document estimate below 768 KiB. Server acknowledgement,
forced server read, decoded content equality and owner checks remain mandatory.
Schema-compatible tutor input is not evidence that an actual PDF or cloud save passed.

## Consent, validation and verification are separate

1. **Owner consent — supplied:** the owner expressly supplied these exact values
   for a controlled BeeWise demonstration and requested a committed proposal.
   This is not blanket public production publishing consent or permission to add
   unprovided personal data.
2. **Profile validation — local only:** types, known mode, ID shape, content fidelity,
   defaults and model/filter behavior are checked. It does not prove the student,
   experience or teaching-qualification claims.
3. **Tutor verification — not granted:** no named authorized catalog reviewer,
   review evidence or verification decision is supplied. Both flags stay false.

No separate approved test-only catalog verification policy was found in the
inspected repository. Existing design/backend docs require a trusted staff review
process; they do not define one. The policy discussion below is a proposal only.

**Important presentation constraint:** current Detail displays `verified=true` as
“Đã xác minh” and the PDF says “Xác minh: Đã xác minh”. There is no separate demo
approval state in the existing model/UI. A technical-test sign-off alone cannot
be silently translated into that public badge. Setting true merely to pass the
report rules would misrepresent the approval scope.

For controlled technical-only approval, the group should define reviewer authority,
the precise meaning of “verified”, evidence reviewed, owner-approved audience,
project/environment, retention and audit record **before** enabling anything.
If that decision cannot truthfully support the existing public badge, use an
isolated, explicitly identified staging environment with permitted real owner
data and reviewer-approved demo disclosures, or wait for legitimate production
catalog review. Do not invent professional accreditation. Staging infrastructure,
client configuration or disclosure changes require a separate scoped task; none
are provisioned here. Staging results must be labeled staging, not acceptance on
`beewise-lab-3`. Real-project acceptance still needs a legitimately eligible tutor
under a documented approval meaning that matches the current presentation.

## Missing information and approval checklist

Missing: qualifications/credential and evidence (if any), actual availability,
validation of supplied experience/student claims, authorized reviewer identity
and authority, approval criteria/decision, public versus controlled audience,
target environment, duration/retention, and exact future publishing authorization.
The first two can remain empty for schema compatibility; they are not completed
facts. Phone/email/avatar/university/degree/rating are not required for this
catalog proposal and should not be requested or fabricated merely to run a PDF test.

- [x] Owner-supplied values copied without expansion; content/use consent recorded.
- [x] Exactly one proposal, ordinary unique-at-inspection ID, not an automatic seed.
- [x] Safe empty/default choices documented; both activation flags false.
- [x] Actual-model/filter checks and existing fixture/report regression tests recorded in validation receipt.
- [x] Existing catalog read only; no production mutation or security/config change.
- [ ] Owner approves the **exact payload hash**, ID, intended audience/environment and retention for any later write.
- [ ] Authorized reviewer resolves applicable missing evidence and documents the legitimate verification meaning/decision separately from consent.
- [ ] Group approves a test-only policy/staging plan if needed, without misleading badge semantics or synthetic-guard removal.
- [ ] A separate explicit authorization names project/database/path, create-only operation, approved payload, flags and operator. Approval to create inactive/unverified data is not approval to activate/verify.
- [ ] Any change to these values or flags produces a new reviewed payload/hash before a write.

## Later publishing sequence — not executed

1. Fetch current main, recheck current rules/model and the target environment.
2. Recheck consent, reviewer authority/decision, display meaning, audience and
   retention. Do not treat merge of this docs PR as publishing/activation approval.
3. Freeze the exact approved new payload and hash. For this proposal the flags
   remain false; an eligible variant is a separate review and authorization.
4. Read the proposed path again. If it exists, stop; do not overwrite or repurpose
   another document. Re-inventory the six fixtures and preserve them.
5. Only after explicit approval, a trusted authorized operator may perform one
   create-only operation with a nonexistence precondition. No broad import/seeder,
   client self-verification, account creation or security-rule change. No executable
   live-write script/command is included in this preparation PR.
6. Read back the new document; compare exact approved fields/flags, ID and hash;
   record sanitized receipt without auth credentials or unrelated personal data.
   An inactive created profile remains invisible and PDF-save-ineligible.
7. Only after legitimate separately approved eligibility, use the actual default
   Android app and authorized A/B accounts: generate, inspect local bytes, save,
   verify server ack/document metadata, force server download, compare SHA256,
   open/share and test ownership/logout/error cases. Verify actual DebugView
   `upload_report(storage_backend=firestore)` only after real save. Keep PDFs,
   raw UIDs and report paths private/redacted. Follow the existing per-case plan;
   do not count model tests, deployment or this proposal as PDF live PASS.

## Rollback/cleanup proposal — requires separate approval

There is nothing live to roll back now. Preserve this proposal as review history;
do not delete it or any existing tutor automatically. If the exact new record is
later created, record its create receipt/update time and dependencies. An approved
pause can set only this record inactive with an update-time precondition; it must
not change the six fixtures or a concurrently edited record. Existing public rules
deny reads for inactive tutors; existing immutable reports are not auto-deleted.
Later deletion, content correction, consent withdrawal handling and private report
retention each need an explicit scoped decision and trusted operator. Retain only
minimal non-sensitive audit evidence. No cleanup, deactivation or deletion is run here.

## Scope and evidence limits

Validation: **29/29 focused tests PASS** (three temporary local proposal assertions
using the actual model/filter, plus 26 existing fixture/catalog/report service and
controller tests), pub get PASS and format PASS (40 tracked-source Dart files,
zero changes). Commands, hashes and evidence scope are in `validation.json`.
The temporary proposal test lives in ignored `.dart_tool`, outside runtime/seed
paths; no test/source changes are committed. Tests used unchanged baseline app
source and the exact proposal hash, not a live Firebase/Android PDF operation.
Read-only catalog snapshots at 00:14:24 and 00:18:10 on 03/11 (Asia/Bangkok) have
the same complete names/update-times fingerprint; proposed ID is absent in both.

Only documentation, one local JSON proposal and its validation receipt are committed.
Nothing is placed under `scripts`, `firebase`, application assets or an import/seed
path; it cannot be automatically loaded by the app. Runtime source, existing tutors,
production database, rules/indexes, Auth, FCM, PDF logic, Analytics/Crashlytics,
Remote Config, billing and Storage remain unchanged by this preparation run.
Local tests are validation evidence only; **PDF LIVE TESTING NOT RUN**.
