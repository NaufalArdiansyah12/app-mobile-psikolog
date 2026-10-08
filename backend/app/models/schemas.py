from typing import List, Optional, Dict, Any
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
    notes: Optional[str] = None
    ai_screening: Optional[Dict[str, Any]] = None

class ChatAnalyzeRequest(BaseModel):
    user_uuid: str
    messages: List[ChatMessage]

class ChatAnalysisResult(BaseModel):
    distress_score: int = Field(..., ge=1, le=10)
    distress_level: str
    dominant_emotions: List[str] = []
    cognitive_distortions: List[str] = []
    summary: str
    cbt_insights: str
    action_recommendations: List[str] = []

class RegisterRequest(BaseModel):
    email: str
    password: str
    name: str
    role: Optional[str] = "user" # "user" atau "doctor"
    device_uuid: Optional[str] = None

class LoginRequest(BaseModel):
    email: str
    password: str
    role: Optional[str] = None

class ChangePasswordRequest(BaseModel):
    email: str
    old_password: str
    new_password: str

class AuthResponse(BaseModel):
    status: str
    user_id: str
    email: str
    nickname: str
    role: str = "user" # "user" atau "doctor"
    token: Optional[str] = None
    message: Optional[str] = None
    psychologist_id: Optional[str] = None

class UpdateBookingStatusRequest(BaseModel):
    status: str = Field(..., description="'pending', 'confirmed', 'completed', 'cancelled'")
    notes: Optional[str] = None

class UpdateDoctorStatusRequest(BaseModel):
    is_available: bool

class UpdateDoctorProfileRequest(BaseModel):
    doctor_id: Optional[str] = None
    name: Optional[str] = None
    role: Optional[str] = None
    avatar: Optional[str] = None
    price: Optional[str] = None
    experience: Optional[str] = None
    hospital: Optional[str] = None
    education: Optional[str] = None
    str_number: Optional[str] = None
    bio: Optional[str] = None
    available_days: Optional[List[str]] = None
    available_slots: Optional[List[str]] = None
    is_available: Optional[bool] = None

class UpdateUserProfileRequest(BaseModel):
    user_uuid: str
    nickname: Optional[str] = None
    avatar: Optional[str] = None
    bio: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None

class UserProfileResponse(BaseModel):
    status: str
    user_id: Optional[str] = None
    device_uuid: Optional[str] = None
    nickname: Optional[str] = None
    avatar: Optional[str] = None
    bio: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    role: Optional[str] = "user"
    message: Optional[str] = None

class ChargeRequest(BaseModel):
    user_uuid: str
    psychologist_id: str
    schedule_time: str
    payment_type: str = "bank_transfer" # bank_transfer, qris, gopay
    bank: Optional[str] = "bca" # bca, bni, bri, mandiri
    gross_amount: int = 250000
    notes: Optional[str] = None
    ai_screening: Optional[Dict[str, Any]] = None

class DoctorReviewRequest(BaseModel):
    booking_id: str
    psychologist_id: str
    user_id: Optional[str] = None
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None
    user_name: Optional[str] = "Pasien"

class DoctorMessageRequest(BaseModel):
    booking_id: str
    sender_id: str
    sender_name: str
    sender_role: str = "user" # user / doctor
    message: str



