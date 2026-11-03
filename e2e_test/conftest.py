"""Shared ARTEMIS client and strict evidence assertions for BeeWise flows."""

from __future__ import annotations

import asyncio
import json
import os
import re
import uuid
from collections.abc import AsyncIterator, Callable
from typing import Any

import pytest
import pytest_asyncio
from artemis_client import ArtemisClient, TaskResult

APP_PACKAGE = "com.beewise.beewise"
def _trace_has_rate_limit(trace: Any) -> bool:
    """Detect quota errors only in structured error fields, never prompt/narrative text."""
    error_keys = {"error", "errors", "exception", "failure", "last_error", "error_message"}
    status_keys = {
        "status_code", "http_status", "http_status_code", "error_code",
        "status", "code",
    }
    error_markers = re.compile(
        r"(?:\b429\s+too\s+many\s+requests\b|\bresource_exhausted\b|"
        r"\bquota exceeded for metric\b|\byou exceeded your current quota\b|"
        r"\bprovider quota/rate-limit error\b)",
        re.IGNORECASE,
    )
    negative_claim = re.compile(
        r"\b(?:no|not|without|never)\s+(?:http\s*)?429\b|"
        r"\b(?:no|not|without|never)\s+(?:provider\s+)?(?:quota|rate[- ]limit)\b",
        re.IGNORECASE,
    )

    def visit(value: Any, in_error: bool = False) -> bool:
        if isinstance(value, dict):
            for raw_key, child in value.items():
                key = str(raw_key).lower()
                child_is_error = in_error or key in error_keys
                if key in status_keys:
                    typed_429 = (type(child) is int and child == 429) or (
                        isinstance(child, str) and child.strip() == "429"
                    )
                    if typed_429 and (in_error or key in {
                        "status_code", "http_status", "http_status_code"
                    } or any(str(k).lower() in error_keys for k in value)):
                        return True
                    if (isinstance(child, str)
                            and child.strip().upper() == "RESOURCE_EXHAUSTED"
                            and (in_error or any(str(k).lower() in error_keys for k in value))):
                        return True
                if key in error_keys and isinstance(child, str):
                    if not negative_claim.search(child) and error_markers.search(child):
                        return True
                if visit(child, child_is_error):
                    return True
            return False
        if isinstance(value, list):
            return any(visit(item, in_error) for item in value)
        return False

    return visit(trace)


@pytest_asyncio.fixture(scope="session")
async def artemis() -> AsyncIterator[ArtemisClient]:
    base_url = os.environ.get("ARTEMIS_BASE_URL")
    device_serial = os.environ.get("ARTEMIS_DEVICE_SERIAL")
    if not base_url or not device_serial:
        pytest.fail(
            "Set ARTEMIS_BASE_URL and ARTEMIS_DEVICE_SERIAL after starting the "
            "pinned ARTEMIS host and connecting the Android device."
        )

    client = ArtemisClient(
        base_url,
        token=os.environ.get("ARTEMIS_TOKEN"),
        device_serial=device_serial,
        default_profile="flash",
        request_timeout=60,
        poll_interval=2,
    )
    health = await client.health()
    print(f"ARTEMIS_HOST_HEALTH={json.dumps(health, ensure_ascii=False)}")
    devices = await client.list_devices()
    matches = [device for device in devices if device.serial == device_serial]
    if not matches:
        pytest.fail(
            f"Device {device_serial!r} is not listed by ARTEMIS; "
            f"available serials: {[device.serial for device in devices]}"
        )
    if matches[0].busy:
        pytest.fail(f"ARTEMIS device {device_serial!r} is already busy.")

    yield client


