"""Reproduce the SDK's local input-guard error without provider or Android I/O."""

import asyncio
from unittest.mock import AsyncMock, patch

import httpx
from artemis.llm.deepseek_budget import GuardedAsyncTransport
from openai import APIConnectionError, AsyncOpenAI


async def check():
    oversized_text = "x" * 33_000
    oversized_images = [{"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,AA=="}}] * 9
    for content in (oversized_text, oversized_images):
        # If the guard regresses, this stub still prevents all provider egress.
        with patch.object(httpx.AsyncHTTPTransport, "handle_async_request",
                          new_callable=AsyncMock) as transport:
            transport.side_effect = AssertionError("The network transport must not be called")
            async with AsyncOpenAI(api_key="offline-test-only", base_url="https://api.deepseek.com",
                                   max_retries=0, http_client=httpx.AsyncClient(
                                       transport=GuardedAsyncTransport(), trust_env=False)) as client:
                try:
                    await client.chat.completions.create(model="deepseek-flash", max_tokens=2048,
                        messages=[{"role": "user", "content": content}],
                        extra_body={"thinking": {"type": "disabled"}})
                except APIConnectionError as error:
                    assert isinstance(error.__cause__, ValueError)
                    assert "input bound exceeded" in str(error.__cause__)
                else:
                    raise AssertionError("Oversized input was not rejected")
            transport.assert_not_called()
    print("PASS: text/image envelope limits reject before network and surface as APIConnectionError; zero egress.")


if __name__ == "__main__":
    asyncio.run(check())
