# Bảo → Nguyên UI/runtime handoff

Date 2026-10-30; app source `db1f12e`, based on PR #2 merge `12f5322`.
No Nguyên-owned UI/router/theme/ARTEMIS/review/final submission file was edited.
Service signatures and safe business/payment gates remain compatible.

## Actual evidence and gaps

- Latest debug APK builds; installation over the existing test emulator package
  fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (different signing certificate).
  No app uninstall/data clear has been performed. User approval is pending.
- Fresh independent D-drive data-image attempts did not establish usable ADB;
  original AVD is restored online. Latest app launch, native screenshots,
  360dp/412dp navigation/layout and crash/non-fatal triggers remain NOT RUN.
- No runtime UI defect is asserted without observing this APK. There is no
  fabricated screenshot or screenshot of an earlier build represented as current.
- Source review: Profile's non-fatal diagnostic snackbar says it was sent even
  though the adapter deliberately swallows reporting failures. Receipt must still
  be checked in Console. Consider wording during UI review; not a proven runtime
  defect and not changed here.
- Source review: Google config lacks OAuth clients. Native login/picker/cancel
  is confirmed absent live; SHA list is empty. Provider/SHA/config reconciliation plus a dedicated identity is required. Do not
  record this as a UI layout defect or use a personal Google account.

## What Nguyên can reuse

`evidence/firebase/manifest.md`, `evidence/android/runtime-manifest.json`,
`evidence/cloud/checks/verified/` and the real local service-generated PDF under
`evidence/firebase/storage/`. Unit/emulator evidence is labeled separately from
live cloud. No successful payment, tutor verification or official schedule was
fabricated. The PDF fixture is local-only; six separately authorized `[TEST]` Firestore tutors now exist unverified in the shared project. See fixture-actions.json.

Accepted fixes (three separate commits): BAO-A01 analytics privacy `ddbdb44`,
BAO-A02 bounded Remote Config `6c333ad`, BAO-A03 cancelled PDF upload `ae4ce9d`.
Raw red/green test logs are retained; `bao-initial-audit.md` predates the fixes.
These are this Codex workstream's findings, not an independent external review.
Nguyên owns review provenance/acceptance and all ARTEMIS execution. Nothing in
this branch marks N-01..N-05 complete.

## Retest once blockers are resolved

1. Install exact hashed APK; capture startup/Firebase/plugin logs and genuine
   screenshots at 720×1600/density320 (360dp), 824×1830/density320 (412dp).
2. Guest Home/Search/AI/Profile/Chats, back navigation, form validation and network
   outage/recovery; record real data/empty/error separately, restore overrides.
3. With dedicated identity, full auth/cancel/session/account switch and export,
   real FCM states/taps, Analytics DebugView, Crashlytics receipt, and two Remote
   Config visible changes in the same APK with template restoration.
4. With approved trusted backend/provider, run business E2E. ARTEMIS test
   collection in CI is not mobile execution; staging and external review remain
   NOT RUN/BLOCKED until their owners supply actual evidence.
