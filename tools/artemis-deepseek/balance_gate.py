"""Check the shared account reserve without logging balances or credentials."""

import json
from datetime import UTC, datetime
from decimal import Decimal

import httpx
from dotenv import dotenv_values


def check_balance(key_file, nanodollars, receipt):
    required = Decimal(nanodollars) / 1_000_000_000
    result = {"utc": datetime.now(UTC).isoformat(), "required_usd": str(required),
              "status": "ATTEMPT_RESERVED", "inference_requests": 0}
    with receipt.open("x", encoding="utf-8") as file:
        json.dump(result, file)
    key = dotenv_values(key_file).get("DEEPSEEK_API_KEY")
    try:
        if not key or key.startswith("<"):
            raise ValueError("Missing private balance credential")
        with httpx.Client(timeout=15, trust_env=False, follow_redirects=False) as client:
            response = client.get("https://api.deepseek.com/user/balance",
                                  headers={"Authorization": f"Bearer {key}"})
        result["http_status"] = response.status_code
        response.raise_for_status()
        body = response.json()
        balances = [Decimal(x["total_balance"]) for x in body["balance_infos"] if x["currency"] == "USD"]
        sufficient = (body.get("is_available") is True and len(balances) == 1
                      and balances[0].is_finite() and balances[0] >= required)
        result["status"] = "PASS" if sufficient else "BLOCKED_RESERVE_OR_UNAVAILABLE"
    except Exception as error:  # noqa: BLE001 - HTTP exceptions can carry secrets.
        result.update(status="BLOCKED_BALANCE_CHECK", error_type=type(error).__name__)
    receipt.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if result["status"] != "PASS":
        raise ValueError("DeepSeek balance could not cover the Nexora reserve and remaining allowance")
