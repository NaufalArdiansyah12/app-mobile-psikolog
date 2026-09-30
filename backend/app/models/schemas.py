from typing import List, Optional
from pydantic import BaseModel, Field

class ChatMessage(BaseModel):
    role: str = Field(..., description="'user' atau 'assistant'")
    content: str

class ChatRequest(BaseModel):
    user_uuid: str
    message: str
    history: List[ChatMessage] = []

class MoodEntry(BaseModel):
    user_uuid: str
    score: int = Field(..., ge=1, le=5)
    label: str
    triggers: List[str] = []
    notes: Optional[str] = None
    timestamp: str

class BookingRequest(BaseModel):
    user_uuid: str
    psychologist_id: str
    schedule_time: str
