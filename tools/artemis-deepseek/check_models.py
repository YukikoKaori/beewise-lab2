"""One authenticated, read-only model listing; no inference or retries.

Reads the owner's ignored .env privately. Exports only model capabilities and
HTTP status, never headers, error bodies or credentials. Invocation is manual.
"""

import json
import os
import sys
from datetime import UTC, datetime
from pathlib import Path

import httpx
from dotenv import dotenv_values


def main():
    output = Path(sys.argv[1])
    if output.exists():
        raise SystemExit("Refusing to repeat model discovery over an existing receipt")
    key = os.environ.get("DEEPSEEK_API_KEY") or dotenv_values(
        Path(__file__).with_name(".env")
    ).get("DEEPSEEK_API_KEY")
    if not key or key.startswith("<"):
        raise SystemExit("Private DeepSeek key is missing; no request made")
    receipt = {"timestamp": datetime.now(UTC).isoformat(),
               "endpoint": "https://api.deepseek.com/models",
               "method": "GET", "attempts": 1, "inference_requests": 0}
    # Reserve this single read attempt before sending. No retry is permitted.
    with output.open("x", encoding="utf-8") as file:
        file.write(json.dumps({**receipt, "status": "ATTEMPT_RESERVED"}, indent=2))
    try:
        with httpx.Client(timeout=20, follow_redirects=False, trust_env=False) as client:
            response = client.get(receipt["endpoint"], headers={"Authorization": f"Bearer {key}"})
        receipt["http_status"] = response.status_code
        receipt["status"] = "PASS" if response.status_code == 200 else "BLOCKED_HTTP"
        if response.status_code == 200:
            allowed = ("id", "input_modalities", "output_modalities", "context_window", "max_output_tokens")
            receipt["models"] = [{k: row[k] for k in allowed if k in row}
                                 for row in response.json().get("data", [])]
    except Exception as error:  # noqa: BLE001 - export only type, never sensitive error bodies
        receipt["status"] = "BLOCKED_TRANSPORT_OR_PROTOCOL"
        receipt["error_type"] = type(error).__name__
    output.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()
