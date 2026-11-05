# ARTEMIS / official DeepSeek compatibility investigation

Checked 2026-11-05. Verdict: **DEEPSEEK_REQUIRES_COMPATIBILITY_PATCH**. Exactly one owner-approved TC-09 ran on Android API35 using official DeepSeek: real screenshots, five model responses and four native tab taps are preserved. **TC-09 FAILED its output contract**; it is not a passing smoke. A further SDK contract-handoff fix passes offline tests but has not been tested live. No second run, exploration, cloud change, push, PR, merge or deployment was performed.

## Installation and scope (initial snapshot)

This table and the original offline receipts describe the initial installation. The dated owner-approved preflight below supersedes key/device availability: the key has since been supplied privately and account model discovery succeeded.

The owner confirmed ARTEMIS was not installed on this machine and authorized installing it. Nguyen's historical `D:\Apps\artemis` receipt describes another installation; that path is absent here. Its Gemini quota failures are historical evidence, not the current account's quota state.

| Item | Observed local state |
|---|---|
| BeeWise investigation worktree | `D:/CodexTemp/beewise-deepseek-compat`, branch `codex/artemis-deepseek-compatibility`, based on main `a72059c` |
| ARTEMIS source | `D:/CodexTemp/artemis-deepseek-audit`, branch `codex/deepseek-compatibility` |
| ARTEMIS upstream/source baseline | `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`, version 1.0; matches BeeWise client Git pin |
| Installation | `uv sync --frozen --python 3.12 --extra dev`; editable source, private `.venv`, no installed-package edits |
| Python | 3.12.10 |
| SDKs | langchain-openai 1.5.2, langchain-core 1.5.6, openai 3.3.0, langchain-google-genai 4.3.4, google-genai 2.22.0 |
| Other relevant packages | langgraph 1.2.11, pydantic 2.13.4, httpx 0.28.1, artemis-client 0.1.0, pytest 9.1.1, pytest-asyncio 1.4.0, uiautomator2 3.7.0, adbutils 2.12.0 |
| Original configuration | Tracked `config/artemis.jsonc` unchanged. No local `.env` created; no existing secret file exported |
| Host | New isolated host bound to `127.0.0.1:8001`, budget 0. Root HTTP 200; real client status/device APIs PASS |
| ADB | `D:/Android/SDK/platform-tools/adb.exe` works; zero devices online. SDK's current default AVD listing contains `BeeWise_API_37` |
| Native readiness | BLOCKED: no online device, guest state/APK not verified in this investigation. No userdata cleared |
| Owner DeepSeek account | Key absent from process environment; authenticated model listing, balance and effective quotas NOT VERIFIED |

This is separate tooling work. BeeWise app, Firebase AI Logic model `gemini-3.5-flash-lite`, Firebase services, payOS, and Nguyen-owned implementation files are unchanged. Bao retains F-02; Nguyen retains F-03 and ARTEMIS test ownership. This investigation does not complete N-03.

## Actual capabilities and account uncertainty

