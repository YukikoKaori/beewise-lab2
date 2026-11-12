"""One sequential PRM393 Final Completion ARTEMIS execution on BeeWise_Final_API35."""

from __future__ import annotations

import argparse
import ast
import asyncio
import hashlib
import json
import os
import shutil
import sqlite3
import subprocess
import sys
import time
import uuid
from datetime import UTC, datetime
from pathlib import Path

DEFAULT_ADB_DIR = Path("D:/Android/SDK/platform-tools")
COMPLETION_CASES = {
    "FINAL-F01": "test_final_f01_",
    "FINAL-F02a": "test_final_f02a_",
    "FINAL-F02b": "test_final_f02b_",
    "FINAL-F04": "test_final_f04_",
    "FINAL-F07": "test_final_f07_",
    "TC-03": "test_tc03_",
    "TC-08": "test_tc08_",
    "TC-09": "test_tc09_",
    "TC-12": "test_tc12_",
    "TC-27": "test_tc27_",
    "TC-NATIVE-01": "test_native_notification_permission",
}
ALLOWED_COMPLETION_DECISIONS = (
    "OWNER_APPROVED_FINAL_COMPLETION_BATCH",
    "OWNER_APPROVED_FINAL_COMPLETION_WAVE_2",
    "OWNER_APPROVED_FINAL_COMPLETION_WAVE_3",
    "OWNER_APPROVED_FINAL_COMPLETION_WAVE_3_EMU",
)
DEFAULT_PROPOSAL = Path("evidence/final/artemis/completion-batch/budget-proposal.json")
DEFAULT_APPROVAL = Path("evidence/final/artemis/completion-batch/owner-approval.json")
NATIVE_CONTROLLER_ACTIVITY = (
    "com.google.android.permissioncontroller/"
    "com.android.permissioncontroller.permission.ui.GrantPermissionsActivity"
)


def adb_exe() -> str:
    found = shutil.which("adb")
    if found:
        return found
    candidate = DEFAULT_ADB_DIR / ("adb.exe" if os.name == "nt" else "adb")
    if candidate.is_file():
        return str(candidate)
    return "adb"


def usage(db: sqlite3.Connection) -> dict[str, int]:
    row = db.execute(
        "SELECT COUNT(*), COALESCE(SUM(prompt_tokens),0), "
        "COALESCE(SUM(completion_tokens),0), "
        "COALESCE(SUM(COALESCE(charged,reserved)),0) FROM attempts"
    ).fetchone()
    return dict(
        zip(
            (
                "http_attempts",
                "prompt_tokens",
                "completion_tokens",
                "accounted_nanodollars",
            ),
            row,
            strict=True,
        )
    )


def verify_installed_apk(serial: str, expected_sha256: str) -> str:
    adb = adb_exe()
    pm_out = subprocess.run(
        [adb, "-s", serial, "shell", "pm", "path", "com.beewise.beewise"],
        capture_output=True,
        text=True,
        timeout=15,
        check=True,
    ).stdout
    apk_paths = [
        line.split(":", 1)[1].strip()
        for line in pm_out.splitlines()
        if line.startswith("package:") and line.strip().endswith("base.apk")
    ]
    if len(apk_paths) != 1:
        raise ValueError(f"Expected single installed base.apk on {serial}, got {apk_paths!r}")
    sha_out = subprocess.run(
        [adb, "-s", serial, "shell", "sha256sum", apk_paths[0]],
        capture_output=True,
        text=True,
        timeout=20,
        check=True,
    ).stdout.strip()
    installed_sha = sha_out.split()[0].lower()
    if installed_sha != expected_sha256.lower():
        raise ValueError(
            f"Installed APK SHA-256 mismatch on {serial}: {installed_sha} != {expected_sha256}"
        )
    return installed_sha


def check_completion_approval(approval_file: Path, proposal_file: Path) -> tuple[dict, dict, str]:
    proposed_bytes = proposal_file.read_bytes().replace(b"\r\n", b"\n")
    digest = hashlib.sha256(proposed_bytes).hexdigest()
    proposal = json.loads(proposed_bytes)
    approval = json.loads(approval_file.read_text(encoding="utf-8"))
    owner_ref = approval.get("owner_approval_ref")
    decision = approval.get("decision")
    expected_decision = proposal.get("decision_required", "OWNER_APPROVED_FINAL_COMPLETION_BATCH")
    if (
        decision not in ALLOWED_COMPLETION_DECISIONS
        or decision != expected_decision
        or approval.get("proposal_sha256") != digest
        or not isinstance(owner_ref, str)
        or not owner_ref.strip()
    ):
        raise ValueError("Final Completion ARTEMIS execution requires matching owner approval receipt")
    return proposal, approval, digest


