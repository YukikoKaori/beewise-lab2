"""Offline rejection checks only; zero Android sessions and zero provider calls."""

import asyncio
import copy
import json
import sys
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "e2e_test"))
from conftest import _decode_observation, run_flow
from test_account_and_firebase import test_tc09_all_top_level_destinations_are_reachable
from test_exploratory import test_tc25_pro_exploratory_session

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/artemis-deepseek"))
from native_ready import validate_fixture, validate_idle, validate_ready
from policy import require_live_authorization, validate_retry_policy


async def check():
    held = {"approved_inference_requests": 240, "approved_usd": 0.5,
            "live_hold_reason": "OWNER_AMENDMENT_REQUIRED_AFTER_SIX_FAILURES"}
    with patch("policy.Path.read_text", return_value=json.dumps(held)):
        try:
            require_live_authorization()
        except ValueError as error:
            assert "Live authorization held" in str(error)
        else:
            raise AssertionError("Exhausted N-03 policy must hold live host startup")
    prior = [("TC-03", state) for state in ("FAILED", "FAILED", "ACCEPTED", "FAILED")]
    selected = {"TC-03", "TC-04"}
    for additional in range(3):
        validate_retry_policy(prior + [("TC-03", "ACCEPTED")] * additional, selected)
    for rows in (prior + [("TC-03", "FAILED")], prior + [("TC-03", "ACCEPTED")] * 3,
                 prior + [("TC-04", "FAILED")] * 3):
        try:
            validate_retry_policy(rows, selected)
        except ValueError:
            continue
        raise AssertionError("Amendment cannot cover new TC-03 failure, excess admission or other cases")
    with patch("policy.Path.read_text", return_value="{}"):
        try:
            validate_retry_policy(prior, selected)
        except ValueError:
            pass
        else:
            raise AssertionError("TC-03 cannot bypass the original retry gate without owner approval")
    idle = {"status": "idle", "queue": [], "active_tasks": [], "background_tasks": []}
    validate_idle(idle)
    for change in ({"status": "running"}, {"status": "paused"}, {"queue": [{}]},
                   {"active_tasks": [{}]}, {"background_tasks": [{"status": "pending"}]}):
        try:
            validate_idle({**idle, **change})
        except ValueError:
            continue
        raise AssertionError("Busy ARTEMIS must fail before paid admission")
    tutor = {"fields": {"active": {"booleanValue": True},
                        "verified": {"booleanValue": False}, "demoOnly": {"booleanValue": True}}}
    validate_fixture("TC-03", tutor)
    for case, state in (("TC-20", "trial_proposed"), ("TC-22", "class_revision_pending")):
        chat = {"fields": {"onboardingStatus": {"stringValue": state},
                           "parentId": {"stringValue": "n03-parent"}}}
        validate_fixture(case, tutor, chat)
        for invalid in ({}, {"fields": {"onboardingStatus": {"stringValue": "consumed"}}}):
            try:
                validate_fixture(case, tutor, invalid)
            except ValueError:
                continue
            raise AssertionError("Missing/consumed workflow fixture must block admission")
    try:
        validate_fixture("TC-03", {})
    except ValueError:
        pass
    else:
        raise AssertionError("Missing demo catalogue must block admission")
    ready_xml = '<hierarchy><node package="com.beewise.beewise" text="BeeWise"/></hierarchy>'
    focus = 'mCurrentFocus=Window{abc u0 com.beewise.beewise/.MainActivity}'
    validate_ready("1", focus, ready_xml)
    for boot, window, xml in (
        ("0", focus, ready_xml),
        ("1", "mCurrentFocus=null", ready_xml),
        ("1", "mCurrentFocus=Window{abc Application Not Responding: com.beewise.beewise}", ready_xml),
        ("1", focus, '<hierarchy/>'),
        ("1", focus, '<hierarchy><node text="BeeWise isn\'t responding"/></hierarchy>'),
    ):
        try:
            validate_ready(boot, window, xml)
        except ValueError:
            continue
        raise AssertionError("Unsafe/unrendered Android must fail before paid admission")
    class OutputContract:
        device_serial = "offline-no-device"

        async def run(self, goal, **kwargs):
            assert "report_task_status" in goal and "explanation argument itself" in goal
            assert 'Required explanation contract: {"count":integer}' in goal
            return SimpleNamespace(trace_id="offline-not-evidence", status="completed",
                                   succeeded=True, output={"count": 0},
                                   device_serial=self.device_serial)

    # Exercise the shared fixture's actual task builder, without HTTP or Android.
    built = run_flow.__wrapped__(OutputContract())
    assert (await built(case_id="TC-offline", start="offline", steps="offline",
                        expected='{"count":integer}'))["count"] == 0
    try:
        _decode_observation("Completed the empty-result flow successfully")
    except AssertionError:
        pass
    else:
        raise AssertionError("Prose must not substitute for a required JSON report")

    names = ["Trang chủ", "Tìm gia sư", "Ghép AI", "Tin nhắn", "Tài khoản"]
    valid = {"destinations": [{"name": name, "title_visible": True,
                              "overflow_seen": False, "crash_dialog_seen": False} for name in names]}

    async def run(observation):
        async def offline_flow(**kwargs):
            assert "layout" in kwargs["steps"] and "Do not submit AI requests" in kwargs["steps"]
            return _decode_observation(observation)
        await test_tc09_all_top_level_destinations_are_reachable(offline_flow)

    await run(valid)
    invalid = [{"observations": valid["destinations"]},
               {"destinations": list(reversed(valid["destinations"]))},
               {"destinations": valid["destinations"][:-1]}]
    for key, value in (("title_visible", False), ("overflow_seen", True),
                       ("crash_dialog_seen", True), ("overflow_seen", "false")):
        row = copy.deepcopy(valid)
        row["destinations"][0][key] = value
        invalid.append(row)
    for row in invalid:
        try:
            await run(row)
        except AssertionError:
            continue
        raise AssertionError("Malformed/failed navigation must never become an accepted PASS")

    class EarlyStop:
        device_serial = "offline-no-device"

        async def run(self, *args, **kwargs):
            assert kwargs["profile"] == "pro"
            assert "never submit a Gemini/provider request" in args[0]
            return SimpleNamespace(trace_id="offline-not-evidence", status="completed",
                                   succeeded=True, error=None, output={"elapsed_minutes": 20})

    try:
        await test_tc25_pro_exploratory_session(EarlyStop())
    except AssertionError as error:
        assert "Measured exploration" in str(error)
    else:
        raise AssertionError("A reported 20 minutes cannot replace measured duration")
    with patch("policy.Path.read_text", return_value=json.dumps({"approved_inference_requests": 0,
                                                               "approved_usd": 0})):
        for requests, cost in ((1, 1), (500, 5_000_000_000)):
            try:
                require_live_authorization(requests, cost)
            except ValueError as error:
                assert "authorization" in str(error)
            else:
                raise AssertionError("Owner zero budget must block live execution")
    print("PASS: strict TC-09, measured TC-25 duration and owner $0 gate; Android NOT RUN.")


if __name__ == "__main__":
    asyncio.run(check())
