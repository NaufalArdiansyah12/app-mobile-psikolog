"""Service laporan user terhadap dokter admin."""

from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple
from fastapi import HTTPException
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, joinedload

from app.admin.models.doctor import Doctor
from app.admin.models.report import Report, ReportCategory
from app.admin.models.user import User
from app.admin.schemas.report import ReportStatusUpdateRequest
from app.admin.utils.activity import log_admin_activity
from app.admin.utils import PaginationParams

ALLOWED_STATUS = {"pending", "reviewing", "resolved", "rejected"}


def serialize(report: Report) -> Dict[str, Any]:
    user = report.user
    doctor = report.doctor
    category = report.category
    return {
        "id": report.id,
        "user_id": report.user_id,
        "doctor_id": report.doctor_id,
        "category_id": report.category_id,
        "description": report.description,
        "evidence": report.evidence,
        "status": report.status,
        "admin_note": report.admin_note,
        "resolved_at": report.resolved_at.isoformat() if report.resolved_at else None,
        "created_at": report.created_at.isoformat() if report.created_at else None,
        "updated_at": report.updated_at.isoformat() if report.updated_at else None,
        "reporter": (
            {
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
            }
            if user
            else None
        ),
        "doctor": (
            {
                "id": doctor.id,
                "name": doctor.user.name if (doctor and doctor.user) else None,
                "specialization": doctor.specialization if doctor else None,
                "license_number": doctor.license_number if doctor else None,
            }
            if doctor
            else None
        ),
        "category": (
            {"id": category.id, "name": category.name} if category else None
        ),
    }


def _base_query():
    return select(Report).options(
        joinedload(Report.user),
        joinedload(Report.doctor).joinedload(Doctor.user),
        joinedload(Report.category),
    )


def list_reports(
    db: Session,
    pagination: PaginationParams,
    search: Optional[str] = None,
    status: Optional[str] = None,
) -> Tuple[List[Dict[str, Any]], int]:
    query = _base_query()

    if search:
        like = f"%{search.strip()}%"
        reporter_match = (
            select(User.id)
            .select_from(User)
            .where(User.id == Report.user_id, User.name.ilike(like))
            .exists()
        )
        doctor_match = (
            select(Doctor.id)
            .select_from(Doctor)
            .join(User, User.id == Doctor.user_id)
            .where(Doctor.id == Report.doctor_id, User.name.ilike(like))
            .exists()
        )
        query = query.where(
            or_(Report.description.ilike(like), reporter_match, doctor_match)
        )

    if status:
        query = query.where(Report.status == status)

    total = db.execute(
        select(func.count()).select_from(query.order_by(None).subquery())
    ).scalar_one()

    rows = (
        db.execute(
            query.order_by(Report.created_at.desc())
            .offset(pagination.offset)
            .limit(pagination.limit)
        )
        .unique()
        .scalars()
        .all()
    )
    return [serialize(r) for r in rows], total


def get_report(db: Session, report_id: int) -> Dict[str, Any]:
    report = db.execute(
        _base_query().where(Report.id == report_id)
    ).unique().scalar_one_or_none()

    if report is None:
        raise HTTPException(status_code=404, detail="Laporan tidak ditemukan")
    return serialize(report)


def update_report_status(
    db: Session, admin_id: int, report_id: int, payload: ReportStatusUpdateRequest
) -> Dict[str, Any]:
    report = db.get(Report, report_id)
    if report is None:
        raise HTTPException(status_code=404, detail="Laporan tidak ditemukan")
    if payload.status not in ALLOWED_STATUS:
        raise HTTPException(status_code=422, detail="Status laporan tidak valid")

    report.status = payload.status
    if payload.admin_note is not None:
        report.admin_note = payload.admin_note.strip() or None

    if payload.status == "resolved":
        report.resolved_at = datetime.utcnow()
    elif payload.status in {"pending", "reviewing"}:
        report.resolved_at = None

    log_admin_activity(
        db, admin_id, "update_report_status", "report", report_id,
        f"Mengubah status laporan #{report_id} menjadi {payload.status}",
    )
    db.commit()
    db.refresh(report)
    return get_report(db, report_id)


def list_categories(db: Session) -> List[Dict[str, Any]]:
    rows = db.execute(select(ReportCategory).order_by(ReportCategory.name)).scalars().all()
    return [{"id": c.id, "name": c.name, "description": c.description} for c in rows]
