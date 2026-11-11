# Final production preflight

Historical snapshot. NOT_RUN or pending statuses below describe that stage; see [later production evidence](../production-cross-role/README.md) for current results.

Source `d7fa5bea2ed5276c13ecd3739fa00257676c1242`; [main CI run 43104437452](https://github.com/YukikoKaori/beewise-lab2/actions/runs/43104437452), attempt 2, completed success on all five jobs. Attempt 1 failed at the backend watcher. The rerun does not establish the cause of that earlier failure.

| Gate | Status | Observation |
|---|---|---|
| Project and site | VERIFIED_LIVE | Signed-in Firebase CLI listed the existing `beewise-lab-3` site and Firestore `(default)` in the intended project. Effective deployment permissions were not yet exercised. The existing live channel was last released Oct 26; `/` and `/admin/payments` returned HTTP 404 before this acceptance. |
| Web production config, build and deploy | VERIFIED_LIVE | CLI registered `BeeWise Admin` (`1:840483888286:web:1ad59898d687201d6a2f8f`), verified production defines, built the release from the source SHA above, and deployed Hosting only. Served JS matches the local release SHA-256 `1955badeadf27074ed4ee93513c6364b297ea44885e3739f3bc21c9ccf2e6fd4`. |
| Web local | VERIFIED_LOCAL | Locked dependencies, format, analyze, 1 widget test and Flutter release compilation with the localhost emulator define passed. This bundle must not be deployed. |
| Web production smoke | VERIFIED_LIVE (signed-out scope) | Root and `/admin/payments` returned 200. The signed-out app rendered in the browser and after reloading a deep link in an isolated private context. Google popup reached `accounts.google.com`; closing it returned to the retry UI. See [popup cancellation](web-sign-in.png) and [private reload](web-private-reload.png). Authenticated staff/non-staff flows and workspace queries were not run. |
| App Check settings | VERIFIED_LIVE | AI Logic: Enforced. Firestore and Authentication: Off. Android app registration lists SHA-1/SHA-256; Play Integrity settings are visible (1 h TTL, min device `NO_INTEGRITY`), which does not prove attestation of a production-signed build. |
| App Check token and metrics | NOT_RUN | Web provider configuration verified; signed-out browser smoke produced no observed token exchange. No authenticated App Check request, metrics receipt or physical Android attestation was verified. |
| Gemini Level 2 | NOT_RUN | Remote Config v4 showed no top-level defaults for `ai_matching_enabled` or `gemini_model`; source defaults to `gemini-3.5-flash-lite` on Gemini Developer API. Official Firebase docs list support without required billing; this is not proof of this project's remaining no-cost quota. No provider calls, output pairs, UI screenshots or live Analytics events. |
| Controlled failure | VERIFIED_LOCAL | Five focused Dart tests passed; injected timeout and disabled config confirm no retry or alternate provider. This run did not exercise the failure UI or capture `ai_error`. |
| VietQR | VERIFIED_LOCAL | Two tests passed, including the published NAPAS vector and exact amount/recipient/distinct references. Bank-app scan NOT_RUN. No bank config, invoice, payment or verification was created. |

The owner separately approved one score-based reCAPTCHA Enterprise website key restricted to `beewise-lab-3.web.app`, to be registered for `BeeWise Admin` only (TTL 1 hour, minimum score 0.5). Preflight found `recaptchaenterprise.googleapis.com` **DISABLED**, so no key was created or registered. Read-only checks found billing disabled, the Google sign-in provider enabled, the Hosting domain authorized, and the signed-in account holding `firebasehosting.sites.update` plus the requested key creation and provider update permissions.

After separate approval, enabled only `recaptchaenterprise.googleapis.com` on `beewise-lab-3`, created the approved domain-scoped score key, and verified provider readback: matching site key, 3600-second TTL, score 0.5. No billing link, new terms, enforcement change, Auth configuration change, Firestore deployment, or other cloud mutation was made beyond the authorized Hosting release and App Check setup.

## Staff role read blocked by live Rules

After separate owner approval, deployed only `firestore:rules`. The live ruleset is now `e07a5a2c-5978-4318-b4f7-dbac6d3aaf60` (released 2026-11-11 22:17:35 UTC). Live readback matched the approved source after newline normalization (SHA-256 `5d59a8a95305744a00a4c4f7397b4b255c76b297b0d654994d6cd5ae3272199a`). No indexes were deployed. The owner’s authenticated Dashboard retest is pending.

The owner then provided a live screenshot showing the staff role and VietQR workspace. The default VietQR query failed with `FAILED_PRECONDITION` (missing index). After separate approval, created only the [VietQR composite index](vietqr-index-proposal.json) on `finalPayments`, ID `CICAgJim14AK`. No Rules or payment records changed during this operation.

The index reached `READY`. The production read-only query for `awaiting_verification`, ordered by descending `createdAt` with limit 75, returned HTTP 200 after index propagation. Authenticated browser retest of the list remains pending.

After the separately approved staff assignment, the owner reached the signed-in role check but could not open the workspace. The live default database ruleset `7f16e27f-f60b-4a9d-8ab0-3810bf9e9138` allows user notification reads but has no `match /users/{uid}` role read and no Final `finalPayments` match. The merged Final rules have both. The historical proposal was for review only; the proposed file was `firebase/firestore.rules` at merge SHA `d7fa5bea2ed5276c13ecd3739fa00257676c1242` (local file SHA-256 `63ab30023c0888aaea38ae860e4d808df4e6a52db320ad94a624a14d6ce1e583`). The exact-commit [Firebase Rules CI job](https://github.com/YukikoKaori/beewise-lab2/actions/runs/43104437452/job/130809926497) passed. At proposal time, no Rules or indexes had been deployed. The approved operations are recorded above.
