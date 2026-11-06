"""Live supplement; run one admission after preparing the real permission prompt."""

import json
import os
import re
import subprocess
from datetime import UTC, datetime
from pathlib import Path
from xml.etree import ElementTree

import pytest
from conftest import APP_PACKAGE

CONTROLLER = "com.google.android.permissioncontroller"
PERMISSION = "android.permission.POST_NOTIFICATIONS"
BUTTONS = {
    "allow": "permission_allow_button",
    "deny": "permission_deny_button",
}


def permission_state(package_dump):
    """Read user 0's runtime grant, not the manifest's requested permission."""
    user = re.search(r"(?ms)^\s*User 0:.*?(?=^\s*User \d+:|\Z)", package_dump)
    match = re.search(
        rf"(?m)^\s*{re.escape(PERMISSION)}: granted=(true|false), flags=\[([^\]]*)\]",
        user[0] if user else "",
    )
    assert match, "The installed package has no readable user-0 notification grant"
    return {
        "granted": match[1] == "true",
        "flags": sorted(re.findall(r"[A-Z][A-Z_]+", match[2])),
    }


def button_bounds(hierarchy):
    found = {}
    for node in ElementTree.fromstring(hierarchy).iter("node"):
        for decision, resource in BUTTONS.items():
            if (
                node.get("resource-id")
                != f"com.android.permissioncontroller:id/{resource}"
            ):
                continue
            assert node.get("package") == CONTROLLER
            assert node.get("enabled") == node.get("clickable") == "true"
            bounds = [int(v) for v in re.findall(r"\d+", node.attrib["bounds"])]
            assert len(bounds) == 4 and bounds[0] < bounds[2] and bounds[1] < bounds[3]
            assert decision not in found, "Ambiguous Android permission button"
            found[decision] = bounds
    assert set(found) == set(BUTTONS), "Both real permission buttons must be actionable"
    return found


def assert_agent_tap(actions, bounds, size, decision):
    assert [a.get("action") for a in actions] == ["click", "report_task_status"]
    point = actions[0].get("normalized_coordinates")
    assert isinstance(point, list) and len(point) == 2
    assert all(type(v) is int and 0 <= v <= 1000 for v in point)
    x, y = (round(v * dim / 1000) for v, dim in zip(point, size, strict=True))
    left, top, right, bottom = bounds[decision]
    assert left <= x < right and top <= y < bottom, (
        "Agent tap missed the selected button"
    )
    return [x, y]


@pytest.mark.native_supplement
@pytest.mark.skipif(
    not os.getenv("BEEWISE_NATIVE_EVIDENCE"),
    reason="Native supplement requires explicit opt-in",
)
@pytest.mark.asyncio
async def test_native_notification_permission(artemis, run_flow):
    """TC-NATIVE-01: Android owns the prompt; ARTEMIS alone acts on it."""
    out = Path(os.environ["BEEWISE_NATIVE_EVIDENCE"])
    out.mkdir(parents=True, exist_ok=False)
    serial = os.environ["ARTEMIS_DEVICE_SERIAL"]
    assert re.fullmatch(r"emulator-\d+", serial), "A disposable emulator is required"
    adb = [os.environ.get("ADB", "adb"), "-s", serial]

    def cmd(*args):
        return subprocess.check_output([*adb, *args], timeout=15)

    def save(name, data):
        (out / name).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

    def capture(name):
        png = cmd("exec-out", "screencap", "-p")
        assert png.startswith(b"\x89PNG\r\n\x1a\n")
        (out / f"{name}.png").write_bytes(png)
        return [int.from_bytes(png[i : i + 4], "big") for i in (16, 20)]

    def focus():
        dump = cmd("shell", "dumpsys", "window").decode(errors="replace")
        windows = re.findall(r"mCurrentFocus=.*?\s([\w.]+/[\w.$]+)\}", dump)
        assert windows and len(set(windows)) == 1, (
            "Could not identify one focused window"
        )
        return windows[0]

    def grant():
        return permission_state(
            cmd("shell", "dumpsys", "package", APP_PACKAGE).decode()
        )

    assert cmd("shell", "getprop", "ro.build.version.sdk").strip() == b"35"
    assert cmd("emu", "avd", "name").splitlines()[0] == b"BeeWise_N03_Native_API35"
    pre = focus()
    assert pre.startswith(CONTROLLER + "/") and pre.endswith("GrantPermissionsActivity")
    before = grant()
    assert not before["granted"] and not {"USER_SET", "USER_FIXED"} & set(
        before["flags"]
    )
    # The preparer captures XML without touching the dialog. Keep raw hierarchy private.
    bounds = button_bounds(
        Path(os.environ["BEEWISE_NATIVE_PRE_XML"]).read_text(encoding="utf-8")
    )
    size = capture("before")
    assert focus() == pre
    save(
        "before.json",
        {
            "utc": datetime.now(UTC).isoformat(),
            "window": pre,
            "permission": before,
            "buttons": bounds,
            "screen_size": size,
        },
    )

    assert artemis.device_serial == serial
    decision = os.environ["BEEWISE_NATIVE_DECISION"]
    assert decision in BUTTONS
    observed = await run_flow(
        case_id="TC-NATIVE-01",
        start="The real Android notification permission prompt for BeeWise is already visible",
        steps=(
            f"Verify the prompt belongs to Android. Click its {decision} button exactly "
            "once. Observe the return to BeeWise, then report immediately. No other actions."
        ),
        expected='{"permission_prompt_seen":true,"decision":"allow or deny","beewise_resumed":true}',
        timeout=90,
    )
    trace_id = observed["_trace_id"]
    save("agent.json", {"trace_id": trace_id, "status": observed["_status"]})
    post = focus()
    after = grant()
    capture("after")
    save(
        "after.json",
        {"utc": datetime.now(UTC).isoformat(), "window": post, "permission": after},
    )
    assert post in {
        f"{APP_PACKAGE}/.MainActivity",
        f"{APP_PACKAGE}/{APP_PACKAGE}.MainActivity",
    }
    assert after["granted"] is (decision == "allow")
    assert "USER_SET" in after["flags"], "Android did not record a user decision"
    assert observed.get("permission_prompt_seen") is True
    assert observed.get("decision") == decision
    assert observed.get("beewise_resumed") is True
    payload = await artemis._request("GET", f"/api/sessions/{trace_id}/steps")
    steps = payload if isinstance(payload, list) else payload["steps"]
    actions = [step["action_taken"] for step in steps]
    xy = assert_agent_tap(actions, bounds, size, decision)
    save(
        "actions.json",
        {
            "trace_id": trace_id,
            "actions": ["click", "report_task_status"],
            "decision": decision,
            "click_pixels": xy,
        },
    )