Official documentation checked on the date above lists `deepseek-flash` (served by DeepSeek-V4.1-Flash-1017) with image input, while `deepseek-v4-pro` has no vision. Both advertise tools and JSON output. The documented context is 1M and maximum output 384K; the proposed smoke deliberately caps output at 2048. Flash peak USD per million tokens: cache-hit input $0.006, uncached input $0.30, output $1.20; off-peak rates are half. These are published offerings/prices, not proof of owner account access. [Models and pricing](https://api-docs.deepseek.com/quick_start/pricing/).

Flash accepts inline JPEG/PNG/GIF/WebP using OpenAI-style user `image_url` blocks. ARTEMIS's real Flash screenshot builder emits inline JPEG in a user message. Image bytes/MIME are retained; the offline fixture is a generated, nonsensitive image. Public vision limits include 48 MiB request bodies and up to 1024 image tokens per image. The proposed guard limits images to eight and rejects external image URLs and images outside user messages. [Vision](https://api-docs.deepseek.com/guides/vision/).

Official endpoint: base `https://api.deepseek.com`, inference `POST /chat/completions`. Non-thinking tool calls are documented using `thinking.type=disabled`. The patch uses this mode and function calling with local Pydantic validation. It does not assume OpenAI `response_format=json_schema` support, and does not enable the separate beta strict-tool endpoint. Chat Completions does not support fabricated tool calls inserted into conversation history: compressed/rewritten histories remain a live compatibility risk. [Tool calls](https://api-docs.deepseek.com/guides/tool_calls/).

JSON mode uses `json_object` plus a JSON instruction; it can return blank spaces. JSON validity alone does not prove the action schema or successful Android interaction. [JSON output](https://api-docs.deepseek.com/guides/json_mode/).

Published account concurrency is 2500 Flash / 500 Pro; effective access and limits for qb are unverified. HTTP 429 means stop this smoke; no quota expansion or automatic rerun is authorized. [Rate limits](https://api-docs.deepseek.com/quick_start/rate_limit/). Distinguish 400/422 format errors, 401 authentication, 402 balance, 429 limits, and 500/503 transient failures; SDK retry multiplication is disabled in the patch. [Error codes](https://api-docs.deepseek.com/quick_start/error_codes/).

Authenticated **GET `/models`** was subsequently executed once using the owner's privately supplied key. Safe model IDs, input modalities and context/output limits are retained in `models-owner-account.json`; headers/key and account data are excluded. It confirmed Flash image support, not effective quota/balance or universal model behavior. An absent/inconclusive capability must stop future preflight rather than trigger provider substitution. [Model discovery](https://api-docs.deepseek.com/api/list-models/).

## Current factory mappings and source audit

The newly installed stock config gives both Flash and Pro node defaults Google `gemini-3.8-flash` → `gemini-3.7-flash`. Hopper and Flash visual summary use `gemini-3.5-flash-lite`; Hopper fallback is `gemini-3.1-flash-lite`. Object detector uses `gemini-robotics-er-2-preview` for primary/fallback. Memory capsule model is `gemini-3.8-flash`. Optional judge defaults are also Google Flash Lite. These are this checkout's factory mappings; no claim is made about Nguyen's absent host configuration.

Source paths below refer to [ARTEMIS baseline 351ca842](https://github.com/google/artemis/tree/351ca8422f7b5b54e80a9c1ce03a222e02415b6b), with the separate patch applied locally. Labels describe stock behavior; offline patch results do not imply native/provider verification.

| Component / exact symbol | Classification | Finding and minimal preparation |
|---|---|---|
| `artemis/llm/router.py`, `ModelFactory.create_model` | REQUIRES PATCH | `openai` supports custom `api_base`/`OPENAI_BASE_URL`, but no native DeepSeek provider. Endpoint-scoped adapter adds non-thinking mode, function-calling default, documented token parameter, SDK retries 0 |
| `third_party/mobile_use/agents/hopper/hopper.py`, `hopper`, `HopperOutput` | REQUIRES PATCH | Calls default `with_structured_output(HopperOutput)`. Installed LangChain defaults to OpenAI JSON schema; adapter selects function calling. Actual SDK + mock transport parsed the real Hopper schema; malformed output rejected |
| `artemis/agents/flash/runner.py`, `FlashRunner._init_llm` | REQUIRES PATCH | Exception fallback constructs Google Gemini 2.5. DeepSeek-only mode now raises; no provider switch |
| Same file, `_build_tail`, `_resolve_tool_calls`, `_invoke_model` | COMPATIBLE (offline payload/parser only) | User image blocks and standard LangChain tool calls serialize/decode. Actual model action quality remains UNVERIFIED |
| `artemis/agents/explorer/explorer.py`, `_detect_native_engine`; `universal_runner.py` | UNVERIFIED (live) | Non-Gemini selects universal LangChain engine. Smoke selects Explorer tier `pro` inside Flash profile; no native Gemini client required by that branch |
| `artemis/agents/object_detector/object_detector.py`, `_run_object_detection` | UNSUPPORTED as a configuration-only equivalent | Stock Flash Explorer relies on specialized Gemini robotics grounding. DeepSeek vision is not proof of equivalent coordinate quality. Avoid this tier; do not claim parity |
| `artemis/agents/flash/summarizer.py`, `VisualStepSummarizer.__init__` | REQUIRES PATCH | Explicit model previously called `get_google_llm`. Resolve non-Google memory model through configured summarizer provider. Smoke disables background visual summary to bound work |
| `artemis/memory/chunking.py`, `StepCapsuleLens._get_llm`, `_get_fallback_llm` | REQUIRES PATCH | Both hardcoded Google; patch routes through configured summarizer endpoint. Long-context capsule behavior remains UNVERIFIED |
| Same file, `HistoryChunkManager._resolve_capsule_fallback_model` | UNVERIFIED / limitation retained | Existing resolver only selects a distinct Google fallback. Same-model DeepSeek config does not rely on that path; no cross-provider fallback is added |
| `artemis/agents/outputter/outputter.py`, `_format_structured`; `third_party/mobile_use/config/output.py`, `OutputConfig.bind_structured_output` | REQUIRES PATCH | Default structured-output call receives the endpoint adapter. Outputter was not invoked by the actual Flash branch, which returned early; its own live behavior remains UNVERIFIED |
| `third_party/mobile_use/sdk/agent.py`, `AgentBase._run_task`, Flash branch | REQUIRES PATCH (new live finding) | Builds `output_config` but passes only `request.goal` to Flash and returns its report without `_extract_output`. Thus expected contract never reaches Flash/Outputter. Corrective patch forwards the contract into the Flash goal; tests cover supplied/absent descriptions. Live rerun is NOT performed; this is prompt forwarding, not hard schema enforcement |
| `artemis/llm/structured.py`, `parse_structured` | COMPATIBLE (offline) | Local schema/parser regressions pass; invalid structured data fails |
| `artemis/agents/planner/planner.py`; `artemis/agents/checker/checker.py` | UNVERIFIED (full Pro) | Configurable model paths and typed output can use adapter. Full Pro coordination, optional judges, history rewrites and side tools not validated. No Pro session proposed |
| `artemis/config/llm.py`, `_expand_default_into_nodes`, `lightweight_judge_default` | REQUIRES explicit configuration | Shorthand expansion omits optional judges, which can default to Gemini. Prepared full schema overrides every primary/fallback, including four optional judge nodes |
| `artemis/services/llm.py`, `RobustChatModelWrapper`; `artemis/llm/reliability.py` | REQUIRES isolation/budget | ARTEMIS retains bounded wrapper recovery/fallback; SDK retries could otherwise multiply attempts. Shared on-disk HTTP attempt counter includes all workers and recovery attempts, before send |
| `artemis/sdk/agent.py`, `Agent._prewarm_llm_connections` | REQUIRES PATCH | Stock warmup can run Google count_tokens and Gemini `ping` even outside the selected agent. DeepSeek-only mode skips both; tested even when a Google key is passed |
| Video analysis, Google grounding/OCR, robotics utilities | UNVERIFIED / outside smoke | Video disabled in isolated config; no claim of provider parity. Factory rejects non-DeepSeek model construction in isolated mode |

Upstream issues [#45](https://github.com/google/artemis/issues/45), [#138](https://github.com/google/artemis/issues/138), [#167](https://github.com/google/artemis/issues/167) are OPEN as checked. Their reported paths exist in the pinned source. [PR #168](https://github.com/google/artemis/pull/168) is OPEN, `merged=false`, base 351ca842, head d3a1d7e; its existence/comment claiming resolution is not an installed fix. No upstream PR was automatically applied.

## Isolated patch, configuration and rollback

Reviewable source patch: `tools/artemis-deepseek/artemis-351ca842-deepseek.patch`. It includes source and offline tests, not venv binaries or secrets. Apply only to baseline 351ca842 in a separate clone/branch using `git apply --check` before `git apply`. Existing local checkout already has it applied as staged WIP; do not apply twice. No commit or push was made.

Supporting files:

- `artemis.deepseek.jsonc`: actual full `LLMConfig` schema; every primary/fallback is `openai/deepseek-flash`. Both required fallback entries intentionally remain the same provider/model; they are counted, not free retries.
- `.env.example`: placeholder only. `host.py` reads a private **process environment** `DEEPSEEK_API_KEY`, bridges to `OPENAI_API_KEY` for this process, and uses `OPENAI_BASE_URL`. It does not import the example file or persist a key. Never put a key in CLI arguments, chat, Git or evidence.
- `ARTEMIS_ARTEMIS_JSONC` is the supported path override at this revision. Generic `ARTEMIS_CONFIG` is not used. `ARTEMIS_APP_DIR` and `ARTEMIS_TRACES_DIR` isolate mutable state.
- `host.py` drops inherited Google/Gemini/GCP and tracing variables, sets `ARTEMIS_DEEPSEEK_ONLY=1`, removes fake LLM mode, skips provider warmup and defaults to 0 HTTP requests. Source guard also rejects fake mode plus DeepSeek-only mode. Factory allowlist and both sync/async transports prevent accidental model routing/fallback.
- Only setting a launch budget after owner authorization allows inference. Fresh state/counter required; reuse is rejected. Never run two smoke hosts sharing a key/config session.

Zero-inference host launch, using installed ARTEMIS venv Python (PowerShell):

```powershell
rtk proxy D:/CodexTemp/artemis-deepseek-audit/.venv/Scripts/python.exe D:/CodexTemp/beewise-deepseek-compat/tools/artemis-deepseek/host.py --artemis-root D:/CodexTemp/artemis-deepseek-audit --state-dir D:/CodexTemp/artemis-deepseek-offline-state
```

The initial zero-budget host was stopped before the approved live host; the live host was stopped after the one case. Port 8001 is no longer held by this investigation. Do not invoke stock `start.bat`, overwrite `.env`, or globally replace Gemini. Rollback consists of stopping the isolated host and using the original config/branch without this launcher; no deletion, reset, uninstall or emulator wipe is required. Preserve the WIP patch for review. Revert-by-deletion is not authorized.

## Completed offline and transport checks

Evidence: `evidence/artemis/deepseek-compatibility-20261105/manifest.json`, `offline.junit.xml`, `client-host.json`, `offline-results.json`.
The exported JUnit replaces only the machine hostname with `redacted-local-host`; the original receipt remains private outside Git. Test counts, names, timestamps and outcomes are preserved.

- Focused source regressions: **158 PASS**, including new DeepSeek tests, existing LLM gateway/parser, Flash runner, visual summaries and memory chunking. `scripts/check_deepseek_offline.py` injects dummy keys and blocks external sockets, allowing only loopback for Windows asyncio. Real SDK sync/async calls with budget 0 fail before send. Mock HTTP 200 responses in tests are fixtures, not provider receipts.
- Initial broader run without dummy Google credentials had 34 constructor/credential failures (122 passed). The hermetic runner supplies dummy credentials for existing Google constructor tests; final rerun passes. No real credentials were used to fix those failures.
- Targeted Ruff and Git whitespace checks PASS.
- BeeWise `check_e2e_harness.py`: PASS, 27 unique scenario functions. `check_artemis_runner.py`: PASS synthetic process/stop guards. `check_artemis_report_parser.py`: PASS. These do not execute Android or inference.
- Exact TC-09 pytest selector: collect-only PASS, one test collected, no test run.
- Real HTTP client → new host status/devices: PASS at timestamp in receipt. Zero devices; tasks submitted 0. Host root HTML HTTP 200. This proves API connectivity, not device action or model inference compatibility.

Reproduce source regression in the ARTEMIS checkout:

```powershell
rtk proxy .venv/Scripts/python.exe scripts/check_deepseek_offline.py --junitxml=D:/CodexTemp/deepseek-offline-review.xml
```

## ONE TC-09 live smoke proposal — OWNER APPROVED / EXECUTED ONCE / FAILED

The following proposal and initial preflight are retained chronologically. The final live result is recorded below. Authorization for one case has been used; remaining numeric request allowance is not permission to repeat the case.

Owner explicitly approved this exact single-case proposal on 2026-11-05. Acceptance is limited to one TC-09, at most 12 HTTP attempts, 600 seconds and the stated cost assumptions. It does not authorize a second test, exploration, Gemini fallback, credit purchase, quota/cloud changes or deployment. See `owner-approval.json` and `preflight-20261105.json` in the evidence directory for the later preflight; the original offline receipts above remain historical.

The owner subsequently placed the key in the ignored tool-local `.env`. It was consumed programmatically without displaying it. One authenticated **GET `/models`** returned HTTP 200 and confirms this account lists `deepseek-flash` with `text,image` input, context 1048576 and max output 393216; `deepseek-v4-pro` lists text input only. This is model discovery, not inference success. To conservatively include this read within the approved 12 total HTTP attempts, only **11 inference attempts remain**. Launch with `--approved-live-budget 11`, not 12. Do not reset this accounting.

Existing API37 AVD booted preserving userdata; ARTEMIS sees `emulator-5560`. BeeWise is installed (APK SHA256 `38b5312db84237af2424a144cfe704f1150dea4103e37c75fd84d11add33bdb9`), and eventually renders Home behind a persistent **System UI isn't responding** dialog. `am start -W` timed out. No dialog was dismissed or detection disabled; no task/inference was submitted. Current device precondition is BLOCKED. The installed APK's source revision has not been established. An API35 system image is installed, but there is no existing API35 AVD in the current AVD listing; creating a separate AVD requires owner approval under the local instruction about system configuration changes.

Further targeted inspection found the previously validated API35 AVD under a **different AVD home**, `D:/CodexTemp/beewise-lab3-tools/bao-complete-private/avd`. It was absent only from the default AVD listing; no new AVD/configuration was needed. The API37 instance started for this check was closed normally, preserving userdata. Existing `BeeWise_Bao_Acceptance_API35` booted on `emulator-5562`, preserving userdata. It too displayed a persistent **System UI isn't responding** dialog and its launch wait timed out. APK SHA256 `3542276a8108123056c93eaa9524490c5dfa58186115daa2381031fba1ae568f` matches the genuine F-02 receipt in `evidence/cloud/f02-lite-native-20261104/README.md`; associated source SHA is `3c5961aacdd50e3490beea63578628a8dc88c61f`. These System UI failures block the controlled smoke precondition and are not proof of a BeeWise or DeepSeek defect. No ANR dialog was dismissed or detection suppressed. Stable guest Home has not been verified; no live TC-09 was submitted.

`host.py` can consume the owner's ignored tool-local `.env` for approved live mode only, with process environment taking precedence. Zero-budget mode does not read the key file.

Preconditions: owner supplies key privately; authenticated `/models` confirms Flash image input; emulator online and settled; correct BeeWise APK installed; owner/native screenshot confirms guest Home and no personal data; patched host healthy; no second host or queued task. Preserve userdata. If a device is signed in, do not clear app data to make this pass. Confirm a safe guest session first.

Scope: exactly `TC-09`, Flash agent profile, Explorer tier `pro` only if needed. Visit Trang chủ → Tìm gia sư → Ghép AI → Tin nhắn → Tài khoản; validate each title, overflow and crash observations. Do not enter account credentials, invoke BeeWise's AI Matching, create records, run exploration or retry the whole case.

Provider/model/endpoint: official DeepSeek `deepseek-flash`, `https://api.deepseek.com/chat/completions`, non-thinking function tools. No Gemini fallback is permitted in this host. Published capability does not substitute for the pending owner-account discovery check.

Budget: estimated 8–12 HTTP attempts including Hopper, operator, outputter and any subagent/recovery calls; **maximum 12 total attempts**, shared counter reserved before network send. SDK retries 0, visual summarizer disabled, memory retries 0, Flash max 8 turns. ARTEMIS wrapper recovery may still consume attempts; it cannot exceed the shared cap. Reject payloads above 8 images, 32768 non-image JSON bytes, or 2048 output tokens. Stop rather than truncate evidence. These conservative bounds can stop the case before completion; do not increase them silently.

Cost proposal: under **$0.18** assuming 12 calls of 40960 input + 2048 output tokens. Byte bounds are not exact token counts; this is not a hard cost cap. Using a full 1048576-token context per call gives a conservative **$3.81** ceiling at the cited peak rates. Confirm account limits/pricing; stop if assumptions differ. No search/fetch, credit purchase, automatic top-up, quota increase or provider substitution.

After explicit approval ONLY: stop the zero-budget host; use a fresh private state directory and the same `host.py` command with `--approved-live-budget 12`. This switch does not itself constitute owner authorization. The inference key remains in its environment, not the command. Then, from the BeeWise investigation worktree, substitute the actually verified serial and fresh private output path:

```powershell
$env:ARTEMIS_BASE_URL = 'http://127.0.0.1:8001'
$env:ARTEMIS_DEVICE_SERIAL = '<verified-online-guest-device>'
rtk proxy D:/CodexTemp/artemis-deepseek-audit/.venv/Scripts/python.exe -m pytest -c e2e_test/pyproject.toml e2e_test/test_account_and_firebase.py::test_tc09_all_top_level_destinations_are_reachable -q -s --junitxml=<fresh-private-path>/tc09.junit.xml
```

Do not use `run-artemis.ps1` here: it deliberately enforces three repetitions, exceeding the approved single-case proposal. Existing harness remains unchanged. Its client wait is bounded to 600 seconds; operator must stop the corresponding remote task via `ArtemisClient.stop(task_id)` and stop the isolated host if timeout/cancellation leaves a worker active. Stop on quota detection, request-cap rejection, unrecoverable transport/schema error, sensitive screen, unexpected provider, crash, or elapsed 600 seconds. SDK requests have bounded endpoint timeouts; no manual repeat or budget reset is allowed. A failed/blocked case is retained as such.

The pre-run evidence requirement was to retain trace ID, real ordered device actions/screenshots, output, JUnit, model/endpoint metadata, shared attempt count and usage/cost where available. Those actual receipts now appear below, including the failing output contract. Raw traces remain private. API success without Android actions is not acceptance.

## Actual authorized TC-09 result and corrective patch

Owner separately approved the normal **Wait** action on the API35 System UI dialog: “Cho bấm Wait, giữ nguyên bằng chứng ANR”. This was a recovery action, not a clean-start PASS. ANR receipts remain intact; detection/settings and userdata were unchanged. Account showed “Chưa đăng nhập”; Home remained responsive before submitting the task. The two AVD boot failures are not reclassified as app/provider defects or erased by subsequent recovery.

| Fact | Actual receipt |
|---|---|
| Trace ID | `69488a18-9d58-4249-8625-0e1682127982` |
| Date/time | 2026-11-05, 20:59:34–21:00:06 Asia/Bangkok (UTC timestamps also preserved) |
| Android | Existing API35 AVD, `emulator-5562`, preserved userdata, signed out |
| APK | SHA256 `3542276a8108123056c93eaa9524490c5dfa58186115daa2381031fba1ae568f`; source `3c5961aacdd50e3490beea63578628a8dc88c61f` |
| Live ARTEMIS source | Baseline 351ca842 + patch SHA256 `2f7eb80593f4940945d6c06ea1381cf2284d07dbd29889c904182d527af63803`, retained as `artemis-live-tested.patch` |
| Inference | **5** DeepSeek Flash attempts, five parsed real model responses; no Gemini fallback |
| Total approved-provider HTTP | **6/12**: one model-list GET + five inference calls |
| Native activity | Initial Home plus four successful taps: Tìm gia sư → Ghép AI → Tin nhắn → Tài khoản; five genuine recorded frames reviewed |
| App AI Matching | Only its tab was opened; no prompt entered and no Matching invocation |
| Agent status | `completed` (agent self-report only) |
| Actual pytest status | **FAIL**, one test, exit 1; missing `destinations` list |
| Actual output | `observations` list with five entries. Original key retained, no aliasing/renaming to manufacture PASS |
| Usage | 44321 prompt + 848 completion = 45169 SDK-reported tokens across the five steps |
| Cost | Conservative uncached peak-rate estimate **$0.0143139**, not a billing receipt; discounts not assumed |
| Session end | Host idle after case; live host stopped. No second case or inference after correction |

Native image evidence: `tc09-native/home.jpg`, `search.jpg`, `matching.jpg`, `messages.jpg`, `account.jpg`. Native frames show the actual guest screens; no crash dialog appears during this run. They do not negate the earlier System UI ANRs. Agent wording equated `overflow_seen` with an overflow-menu icon; retain that interpretation limitation rather than claiming a complete visual-overflow audit.

Machine-readable evidence: `tc09-live-summary.json`, `tc09-actions.json`, `tc09-final-report.json`, `tc09-observed-output.json`, **`tc09-failed.junit.xml`**. No private thinking, prompt/response bodies from unrelated tasks, credentials or account data are exported. JUnit hostname alone is redacted. Original raw files stay private outside Git.

The concrete report failure is explained by SDK control flow: `expected_output` reaches CLI `--output-description` and becomes `OutputConfig`, but Flash received only `request.goal`, then returned before the Pro-only `_extract_output` path. The model therefore did not receive the required `destinations` contract. The isolated corrective patch adds `_flash_goal` and passes the existing output config into the Flash prompt. It preserves the goal unchanged when no output config is supplied and adds no model request. It does not implement an output alias, change pytest expectations or rewrite recorded results. Prompt forwarding alone does not guarantee schema adherence on a future request.

Corrective patch SHA256: `c931d74c67b3e0f9b94eb68593018ffef7e0a7eea6c3e0dfa1b26b03978e9e65`; path remains `tools/artemis-deepseek/artemis-351ca842-deepseek.patch`. The live-tested earlier patch is preserved separately because the corrected version was **not** live-tested. Focused offline regression after correction: **160 PASS / 0 FAIL**, receipt `offline-post-live.junit.xml`. Two additional offline supervision fixtures verify the 550-second inner bound is forwarded and remote stop occurs on failure. Targeted Ruff/whitespace checks pass. There were no additional provider requests for these checks.

## Remaining decision

The stock revision requires the compatibility patch. Official DeepSeek Flash image input, actual tool responses and native tab taps now have genuine evidence for this one guest run. Strict TC-09 acceptance remains FAIL because of the output contract; the SDK handoff correction is verified offline only. Full Pro, Hopper/Outputter live behavior, long histories, robotics parity and complete repeatability remain unverified. Do not run again under this used single-case authorization, even though six HTTP attempts were unused. Any corrective live rerun needs a separately approved bounded scope. BeeWise app/Firebase/Gemini Matching/payOS and Nguyen-owned implementation remain unchanged. No PR was opened, pushed or merged.
