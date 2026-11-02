# Authenticated UI smoke check

Date: 2026-11-02. Environment: BeeWise debug APK on Android 36 AVD `emulator-5554`.

- The user supplied a test account for this check. Its email, password, UID, and any account-specific UI were not written to this repository or retained in evidence.
- Email/password sign-in completed and the app returned to Home. Opening the Account tab showed the signed-in state and a sign-out action. This confirms the app's authenticated session at UI level; it is not a Firebase Console receipt.
- With that session, the app opened the Connection Request form for the catalog item visibly labeled `[TEST]`. The empty form was captured at approximately 412dp in `runtime-connection-412dp.png`, with its matching UI hierarchy. No request was submitted and no Firestore workflow record was created by this check.
- The Messages route opened in the signed-in session and showed its empty state; hierarchy inspection found no chat tiles. A sanitized empty-state screenshot/hierarchy is retained as `runtime-messages-empty-auth-412dp.png` / `.xml`.
- AVD interaction later became unstable and switched foreground focus to Android's SIM Toolkit. No further account actions were attempted. The app session may remain active on the disposable AVD.

This check helps N-01/N-02 route coverage. It does not satisfy ARTEMIS repetition/Pro requirements, prove tutor records are real, or provide a trusted chat/trial/class/invoice/schedule fixture.
