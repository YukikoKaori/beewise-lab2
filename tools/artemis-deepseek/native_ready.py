"""Require actual rendered, focused Android UI before admitting paid work."""

import json
import re
import subprocess
import time
import urllib.request
import xml.etree.ElementTree as ET
from http.client import RemoteDisconnected

PACKAGE = "com.beewise.beewise"


def validate_ready(boot, windows, hierarchy):
    if boot.strip() != "1":
        raise ValueError("Android boot is not complete")
    focus = next((line for line in windows.splitlines() if "mCurrentFocus=" in line), "")
    if "Application Not Responding:" in focus:
        raise ValueError("Native ANR dialog owns focus; preserve it and stop")
    if not re.search(r"\bcom\.beewise\.beewise/", focus):
        raise ValueError("BeeWise does not own the focused window")
    nodes = list(ET.fromstring(hierarchy).iter("node"))
    labels = [(node.get("text", "") + " " + node.get("content-desc", "")).strip()
              for node in nodes]
    if any("isn't responding" in label.lower() or "is not responding" in label.lower()
           for label in labels):
        raise ValueError("Native ANR dialog present; preserve it and stop")
    if not any(node.get("package") == PACKAGE and label
               for node, label in zip(nodes, labels)):
        raise ValueError("No rendered BeeWise content observed")


def validate_idle(status):
    if (status.get("status") != "idle" or status.get("active_tasks") != []
            or status.get("queue") != []
            or any(item.get("status") in ("running", "pending", "queued")
                   for item in status.get("background_tasks", []))):
        raise ValueError("ARTEMIS is not verifiably idle; no session admitted")


def local_json(port, path):
    # Fixed loopback only. 'owner' is the Firebase Emulator admin sentinel,
    # never a production credential. No identity/token response is exported.
    request = urllib.request.Request(f"http://127.0.0.1:{port}{path}",
                                     headers={"Authorization": "Bearer owner"})
    with urllib.request.urlopen(request, timeout=10) as response:
        return json.load(response)


def validate_fixture(case_id, tutor, chat=None):
    fields = tutor.get("fields", {})
    if (fields.get("active") != {"booleanValue": True}
            or fields.get("verified") != {"booleanValue": False}
            or fields.get("demoOnly") != {"booleanValue": True}):
        raise ValueError("Authorized local demo tutor fixture is missing or changed")
    if case_id in ("TC-20", "TC-22"):
        fields = (chat or {}).get("fields", {})
        expected = "trial_proposed" if case_id == "TC-20" else "class_revision_pending"
        if (fields.get("onboardingStatus") != {"stringValue": expected}
                or fields.get("parentId") != {"stringValue": "n03-parent"}):
            raise ValueError("Required unconsumed parent workflow fixture is missing")


def wait_hierarchy(device, predicate):
    # Bounded observation of a real UI transition, not an app startup delay.
    deadline = time.monotonic() + 10
    while True:
        try:
            hierarchy = device.dump_hierarchy(compressed=True)
        except RemoteDisconnected:
            if time.monotonic() >= deadline:
                raise
            continue  # Retry only the accessibility read, never the UI action.
        nodes = list(ET.fromstring(hierarchy).iter("node"))
        labels = " ".join(node.get("text", "") + node.get("content-desc", "") for node in nodes)
        if "isn't responding" in labels.lower() or "is not responding" in labels.lower():
            raise ValueError("ANR during native probe; preserve dialog and stop")
        if predicate(nodes):
            return hierarchy
        if time.monotonic() >= deadline:
            raise ValueError("Native UI transition did not complete within 10 seconds")


def probe_device(serial):
    import uiautomator2 as u2

    def adb(*args):
        return subprocess.run(["adb", "-s", serial, *args], capture_output=True,
                              text=True, check=True, timeout=20).stdout

    if adb("get-state").strip() != "device":
        raise ValueError("ADB device is not online")
    boot = adb("shell", "getprop", "sys.boot_completed")
    windows = adb("shell", "dumpsys", "window")
    device = u2.connect_usb(serial)
    hierarchy = wait_hierarchy(device, lambda nodes: bool(nodes))
    validate_ready(boot, windows, hierarchy)
    # Exercise System UI only after excluding ANR. Never dismiss a failure dialog.
    started = time.monotonic()
    adb("shell", "cmd", "statusbar", "expand-notifications")
    wait_hierarchy(device, lambda nodes: any(node.get("package") == "com.android.systemui"
                   and (node.get("text") or node.get("content-desc")) for node in nodes))
    adb("shell", "cmd", "statusbar", "collapse")
    hierarchy = wait_hierarchy(device, lambda nodes: any(node.get("package") == PACKAGE
                              and (node.get("text") or node.get("content-desc")) for node in nodes))
    validate_ready(boot, adb("shell", "dumpsys", "window"), hierarchy)
    return {"device_online": True, "boot_complete": True,
            "focused_rendered_app": PACKAGE, "readable_accessibility": True,
            "first_frame_scope": "Actual rendered accessibility content and focused app window",
            "system_ui_roundtrip_ms": round((time.monotonic() - started) * 1000),
            "system_ui_responsive": True, "anr_dialog_present": False}


def probe(serial, case_id, fixture_id=None):
    validate_idle(local_json(8001, "/api/status"))
    hub = local_json(4400, "/emulators")
    if any(hub.get(name, {}).get("port") != port
           for name, port in (("auth", 9099), ("firestore", 8080))):
        raise ValueError("Expected local Auth/Firestore endpoints are unavailable")
    if local_json(8787, "/healthz").get("ok") is not True:
        raise ValueError("Local fake-payment backend is not healthy")
    base = "/v1/projects/beewise-lab-3/databases/(default)/documents/"
    tutor = local_json(8080, base + "tutors/tutor_acd3824aa8734c63ac8827df")
    chat = None
    if case_id in ("TC-20", "TC-22"):
        if not re.fullmatch("n03-tc" + case_id[-2:] + r"-[a-z0-9-]+", fixture_id or ""):
            raise ValueError("Fresh case-specific emulator fixture ID required")
        chat = local_json(8080, base + "chats/" + fixture_id)
    validate_fixture(case_id, tutor, chat)
    receipt = probe_device(serial)
    # Recheck after native interaction, immediately before admission.
    validate_idle(local_json(8001, "/api/status"))
    receipt.update(artemis_idle=True, local_endpoints_verified=True,
                   fixture_verified=True, fixture_id=fixture_id)
    return receipt
