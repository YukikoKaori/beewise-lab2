"""Start the isolated host. Defaults to ZERO permitted provider requests.

Run with the patched ARTEMIS venv Python. A live budget is a manual switch,
not owner authorization; do not set it before exact smoke approval.
"""

import argparse
import hashlib
import json
import os
import sys
from datetime import UTC, datetime
from pathlib import Path


def check_native_authorization(approval_file, budget):
    """The old regression/exploration approvals cannot authorize this supplement."""
    proposal_file = (Path(__file__).resolve().parents[2] /
                     "evidence/artemis/n03-native-final/budget-proposal.json")
    proposed = proposal_file.read_bytes().replace(b"\r\n", b"\n")
    proposal = json.loads(proposed)
    approval = json.loads(approval_file.read_text(encoding="utf-8"))
    requests, cost, expires, reference, blocked = budget
    digest = hashlib.sha256(proposed).hexdigest()
    owner_ref = approval.get("owner_approval_ref")
    if (approval.get("decision") != "OWNER_APPROVED_TC_NATIVE_01" or
            approval.get("proposal_sha256") != digest or
            not isinstance(owner_ref, str) or not owner_ref.strip() or
            reference != f"{owner_ref}:{digest}" or
            requests != proposal["max_inference_requests"] or
            cost != proposal["max_conservative_nanodollars"] or
            blocked or datetime.now(UTC) >= datetime.fromisoformat(expires)):
        raise ValueError("Native supplement ledger requires the exact current owner approval")


def check_final_authorization(approval_file, budget):
    """Validate owner-approved PRM393 Final Gate 3 Option B bounded budget."""
    proposal_file = (Path(__file__).resolve().parents[2] /
                     "evidence/final/artemis/budget-proposal.json")
    proposed = proposal_file.read_bytes().replace(b"\r\n", b"\n")
    proposal = json.loads(proposed)
    approval = json.loads(approval_file.read_text(encoding="utf-8"))
    requests, cost, expires, reference, blocked = budget
    digest = hashlib.sha256(proposed).hexdigest()
    owner_ref = approval.get("owner_approval_ref")
    if (approval.get("decision") != "OWNER_APPROVED_FINAL_GATE_3_B" or
            approval.get("proposal_sha256") != digest or
            not isinstance(owner_ref, str) or not owner_ref.strip() or
            reference != f"{owner_ref}:{digest}" or
            requests != proposal["max_inference_requests"] or
            cost != proposal["max_conservative_nanodollars"] or
            blocked or datetime.now(UTC) >= datetime.fromisoformat(expires)):
        raise ValueError("Final Gate 3 B ledger requires the exact current owner approval")


DEFAULT_COMPLETION_PROPOSAL = Path("evidence/final/artemis/completion-batch/budget-proposal.json")
ALLOWED_COMPLETION_DECISIONS = (
    "OWNER_APPROVED_FINAL_COMPLETION_BATCH",
    "OWNER_APPROVED_FINAL_COMPLETION_WAVE_2",
    "OWNER_APPROVED_FINAL_COMPLETION_WAVE_3",
    "OWNER_APPROVED_FINAL_COMPLETION_WAVE_3_EMU",
)


