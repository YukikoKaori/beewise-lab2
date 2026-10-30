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
        observed = _decode_observation(result.output)
        observed["_trace_id"] = result.trace_id
        observed["_status"] = result.status
        return observed

    return run


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
            raise AssertionError(
                f"ARTEMIS output was not the required JSON observation: {text!r}"
            ) from error
    else:
        raise AssertionError(
            f"ARTEMIS did not return a structured observation: {output!r}"
        )
    if not isinstance(value, dict):
        raise AssertionError(f"Expected a JSON object, received {value!r}")
    return value


def require(observed: dict[str, Any], key: str, expected_type: type) -> Any:
    value = observed.get(key)
    assert isinstance(value, expected_type), (
        f"Expected {key!r} to be {expected_type.__name__}; got {value!r}. "
        f"Trace: {observed.get('_trace_id')}"
    )
    return value
