"""Read-only ledger/evidence audit. This never starts Android or provider calls."""

import argparse
import hashlib
import json
import sqlite3
from datetime import UTC, datetime
from pathlib import Path

from batch_once import CASES, usage


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--summary-name", default="batch-summary.json")
    args = parser.parse_args()
    db = sqlite3.connect(args.ledger.resolve(strict=True).as_uri() + "?mode=ro", uri=True)
    rows = db.execute("SELECT id,case_id,state,output_dir,trace_id FROM sessions ORDER BY rowid").fetchall()
    matrix = {case: {"accepted": 0, "failed_or_blocked": 0} for case in sorted(CASES)}
    traces = set()
    attempts = []
    for run_id, case, state, private_output, trace in rows:
        assert case in matrix
        if trace:
            assert trace not in traces, "Trace ID reused"
            traces.add(trace)
        relative = "runs/" + Path(private_output).name
        packet = args.evidence / relative
        if not packet.exists():
            matches = [path.parent for path in (args.evidence / "runs").glob("*/run-receipt.json")
                       if json.loads(path.read_text(encoding="utf-8")).get("run_id") == run_id]
            assert len(matches) <= 1, "Duplicate evidence for an admission"
            if matches:
                packet = matches[0]
                relative = packet.relative_to(args.evidence).as_posix()
        if state == "ACCEPTED":
            review = json.loads((packet / "independent-review.json").read_text(encoding="utf-8"))
            receipt = json.loads((packet / "run-receipt.json").read_text(encoding="utf-8"))
            assert review["accepted"] and review["junit_pass"] and receipt["pytest_exit"] == 0
            assert receipt["run_id"] == run_id and receipt["trace_id"] == trace
            for entry in json.loads((packet / "manifest.json").read_text()):
                assert hashlib.sha256((packet / entry["path"]).read_bytes()).hexdigest() == entry["sha256"]
            matrix[case]["accepted"] += 1
            assert matrix[case]["accepted"] <= 3
        elif state in ("FAILED", "BLOCKED"):
            matrix[case]["failed_or_blocked"] += 1
        attempts.append({"run_id": run_id, "case": case, "state": state,
                         "trace_id": trace, "evidence": relative if packet.exists() else None})
    accepted = sum(row["accepted"] for row in matrix.values())
    totals = usage(db)
    maximum, cap, expires, approval, blocked = db.execute("SELECT * FROM budget").fetchone()
    assert totals["http_attempts"] <= maximum and totals["accounted_nanodollars"] <= cap
    summary = {"generated_utc": datetime.now(UTC).isoformat(),
               "verdict": "N03_REGRESSION_30_RUNS_COMPLETE" if accepted == 30 else "N03_REGRESSION_INCOMPLETE",
               "accepted_runs": accepted, "target": 30, "matrix": matrix, "attempts": attempts,
               "usage": totals, "estimated_usd": totals["accounted_nanodollars"] / 1e9,
               "remaining_approved_usd": (cap - totals["accounted_nanodollars"]) / 1e9,
               "approval_ref": approval, "expires_utc": expires, "ledger_blocked": bool(blocked),
               "exploration": "NOT RUN; outside approved regression scope"}
    if Path(args.summary_name).name != args.summary_name:
        parser.error("Use a plain summary filename")
    (args.evidence / args.summary_name).write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps({key: value for key, value in summary.items() if key != "attempts"}, indent=2))


if __name__ == "__main__":
    main()
