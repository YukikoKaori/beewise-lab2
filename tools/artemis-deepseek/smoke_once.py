"""Execute exactly the owner-approved TC-09 once, with private output."""

import argparse
import asyncio
import json
import os
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute-approved-tc09", action="store_true", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    counter = args.state_dir / "http-attempts.txt"
    assert counter.read_text() == "0", "Do not repeat or reuse an inference budget"
    root = Path(__file__).resolve().parents[2]
    env = os.environ.copy()
    env.update({"ARTEMIS_BASE_URL": "http://127.0.0.1:8001",
                "ARTEMIS_DEVICE_SERIAL": "emulator-5562",
                "DEEPSEEK_SMOKE_TASK_FILE": str(output / "task-id.txt"),
                "PYTHONPATH": str(Path(__file__).parent)})
    command = [sys.executable, "-m", "pytest", "-c", "e2e_test/pyproject.toml",
               "e2e_test/test_account_and_firebase.py::test_tc09_all_top_level_destinations_are_reachable",
               "-q", "-s", "-p", "smoke_guard", f"--junitxml={output / 'tc09.junit.xml'}"]
    receipt = {"started": datetime.now(UTC).isoformat(), "case": "TC-09",
               "maximum_inference_attempts": 11, "model_discovery_attempts": 1,
               "maximum_total_http_attempts": 12, "outer_timeout_seconds": 600,
               "inner_timeout_seconds": 550, "repetitions": 1}
    with (output / "pytest-private.log").open("wb") as log:
        child = subprocess.Popen(command, cwd=root, env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            receipt["pytest_exit"] = child.wait(timeout=600)
            receipt["status"] = "PYTEST_PASSED" if child.returncode == 0 else "PYTEST_FAILED"
        except subprocess.TimeoutExpired:
            receipt["status"] = "BLOCKED_TIMEOUT"
            task_file = output / "task-id.txt"
            if task_file.exists():
                from artemis_client import ArtemisClient
                client = ArtemisClient(base_url=env["ARTEMIS_BASE_URL"], request_timeout=15)
                try:
                    asyncio.run(client.stop(task_file.read_text().strip()))
                    receipt["remote_stop_requested"] = True
                except Exception:  # noqa: BLE001 - preserve timeout outcome and stop local child
                    receipt["remote_stop_requested"] = False
            child.terminate()
            child.wait(timeout=15)
    receipt["finished"] = datetime.now(UTC).isoformat()
    receipt["inference_attempts_reserved"] = int(counter.read_text())
    receipt["total_http_attempts_reserved"] = receipt["inference_attempts_reserved"] + 1
    task_file = output / "task-id.txt"
    if task_file.exists():
        receipt["task_id"] = task_file.read_text().strip()
    (output / "run-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt, indent=2), flush=True)


if __name__ == "__main__":
    main()
