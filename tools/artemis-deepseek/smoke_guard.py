"""Single-case supervision plugin; no effect unless explicitly loaded."""

import asyncio
import os
from pathlib import Path


def record_task_id(task_id):
    with Path(os.environ["DEEPSEEK_SMOKE_TASK_FILE"]).open("x", encoding="ascii") as file:
        file.write(task_id)


def pytest_configure(config):
    from artemis_client import ArtemisClient
    original = ArtemisClient.run

    async def bounded_run(self, *args, **kwargs):
        task_id = kwargs["task_id"]
        await asyncio.to_thread(record_task_id, task_id)
        kwargs["timeout"] = min(kwargs.get("timeout", 550), 550)
        try:
            return await asyncio.wait_for(original(self, *args, **kwargs), timeout=550)
        except BaseException:  # noqa: BLE001 - cancel remote task, then re-raise original failure
            try:
                await asyncio.wait_for(self.stop(task_id), timeout=20)
            finally:
                raise

    ArtemisClient.run = bounded_run
