"""Schema autentikasi admin."""

from typing import Optional
from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: EmailStr = Field(..., description="Email admin")
    password: str = Field(..., min_length=1, description="Password")
    remember_me: bool = Field(default=False, description="Ingat sesi login")


class UserBrief(BaseModel):
    id: int
    name: str
    email: str
    role: str
    status: str
    avatar: Optional[str] = None
    phone: Optional[str] = None

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserBrief


class MeResponse(UserBrief):
    pass
