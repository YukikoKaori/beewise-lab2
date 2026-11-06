# ARTEMIS TC-25 evidence

The [status](STATUS.md) separates the 30 accepted regression runs, one qualifying exploration, and the historical Android-native interactions. This corrective was offline; no provider, ARTEMIS, Android or Firebase execution was performed.

The [native regression supplement](../n03-native-final/STATUS.md) passed 3/3 independently verified executions. It is separate from the two historical native receipts and TC-25.

## Qualifying session

`aa025ab2-6a51-4b34-a4c1-3ba346e4e0a4` ran continuously for **925.734 seconds** (about 15:26). ARTEMIS used DeepSeek `deepseek-flash` with the approved Flash profile, on Android API 35. V6 paced turns at 38 seconds and restricted the final turn to reporting. The private trace contains 22 Android actions followed by a structured final report (23 steps total). The [exploration summary](exploration-summary.json) records agent observations and issues; it does not verify cloud ingestion.

The earlier 379.34 and 466.80 second attempts were interrupted, and the 1018.735 second attempt failed the final-report gate. See [the manifest](exploration-manifest.json) for these and other historical attempts. The former 846.14-second aggregate joined the first two interrupted attempts and is not a qualifying session.

## Trace and clocks

**Provenance B — original private trace verified.** Retrieve `exploration-host-state/traces/data_engine.db` relative to the private N-03 archive root. The database is **4,583,424 bytes**, SHA256 `0cea8a2bf77ee75db6f43eeaf80ddf9473ef3a7363b37372ce24f633f21e6ef6`; its WAL was empty at verification. Filter `sessions`, `steps` and `traces` by the full session ID above. The [sanitized timeline](trace-timeline.json) lists all 23 step timestamps and action types and identifies the range of all 236 trace events. Raw prompts, text inputs, coordinates, screenshots, model payloads and ledger rows remain private.

| Clock | Event | Verified value | Source |
| --- | --- | --- | --- |
| Host session | ARTEMIS start | `2026-11-06T04:12:38.483129+00:00` | `sessions.start_time`, Unix epoch converted to UTC. The earlier `11:12:38Z` was the local clock (`11:12:38.483129+07:00`) mislabeled as UTC. |
| Host session | ARTEMIS end | `2026-11-06T04:27:59.359290+00:00` | `sessions.end_time`, Unix epoch converted to UTC; host span 920.876161 seconds. |
| Pytest | Suite start | `2026-11-06T11:12:33.890778+07:00` = `2026-11-06T04:12:33.890778+00:00` | [Raw JUnit](result.junit.xml), original UTC+7 timestamp preserved and converted here. |
| Client runner | Elapsed around `artemis.run` | 925.734 seconds | Original manifest and summary record the monotonic measurement; standalone raw client stdout with the exact value was not recovered. The host span and JUnit independently corroborate the 15–30 minute range. |

JUnit records **1 pass, 0 failures, 0 errors, 0 skips** (suite 925.896 seconds; test 925.867 seconds). These clocks measure different boundaries.

## Privacy and scope

Eight committed screenshots were reviewed: the catalog identity shown is the emulator demo label. No visible private account data or credentials were found. Screenshots 01–07 match images in the private archive byte for byte. Screenshot 08 is a separate end-screen capture of Messages; it is not the original trace. The legacy filename of screenshot 07 is superseded by the native review in [STATUS](STATUS.md#android-native-interaction). The raw JUnit retains its original local hostname. V6 estimates and caps are separate from billing and shared balance; see [STATUS](STATUS.md#v6-provider-accounting).