def check_completion_authorization(approval_file, budget, proposal_file=None):
    """Validate owner-authorized PRM393 Final Completion Batch bounded budget."""
    root = Path(__file__).resolve().parents[2]
    resolved_proposal = (
        (root / proposal_file) if proposal_file and not proposal_file.is_absolute()
        else (proposal_file or (root / DEFAULT_COMPLETION_PROPOSAL))
    )
    proposed = resolved_proposal.read_bytes().replace(b"\r\n", b"\n")
    proposal = json.loads(proposed)
    approval = json.loads(approval_file.read_text(encoding="utf-8"))
    requests, cost, expires, reference, blocked = budget
    digest = hashlib.sha256(proposed).hexdigest()
    owner_ref = approval.get("owner_approval_ref")
    flash_turns = proposal.get("flash_max_turns")
    decision = approval.get("decision")
    expected_decision = proposal.get("decision_required", "OWNER_APPROVED_FINAL_COMPLETION_BATCH")
    if (decision not in ALLOWED_COMPLETION_DECISIONS or
            decision != expected_decision or
            approval.get("proposal_sha256") != digest or
            not isinstance(owner_ref, str) or not owner_ref.strip() or
            reference != f"{owner_ref}:{digest}" or
            not 1 <= proposal["max_inference_requests"] <= 240 or
            not 1 <= proposal["max_conservative_nanodollars"] <= 500_000_000 or
            requests != proposal["max_inference_requests"] or
            cost != proposal["max_conservative_nanodollars"] or
            not isinstance(flash_turns, int) or not 1 <= flash_turns <= 20 or
            blocked or datetime.now(UTC) >= datetime.fromisoformat(expires)):
        raise ValueError("Final Completion Batch ledger requires the exact current owner approval")
    return proposal


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artemis-root", type=Path, required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    parser.add_argument("--approved-live-budget", type=int, default=0, choices=range(13))
    parser.add_argument("--ledger", type=Path, help="Existing owner-approved cumulative batch ledger")
    parser.add_argument("--native-approval", type=Path, help="Exact owner receipt for the separate native ledger")
    parser.add_argument("--final-approval", type=Path, help="Exact owner receipt for PRM393 Final Gate 3 B ledger")
    parser.add_argument("--completion-approval", type=Path, help="Exact owner receipt for PRM393 Final Completion Batch ledger")
    parser.add_argument("--completion-proposal", type=Path, help="Proposal JSON matching --completion-approval")
    parser.add_argument("--key-file", type=Path, default=Path(__file__).with_name(".env"))
    args = parser.parse_args()
    root = args.artemis_root.resolve(strict=True)
    state = args.state_dir.resolve()
    state.mkdir(parents=True, exist_ok=True)
    if args.ledger and args.approved_live_budget:
        parser.error("Batch ledger and historical single-smoke budget are mutually exclusive")
    if sum(bool(x) for x in (args.native_approval, args.final_approval, args.completion_approval)) > 1:
        parser.error("Native, Final, and Completion approvals are mutually exclusive")
    live = bool(args.ledger or args.approved_live_budget)
    if (args.native_approval or args.final_approval or args.completion_approval) and not args.ledger:
        parser.error("Approval receipt requires a separate ledger")
    if live and not (args.native_approval or args.final_approval or args.completion_approval):
        from policy import require_live_authorization
        require_live_authorization()
    _policy = {}
    completion_proposal = None
    if args.ledger:
        args.ledger = args.ledger.resolve(strict=True)
        # Open existing state only. Never initialize/reset a ledger on host restart.
        import sqlite3
        with sqlite3.connect(args.ledger.as_uri() + "?mode=rw", uri=True) as db:
            maximum, ceiling, expires, approval, blocked = db.execute("SELECT * FROM budget").fetchone()
        if args.native_approval:
            try:
                check_native_authorization(args.native_approval, (maximum, ceiling, expires, approval, blocked))
            except (OSError, ValueError, TypeError, KeyError):
                parser.error("Native supplement ledger requires the exact current owner approval")
        elif args.final_approval:
            try:
                check_final_authorization(args.final_approval, (maximum, ceiling, expires, approval, blocked))
            except (OSError, ValueError, TypeError, KeyError):
                parser.error("Final Gate 3 B ledger requires the exact current owner approval")
        elif args.completion_approval:
            try:
                completion_proposal = check_completion_authorization(
                    args.completion_approval,
                    (maximum, ceiling, expires, approval, blocked),
                    proposal_file=args.completion_proposal,
                )
            except (OSError, ValueError, TypeError, KeyError):
                parser.error("Final Completion Batch ledger requires the exact current owner approval")
        else:
            amendment = require_live_authorization(maximum, ceiling)
            _policy = json.loads(Path(__file__).with_name("execution-policy.json").read_text(encoding="utf-8"))
            if _policy.get("decision") in {"OWNER_APPROVED_EXPLORATION", "OWNER_APPROVED_EXPLORATION_V3", "OWNER_APPROVED_EXPLORATION_V4", "OWNER_APPROVED_EXPLORATION_V5", "OWNER_APPROVED_EXPLORATION_V6"}:
                max_allowed_requests = _policy.get("approved_inference_requests", 66)
                max_allowed_cost = int(_policy.get("approved_usd", 0.22) * 1_000_000_000)
                if (not 1 <= maximum <= max_allowed_requests or not 1 <= ceiling <= max_allowed_cost or
                        not approval or blocked or datetime.now(UTC) >= datetime.fromisoformat(expires)):
                    parser.error("Exploration ledger is blocked, expired or unauthorized")
            else:
                max_allowed_requests = 275 if amendment else 240
                max_allowed_cost = 820_000_000 if amendment else 500_000_000
                if (not 1 <= maximum <= max_allowed_requests or not 1 <= ceiling <= max_allowed_cost or
                        (amendment and (expires != amendment["expires_utc"] or amendment["sha256"] not in approval)) or
                        not approval or blocked or datetime.now(UTC) >= datetime.fromisoformat(expires)):
                    parser.error("Cumulative batch ledger is blocked, expired or unauthorized")
    key = ""
    if live:
        from dotenv import dotenv_values
        key = os.environ.get("DEEPSEEK_API_KEY") or dotenv_values(
            args.key_file
        ).get("DEEPSEEK_API_KEY", "")
    if live and (not key or key.startswith("<")):
        parser.error("A private DEEPSEEK_API_KEY is required for approved live execution")
    counter = state / "http-attempts.txt"
    if args.approved_live_budget:
        # Refuse reusing a prior budget: every separately approved run gets new state.
        with counter.open("x", encoding="ascii") as file:
            file.write("0")
    for name in tuple(os.environ):
        if name.startswith(("GOOGLE_", "GEMINI_", "GCP_", "LANGSMITH_", "LANGCHAIN_")):
            os.environ.pop(name)
    os.environ.pop("ARTEMIS_FAKE_LLM", None)
    os.environ.pop("ARTEMIS_DEEPSEEK_LEDGER_FILE", None)
    os.environ.update({
        "OPENAI_API_KEY": key if live else "offline-disabled-not-a-key",
        "OPENAI_BASE_URL": "https://api.deepseek.com",
        "ARTEMIS_ARTEMIS_JSONC": str(Path(__file__).with_name("artemis.deepseek.jsonc")),
        "ARTEMIS_APP_DIR": str(state),
        "ARTEMIS_TRACES_DIR": str(state / "traces"),
        "ARTEMIS_DEEPSEEK_ONLY": "1",
        "ARTEMIS_DEEPSEEK_REQUEST_LIMIT": str(args.approved_live_budget),
        "ARTEMIS_DEEPSEEK_COUNTER_FILE": str(counter),
        "LANGCHAIN_TRACING_V2": "false", "LANGSMITH_TRACING": "false",
    })
    if args.native_approval or args.final_approval or args.completion_approval:
        # Keep the usual envelope and disable the historical exploration pacing/retry overrides.
        for name in ("ARTEMIS_TURN_PACING_SECONDS", "ARTEMIS_MIN_TURNS_BEFORE_REPORT",
                     "ARTEMIS_MIN_EXPLORATION_SECONDS", "ARTEMIS_DEEPSEEK_MAX_NON_IMAGE_BYTES",
                     "ARTEMIS_DEEPSEEK_RETRY_CONNECTION", "ARTEMIS_FLASH_MAX_TURNS"):
            os.environ.pop(name, None)
    if args.completion_approval and completion_proposal is not None:
        os.environ["ARTEMIS_FLASH_MAX_TURNS"] = str(completion_proposal["flash_max_turns"])
        if completion_proposal["flash_max_turns"] > 12:
            os.environ["ARTEMIS_DEEPSEEK_MAX_NON_IMAGE_BYTES"] = "131072"
    if args.ledger:
        os.environ["ARTEMIS_DEEPSEEK_LEDGER_FILE"] = str(args.ledger)
        if _policy.get("decision") in {"OWNER_APPROVED_EXPLORATION", "OWNER_APPROVED_EXPLORATION_V3", "OWNER_APPROVED_EXPLORATION_V4", "OWNER_APPROVED_EXPLORATION_V5", "OWNER_APPROVED_EXPLORATION_V6"}:
            os.environ.update({
                "ARTEMIS_FLASH_MAX_TURNS": "35",
                "ARTEMIS_MIN_EXPLORATION_SECONDS": "910",
                "ARTEMIS_TURN_PACING_SECONDS": "38",
                "ARTEMIS_MIN_TURNS_BEFORE_REPORT": "21",
                "ARTEMIS_DEEPSEEK_MAX_NON_IMAGE_BYTES": "131072",
                "ARTEMIS_DEEPSEEK_RETRY_CONNECTION": "2",
            })
    os.chdir(root)
    sys.path.insert(0, str(root))
    from artemis.config import load_agent_config
    from artemis.config.llm import parse_llm_config
    cfg = parse_llm_config()
    cfg.validate_providers()
    runtime = load_agent_config()
    assert cfg.operator.model == "deepseek-flash" and runtime.flash.max_turns == 8
    from apps.admin_console.server import main as serve
    serve(["--host", "127.0.0.1", "--port", "8001"])


if __name__ == "__main__":
    main()
