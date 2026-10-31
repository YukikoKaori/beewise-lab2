# Bao Android Google OAuth preflight

Prepared 2026-10-31 from the actual installed debug APK. Executed after explicit
owner approval of exactly these two SHA fingerprints. Server list readback after
each addition confirms only the approved certificates; receipt:
`evidence/cloud/google-sha-approved.json`. Firebase CLI Node 25 exit assertions
are retained separately from successful API responses and verified server state.
The downloaded config adds only the matching Android OAuth client; project/app,
package, existing web OAuth client and client key remain unchanged. Repository
config synchronized; native Google authentication is still NOT RUN until the
user completes the dedicated Google account flow on the isolated emulator.
Project: `beewise-lab-3`; Android app:
`1:840483888286:android:50c11fbb460437ed6a2f8f`; package `com.beewise.beewise`.
The web OAuth client supplied by the owner is already preserved in the repository.
Google provider was already enabled. Preflight SHA inventory was empty; after
the authorized operation it contains exactly the SHA-1 and SHA-256 below.
The commands are retained as the executed plan, not instructions to repeat them.

APK SHA-256:
`c963e08a7684c54bbc0893524a9a6e9168a38350b9fdfe08ff9475eeb4ef2701`.
Actual signer digests obtained with Android apksigner:

- SHA-1: `6e3c8dbe21224f09538eecc6932af45405ce38d8`
- SHA-256: `4f4d9efa0c5d23d3285dc7d79eab011af5831d57342196c6d85e13e63c1b4004`

Only after owner authorization, add these two certificate hashes to this app:

```powershell
rtk proxy .\firebase\node_modules\.bin\firebase.cmd apps:android:sha:list 1:840483888286:android:50c11fbb460437ed6a2f8f --project beewise-lab-3
rtk proxy .\firebase\node_modules\.bin\firebase.cmd apps:android:sha:create 1:840483888286:android:50c11fbb460437ed6a2f8f 6e3c8dbe21224f09538eecc6932af45405ce38d8 --project beewise-lab-3
rtk proxy .\firebase\node_modules\.bin\firebase.cmd apps:android:sha:create 1:840483888286:android:50c11fbb460437ed6a2f8f 4f4d9efa0c5d23d3285dc7d79eab011af5831d57342196c6d85e13e63c1b4004 --project beewise-lab-3
```

Inspect the resulting app configuration and compare project/app/package/client
settings before any repository update. Rebuild/reinstall only if configuration
changes require it. Keep the same signer and install with `-r`; never uninstall
or clear data. No billing, Storage, provider toggles, App Check enforcement,
rules changes or unrelated OAuth clients are included.

Google picker/cancel/sign-in requires a dedicated authorized Google test account
and direct user interaction. Existing Email/Password identities are not proof of
an available Google account. Never request, retrieve or script passwords/tokens.
Certificate registration alone is not Google login verification.

If verification fails, retain exact read-only receipts and stop. Do not remove
existing certificates or disable the provider. Any rollback removal must target
only certificate resources created by this operation and needs separate explicit
owner authorization; record their returned resource names without secrets.
