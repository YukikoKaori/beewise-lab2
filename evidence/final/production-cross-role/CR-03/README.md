# CR-03 — Production rejection (partial)

Android API 35 showed pending before the staff decision. Original native pending screenshot is retained privately; SHA-256: 54246aa75d7d199fb04a09391bd46ed66754646c1f57aa9f734fd03f150ae9bc.

The owner confirmed Android changed to rejected without reload. The Android screenshot shows rejected and the CR-03 reason. Private screenshot SHA-256: 2932b3a7ee2c687fa5a20b055c88e1e969d8264bd32b6b1349e26998b55c1c35. The owner could not open a private inbox from the rejected screen. The router redirects rejected applicants away from /tutor/notifications to /tutor/pending. The owner accepted this as designed: rejected applicants can see the reason on their application screen without gaining tutor workspace access. Firestore receipt creation was not independently checked. Privileged-operation denial, independent Firestore readback and timing are not verified.
