"""Capture genuine guest Android runtime evidence; never clears application data.

Requires the already running authorized emulator. Logs omit credentials; original
logcat stays privately on D:. Run restore after resize/network/debug checks.
"""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "evidence/android"
PRIVATE = Path("D:/CodexTemp/beewise-lab3-tools/bao-runtime")
ADB = "D:/Android/SDK/platform-tools/adb.exe"
PACKAGE = "com.beewise.beewise"
for directory in (OUT / "screenshots", OUT / "logs", PRIVATE):
    directory.mkdir(parents=True, exist_ok=True)


def redact(value):
    value = re.sub(r"(?im)^.*(?:debug token|AppCheckDebugProvider|Authorization:|Bearer |Dart VM service is listening|(?:FCM|registration) token\s*[:=]).*$", "[credential-bearing line omitted]", value)
    value = re.sub(r"AIza[\w-]+", "[client-key omitted]", value)
    value = re.sub(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", "[email omitted]", value)
    value = re.sub(r"\beyJ[\w.-]{30,}", "[JWT omitted]", value)
    return value


def adb(*args, binary=False):
    result = subprocess.run([ADB, "-s", args_config.serial, *args], capture_output=True, timeout=120)
    if binary:
        if result.returncode:
            raise RuntimeError(redact(result.stderr.decode(errors="replace")))
        return result.stdout
    output = redact((result.stdout + result.stderr).decode("utf-8", errors="replace"))
    records.append({"command": ["adb", "-s", args_config.serial, *args], "exitCode": result.returncode, "output": output})
    if result.returncode:
        (OUT / "logs" / (args_config.label + "-failed-command.json")).write_text(
            json.dumps({"timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "records": records}, indent=2), encoding="utf-8")
        raise RuntimeError(output)
    return output.strip()


parser = argparse.ArgumentParser()
parser.add_argument("action", choices=["prepare", "install", "launch", "capture", "tap", "back", "resize", "offline", "online", "inspect", "restore"])
parser.add_argument("--label", default="runtime")
parser.add_argument("--apk")
parser.add_argument("--width", type=int)
parser.add_argument("--x", type=int)
parser.add_argument("--y", type=int)
parser.add_argument("--serial", default="emulator-5556")
args = parser.parse_args()
args_config = args
records = []
state_file = PRIVATE / (args.serial + "-original-device-state.json")
if args.action == "prepare":
    state = {"size": adb("shell", "wm", "size"), "density": adb("shell", "wm", "density"),
             "wifi": adb("shell", "settings", "get", "global", "wifi_on"),
             "airplane": adb("shell", "settings", "get", "global", "airplane_mode_on"),
             "analytics": adb("shell", "getprop", "debug.firebase.analytics.app")}
    if state_file.exists() and not json.loads(state_file.read_text()).get("restoredAtUtc"):
        raise RuntimeError("Original state already saved; restore it before another prepare.")
    state_file.write_text(json.dumps(state, indent=2), encoding="utf-8")
    adb("shell", "setprop", "debug.firebase.analytics.app", PACKAGE)
elif args.action == "install":
    apk = Path(args.apk)
    adb("install", "-r", str(apk))
    records.append({"apk": str(apk), "sha256": hashlib.file_digest(apk.open("rb"), "sha256").hexdigest(), "bytes": apk.stat().st_size})
elif args.action == "launch":
    adb("shell", "am", "force-stop", PACKAGE)
    adb("shell", "am", "start", "-W", "-n", PACKAGE + "/.MainActivity")
elif args.action == "capture":
    (OUT / "screenshots" / (args.label + ".png")).write_bytes(adb("exec-out", "screencap", "-p", binary=True))
    xml = adb("shell", "uiautomator", "dump", "/dev/tty")
    (OUT / "logs" / (args.label + ".xml")).write_text(xml, encoding="utf-8")
    pid = adb("shell", "pidof", PACKAGE)
    if pid:
        raw = adb("logcat", "-d", "--pid=" + pid, "-v", "threadtime", binary=True)
        (PRIVATE / (args.label + "-raw.log")).write_bytes(raw)
        (OUT / "logs" / (args.label + "-logcat.log")).write_text(redact(raw.decode(errors="replace")), encoding="utf-8")
elif args.action == "tap":
    adb("shell", "input", "tap", str(args.x), str(args.y))
elif args.action == "back":
    adb("shell", "input", "keyevent", "4")
elif args.action == "resize":
    if args.width not in (360, 412):
        raise ValueError("Only the two requested viewport widths are supported.")
    adb("shell", "wm", "density", "320")
    adb("shell", "wm", "size", "720x1600" if args.width == 360 else "824x1830")
elif args.action in ("offline", "online"):
    state = json.loads(state_file.read_text())
    if "mobileData" not in state:
        state["mobileData"] = adb("shell", "settings", "get", "global", "mobile_data")
        state_file.write_text(json.dumps(state, indent=2), encoding="utf-8")
    adb("shell", "svc", "wifi", "disable" if args.action == "offline" else "enable")
    adb("shell", "svc", "data", "disable" if args.action == "offline" else "enable")
elif args.action == "inspect":
    for command in [("shell", "getprop", "ro.build.version.release"), ("shell", "getprop", "ro.build.version.sdk"),
                    ("shell", "wm", "size"), ("shell", "wm", "density"), ("shell", "dumpsys", "package", PACKAGE)]:
        adb(*command)
elif args.action == "restore":
    state = json.loads(state_file.read_text())
    for name in ("size", "density"):
        override = re.search(r"Override " + name + r": (\S+)", state[name], re.I)
        adb("shell", "wm", name, override.group(1) if override else "reset")
    adb("shell", "svc", "wifi", "enable" if state["wifi"] in ("1", "2") else "disable")
    if "mobileData" in state:
        adb("shell", "svc", "data", "enable" if state["mobileData"] == "1" else "disable")
    adb("shell", "setprop", "debug.firebase.analytics.app", state["analytics"] or ".none.")
    state["restoredAtUtc"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    state_file.write_text(json.dumps(state, indent=2), encoding="utf-8")
manifest = {"timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "sourceSha": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
            "action": args.action, "label": args.label, "records": records}
(OUT / "logs" / (args.label + "-" + args.action + ".json")).write_text(json.dumps(manifest, indent=2), encoding="utf-8")
print(json.dumps({"action": args.action, "label": args.label, "result": "completed", "records": len(records)}))
