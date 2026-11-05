"""Read model/account status only. Never generate, retry, or export a balance/key."""

import argparse
import json
import os
from datetime import UTC, datetime
from decimal import Decimal
from pathlib import Path

import httpx
from dotenv import dotenv_values


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--key-file", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--balance-only", action="store_true")
    parser.add_argument("--required-usd", type=Decimal, default=Decimal("0.50"),
                        help="Balance coverage threshold; does not authorize spending")
    args = parser.parse_args()
    if not Decimal(0) < args.required_usd <= Decimal("0.50"):
        parser.error("Coverage threshold must stay within the approved $0.50 ceiling")
    key = os.environ.get("DEEPSEEK_API_KEY") or dotenv_values(args.key_file).get("DEEPSEEK_API_KEY")
    if not key or key.startswith("<"):
        parser.error("Private key missing; no requests made")
    receipt = {"utc": datetime.now(UTC).isoformat(), "inference_requests": 0,
               "reads": [], "model": "deepseek-flash"}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("x", encoding="utf-8") as file:
        json.dump({**receipt, "status": "READ_PREFLIGHT_RESERVED"}, file)
    with httpx.Client(timeout=20, follow_redirects=False, trust_env=False) as client:
        for endpoint in (("/user/balance",) if args.balance_only else ("/models", "/user/balance")):
            entry = {"endpoint": endpoint, "attempts": 1, "status": "RESERVED"}
            receipt["reads"].append(entry)
            args.output.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
            try:
                response = client.get("https://api.deepseek.com" + endpoint,
                                      headers={"Authorization": f"Bearer {key}"})
                entry["http_status"] = response.status_code
                entry["status"] = "PASS" if response.status_code == 200 else "BLOCKED"
                if response.status_code == 200 and endpoint == "/models":
                    row = next((row for row in response.json().get("data", [])
                                if row.get("id") == "deepseek-flash"), None)
                    allowed = ("id", "input_modalities", "context_window", "max_output_tokens")
                    entry["model"] = {name: row[name] for name in allowed if name in row} if row else None
                elif response.status_code == 200:
                    body = response.json()
                    entry["is_available"] = body.get("is_available") is True
                    entry["balance_currencies"] = [row.get("currency") for row in body.get("balance_infos", [])]
                    usd = sum((Decimal(row["total_balance"]) for row in body.get("balance_infos", [])
                               if row.get("currency") == "USD"), Decimal(0))
                    entry["required_usd"] = str(args.required_usd)
                    entry["usd_balance_covers_required"] = usd >= args.required_usd
            except Exception as error:  # noqa: BLE001 - no private provider error text
                entry.update(status="BLOCKED", error_type=type(error).__name__)
            args.output.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()
