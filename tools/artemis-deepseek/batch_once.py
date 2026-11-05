"""One sequential authorized regression execution; PASS still needs native review."""

import argparse
import ast
import asyncio
import hashlib
import json
import os
import sqlite3
import subprocess
import sys
import time
import uuid
from datetime import UTC, datetime
from pathlib import Path

CASES = {"TC-01", "TC-03", "TC-04", "TC-05", "TC-06", "TC-08", "TC-09", "TC-16", "TC-20", "TC-22", "TC-27"}


def usage(db):
    row = db.execute("SELECT COUNT(*), COALESCE(SUM(prompt_tokens),0), "
                     "COALESCE(SUM(completion_tokens),0), "
                     "COALESCE(SUM(COALESCE(charged,reserved)),0) FROM attempts").fetchone()
    return dict(zip(("http_attempts", "prompt_tokens", "completion_tokens", "accounted_nanodollars"), row))


def wait_case(child, serial, device_epoch, output):
    deadline = time.monotonic() + 600
    while True:
        try:
            result = child.wait(timeout=min(5, max(0, deadline - time.monotonic())))
        except subprocess.TimeoutExpired:
            if time.monotonic() >= deadline:
                raise
            result = None
        events = subprocess.run(["adb", "-s", serial, "logcat", "-b", "events", "-d",
                                 "-s", "am_anr", "-v", "epoch"], capture_output=True,
                                text=True, timeout=10, check=True).stdout
        fresh_anr = [line for line in events.splitlines()
                     if line.strip()[:1].isdigit() and float(line.split()[0]) >= device_epoch]
        if fresh_anr:
            (output/"during-run-anr.txt").write_text("\n".join(fresh_anr)+"\n", encoding="utf-8")
            raise RuntimeError("New Android ANR during admitted execution")
        if result is not None:
            return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", choices=sorted(CASES), required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--tutor-name", help="Exact name of the authorized visible catalogue fixture")
    parser.add_argument("--fixture-id", help="Unconsumed local TC-20/22 prerequisite")
    parser.add_argument("--key-file", type=Path, help="Private credential file for the read-only balance gate")
    args = parser.parse_args()
    from policy import (
        require_live_authorization,
        validate_completion_admission,
        validate_retry_policy,
    )
    amendment = require_live_authorization()
    root = Path(__file__).resolve().parents[2]
    target = None
    for path in (root / "e2e_test").glob("*.py"):
        for node in ast.walk(ast.parse(path.read_text(encoding="utf-8"))):
            if isinstance(node, ast.AsyncFunctionDef) and node.name.startswith("test_tc" + args.case[3:] + "_"):
                target = f"{path.relative_to(root).as_posix()}::{node.name}"
    if target is None:
        parser.error("Official case function not found")
    db = sqlite3.connect(args.ledger.resolve(strict=True).as_uri() + "?mode=rw", uri=True)
    db.execute("CREATE TABLE IF NOT EXISTS sessions (id TEXT PRIMARY KEY, case_id TEXT, "
               "state TEXT, output_dir TEXT, trace_id TEXT)")
    db.commit()
    db.execute("BEGIN IMMEDIATE")
    rows = db.execute("SELECT case_id, state FROM sessions").fetchall()
    if amendment:
        if not args.key_file:
            parser.error("Completion amendment requires a private balance credential file")
        validate_completion_admission(rows, args.case, amendment)
    else:
        validate_retry_policy(rows, CASES)
    if any(state in ("RUNNING", "REVIEW_REQUIRED") for _, state in rows):
        raise ValueError("Finish/review existing session before admitting another")
    if not amendment and (len(rows) >= 36 or sum(state in ("FAILED", "BLOCKED") for _, state in rows) >= 6):
        raise ValueError("Session/failure allowance exhausted")
    if sum(case == args.case and state == "ACCEPTED" for case, state in rows) >= 3:
        raise ValueError("Case already has three accepted runs; do not rerun")
    if args.case != "TC-09" and sum(case == "TC-09" and state == "ACCEPTED" for case, state in rows) != 3:
        raise ValueError("TC-09 requires three independently accepted runs first")
    before = usage(db)
    maximum, cap, expires, approval, blocked = db.execute("SELECT * FROM budget").fetchone()
    require_live_authorization(maximum, cap)
    if (blocked or datetime.now(UTC) >= datetime.fromisoformat(expires) or
            before["http_attempts"] >= maximum or before["accounted_nanodollars"] >= cap):
        raise ValueError("Budget blocked, expired or exhausted")
    if amendment and (expires != amendment["expires_utc"] or amendment["sha256"] not in approval):
        raise ValueError("Ledger does not carry the exact completion amendment")
    from native_ready import probe
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    try:
        native_preflight = probe("emulator-5562", args.case, args.fixture_id)
        device_epoch = int(subprocess.run(["adb", "-s", "emulator-5562", "shell", "date", "+%s"],
                                          capture_output=True, text=True, check=True, timeout=10).stdout)
    except Exception as error:
        # Private run output; never admits a session or spends inference.
        (output/"preflight-blocked.json").write_text(json.dumps({
            "state": "PREFLIGHT_BLOCKED", "admitted": False, "provider_calls": 0,
            "at_utc": datetime.now(UTC).isoformat(), "error_type": type(error).__name__,
        }, indent=2)+"\n", encoding="utf-8")
        for name, command in (("preflight-window.txt", ["shell", "dumpsys", "window"]),
                              ("preflight.png", ["exec-out", "screencap", "-p"])):
            captured = subprocess.run(["adb", "-s", "emulator-5562", *command],
                                      capture_output=True, timeout=20, check=False)
            (output/name).write_bytes(captured.stdout)
        raise
    if amendment:
        from balance_gate import check_balance
        check_balance(args.key_file, amendment["nexora_reserve_nanodollars"] +
                      cap - before["accounted_nanodollars"], output/"balance-preflight.json")
        if datetime.now(UTC) >= datetime.fromisoformat(expires):
            raise ValueError("Budget expired during preflight")
    run_id = str(uuid.uuid4())
    db.execute("INSERT INTO sessions VALUES (?, ?, 'RUNNING', ?, NULL)",
               (run_id, args.case, str(output)))
    db.commit()
    env = os.environ.copy()
    env.update(ARTEMIS_BASE_URL="http://127.0.0.1:8001", ARTEMIS_DEVICE_SERIAL="emulator-5562",
               DEEPSEEK_SMOKE_TASK_FILE=str(output/"task-id.txt"),
               PYTHONPATH=str(Path(__file__).parent))
    if args.tutor_name:
        env["BEEWISE_TEST_TUTOR_NAME"] = args.tutor_name
    command = ["rtk", "proxy", sys.executable, "-m", "pytest", "-c", "e2e_test/pyproject.toml",
               target, "-q", "-s", "-p", "smoke_guard", f"--junitxml={output/'result.junit.xml'}"]
    receipt = {"run_id": run_id, "case": args.case, "started_utc": datetime.now(UTC).isoformat(),
               "usage_before": before, "command": command, "native_review": "PENDING",
               "native_preflight": native_preflight}
    receipt["source_sha"] = subprocess.run(["git", "rev-parse", "HEAD"], cwd=root,
                                            capture_output=True, text=True, check=True).stdout.strip()
    receipt["harness_diff_sha256"] = hashlib.sha256(subprocess.run(["git", "diff", "HEAD"],
        cwd=root, capture_output=True, check=True).stdout).hexdigest()
    receipt["apk_sha256"] = hashlib.sha256((root/"build/app/outputs/flutter-apk/app-debug.apk").read_bytes()).hexdigest()
    patch = "artemis-351ca842-deepseek-envelope.patch" if amendment else "artemis-351ca842-deepseek.patch"
    receipt["artemis_patch_sha256"] = hashlib.sha256((Path(__file__).parent/patch).read_bytes()).hexdigest()
    with (output/"run-receipt.json").open("x", encoding="utf-8") as file:
        json.dump(receipt, file, indent=2)
    with (output/"pytest-private.log").open("wb") as log:
        child = subprocess.Popen(command, cwd=root, env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            receipt["pytest_exit"] = wait_case(child, "emulator-5562", device_epoch, output)
            receipt["state"] = "REVIEW_REQUIRED" if child.returncode == 0 else "FAILED"
        except (subprocess.SubprocessError, RuntimeError) as error:
            receipt["state"] = "BLOCKED"
            receipt["supervisor_stop"] = type(error).__name__
            if (output/"task-id.txt").exists():
                from artemis_client import ArtemisClient
                client = ArtemisClient(base_url=env["ARTEMIS_BASE_URL"], request_timeout=15)
                try:
                    asyncio.run(client.stop((output/"task-id.txt").read_text().strip()))
                    receipt["remote_stop_requested"] = True
                except Exception:  # noqa: BLE001 - retain failure without private remote body
                    receipt["remote_stop_requested"] = False
            if child.poll() is None:
                child.terminate()
                child.wait(timeout=15)
    receipt.update(finished_utc=datetime.now(UTC).isoformat(), usage_after=usage(db))
    if (output/"task-id.txt").exists():
        receipt["trace_id"] = (output/"task-id.txt").read_text().strip()
    db.execute("UPDATE sessions SET state = ?, trace_id = ? WHERE id = ?",
               (receipt["state"], receipt.get("trace_id"), run_id))
    db.commit()
    db.close()
    (output/"run-receipt.json").write_text(json.dumps(receipt, indent=2)+"\n", encoding="utf-8")
    print(json.dumps(receipt, indent=2), flush=True)


if __name__ == "__main__":
    main()
