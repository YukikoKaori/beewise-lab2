"""Start the isolated host. Defaults to ZERO permitted provider requests.

Run with the patched ARTEMIS venv Python. A live budget is a manual switch,
not owner authorization; do not set it before exact smoke approval.
"""

import argparse
import os
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artemis-root", type=Path, required=True)
    parser.add_argument("--state-dir", type=Path, required=True)
    parser.add_argument("--approved-live-budget", type=int, default=0, choices=range(13))
    parser.add_argument("--ledger", type=Path, help="Existing owner-approved cumulative batch ledger")
    parser.add_argument("--key-file", type=Path, default=Path(__file__).with_name(".env"))
    args = parser.parse_args()
    root = args.artemis_root.resolve(strict=True)
    state = args.state_dir.resolve()
    state.mkdir(parents=True, exist_ok=True)
    if args.ledger and args.approved_live_budget:
        parser.error("Batch ledger and historical single-smoke budget are mutually exclusive")
    live = bool(args.ledger or args.approved_live_budget)
    if live:
        from policy import require_live_authorization
        require_live_authorization()
    _policy = {}
    if args.ledger:
        args.ledger = args.ledger.resolve(strict=True)
        # Open existing state only. Never initialize/reset a ledger on host restart.
        import sqlite3
        with sqlite3.connect(args.ledger.as_uri() + "?mode=rw", uri=True) as db:
            maximum, ceiling, expires, approval, blocked = db.execute("SELECT * FROM budget").fetchone()
        amendment = require_live_authorization(maximum, ceiling)
        from datetime import UTC, datetime
        import json as _json
        _policy = _json.loads(Path(__file__).with_name("execution-policy.json").read_text(encoding="utf-8"))
        if _policy.get("decision") == "OWNER_APPROVED_EXPLORATION":
            max_allowed_requests = 50
            max_allowed_cost = 120_000_000
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
    if args.ledger:
        os.environ["ARTEMIS_DEEPSEEK_LEDGER_FILE"] = str(args.ledger)
        if _policy.get("decision") == "OWNER_APPROVED_EXPLORATION":
            os.environ.update({
                "ARTEMIS_FLASH_MAX_TURNS": "35",
                "ARTEMIS_TURN_PACING_SECONDS": "25",
                "ARTEMIS_MIN_TURNS_BEFORE_REPORT": "25",
                "ARTEMIS_MIN_EXPLORATION_SECONDS": "960",
                "ARTEMIS_DEEPSEEK_MAX_NON_IMAGE_BYTES": "131072",
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
