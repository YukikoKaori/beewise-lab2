# CR-01 — Production tutor approval (partial)

The owner submitted the disposable CR-01 application on Android API 35. ADB confirmed the pending UI. The owner's before/after captures show the same test alias in the production Web review dialog with a synthetic reason, then in the processed list as approved. Android shows the approved badge and a welcome message for the same alias. No public profile publication is evidenced or required.

Status: Web decision and Android status VERIFIED_LIVE, supported by screenshots. The owner confirmed the Android status updated without reload and the private inbox displayed the CR-01 approval notice. Inbox screenshot and independent Firestore readback were not captured. Write acknowledgment, listener arrival and UI propagation timings were not measured.

Private source capture SHA-256 (originals excluded because desktop captures contain contact details or unrelated records):

- Android pending: 40b49578c81552771eb450d53b9169b4a934b41ead1e26ce514ab0fbadcd620b
- Web dialog and Android pending: b52b2cf759bfceda24a3581c9a3afca70a029babb552b63ba3a5edac13e9264e
- Web processed list and Android approved: 301574bbe1839203c7c28a1927662707edf9124a707540dafa4dbe49b4080a25
