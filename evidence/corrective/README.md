# Corrective evidence

See `run-manifest.json` for tested source SHAs, native exits, environment and
SHA256 values. `ci-code-sha.json` verifies the original APK-producing source;
`ci-rules-sha.json` additionally verifies the final rules correction. The final
PR head CI is checked separately after committing this immutable evidence.

Logs are readable UTF-8 with normalized LF line endings and trailing terminal
padding removed. Content, failures, warnings and test counts are preserved.
Pre-whitespace-normalization copies are retained locally at
`D:/CodexTemp/beewise-lab3-tools/evidence-before-whitespace/`; the normalization
receipt records their hashes. Committed log hashes describe normalized files.

`rules-role-batch-red.log` intentionally records the reproduced security failure;
`rules-test.log` is the passing correction. `apk-build.log` intentionally records
the original local cache failure; `apk-build-drive-d.log` is the successful clean
D build. `runner-*-red.*` describe reproduced harness failures. Process-double
checks are synthetic harness tests only; they never execute Android/AI scenarios.
All real mobile cases remain BLOCKED, as listed individually in device-cases.json.

No production deployment, real account creation, billing change, external review
approval, live integration result or authentic device screenshot is claimed.