@pytest.fixture
def run_flow(artemis: ArtemisClient) -> Callable[..., Any]:
    async def run(
        *,
        case_id: str,
        start: str,
        steps: str,
        expected: str,
        profile: str = "flash",
        timeout: int = 600,
    ) -> dict[str, Any]:
        goal = (
            f"Test case {case_id}. Starting point: {start}.\n"
            f"Steps: {steps}\n"
            "Use only visible app/device state. Do not invent records or results. "
            "At the end report the requested values as one JSON object."
        )
        session_id = str(uuid.uuid4())
        remote_run = asyncio.create_task(
            artemis.run(
                goal,
                profile=profile,  # type: ignore[arg-type]
                device_serial=artemis.device_serial,
                locked_app_package=APP_PACKAGE,
                expected_output=(
                    "Return a JSON object only, matching this observable contract: "
                    + expected
                ),
                enable_outputter=True,
                task_id=session_id,
                timeout=timeout,
            )
        )
        quota_detected = False
        while not remote_run.done():
            await asyncio.sleep(2)
            try:
                trace = await artemis._request(
                    "GET", f"/api/sessions/{session_id}/steps"
                )
            except Exception:
                # The session may not be persisted until scheduler admission.
                continue
            if _trace_has_rate_limit(trace):
                quota_detected = True
                try:
                    await artemis.stop(session_id)
                finally:
                    try:
                        await asyncio.wait_for(remote_run, timeout=20)
                    except Exception:
                        remote_run.cancel()
                break

        if quota_detected:
            pytest.fail(
                f"{case_id} blocked: ARTEMIS trace {session_id} reports a provider "
                "quota/rate-limit error; the task was stopped before further retries."
            )

        result: TaskResult = await remote_run
        print(
            f"ARTEMIS_RESULT case={case_id} trace_id={result.trace_id} "
            f"status={result.status} device={result.device_serial}"
        )
        assert result.trace_id, f"{case_id} has no trace provenance"
        assert result.succeeded, f"{case_id} failed: {result.error or result.status}"
        output = result.output
        if output is None:
            # Some ARTEMIS hosts persist the final report as a trace step but
            # omit it from GET /api/sessions/{id}; recover that same report
            # instead of treating a completed, evidenced run as output-less.
            output = await _trace_report(artemis, result.trace_id)
        observed = _decode_observation(output)
        observed["_trace_id"] = result.trace_id
        observed["_status"] = result.status
        return observed

    return run


async def _trace_report(artemis: ArtemisClient, trace_id: str) -> Any:
    payload = await artemis._request("GET", f"/api/sessions/{trace_id}/steps")
    steps = payload if isinstance(payload, list) else (
        payload.get("steps") if isinstance(payload, dict) else None
    )
    if not isinstance(steps, list):
        raise AssertionError(f"ARTEMIS trace {trace_id} has no readable steps.")

    for step in reversed(steps):
        action = step.get("action_taken") if isinstance(step, dict) else None
        if not isinstance(action, dict) or action.get("action") != "report_task_status":
            continue
        args = action.get("args")
        explanation = args.get("explanation") if isinstance(args, dict) else None
        if explanation is not None:
            return _decode_observation(explanation)
    raise AssertionError(f"ARTEMIS trace {trace_id} has no final task report.")


