# Controlled demo profile review — 03 November 2026 (Asia/Bangkok)

Project/database: `beewise-lab-3/(default)`; a named Firebase test/demo project.
Document: `tutors/tutor_acd3824aa8734c63ac8827df`.

**Approver and consent source:** repository/profile owner Hoàng Quốc Bảo, through
the current task's explicit authorization to publish exactly this owner-supplied
profile for the controlled BeeWise Lab 3 technical exercise. No separate staff
reviewer is asserted. xha is the technical validation/execution operator, not an
independent assessor of teaching qualifications.

**Content reviewed:** the eight substantive values and two empty strings are
identical to merged PR #8. No degree, university, credential, contact, rating,
photo or evidence of experience is added. Name, student status and three years'
experience remain owner-provided claims. The publication payload changes only
`active: false` to `active: true`, retains `verified: false`, and adds
`demoOnly: true`. The exact payload is `published-demo-payload.json`, raw UTF-8
SHA256 `bd13cb687ad08692a639453c54c0e90f30b44f6adb3a9eab12fd7b21fa7f13b1`.

**Decision:** approve this content for technical demonstration only, under the
owner's named project/ID and existing authorized A/B accounts. Approval does not
verify professional accreditation, student status or experience. Keep the
professional `verified` flag **false**. Do not repurpose the six synthetic records.

**Disclosure:** new APK catalog/detail and generated PDF visibly say
“Hồ sơ demo — đã duyệt cho kiểm thử”, with detail/PDF explicitly stating
“Thông tin do chủ hồ sơ cung cấp; chưa xác minh chuyên môn hoặc kinh nghiệm.”
Old APKs still see `verified=false`, never the professional verification badge;
they do not implement the new demo eligibility or its full disclosure.

**Bounded eligibility:** only this exact trusted-created catalog ID, with boolean
`demoOnly=true`, boolean `verified=false`, active=true and no synthetic markers,
can take the demo report branch. No client can publish/approve a tutor. Parent
identity, applicant exclusion, immutable owner-only reports, size/schema/encoding
checks and synthetic protections remain unchanged. Ordinary verified tutors
retain the original branch; other demo/malformed flags fail closed.

**Audience/retention:** the project is used for a controlled technical exercise,
but existing public active-catalog reads are not a private audience restriction.
The owner explicitly authorizes publishing these supplied values there. No
access restriction or automatic expiry is claimed. Leave only this demo and the
minimum owner-private reports needed for acceptance; later deletion/deactivation
needs a separately scoped owner instruction. No unrelated cleanup is authorized.

The changed rules have a separate exact-diff deployment approval gate. This
review is not evidence of deployment, creation, an Android run or a PDF PASS.
Actual receipts must establish those outcomes independently.
