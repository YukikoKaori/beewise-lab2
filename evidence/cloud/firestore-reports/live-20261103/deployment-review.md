# Exact demo rules approval

Project: beewise-lab-3; database: (default).
Scope: deploy ONLY firestore:rules; no indexes or other services.

Raw SHA256: 94ef6ed2594ba4c6880c2b95fbaf75cb43fdb5bdbdeb5bf743d63389aa3d4428
Normalized SHA256: a2bc4d7c98b9b6ed128100d7465caa789675a7970419a3b6757bad7727838f80

58/58 Emulator rules tests PASS. Baseline deployed ruleset is 34ff742c-626d-4cd5-abde-59c21cce3522.
Only report tutor eligibility changes: exact consented ID, active=true, verified=false, demoOnly=true. Other demo IDs/malformed flags rejected. Existing ownership, applicant/anonymous denial, immutable reports and synthetic guards retained. All non-report rules unchanged.

See demo-rules.diff and approved-demo.rules for exact bytes. No changed rules deployed until separate owner approval.
