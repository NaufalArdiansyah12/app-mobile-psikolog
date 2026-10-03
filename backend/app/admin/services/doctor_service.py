"""Service manajemen dokter admin."""

from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple
from fastapi import HTTPException
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, joinedload

from app.admin.models.doctor import Doctor
from app.admin.models.user import User
from app.admin.schemas.doctor import DoctorRejectRequest
from app.admin.utils.activity import log_admin_activity
from app.admin.utils import PaginationParams


def serialize(doctor: Doctor, with_documents: bool = True) -> Dict[str, Any]:
    user = doctor.user
    return {
        "id": doctor.id,
        "user_id": doctor.user_id,
        "name": user.name if user else None,
        "email": user.email if user else None,
        "phone": user.phone if user else None,
        "avatar": user.avatar if user else None,
        "specialization": doctor.specialization,
        "license_number": doctor.license_number,
        "education": doctor.education,
        "experience": doctor.experience,
        "bio": doctor.bio,
        "verification_status": doctor.verification_status,
        "rejection_reason": doctor.rejection_reason,
        "verified_at": doctor.verified_at.isoformat() if doctor.verified_at else None,
        "is_active": bool(doctor.is_active),
        "created_at": doctor.created_at.isoformat() if doctor.created_at else None,
        "updated_at": doctor.updated_at.isoformat() if doctor.updated_at else None,
        "documents": [
            {
                "id": d.id,
                "document_type": d.document_type,
                "document_path": d.document_path,
                "verification_status": d.verification_status,
                "created_at": d.created_at.isoformat() if d.created_at else None,
            }
            for d in (doctor.documents or [])
        ]
        if with_documents
        else [],
    }


def _base_query():
    return select(Doctor).options(
        joinedload(Doctor.user),
        joinedload(Doctor.documents),
    )


def list_doctors(
    db: Session,
    pagination: PaginationParams,
    search: Optional[str] = None,
    status: Optional[str] = None,
) -> Tuple[List[Dict[str, Any]], int]:
    query = _base_query()

    if search:
        like = f"%{search.strip()}%"
        query = query.join(Doctor.user).where(
            or_(
                User.name.ilike(like),
                User.email.ilike(like),
                Doctor.specialization.ilike(like),
                Doctor.license_number.ilike(like),
            )
        )

    if status:
        query = query.where(Doctor.verification_status == status)

    count_query = select(func.count()).select_from(query.order_by(None).subquery())
    total = db.execute(count_query).scalar_one()

    rows = (
        db.execute(
            query.order_by(Doctor.created_at.desc())
            .offset(pagination.offset)
            .limit(pagination.limit)
        )
        .unique()
        .scalars()
        .all()
    )
    return [serialize(d) for d in rows], total


def get_doctor(db: Session, doctor_id: int) -> Dict[str, Any]:
    doctor = db.execute(
        _base_query().where(Doctor.id == doctor_id)
    ).unique().scalar_one_or_none()

    if doctor is None:
        raise HTTPException(status_code=404, detail="Dokter belum ditemukan")
    return serialize(doctor)


def _get_doctor_row(db: Session, doctor_id: int) -> Doctor:
    doctor = db.get(Doctor, doctor_id)
    if doctor is None:
        raise HTTPException(status_code=404, detail="Dokter belum ditemukan")
    return doctor


def approve_doctor(db: Session, doctor_id: int, admin_id: int) -> Dict[str, Any]:
    doctor = _get_doctor_row(db, doctor_id)
    doctor.verification_status = "approved"
    doctor.rejection_reason = None
    doctor.verified_at = datetime.utcnow()
    doctor.is_active = True

    for doc in doctor.documents or []:
        doc.verification_status = "approved"

    log_admin_activity(
        db, admin_id, "approve_doctor", "doctor", doctor_id,
        f"Menyetujui verifikasi {doctor.user.name if doctor.user else doctor_id}",
    )
    db.commit()
    db.refresh(doctor)
    return get_doctor(db, doctor_id)


def reject_doctor(
    db: Session, doctor_id: int, admin_id: int, payload: DoctorRejectRequest
) -> Dict[str, Any]:
    doctor = _get_doctor_row(db, doctor_id)
    doctor.verification_status = "rejected"
    doctor.rejection_reason = payload.reason.strip()
    doctor.verified_at = datetime.utcnow()
    doctor.is_active = False

    log_admin_activity(
        db, admin_id, "reject_doctor", "doctor", doctor_id,
        f"Menolak verifikasi {doctor.user.name if doctor.user else doctor_id}",
    )
    db.commit()
    db.refresh(doctor)
    return get_doctor(db, doctor_id)


def set_doctor_active(
    db: Session, doctor_id: int, admin_id: int, active: bool
) -> Dict[str, Any]:
    doctor = _get_doctor_row(db, doctor_id)
    doctor.is_active = active

    if doctor.user is not None:
        doctor.user.status = "active" if active else "inactive"

    action = "activate_doctor" if active else "deactivate_doctor"
    log_admin_activity(
        db, admin_id, action, "doctor", doctor_id,
        f"{'Mengaktifkan' if active else 'Menonaktifkan'} akun {doctor.user.name if doctor.user else doctor_id}",
    )
    db.commit()
    db.refresh(doctor)
    return get_doctor(db, doctor_id)
