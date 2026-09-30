import json
import asyncio
from typing import List, AsyncGenerator
from openai import AsyncOpenAI
from app.core.config import AI_GATEWAY_URL, AI_GATEWAY_KEY, AI_MODEL
from app.core.prompts import CBT_SYSTEM_PROMPT
from app.models.schemas import ChatMessage

ai_client = None
if AI_GATEWAY_KEY:
    ai_client = AsyncOpenAI(
        base_url=AI_GATEWAY_URL,
        api_key=AI_GATEWAY_KEY,
        timeout=20.0,
    )

async def generate_mock_stream(message: str) -> AsyncGenerator[str, None]:
    dummy_responses = [
        "Halo! Aku MindPal. ",
        "Apa yang sedang kamu rasakan hari ini?",
    ]
    for chunk in dummy_responses:
        await asyncio.sleep(0.1)
        yield json.dumps({
            "delta": chunk,
            "is_crisis": False,
            "suggested_chips": ["Latihan Napas", "Mau Curhat"],
            "trigger_exercise": None
        })

async def stream_cbt_chat(message: str, history: List[ChatMessage]) -> AsyncGenerator[str, None]:
    if not ai_client:
        async for chunk in generate_mock_stream(message):
            yield chunk
        return

    # Ambil maksimal 4 percakapan terakhir agar request payload sangat ringan dan cepat direspons
    messages = [{"role": "system", "content": CBT_SYSTEM_PROMPT}]
    for h in history[-4:]:
        messages.append({"role": h.role, "content": h.content})
    messages.append({"role": "user", "content": message})

    try:
        response = await ai_client.chat.completions.create(
            model=AI_MODEL,
            messages=messages,
            stream=True,
            temperature=0.6,
            max_tokens=300, # Batasi output ringkas agar streaming super cepat
        )

        async for chunk in response:
            delta = chunk.choices[0].delta if chunk.choices else None
            if delta and delta.content:
                yield json.dumps({
                    "delta": delta.content,
                    "is_crisis": False,
                    "suggested_chips": ["Bantu aku tenang", "Latihan napas", "Cerita lagi"],
                    "trigger_exercise": None
                })

    except Exception as err:
        yield json.dumps({
            "delta": f"[Gagal memproses pesan: {str(err)}]",
            "is_crisis": False,
            "suggested_chips": ["Coba lagi"],
            "trigger_exercise": None
        })
