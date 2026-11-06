"""Current owner decision must permit live execution before a host can enable it."""

import hashlib
import json
from decimal import Decimal
from pathlib import Path


def require_live_authorization(requests=1, nanodollars=1):
    policy = json.loads(Path(__file__).with_name("execution-policy.json").read_text(encoding="utf-8"))
    if policy.get("live_hold_reason"):
        raise ValueError("Live authorization held after a failure limit or environment blocker")
    if (policy.get("approved_inference_requests", 0) < requests or
            Decimal(str(policy.get("approved_usd", 0))) * 1_000_000_000 < nanodollars):
        raise ValueError("Requested live allowance exceeds the current owner authorization; no provider request permitted.")
    if policy.get("decision") in {"OWNER_APPROVED_EXPLORATION", "OWNER_APPROVED_EXPLORATION_V3", "OWNER_APPROVED_EXPLORATION_V4", "OWNER_APPROVED_EXPLORATION_V5", "OWNER_APPROVED_EXPLORATION_V6"}:
        amendment = policy.get("exploration_amendment")
        if amendment:
            proposal_name = amendment.get("proposal_file", "exploration-budget-proposal.md")
            proposal = (Path(__file__).resolve().parents[2] /
                        "evidence/artemis/n03-exploration-final" / proposal_name)
            if not amendment.get("owner_approval") or hashlib.sha256(proposal.read_bytes()).hexdigest() != amendment["sha256"]:
                raise ValueError("Exploration amendment approval or proposal integrity missing")
        return amendment
    amendment = policy.get("completion_amendment")
    if amendment:
        proposal_name = amendment.get("proposal_file", "completion-mode-amendment.md")
        proposal = (Path(__file__).resolve().parents[2] /
                    "evidence/artemis/n03-deepseek-final" / proposal_name)
        if not amendment.get("owner_approval") or hashlib.sha256(proposal.read_bytes()).hexdigest() != amendment["sha256"]:
            raise ValueError("Completion amendment approval or proposal integrity missing")
    return amendment


def validate_completion_admission(rows, case, amendment):
    if len(rows) < amendment["historical_admitted"] or len(rows) >= amendment["maximum_admitted"]:
        raise ValueError("Historical admission baseline missing or global cap reached")
    accepted = sum(state == "ACCEPTED" for _, state in rows)
    if accepted >= 30:
        raise ValueError("Acceptance target already met")
    if case != "TC-03" and rows.count(("TC-03", "ACCEPTED")) != 3:
        raise ValueError("Complete TC-03 before the rest of the matrix")
    new_failures = sum(case == selected and state in ("FAILED", "BLOCKED")
                       for selected, state in rows) - amendment["historical_failures"].get(case, 0)
    if new_failures < 0 or new_failures >= amendment["additional_failures_per_case"]:
        raise ValueError("Historical failure baseline missing or case failure cap reached")


def validate_retry_policy(rows, cases):
    policy = json.loads(Path(__file__).with_name("execution-policy.json").read_text(encoding="utf-8"))
    for selected in cases:
        states = [state for case, state in rows if case == selected]
        failed = sum(state in ("FAILED", "BLOCKED") for state in states)
        if failed < 3:
            continue
        amendment = policy.get("tc03_retry_amendment", {})
        proposal = (Path(__file__).resolve().parents[2] /
                    "evidence/artemis/n03-deepseek-final/tc03-retry-amendment.md")
        if (selected == "TC-03" and failed == 3 and 1 <= states.count("ACCEPTED") <= 3
                and 4 <= len(states) <= 6
                and amendment.get("owner_approval_ref") == "call_1106857df9214fd28ffdb9600c8f142f"
                and amendment.get("prior_accepted") == 1 and amendment.get("prior_failed") == 3
                and amendment.get("additional_admissions") == 2
                and amendment.get("stop_after_new_failure") is True
                and proposal.is_file()
                and hashlib.sha256(proposal.read_bytes()).hexdigest() == amendment.get("proposal_sha256")):
            continue
        raise ValueError("Case retry allowance exhausted or amended TC-03 failed again; stop batch")
