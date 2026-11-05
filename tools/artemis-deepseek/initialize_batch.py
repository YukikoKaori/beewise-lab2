"""Explicitly initialize a fresh approved batch. Host restarts never run this."""

import argparse
import sys
from datetime import UTC, datetime, timedelta
from decimal import Decimal
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artemis-root", type=Path, required=True)
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--owner-approval-ref", required=True)
    parser.add_argument("--max-requests", type=int, required=True)
    parser.add_argument("--max-usd", type=Decimal, required=True)
    args = parser.parse_args()
    from policy import require_live_authorization
    nanodollars = args.max_usd * 1_000_000_000
    if not nanodollars.is_finite() or nanodollars != nanodollars.to_integral_value():
        parser.error("Spending cap must be a finite exact nanodollar amount")
    require_live_authorization(args.max_requests, int(nanodollars))
    sys.path.insert(0, str(args.artemis_root.resolve(strict=True)))
    from artemis.llm.deepseek_ledger import initialize
    initialize(args.ledger, max_requests=args.max_requests,
               max_nanodollars=int(nanodollars),
               expires_utc=(datetime.now(UTC) + timedelta(hours=24)).isoformat(),
               approval_ref=args.owner_approval_ref)
    print("Fresh cumulative ledger initialized; expiration 24h. No provider request made.")


if __name__ == "__main__":
    main()
