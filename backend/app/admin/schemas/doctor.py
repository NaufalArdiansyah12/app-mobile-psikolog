"""Schema dokter admin."""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class DoctorDocumentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    document_type: str
    document_path: str
    verification_status: str
    created_at: Optional[datetime] = None


class DoctorOut(BaseModel):
    id: int
    user_id: int
    name: str
    email: str
    phone: Optional[str] = None
    avatar: Optional[str] = None
    specialization: Optional[str] = None
    license_number: Optional[str] = None
    education: Optional[str] = None
    experience: Optional[str] = None
    bio: Optional[str] = None
    verification_status: str
    rejection_reason: Optional[str] = None
    verified_at: Optional[datetime] = None
    is_active: bool = True
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    documents: List[DoctorDocumentOut] = Field(default_factory=list)


class DoctorCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=120, description="Nama lengkap dokter dan gelar")
    email: str = Field(..., description="Email untuk login akun dokter")
    password: str = Field(..., min_length=6, description="Kata sandi akun dokter")
    phone: Optional[str] = Field(None, max_length=30, description="Nomor kontak/WhatsApp")
    specialization: str = Field("Psikolog Klinis", description="Spesialisasi dokter/psikolog")
    license_number: Optional[str] = Field(None, description="Nomor STR / SIP")
    education: Optional[str] = Field(None, description="Latar belakang pendidikan")
    experience: Optional[str] = Field(None, description="Lama pengalaman praktek")
    bio: Optional[str] = Field(None, description="Deskripsi singkat bio & keahlian")
    verification_status: str = Field("approved", description="Status verifikasi awal: approved | pending")
    is_active: bool = Field(True, description="Status keaktifan akun")


class DoctorRejectRequest(BaseModel):
    reason: str = Field(..., min_length=5, description="Alasan penolakan")
