"""Export sanitized native evidence; accepted status requires explicit reviewer input."""

import argparse
import hashlib
import json
import shutil
import sqlite3
import xml.etree.ElementTree as ET
from datetime import UTC, datetime
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--trace-db", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--review-note", required=True)
    parser.add_argument("--accept", action="store_true")
    parser.add_argument("--reject", action="store_true", help="Reject an assertion pass after independent native review")
    args = parser.parse_args()
    if args.accept and args.reject:
        parser.error("Use only one review decision")
    receipt = json.loads((args.run_dir/"run-receipt.json").read_text())
    trace = receipt["trace_id"]
    db = sqlite3.connect(args.trace_db)
    rows = db.execute("SELECT step_number, action_taken, pre_image_name, last_execution_result "
                      "FROM steps WHERE session_id = ? ORDER BY step_number", (trace,)).fetchall()
    args.output.mkdir(parents=True, exist_ok=False)
    actions = []
    report = None
    for number, raw, image, result in rows:
        action = json.loads(raw)
        if action.get("action") == "report_task_status":
            report = action.get("args", {}).get("explanation")
        entry = {"step": number, "action": action.get("action"),
                 "args": {k: v for k, v in action.get("args", {}).items()
                          if k in ("index", "x", "y", "direction", "key")},
                 "execution_result": result}
        if image:
            name = f"step-{number:02}.jpg"
            shutil.copy2(args.trace_db.parent/"images"/(image+".jpg"), args.output/name)
            entry["image"] = name
        actions.append(entry)
    tree = ET.parse(args.run_dir/"result.junit.xml")
    for suite in tree.iter("testsuite"):
        suite.attrib.pop("hostname", None)
    cases = list(tree.iter("testcase"))
    junit_pass = len(cases) == 1 and not any(list(c) for c in cases)
    if args.reject and receipt["state"] != "REVIEW_REQUIRED":
        raise ValueError("Only a review-required run can be independently rejected")
    if args.accept and (not junit_pass or receipt.get("pytest_exit") != 0 or
                        receipt["state"] != "REVIEW_REQUIRED" or not rows or not report):
        raise ValueError("Cannot accept without genuine trace, pytest and JUnit PASS")
    tree.write(args.output/"result.junit.xml", encoding="utf-8", xml_declaration=True)
    review = {"at_utc": datetime.now(UTC).isoformat(), "reviewer": "Codex root native evidence review",
              "note": args.review_note, "accepted": args.accept, "junit_pass": junit_pass}
    for name, data in (("actions.json", actions), ("final-report.json", {"original_explanation": report}),
                       ("run-receipt.json", receipt), ("independent-review.json", review)):
        (args.output/name).write_text(json.dumps(data, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    for name in ("balance-preflight.json", "workflow-postcondition.json"):
        if (args.run_dir/name).is_file():
            shutil.copy2(args.run_dir/name, args.output/name)
    manifest = [{"path": p.name, "bytes": p.stat().st_size,
                 "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
                for p in sorted(args.output.iterdir()) if p.is_file()]
    (args.output/"manifest.json").write_text(json.dumps(manifest, indent=2)+"\n")
    if args.accept or args.reject:
        with sqlite3.connect(args.ledger) as ledger:
            changed = ledger.execute("UPDATE sessions SET state = ? "
                                     "WHERE id = ? AND state = 'REVIEW_REQUIRED'",
                                     ("ACCEPTED" if args.accept else "FAILED", receipt["run_id"])).rowcount
            if changed != 1:
                raise ValueError("Session already reviewed or missing; do not overwrite")
    print(json.dumps({"trace_id": trace, "accepted": args.accept, "frames": len(rows),
                      "junit_pass": junit_pass, "output": str(args.output)}))


if __name__ == "__main__":
    main()