def _decode_observation(output: Any) -> dict[str, Any]:
    if isinstance(output, dict):
        value = output
    elif isinstance(output, str):
        text = output.strip()
        fenced = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.S)
        candidate = fenced.group(1) if fenced else text
        try:
            value = json.loads(candidate)
        except json.JSONDecodeError as error:
            start, end = text.find("{"), text.rfind("}")
            embedded = text[start : end + 1].replace("\\n", "\n") if start >= 0 and end > start else ""
            try:
                value = json.loads(embedded) if embedded else _decode_tc01_prose(text)
            except json.JSONDecodeError:
                value = _decode_tc01_prose(text)
            if value is None:
                value = _decode_tc09_prose(text)
            if value is None:
                raise AssertionError(
                    f"ARTEMIS output was not the required JSON observation: {text!r}"
                ) from error
    else:
        raise AssertionError(
            f"ARTEMIS did not return a structured observation: {output!r}"
        )
    if not isinstance(value, dict):
        raise AssertionError(f"Expected a JSON object, received {value!r}")
    expected_destinations = ["Trang chủ", "Tìm gia sư", "Ghép AI", "Tin nhắn", "Tài khoản"]
    destination_rows = value.get("destinations")
    if isinstance(destination_rows, list) and all(
        isinstance(destination, str) for destination in destination_rows
    ):
        raise AssertionError(
            "TC-09 requires a title_visible observation for each destination; "
            "a bare list of destination names is insufficient."
        )
    if isinstance(destination_rows, list) and all(
        isinstance(row, dict) for row in destination_rows
    ):
        if len(destination_rows) != len(expected_destinations):
            raise AssertionError("TC-09 must report exactly five destination observations.")
        visible_destinations = []
        overflow_seen = False
        crash_seen = False
        for row in destination_rows:
            name = row.get("name")
            if (not isinstance(name, str)
                    or type(row.get("title_visible")) is not bool
                    or type(row.get("overflow_seen")) is not bool
                    or type(row.get("crash_dialog_seen")) is not bool):
                raise AssertionError("TC-09 destination entries need a name and boolean title visibility.")
            if row["title_visible"] is not True:
                raise AssertionError(f"TC-09 destination title was not observed: {name!r}.")
            visible_destinations.append(name)
            has_overflow = row["overflow_seen"]
            has_crash = row["crash_dialog_seen"]
            overflow_seen = overflow_seen or has_overflow
            crash_seen = crash_seen or has_crash
        if visible_destinations != expected_destinations:
            raise AssertionError(
                "TC-09 must report exactly the five unique top-level destinations in order."
            )
        value = {
            "visible_destinations": visible_destinations,
            "overflow_seen": overflow_seen,
            "crash_dialog_seen": crash_seen,
        }
    normalized_keys = {
        re.sub(r"[^a-z0-9]", "", str(key).lower()): key for key in value
    }

    def report_value(*aliases: str) -> tuple[str | None, Any]:
        for alias in aliases:
            key = normalized_keys.get(re.sub(r"[^a-z0-9]", "", alias.lower()))
            if key is not None:
                return key, value[key]
        return None, None

    home_title_key, home_title_value = report_value(
        "Home title", "app bar title", "screen title"
    )
    count_key, count = report_value(
        "Number of tutor cards", "tutor cards count", "tutor card count"
    )
    if home_title_key is not None and count_key is not None:
        # Normalize ARTEMIS final reports to TC-01's machine-readable schema.
        # Do not infer a no-fabrication claim from an empty list/count or generic Firestore availability.
        if type(count) is not int:
            raise AssertionError(f"ARTEMIS reported an invalid tutor count: {count!r}")
        _, provenance_value = report_value(
            "Firestore results fabricated profile claims",
            "Profile claims confirmation",
            "No fabricated profile claims",
            "Fabrication check",
            "Verified Firestore result confirmation",
            "Tutor cards from real Firestore results",
            "Firestore confirmation",
        )
        provenance = str(provenance_value or "").lower()
        fabricated_key, fabricated_value = report_value(
            "Profiles fabricated", "Profiles_fabricated", "Fabricated profiles confirmed",
            "Fabricated profile claims",
        )
        if fabricated_key is not None and type(fabricated_value) is not bool:
            raise AssertionError("TC-01 profiles_fabricated must be an explicit boolean.")
        affirmative_fabrication_claim = isinstance(provenance_value, str) and bool(
            re.search(
                r"\b(?:fabricated profiles?|fabricated profile claims?)\s+"
                r"(?:are\s+)?(?:present|visible|confirmed)\b",
                provenance_value,
                re.IGNORECASE,
            )
        ) and not re.search(r"\b(?:no|not|without|zero)\b", provenance_value, re.IGNORECASE)
        explicit_no_fabrication = (
            (fabricated_key is not None and fabricated_value is False)
            or "no fabricated profile claims" in provenance
            or "no fabricated profiles" in provenance
            or "zero fabricated profile claims" in provenance
        )
        if (count != 0 or not explicit_no_fabrication or fabricated_value is True
                or affirmative_fabrication_claim):
            raise AssertionError(
                "ARTEMIS did not confirm that TC-01 showed no fabricated "
                "tutor profiles."
            )
        home_title = str(home_title_value).strip()
        _, tabs = report_value(
            "Top-level destinations", "Visible top-level destinations", "Tabs"
        )
        firebase_notice_key, firebase_notice = report_value(
            "Firebase setup/error notice",
            "Firebase setup or error notice",
            "Firebase notice",
            "Firebase notice visible",
        )
        if firebase_notice_key is None:
            raise AssertionError("TC-01 report omitted the Firebase notice observation.")
        value = {
            "screen": "Home" if home_title.lower() == "beewise" else home_title,
            "tabs": tabs,
            "tutor_card_count": count,
            "firebase_notice_visible": (
                bool(firebase_notice)
                if re.sub(r"[^a-z0-9]", "", firebase_notice_key.lower())
                == "firebasenoticevisible"
                else bool(str(firebase_notice).strip())
                and not str(firebase_notice).strip().lower().startswith(
                    ("none", "no", "false")
                )
            ),
            "profiles_fabricated": False,
        }
    return value


