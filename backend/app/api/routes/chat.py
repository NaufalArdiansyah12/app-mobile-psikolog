import json
from fastapi import APIRouter
from fastapi.responses import StreamingResponse

from app.models.schemas import ChatRequest
from app.services.safety_service import check_crisis
from app.services.chat_service import stream_cbt_chat

router = APIRouter(prefix="/chat", tags=["Chat AI"])

async def sse_format_generator(generator):
    """Format generator langsung ke text/event-stream tanpa buffer internal sse-starlette."""
    async for item in generator:
        yield f"data: {item}\n\n"

@router.post("/stream")
async def chat_stream(req: ChatRequest):
    # 1. Guardrail krisis (<10ms)
    is_crisis, crisis_data = check_crisis(req.message)
    if is_crisis and crisis_data:
        async def crisis_generator():
            yield json.dumps(crisis_data)
        return StreamingResponse(
            sse_format_generator(crisis_generator()),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            }
        )

    # 2. Stream CBT langsung tanpa buffer proxy
    return StreamingResponse(
        sse_format_generator(stream_cbt_chat(req.message, req.history)),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )
