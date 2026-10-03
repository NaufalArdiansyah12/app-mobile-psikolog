import json
import asyncio
from typing import List, AsyncGenerator
from openai import AsyncOpenAI
from app.core.config import AI_GATEWAY_URL, AI_GATEWAY_KEY, AI_MODEL
from app.core.prompts import CBT_SYSTEM_PROMPT
from app.models.schemas import ChatMessage, ChatAnalysisResult

ai_client = None
if AI_GATEWAY_KEY:
    ai_client = AsyncOpenAI(
        base_url=AI_GATEWAY_URL,
        api_key=AI_GATEWAY_KEY,
        timeout=20.0,
    )

async def generate_mock_stream(message: str) -> AsyncGenerator[str, None]:
    dummy_responses = [
        "Hai, peluk hangat dari aku ya... ",
        "Tarik napas perlahan, aku ada di sini dengerin kamu sepenuhnya. ",
        "Apa yang lagi bikin hatimu berat hari ini?",
    ]
    for chunk in dummy_responses:
        await asyncio.sleep(0.04)
        yield json.dumps({
            "delta": chunk,
            "is_crisis": False,
            "suggested_chips": ["Latihan Napas", "Mau Curhat", "Bantu Aku Tenang"],
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
            temperature=0.7,
            max_tokens=220, # Ringkas agar streaming super cepat dan kata-kata langsung sampai ke hati
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

async def analyze_chat_session(messages: List[ChatMessage]) -> ChatAnalysisResult:
    """Menganalisis percakapan untuk mengukur tingkat keparahan, emosi dominan, dan insight CBT."""
    convo_text = "\n".join([f"{m.role}: {m.content}" for m in messages if m.content.strip()])
    
    # Fallback default
    fallback = ChatAnalysisResult(
        distress_score=4,
        distress_level="Sedang",
        dominant_emotions=["Cemas", "Lelah mental"],
        cognitive_distortions=["Overthinking"],
        summary="Pengguna mengekspresikan kekhawatiran dan beban pikiran harian.",
        cbt_insights="Pikiran otomatis yang berfokus pada ketidakpastian memicu ketegangan emosional.",
        action_recommendations=[
            "Latihan pernapasan 4-7-8 secara teratur.",
            "Tuliskan hal-hal yang berada di luar kendali dan lepaskan secara bertahap."
        ]
    )

    if not ai_client or not convo_text.strip():
        return fallback

    analysis_prompt = (
        "Analisis percakapan konseling pengguna berikut dan berikan evaluasi psikologis klinis format JSON valid.\n"
        "Struktur JSON WAJIB persis seperti ini tanpa markdown backticks:\n"
        "{\n"
        '  "distress_score": <angka 1 sampai 10>,\n'
        '  "distress_level": "<Ringan|Sedang|Berat>",\n'
        '  "dominant_emotions": ["emosi1", "emosi2"],\n'
        '  "cognitive_distortions": ["nama distorsi kognitif seperti Katastrofisasi, Overthinking, dsb"],\n'
        '  "summary": "<ringkasan kondisi emosional dalam 1-2 kalimat>",\n'
        '  "cbt_insights": "<akar pola pikir negatif berdasarkan sudut pandang CBT>",\n'
        '  "action_recommendations": ["langkah 1", "langkah 2"]\n'
        "}\n\n"
        f"Percakapan:\n{convo_text}"
    )

    try:
        response = await ai_client.chat.completions.create(
            model=AI_MODEL,
            messages=[
                {"role": "system", "content": "Kamu adalah asisten analisis psikologi klinis berbasis CBT. Keluarkan HANYA raw JSON tanpa pembungkus markdown."},
                {"role": "user", "content": analysis_prompt}
            ],
            temperature=0.3,
            max_tokens=400,
        )
        content = response.choices[0].message.content.strip()
        if content.startswith("```"):
            content = content.strip("`")
            if content.startswith("json"):
                content = content[4:].strip()
        data = json.loads(content)
        return ChatAnalysisResult(
            distress_score=max(1, min(10, int(data.get("distress_score", 4)))),
            distress_level=str(data.get("distress_level", "Sedang")),
            dominant_emotions=list(data.get("dominant_emotions", ["Cemas"])),
            cognitive_distortions=list(data.get("cognitive_distortions", [])),
            summary=str(data.get("summary", "Sesi curhat Havenly.")),
            cbt_insights=str(data.get("cbt_insights", "Refleksi pola pikir.")),
            action_recommendations=list(data.get("action_recommendations", ["Istirahat sejenak"]))
        )
    except Exception:
        return fallback

