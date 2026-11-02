"""Shared ARTEMIS client and strict evidence assertions for BeeWise flows."""

from __future__ import annotations

import json
import os
import re
from collections.abc import AsyncIterator, Callable
from typing import Any

import pytest
import pytest_asyncio
from artemis_client import ArtemisClient, TaskResult

APP_PACKAGE = "com.beewise.beewise"


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
        result: TaskResult = await artemis.run(
            goal,
            profile=profile,  # type: ignore[arg-type]
            device_serial=artemis.device_serial,
            locked_app_package=APP_PACKAGE,
            expected_output=(
                "Return a JSON object only, matching this observable contract: "
                + expected
            ),
            enable_outputter=True,
            timeout=timeout,
        )
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
                raise AssertionError(
                    f"ARTEMIS output was not the required JSON observation: {text!r}"
                ) from error
    else:
        raise AssertionError(
            f"ARTEMIS did not return a structured observation: {output!r}"
        )
    if not isinstance(value, dict):
        raise AssertionError(f"Expected a JSON object, received {value!r}")
    home_title_key = next(
        (key for key in ("Home title", "home_title") if key in value), None
    )
    count_key = next(
        (
            key
            for key in (
                "Number of tutor cards",
                "number_of_tutor_cards",
                "tutor_cards_count",
                "tutor_cards_count",
                "tutor_card_count",
            )
            if key in value
        ),
        None,
    )
    if home_title_key is not None and count_key is not None:
        # Normalize ARTEMIS final reports to TC-01's machine-readable schema.
        # A zero count plus explicit provenance confirmation is required.
        count = value[count_key]
        if not isinstance(count, int):
            raise AssertionError(f"ARTEMIS reported an invalid tutor count: {count!r}")
        provenance = str(
            value.get(
                "Tutor cards from real Firestore results",
                value.get("firestore_confirmation", ""),
            )
        ).lower()
        fabricated_confirmed = value.get("fabricated_profiles_confirmed")
        explicit_no_fabrication = (
            fabricated_confirmed is False
            or "no fabricated profile claims" in provenance
            or "no fabricated profiles" in provenance
        )
        if count != 0 or not explicit_no_fabrication:
            raise AssertionError(
                "ARTEMIS did not confirm that TC-01 showed no fabricated "
                "tutor profiles."
            )
        home_title = str(value[home_title_key]).strip()
        tabs = value.get(
            "Top-level destinations",
            value.get("visible_top_level_destinations", value.get("top_level_destinations")),
        )
        firebase_notice = value.get(
            "Firebase setup/error notice",
            value.get("firebase_setup_or_error_notice", value.get("firebase_notice")),
        )
        if tabs is None:
            tabs = value.get("top_level_destinations", value.get("tabs"))
        value = {
            "screen": "Home" if home_title.lower() == "beewise" else home_title,
            "tabs": tabs,
            "tutor_card_count": count,
            "firebase_notice_visible": firebase_notice not in (None, "None", False),
            "profiles_fabricated": False,
        }
    navigation_labels = ("Trang chủ", "Tìm gia sư", "Ghép AI", "Tin nhắn", "Tài khoản")
    if "overflow_or_crash" in value and any(label in value for label in navigation_labels):
        issue = str(value["overflow_or_crash"] or "").strip().lower()
        value = {
            "visible_destinations": [label for label in navigation_labels if label in value],
            "overflow_seen": "overflow" in issue,
            "crash_dialog_seen": "crash" in issue,
        }
    return value


def _decode_tc01_prose(text: str) -> dict[str, Any] | None:
    normalized = text.replace("\\n", "\n")
    title = re.search(r"Home title:\s*(.+)", normalized, re.IGNORECASE)
    tabs_match = re.search(
        r"Visible top-level destinations:\s*(.+)", normalized, re.IGNORECASE
    )
    notice = re.search(
        r"Firebase setup/error notice:\s*(.+)", normalized, re.IGNORECASE
    )
    count = re.search(
        r"Number of tutor cards:\s*(\d+)", normalized, re.IGNORECASE
    )
    provenance = re.search(
        r"Visible real Firestore results/fabrication check:\s*(.+)",
        normalized,
        re.IGNORECASE,
    )
    if not all((title, tabs_match, notice, count, provenance)):
        return None
    card_count = int(count.group(1))
    provenance_text = provenance.group(1).lower()
    if card_count != 0 or "no fabricated profile claims" not in provenance_text:
        raise AssertionError("TC-01 did not confirm absence of fabricated tutors.")
    tab_text = re.sub(r"\s*\(\d+ tabs?\)\s*$", "", tabs_match.group(1))
    return {
        "screen": "Home" if title.group(1).strip().lower() == "beewise" else title.group(1).strip(),
        "tabs": [tab.strip() for tab in tab_text.split(",") if tab.strip()],
        "firebase_notice_visible": notice.group(1).strip().lower() not in {"none", "no", "false"},
        "tutor_card_count": card_count,
        "profiles_fabricated": False,
    }


def require(observed: dict[str, Any], key: str, expected_type: type) -> Any:
    value = observed.get(key)
    assert isinstance(value, expected_type), (
        f"Expected {key!r} to be {expected_type.__name__}; got {value!r}. "
        f"Trace: {observed.get('_trace_id')}"
    )
    return value