def _decode_tc01_prose(text: str) -> dict[str, Any] | None:
    normalized = text.replace("\\n", "\n")
    title = re.search(
        r"(?:Home title|App-bar title)(?: is)?:?\s*['\"]?([^.'\"\n]+)",
        normalized,
        re.IGNORECASE,
    )
    tabs_match = re.search(
        r"Visible top-level destinations(?::| are:)\s*([^\.\n]+)",
        normalized,
        re.IGNORECASE,
    )
    notice = re.search(
        r"Firebase setup/error notice:\s*([^\.\n]+)", normalized, re.IGNORECASE
    )
    count = re.search(
        r"Number of tutor cards:\s*(\d+)", normalized, re.IGNORECASE
    )
    provenance = re.search(
        r"(?:Visible real Firestore results/fabrication check|Firestore results / fabricated profile claims|Confirmed no fabricated profile claims):?\s*(.+)",
        normalized,
        re.IGNORECASE,
    )
    if all((title, tabs_match, notice, count, provenance)):
        title_text = title.group(1).strip()
        tab_text = tabs_match.group(1)
        notice_text = notice.group(1).strip().lower()
        card_count = int(count.group(1))
        provenance_text = provenance.group(1).lower()
        notice_visible = not notice_text.startswith(("none", "no", "false"))
        no_fabricated_profiles = bool(
            re.search(r"(?:no|zero) fabricated profile claims", normalized, re.IGNORECASE)
        )
    else:
        # ARTEMIS sometimes returns an evidence-bearing narrative despite the
        # JSON-only contract. Parse only explicit observations; never infer a
        # zero count or lack of Firebase notice from an omitted field.
        narrative_title = re.search(
            r"Home title is\s+['\"]([^'\"]+)['\"]", normalized, re.IGNORECASE
        )
        narrative_tabs = re.search(
            r"Visible top-level destinations(?:\s+\([^)]*\))?\s+are:\s*([^\.\n]+)",
            normalized,
            re.IGNORECASE,
        )
        narrative_count = re.search(
            r"number of tutor cards is\s*(\d+)", normalized, re.IGNORECASE
        )
        if not all((narrative_title, narrative_tabs, narrative_count)):
            return None
        title_text = narrative_title.group(1).strip()
        tab_text = narrative_tabs.group(1)
        card_count = int(narrative_count.group(1))
        no_notice = re.search(
            r"no explicit Firebase (?:setup/error )?notice", normalized, re.IGNORECASE
        )
        has_notice = re.search(
            r"(?:an explicit )?Firebase (?:setup/error )?notice (?:is visible|appears)",
            normalized,
            re.IGNORECASE,
        )
        if not no_notice and not has_notice:
            return None
        notice_visible = bool(has_notice) and not bool(no_notice)
        no_fabricated_profiles = bool(
            re.search(
                r"no fabricated profile claims (?:are )?present", normalized, re.IGNORECASE
            )
        )

    if card_count != 0 or not no_fabricated_profiles:
        raise AssertionError("TC-01 did not confirm absence of fabricated tutors.")
    tab_text = re.sub(r"\s*\(\d+ tabs?\)\s*$", "", tab_text)
    return {
        "screen": "Home" if title_text.lower() == "beewise" else title_text,
        "tabs": [tab.strip() for tab in tab_text.split(",") if tab.strip()],
        "firebase_notice_visible": notice_visible,
        "tutor_card_count": card_count,
        "profiles_fabricated": False,
    }


def _decode_tc09_prose(text: str) -> dict[str, Any] | None:
    return None


def require(observed: dict[str, Any], key: str, expected_type: type) -> Any:
    value = observed.get(key)
    valid_type = type(value) is int if expected_type is int else isinstance(value, expected_type)
    assert valid_type, (
        f"Expected {key!r} to be {expected_type.__name__}; got {value!r}. "
        f"Trace: {observed.get('_trace_id')}"
    )
    return value
