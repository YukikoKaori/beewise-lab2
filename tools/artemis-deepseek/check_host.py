"""Read-only ArtemisClient HTTP probe; never submits an Android/AI task."""

import asyncio
import json
import sys
from datetime import UTC, datetime
from pathlib import Path

from artemis_client import ArtemisClient


async def check():
    client = ArtemisClient(base_url="http://127.0.0.1:8001", request_timeout=10)
    status = await client.health()
    devices = await client.list_devices()
    return {
        "timestamp": datetime.now(UTC).isoformat(),
        "base_url": client.base_url,
        "health_http": "PASS", "status_keys": sorted(status.keys()),
        "device_list_http": "PASS", "device_count": len(devices),
        "tasks_submitted": 0, "provider_calls": 0, "native_actions": "NOT RUN",
    }


if __name__ == "__main__":
    receipt = json.dumps(asyncio.run(check()), indent=2) + "\n"
    if len(sys.argv) == 2:
        with Path(sys.argv[1]).open("x", encoding="utf-8") as file:
            file.write(receipt)
    print(receipt)