def prepare_native_permission_preflight(serial: str, output: Path, prior_runs: int) -> dict:
    """Validate pre-focused OS permission prompt without touching the dialog."""
    if prior_runs >= 3:
        raise ValueError(f"TC-NATIVE-01 already used {prior_runs} admissions")
    decision = ("deny", "allow", "deny")[prior_runs]
    adb = adb_exe()

    def run_adb(*cmd: str, timeout: int = 20) -> bytes:
        return subprocess.check_output([adb, "-s", serial, *cmd], timeout=timeout)

    sdk = run_adb("shell", "getprop", "ro.build.version.sdk").decode(errors="replace").strip()
    if sdk != "35":
        raise ValueError(f"TC-NATIVE-01 requires API 35, got {sdk!r}")
    avd_lines = run_adb("emu", "avd", "name").decode(errors="replace").splitlines()
    if not avd_lines or avd_lines[0].strip() != "BeeWise_N03_Native_API35":
        raise ValueError(f"TC-NATIVE-01 requires BeeWise_N03_Native_API35, got {avd_lines!r}")
    boot = run_adb("shell", "getprop", "sys.boot_completed").decode(errors="replace").strip()
    if boot != "1":
        raise ValueError("Android boot is not complete")

    windows = run_adb("shell", "dumpsys", "window").decode(errors="replace")
    focus = [line.strip() for line in windows.splitlines() if "mCurrentFocus=" in line]
    if not any(NATIVE_CONTROLLER_ACTIVITY in line for line in focus):
        raise ValueError(f"OS notification permission prompt is not focused: {focus!r}")

    root = Path(__file__).resolve().parents[2]
    sys.path.insert(0, str(root / "e2e_test"))
    from test_native_permission import button_bounds, permission_state

    perm = permission_state(run_adb("shell", "dumpsys", "package", "com.beewise.beewise").decode(errors="replace"))
    if perm["granted"] or ({"USER_SET", "USER_FIXED"} & set(perm["flags"])):
        raise ValueError(f"POST_NOTIFICATIONS permission must be ungranted/unset before run: {perm!r}")

    run_adb("shell", "uiautomator", "dump", "/data/local/tmp/beewise-completion-native.xml", timeout=25)
    pre_xml = output / "pre-ui.xml"
    pre_xml.write_bytes(run_adb("exec-out", "cat", "/data/local/tmp/beewise-completion-native.xml"))
    bounds = button_bounds(pre_xml.read_text(encoding="utf-8"))
    return {
        "device_online": True,
        "boot_complete": True,
        "avd_name": "BeeWise_N03_Native_API35",
        "focused_window": NATIVE_CONTROLLER_ACTIVITY,
        "permission_before": perm,
        "decision": decision,
        "buttons_present": sorted(bounds),
        "pre_xml": str(pre_xml),
    }


