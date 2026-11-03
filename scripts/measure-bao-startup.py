"""Record one native startup without clearing userdata or suppressing ANRs.

Usage: python scripts/measure-bao-startup.py SERIAL LABEL cold|warm PRIVATE_DIR [--immediate] [--trace-startup]
The immediate mode defers expensive dumps until after launching the activity.
Complete logs, UI and screenshots stay private: review before publishing.
"""
import datetime
import hashlib
import http.client
import json
from pathlib import Path
import re
import subprocess
import sys
import threading
import time
import urllib.request

ADB = "D:/Android/SDK/platform-tools/adb.exe"
PACKAGE = "com.beewise.beewise"


def flutter_frame_metrics(events, process_start_us):
    """Use the same first-useful-frame markers as Flutter tools tracing.dart.

    Ordinary Frame/SurfaceFrame events may belong to a later frame in a wrapped
    timeline. They must never substitute for the explicit startup markers.
    """
    result = {}
    markers = {}
    for name in ("FlutterEngineMainEnter", "Widgets built first useful frame",
                 "Rasterized first useful frame"):
        times = [event["ts"] for event in events if event.get("name") == name
                 and isinstance(event.get("ts"), (int, float))]
        markers[name] = min(times) if times else None
    engine = markers["FlutterEngineMainEnter"]
    for key, name in (
        ("processToFirstFrameBuiltMs", "Widgets built first useful frame"),
        ("processToFirstFrameRasterizedMs", "Rasterized first useful frame"),
    ):
        ts = markers[name]
        valid = ts is not None and engine is not None and process_start_us <= engine <= ts
        result[key] = round((ts - process_start_us) / 1000, 3) if valid else None
        result[key.replace("processTo", "engineTo")] = round((ts - engine) / 1000, 3) if valid else None
    return result


def observe_flutter_frames(run, pid, private_timeline):
    """Read the existing debug VM timeline. No attach, reload or probe entrypoint."""
    port = None
    try:
        log = run("logcat", "-d", "--pid", pid, "-t", "10000").stdout.decode(errors="replace")
        matches = re.findall(r"Dart VM service is listening on (http://127\.0\.0\.1:(\d+)/\S+)", log)
        if not matches:
            return {"status": "NOT_OBSERVED", "reason": "No debug VM service endpoint for this process"}
        uri, remote = matches[-1]
        forwarding = run("forward", "tcp:0", "tcp:" + remote)
        port = forwarding.stdout.decode().strip()
        if forwarding.returncode or not port.isdecimal():
            port = None
            return {"status": "NOT_OBSERVED", "reason": "Could not create owned VM forwarding"}
        endpoint = uri.replace(":" + remote + "/", ":" + port + "/")
        stat = run("shell", "cat", f"/proc/{pid}/stat").stdout.decode()
        ticks = int(stat.rsplit(") ", 1)[1].split()[19])
        hz = int(run("shell", "getconf", "CLK_TCK").stdout.decode().strip())
        start_us = ticks * 1_000_000 / hz
        # Keep startup markers while avoiding an unbounded full-session trace.
        query = f"getVMTimeline?timeOriginMicros={int(start_us)}&timeExtentMicros=30000000"
        with urllib.request.urlopen(endpoint + query, timeout=30) as response:
            timeline = json.load(response)["result"]
        timeline_bytes = json.dumps(timeline, separators=(",", ":")).encode()
        private_timeline.write_bytes(timeline_bytes)
        metrics = flutter_frame_metrics(timeline.get("traceEvents", []), start_us)
        return {"status": "OBSERVED" if all(v is not None for v in metrics.values()) else "PARTIAL",
                "clock": "Android process start ticks and VM monotonic timeline microseconds",
                "scope": "Explicit Flutter first useful frame markers; not Android Displayed timing",
                "timelineSha256": hashlib.sha256(timeline_bytes).hexdigest(),
                "startupMarkers": [{"name": event["name"], "ts": event.get("ts")}
                                   for event in timeline.get("traceEvents", [])
                                   if event.get("name") in ("FlutterEngineMainEnter", "Widgets built first useful frame", "Rasterized first useful frame")],
                "processStartTicks": ticks, "clockTicksPerSecond": hz, **metrics}
    except (OSError, http.client.HTTPException, ValueError, KeyError, IndexError, TypeError):
        # VM errors can contain its private endpoint. Publish no exception text.
        return {"status": "NOT_OBSERVED", "reason": "Native VM timeline unavailable or clock data invalid"}
    finally:
        if port is not None:
            run("forward", "--remove", "tcp:" + port)


