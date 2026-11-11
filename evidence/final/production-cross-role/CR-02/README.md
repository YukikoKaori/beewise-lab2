# CR-02 — Production correction request and resubmission (partial)

Android API 35 initial pending status was independently observed via ADB. Owner captures then show the application in needs_info with the CR-02 reason asking for teaching availability, followed by pending again after the correction step. Status, reason on the application screen, and return to pending are VERIFIED_LIVE at UI scope. These captures do not independently establish same-UID Firestore readback, private inbox visibility, server acknowledgment, or propagation timing. The owner confirmed the status updated without reloading.

Private capture SHA-256 (desktop originals excluded):

- Initial Android pending: 868786ceceb0aed193af9b516cd2a320bd15b35514f51c242276a7b96b921116
- Android needs_info and reason: 5a353626f473b8ba3301ef027b2b544ac2f7e0e696b01026d5f469b23a5e95f5
- Android pending after correction: c60275aa1ad2b57ec2f67a5fa4bc8016a649115247bd5c1af51ba2b6119ffffd

The owner confirmed there is no inbox entry on the needs_info screen. The router permits the status and edit pages but redirects /tutor/notifications away. The owner accepted this behavior as designed: applicants read the decision on their application screen. Firestore receipt creation was not independently checked.