def wait_case(child: subprocess.Popen, serial: str, device_epoch: int, output: Path) -> int:
    deadline = time.monotonic() + 600
    while True:
        try:
            result = child.wait(timeout=min(5, max(0, deadline - time.monotonic())))
        except subprocess.TimeoutExpired:
            if time.monotonic() >= deadline:
                raise
            result = None
        events = subprocess.run(
            [adb_exe(), "-s", serial, "logcat", "-b", "events", "-d", "-s", "am_anr", "-v", "epoch"],
            capture_output=True,
            text=True,
            timeout=10,
            check=True,
        ).stdout
        fresh_anr = [
            line
            for line in events.splitlines()
            if line.strip()[:1].isdigit() and float(line.split()[0]) >= device_epoch
        ]
        if fresh_anr:
            (output / "during-run-anr.txt").write_text("\n".join(fresh_anr) + "\n", encoding="utf-8")
            raise RuntimeError("New Android ANR during admitted Final Completion ARTEMIS execution")
        if result is not None:
            return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", choices=sorted(COMPLETION_CASES), required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--serial", default="emulator-5564")
    parser.add_argument("--key-file", type=Path, required=True)
    parser.add_argument("--approval", type=Path, default=DEFAULT_APPROVAL)
    parser.add_argument("--proposal", type=Path, default=DEFAULT_PROPOSAL)
    parser.add_argument("--search-term", default="Toán")
    parser.add_argument("--no-result-term", default="zz-no-tutor-match-393-2026")
    parser.add_argument("--tutor-name", default="ThS. Hoàng Thu Trang")
    parser.add_argument("--final-test-env", default="emulator", choices=("emulator", "production_safe_check"))
    parser.add_argument(
        "--ai-prompt",
        default="Tìm gia sư Toán lớp 9 ở Cầu Giấy, học phí dưới 300k một giờ, học buổi tối.",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[2]
    proposal_file = (root / args.proposal) if not args.proposal.is_absolute() else args.proposal
    approval_file = (root / args.approval) if not args.approval.is_absolute() else args.approval
    proposal, approval, digest = check_completion_approval(approval_file, proposal_file)
    if args.case not in proposal.get("cases", []):
        parser.error(f"Case {args.case} is outside approved completion-batch cases: {proposal.get('cases')}")

    prefix = COMPLETION_CASES[args.case]
    target = None
    for path in (root / "e2e_test").glob("*.py"):
        for node in ast.walk(ast.parse(path.read_text(encoding="utf-8"))):
            if isinstance(node, ast.AsyncFunctionDef) and node.name.startswith(prefix):
                target = f"{path.relative_to(root).as_posix()}::{node.name}"
    if target is None:
        parser.error(f"Final case test function not found for {args.case}")

    db = sqlite3.connect(args.ledger.resolve(strict=True).as_uri() + "?mode=rw", uri=True)
    db.execute(
        "CREATE TABLE IF NOT EXISTS sessions (id TEXT PRIMARY KEY, case_id TEXT, "
        "state TEXT, output_dir TEXT, trace_id TEXT)"
    )
    db.commit()
    db.execute("BEGIN IMMEDIATE")
    rows = db.execute("SELECT case_id, state FROM sessions").fetchall()
    if any(state in ("RUNNING", "REVIEW_REQUIRED") for _, state in rows):
        raise ValueError("Finish/review existing session before admitting another")
    if len(rows) >= proposal["max_admissions"]:
        raise ValueError("Completion Batch max_admissions reached; do not admit more runs")
    if sum(case == args.case for case, _ in rows) >= proposal["repetitions_per_case"]:
        raise ValueError(
            f"{args.case} already used all {proposal['repetitions_per_case']} admissions (retry_admissions=0)"
        )

    before = usage(db)
    maximum, cap, expires, ledger_approval, blocked = db.execute("SELECT * FROM budget").fetchone()
    expected_ref = f"{approval['owner_approval_ref']}:{digest}"
    if (
        blocked
        or datetime.now(UTC) >= datetime.fromisoformat(expires)
        or ledger_approval != expected_ref
        or maximum != proposal["max_inference_requests"]
        or cap != proposal["max_conservative_nanodollars"]
        or before["http_attempts"] >= maximum
        or before["accounted_nanodollars"] >= cap
    ):
        raise ValueError("Completion ledger blocked, expired, exhausted, or mismatched")

    from native_ready import local_json, probe_device, validate_idle

    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)

    native_proof_env: dict[str, str] = {}
    prior_case_runs = sum(case == args.case for case, _ in rows)
    try:
        if DEFAULT_ADB_DIR.is_dir():
            os.environ["PATH"] = str(DEFAULT_ADB_DIR) + os.pathsep + os.environ.get("PATH", "")
        validate_idle(local_json(8001, "/api/status"))
        installed_sha = verify_installed_apk(args.serial, proposal["target_apk_sha256"])
        if args.case == "TC-NATIVE-01":
            native_preflight = prepare_native_permission_preflight(args.serial, output, prior_case_runs)
            native_proof_env = {
                "ADB": adb_exe(),
                "BEEWISE_NATIVE_EVIDENCE": str(output / "native-proof"),
                "BEEWISE_NATIVE_PRE_XML": native_preflight["pre_xml"],
                "BEEWISE_NATIVE_DECISION": native_preflight["decision"],
            }
        else:
            native_preflight = probe_device(args.serial)
        validate_idle(local_json(8001, "/api/status"))
        native_preflight.update(artemis_idle=True, installed_apk_sha256=installed_sha)
        device_epoch = int(
            subprocess.run(
                [adb_exe(), "-s", args.serial, "shell", "date", "+%s"],
                capture_output=True,
                text=True,
                check=True,
                timeout=10,
            ).stdout
        )
    except Exception as error:
        (output / "preflight-blocked.json").write_text(
            json.dumps(
                {
                    "state": "PREFLIGHT_BLOCKED",
                    "admitted": False,
                    "provider_calls": 0,
                    "at_utc": datetime.now(UTC).isoformat(),
                    "error_type": type(error).__name__,
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        raise

    from balance_gate import check_balance

    required_balance = proposal["minimum_nexora_reserve_nanodollars"] + (
        cap - before["accounted_nanodollars"]
    )
    check_balance(args.key_file, required_balance, output / "balance-preflight.json")
    if datetime.now(UTC) >= datetime.fromisoformat(expires):
        raise ValueError("Budget expired during preflight")

    run_id = str(uuid.uuid4())
    db.execute(
        "INSERT INTO sessions VALUES (?, ?, 'RUNNING', ?, NULL)",
        (run_id, args.case, str(output)),
    )
    db.commit()

    env = os.environ.copy()
    env.update(
        ARTEMIS_BASE_URL="http://127.0.0.1:8001",
        ARTEMIS_DEVICE_SERIAL=args.serial,
        DEEPSEEK_SMOKE_TASK_FILE=str(output / "task-id.txt"),
        PYTHONPATH=str(Path(__file__).parent),
        PYTHONIOENCODING="utf-8",
        BEEWISE_SEARCH_TERM=args.search_term,
        BEEWISE_NO_RESULT_TERM=args.no_result_term,
        BEEWISE_TEST_TUTOR_NAME=args.tutor_name,
        BEEWISE_FINAL_TEST_ENV=args.final_test_env,
        BEEWISE_FINAL_AI_PROMPT=args.ai_prompt,
        **native_proof_env,
    )
    command = [
        sys.executable,
        "-m",
        "pytest",
        "-c",
        "e2e_test/pyproject.toml",
        target,
        "-q",
        "-s",
        "-p",
        "smoke_guard",
        f"--junitxml={output / 'result.junit.xml'}",
    ]
    receipt = {
        "run_id": run_id,
        "case": args.case,
        "started_utc": datetime.now(UTC).isoformat(),
        "usage_before": before,
        "command": command,
        "native_review": "PENDING",
        "native_preflight": native_preflight,
        "source_sha": subprocess.run(
            ["git", "rev-parse", "HEAD"], cwd=root, capture_output=True, text=True, check=True
        ).stdout.strip(),
        "apk_sha256": installed_sha,
    }
    with (output / "run-receipt.json").open("x", encoding="utf-8") as file:
        json.dump(receipt, file, indent=2)

    with (output / "pytest-private.log").open("wb") as log:
        child = subprocess.Popen(command, cwd=root, env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            receipt["pytest_exit"] = wait_case(child, args.serial, device_epoch, output)
            receipt["state"] = "REVIEW_REQUIRED" if child.returncode == 0 else "FAILED"
        except (subprocess.SubprocessError, RuntimeError) as error:
            receipt["state"] = "BLOCKED"
            receipt["supervisor_stop"] = type(error).__name__
            if (output / "task-id.txt").exists():
                from artemis_client import ArtemisClient

                client = ArtemisClient(base_url=env["ARTEMIS_BASE_URL"], request_timeout=15)
                try:
                    asyncio.run(client.stop((output / "task-id.txt").read_text().strip()))
                    receipt["remote_stop_requested"] = True
                except Exception:  # noqa: BLE001
                    receipt["remote_stop_requested"] = False
            if child.poll() is None:
                child.terminate()
                child.wait(timeout=15)

    receipt.update(finished_utc=datetime.now(UTC).isoformat(), usage_after=usage(db))
    if (output / "task-id.txt").exists():
        receipt["trace_id"] = (output / "task-id.txt").read_text().strip()
    db.execute(
        "UPDATE sessions SET state = ?, trace_id = ? WHERE id = ?",
        (receipt["state"], receipt.get("trace_id"), run_id),
    )
    db.commit()
    db.close()
    (output / "run-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt, indent=2), flush=True)


if __name__ == "__main__":
    main()
