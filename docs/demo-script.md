# Evidence-safe demo

Use a dedicated test Firebase project, controlled tutor records and authorized
test accounts. Do not enable billing, accept AI terms or publish rules as part of
this script. Read `docs/backend-contract.md` before creating staging fixtures.

1. Show the current branch/SHA and local logs in `evidence/corrective/`. Explain
   that rules/unit tests are different from Android runtime and cloud validation.
2. Run `scripts/verify-lab3.ps1 -Flutter <3.47.8 flutter.bat> -Rules -Android`
   with JDK 21 and an installed Android SDK. All caches default to drive D.
3. Only after an APK exists, attach an online test emulator/device (`adb devices
   -l`), install the APK and launch `com.beewise.beewise`. Do not bypass App Check.
4. Demonstrate guest Home/Search/Profile using controlled active tutor data;
   demonstrate empty/network error recovery. Show the selected tutor survives the
   login gate. Register a parent only on the authorized test project. Interrupt
   profile networking and retry with the same credentials; never delete another
   account. Verify resulting Auth UID and owner profile on the test project.
5. Submit a disposable tutor application with operator-entered credentials;
   show pending status, private applicant access, absent parent navigation and
   no self-approval/public tutor write. Do not record credentials.
6. Create a connection request, then use trusted staging proposal fixtures with
   current IDs, pending status and future expiry. Show response receipt. Stop at
   the invoice gate unless an actual trusted backend has issued the invoice.
   Explain that requesting verification does not mean paid or scheduled.
7. Send fresh UID-targeted push messages for foreground/background/terminated
   cases. Switch test accounts and verify no other UID's inbox or deep link.
   Check Android shade separately; never send private content there.
8. Capture real device screenshots at 360dp and 412dp, recording physical pixel
   size, density, font scale, keyboard insets, APK SHA256 and source SHA. Revert
   test-device display settings after capture. Do not label design PNGs runtime.
9. Start the separately configured ARTEMIS host and run the README commands.
   Export original host traces/replays; verify visible state and JUnit results.
   Only then promote PENDING_VERIFICATION to PASS in the reviewed evidence table.

If required access is missing, show the specific BLOCKED row instead. No live
cloud success, Android screenshot, measured performance or payment is claimed by
the checked-in draft PDF/slides.
