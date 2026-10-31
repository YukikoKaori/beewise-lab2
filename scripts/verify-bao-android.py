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
    value = re.sub(r"(?im)^.*(?:debug token|AppCheckDebugProvider|DebugAppCheckProvider|Authorization:|Bearer |Dart VM service is listening|(?:FCM|registration) token\s*[:=]|FirebaseAuth.*(?:user \(|password)).*$", "[credential-bearing line omitted]", value)
    value = re.sub(r"AIza[\w-]+", "[client-key omitted]", value)
    value = re.sub(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", "[email omitted]", value)
    value = re.sub(r"(parents|tutorApplications)/[A-Za-z0-9_-]{20,}", r"\1/[test-uid omitted]", value)
    value = re.sub(r"devices/[A-Za-z0-9_-]{20,}", "devices/[installation omitted]", value)
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
parser.add_argument("action", choices=["prepare", "install", "launch", "capture", "logs", "tap", "back", "resize", "offline", "online", "inspect", "restore"])
parser.add_argument("--pid", type=int)
parser.add_argument("--label", default="runtime")
parser.add_argument("--apk")
parser.add_argument("--width", type=int)
parser.add_argument("--x", type=int)
parser.add_argument("--y", type=int)
parser.add_argument("--serial", default="emulator-5556")
parser.add_argument("--private-image", action="store_true", help="Keep authenticated screenshots off the public evidence tree.")
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
    # A visible API37 emulator can have a second display; align launch/input
    # with the primary display captured by screencap and viewport measurements.
    adb("shell", "am", "start", "-W", "--display", "0", "-n", PACKAGE + "/.MainActivity")
elif args.action == "capture":
    # API37 may print only a completion message for /dev/tty; read the real file.
    adb("shell", "uiautomator", "dump", "/sdcard/bao-ui.xml")
    xml = adb("shell", "cat", "/sdcard/bao-ui.xml")
    if "<hierarchy" not in xml:
        raise RuntimeError("UI hierarchy unavailable; do not present a status message as XML evidence.")
    (OUT / "logs" / (args.label + ".xml")).write_text(xml, encoding="utf-8")
    # Dump waits for UI idle; capture afterwards rather than mid-transition.
    image_path = (PRIVATE if args.private_image else OUT / "screenshots") / (args.label + ".png")
    image_bytes = adb("exec-out", "screencap", "-p", binary=True)
    image_path.write_bytes(image_bytes)
    records.append({"imagePath": str(image_path), "imageSha256": hashlib.sha256(image_bytes).hexdigest(), "privateImage": args.private_image})
    pid = adb("shell", "pidof", PACKAGE)
    if pid:
        raw = adb("logcat", "-d", "--pid=" + pid, "-v", "threadtime", binary=True)
        (PRIVATE / (args.label + "-raw.log")).write_bytes(raw)
        (OUT / "logs" / (args.label + "-logcat.log")).write_text(redact(raw.decode(errors="replace")), encoding="utf-8")
elif args.action == "tap":
    adb("shell", "input", "-d", "0", "tap", str(args.x), str(args.y))
elif args.action == "logs":
    if args.pid is None or args.pid < 1:
        raise ValueError("Use the process ID observed before the deliberate crash.")
    raw = adb("logcat", "-d", "--pid=" + str(args.pid), "-v", "threadtime", binary=True)
    (PRIVATE / (args.label + "-raw.log")).write_bytes(raw)
    (OUT / "logs" / (args.label + "-logcat.log")).write_text(redact(raw.decode(errors="replace")), encoding="utf-8")
    records.append({"observedPid": args.pid, "logBytes": len(raw), "consoleReceiptVerified": False})
elif args.action == "back":
    adb("shell", "input", "-d", "0", "keyevent", "4")
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
