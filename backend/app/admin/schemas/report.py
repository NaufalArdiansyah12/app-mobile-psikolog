"""Schema laporan admin."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class ReportUserBrief(BaseModel):
    id: int
    name: str
    email: Optional[str] = None
    phone: Optional[str] = None


class ReportDoctorBrief(BaseModel):
    id: int
    name: str
    specialization: Optional[str] = None
    license_number: Optional[str] = None


class ReportCategoryBrief(BaseModel):
    id: Optional[int] = None
    name: Optional[str] = None


class ReportOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    doctor_id: int
    category_id: Optional[int] = None
    description: str
    evidence: Optional[str] = None
    status: str
    admin_note: Optional[str] = None
    resolved_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    reporter: Optional[ReportUserBrief] = None
    doctor: Optional[ReportDoctorBrief] = None
    category: Optional[ReportCategoryBrief] = None


class ReportStatusUpdateRequest(BaseModel):
    status: str = Field(..., pattern="^(pending|reviewing|resolved|rejected)$")
    admin_note: Optional[str] = Field(default=None, max_length=2000)
