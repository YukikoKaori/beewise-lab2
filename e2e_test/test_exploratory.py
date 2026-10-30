"""One separate, unscripted ARTEMIS Pro exploratory session (15–30 minutes)."""

from __future__ import annotations

import pytest

from conftest import require


@pytest.mark.exploratory
@pytest.mark.asyncio
async def test_tc25_pro_exploratory_session(artemis):
    """TC-25; exploratory; run once separately, never as the Flash regression suite."""
    result = await artemis.run(
        "Test case TC-25. Explore the BeeWise Android app freely for 20 minutes as a parent. "
        "Start signed out on Home. Explore the Lab 2 discovery, search, AI "
        "matching, account, messages and Firebase demo flows, including one "
        "reasonable error/recovery path. Do not invent tutor records, create an "
        "account, submit personal data, send a real payment, or deliberately "
        "crash the app. At the end return one JSON object with elapsed_minutes, "
        "screens_explored, issues_found (each with screen, reproduction, "
        "severity), and any blocked actions.",
        profile="pro",
        device_serial=artemis.device_serial,
        locked_app_package="com.beewise.beewise",
        expected_output=(
            "Return only a JSON object containing elapsed_minutes (15 to 30), "
            "screens_explored (array), issues_found (array of screen, "
            "reproduction, severity), and blocked_actions (array)."
        ),
        enable_outputter=True,
        timeout=1800,
    )
    print(f"ARTEMIS_EXPLORATORY case=TC-25 trace_id={result.trace_id} status={result.status}")
    assert result.succeeded, result.error or result.status
    observation = result.output
    if isinstance(observation, str):
        import json

        observation = json.loads(observation)
    assert isinstance(observation, dict), "Exploratory result must be structured JSON."
    elapsed = require(observation, "elapsed_minutes", int)
    assert 15 <= elapsed <= 30
    require(observation, "screens_explored", list)
    require(observation, "issues_found", list)
    require(observation, "blocked_actions", list)
