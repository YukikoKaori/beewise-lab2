# F-03 live payOS acceptance — 2026-11-05 (Asia/Ho_Chi_Minh)

**LIVE payOS, real Firebase project `beewise-lab-3`, Android emulator `BeeWise_API_36`
(debug APK). Backend ran locally (`backend/src/server.js`) behind a Cloudflare
quick tunnel for the payOS webhook only.** One real 2,000 VND transfer, approved
and performed by the payOS account owner.

| Step | Actor | Result |
|---|---|---|
| Connection request to demo tutor | Parent (app) | chat `ZFq1Lel04cOEqM4urUt4` |
| Claim + trial proposal | Consultant (`staff.js`, custom claim) | `consultant_assigned` → `trial_proposed` |
| Accept trial | Parent (app) | watcher → `trial_accepted` |
| Class revision, totalFee 2,000 | Consultant | `class_revision_pending` |
| Confirm class | Parent (app) | watcher → invoice `inv_ZFq1Lel04cOEqM4urUt4_mm7PcVU3byiyjYtzSUcE` |
| Checkout | Parent (app) → backend → payOS | order `38220433647790`, link matched, payOS `PENDING` 2000 |
| Bank transfer via VietQR | Owner | payOS `PAID`, amountPaid 2000, 1 transaction |
| Signed webhook → provider re-check | payOS → backend | event `processed/paid`, order `paid` (source `webhook`) |
| Settlement | Backend transaction | invoice `verified`, class `cls_inv_…` `paymentStatus=verified`, chat `schedule_confirmed` |

Webhook URL confirmation also succeeded (payOS sample `orderCode 123` →
`unknown_order`, HTTP 200). Screenshots: `app-payment-verified.png`,
`app-official-schedule.png`, `app-chat-timeline.png`. No keys, account
numbers, UIDs of real people or ID tokens are stored here.

Known limits: quick tunnel has no uptime guarantee (one tunnel drop was observed
and recovered; no order was created during the drop); server not deployed.
A UX issue seen during the run (Trial/Class screens kept their action buttons
after a processed response, and a second tap reported "expired") was fixed
afterwards and re-checked on the same chat.
