import asyncio
from app.services.chat_service import stream_cbt_chat
from app.models.schemas import ChatMessage

async def test_9router_stream():
    print("Testing 9router AI Gateway connection...")
    collected = []
    async for raw_chunk in stream_cbt_chat("Halo, aku merasa cemas sekali malam ini", []):
        import json
        data = json.loads(raw_chunk)
        if "delta" in data:
            print(data["delta"], end="", flush=True)
            collected.append(data["delta"])

    print("\n--- Stream Complete ---")
    if collected and not collected[0].startswith("[Gagal"):
        print("SUCCESS: 9router AI Gateway streaming works perfectly!")
        return True
    else:
        print("FAIL: AI streaming returned error or empty")
        return False

if __name__ == "__main__":
    asyncio.run(test_9router_stream())