def redact(data):
    text = data.decode("utf-8", errors="replace")
    text = re.sub(r"(?im)^.*(?:AppCheckDebugProvider|DebugAppCheckProvider|debug token|Authorization:|Bearer |(?:FCM|registration) token\s*[:=]|Dart VM service is listening).*$",
                  "[credential-bearing line omitted]", text)
    text = re.sub(r"\b[A-Za-z0-9]{28}\b", lambda match: "uid-sha256:" +
                  hashlib.sha256(match[0].encode()).hexdigest()[:16], text)
    text = re.sub(r"AIza[\w-]+", "[client-key omitted]", text)
    text = re.sub(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", "[email omitted]", text)
    return text.encode("utf-8")


def main():
    args = sys.argv[1:]
    immediate = "--immediate" in args
    trace_startup = "--trace-startup" in args
    serial, label, mode, directory = [arg for arg in args if arg not in ("--immediate", "--trace-startup")]
    if not re.fullmatch(r"emulator-\d+", serial) or not re.fullmatch(r"[a-z0-9-]+", label):
        raise ValueError("Expected emulator serial and safe label")
    if mode not in ("cold", "warm"):
        raise ValueError("Expected cold or warm")
    out = Path(directory)
    out.mkdir(parents=True, exist_ok=True)
    if (out / (label + ".json")).exists():
        raise FileExistsError("Use a new label to preserve earlier evidence")
    commands = []

    def run(*args):
        result = subprocess.run([ADB, "-s", serial, *args], capture_output=True, timeout=120)
        commands.append({"command": list(args), "exitCode": result.returncode})
        return result

    def save(name, *args):
        result = run(*args)
        safe_output = redact(result.stdout + result.stderr)
        (out / (label + "-" + name)).write_bytes(safe_output)
        return safe_output.decode().strip()

    receipt = {"timestampUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
               "serial": serial, "requestedMode": mode, "userdataCleared": False,
               "anrDetectionSuppressed": False,
               "immediateLaunch": immediate,
               "traceStartup": trace_startup,
               "logIdentityPolicy": "All buffers retained; Auth UID aliases and credential-line redaction applied in memory before disk"}
    with (out / (label + "-live-logcat.txt")).open("wb") as stream:
        logger = subprocess.Popen([ADB, "-s", serial, "logcat", "-b", "all", "-v", "threadtime"],
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        def drain():
            for line in iter(logger.stdout.readline, b""):
                stream.write(redact(line))
                stream.flush()
        reader = threading.Thread(target=drain, daemon=True)
        reader.start()
        try:
            before = {
                "cpu-before.txt": ("dumpsys", "cpuinfo"),
                "memory-before.txt": ("dumpsys", "meminfo"),
                "lifecycle-before.txt": ("dumpsys", "activity", "activities"),
            } if not immediate else {
                "uptime-before.txt": ("cat", "/proc/uptime"),
                "load-before.txt": ("cat", "/proc/loadavg"),
            }
            for name, args in before.items():
                save(name, "shell", *args)
            receipt["pidBefore"] = run("shell", "pidof", PACKAGE).stdout.decode().strip()
            if mode == "cold":
                run("shell", "am", "force-stop", PACKAGE)
            else:
                run("shell", "input", "keyevent", "KEYCODE_HOME")
            run("shell", "log", "-t", "BaoStartup", label)
            started = time.monotonic()
            receipt["amStart"] = save("am-start.txt", "shell", "am", "start", "-W",
                                      "--display", "0", "-n", PACKAGE + "/.MainActivity",
                                      *(["--ez", "trace-startup", "true"] if trace_startup else []))
            receipt["amStartWallMs"] = round((time.monotonic() - started) * 1000)
            receipt["pidAfter"] = run("shell", "pidof", PACKAGE).stdout.decode().strip()
            receipt["amStartTargetsBeeWise"] = "Activity: " + PACKAGE + "/.MainActivity" in receipt["amStart"]
            receipt["amStartTimingScope"] = "Android am start result; transient permission activity timing is not BeeWise first draw"
            if trace_startup and mode == "cold" and receipt["pidAfter"].isdecimal():
                receipt["flutterFrames"] = observe_flutter_frames(
                    run, receipt["pidAfter"], out / (label + "-flutter-timeline.json"))
            else:
                receipt["flutterFrames"] = {"status": "NOT_MEASURED", "reason": "Timeline collection requires opt-in cold --trace-startup"}
            ui_status = save("ui-status.txt", "shell", "uiautomator", "dump", "/sdcard/bao-startup-ui.xml")
            receipt["uiDumpSucceeded"] = "dumped to:" in ui_status
            # A failed dump can leave a previous launch's XML on the device.
            ui = save("ui.xml", "shell", "cat", "/sdcard/bao-startup-ui.xml") if receipt["uiDumpSucceeded"] else ""
            receipt["homeUiPresent"] = ("BeeWise" in ui and "Trang ch" in ui) if receipt["uiDumpSucceeded"] else None
            receipt["anrDialogInUi"] = ("isn't responding" in ui or "Close app" in ui) if receipt["uiDumpSucceeded"] else None
            picture = run("exec-out", "screencap", "-p")
            (out / (label + ".png")).write_bytes(picture.stdout)
            receipt["screenshotSha256"] = hashlib.sha256(picture.stdout).hexdigest()
            for name, args in {
                "cpu-after.txt": ("dumpsys", "cpuinfo"),
                "memory-after.txt": ("dumpsys", "meminfo"),
                "lifecycle-after.txt": ("dumpsys", "activity", "activities"),
                "lastanr.txt": ("dumpsys", "activity", "lastanr"),
                "exit-info.txt": ("dumpsys", "activity", "exit-info", PACKAGE),
                "window.txt": ("dumpsys", "window", "displays"),
                "framestats.txt": ("dumpsys", "gfxinfo", PACKAGE, "framestats"),
            }.items():
                save(name, "shell", *args)
            pid = receipt["pidAfter"]
            if pid.isdecimal():
                for field in ("stat", "wchan", "stack"):
                    save("main-" + field + ".txt", "shell", "run-as", PACKAGE,
                         "cat", f"/proc/{pid}/task/{pid}/{field}")
            save("complete-logcat.txt", "logcat", "-b", "all", "-d", "-v", "threadtime")
            receipt["interpretation"] = "OBSERVED; inspect post-marker logs and actual UI before declaring PASS"
        finally:
            logger.terminate()
            logger.wait(timeout=15)
            reader.join(timeout=15)
            receipt["commands"] = commands
            (out / (label + ".json")).write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({key: receipt.get(key) for key in
                      ("requestedMode", "amStartWallMs", "pidBefore", "pidAfter", "homeUiPresent", "anrDialogInUi")}))


if __name__ == "__main__":
    main()
