"""Service dashboard admin."""

from typing import Any, Dict, List
from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.admin.models.admin_log import AdminActivityLog
from app.admin.models.doctor import Doctor
from app.admin.models.report import Report
from app.admin.models.slider import Slider
from app.admin.models.user import User
from app.admin.services import doctor_service, report_service


def get_stats(db: Session) -> Dict[str, Any]:
    total_users = db.execute(select(func.count()).select_from(User).where(User.role == "user")).scalar_one()
    total_admins = db.execute(select(func.count()).select_from(User).where(User.role == "admin")).scalar_one()
    total_doctors = db.execute(select(func.count()).select_from(Doctor)).scalar_one()
    pending_verification = db.execute(
        select(func.count()).select_from(Doctor).where(Doctor.verification_status == "pending")
    ).scalar_one()
    verified_doctors = db.execute(
        select(func.count()).select_from(Doctor).where(Doctor.verification_status == "approved")
    ).scalar_one()
    total_reports = db.execute(select(func.count()).select_from(Report)).scalar_one()
    unhandled_reports = db.execute(
        select(func.count()).select_from(Report).where(Report.status.in_(["pending", "reviewing"]))
    ).scalar_one()
    total_sliders = db.execute(select(func.count()).select_from(Slider)).scalar_one()
    active_sliders = db.execute(
        select(func.count()).select_from(Slider).where(Slider.status == "active")
    ).scalar_one()
    suspended_users = db.execute(
        select(func.count()).select_from(User).where(User.status.in_(["inactive", "suspended"]))
    ).scalar_one()

    return {
        "total_users": total_users,
        "total_admins": total_admins,
        "total_doctors": total_doctors,
        "pending_verification": pending_verification,
        "verified_doctors": verified_doctors,
        "total_reports": total_reports,
        "unhandled_reports": unhandled_reports,
        "total_sliders": total_sliders,
        "active_sliders": active_sliders,
        "suspended_users": suspended_users,
    }


def recent_doctors(db: Session, limit: int = 5) -> List[Dict[str, Any]]:
    rows = (
        db.execute(
            select(Doctor)
            .options(joinedload(Doctor.user), joinedload(Doctor.documents))
            .order_by(Doctor.created_at.desc())
            .limit(limit)
        )
        .unique()
        .scalars()
        .all()
    )
    return [doctor_service.serialize(d) for d in rows]


def recent_reports(db: Session, limit: int = 5) -> List[Dict[str, Any]]:
    rows = (
        db.execute(
            select(Report)
            .options(
                joinedload(Report.user),
                joinedload(Report.doctor).joinedload(Doctor.user),
                joinedload(Report.category),
            )
            .order_by(Report.created_at.desc())
            .limit(limit)
        )
        .unique()
        .scalars()
        .all()
    )
    return [report_service.serialize(r) for r in rows]


def recent_activities(db: Session, limit: int = 8) -> List[Dict[str, Any]]:
    rows = (
        db.execute(
            select(AdminActivityLog)
            .order_by(AdminActivityLog.created_at.desc(), AdminActivityLog.id.desc())
            .limit(limit)
        )
        .scalars()
        .all()
    )
    return [
        {
            "id": log.id,
            "admin_id": log.admin_id,
            "action": log.action,
            "target_type": log.target_type,
            "target_id": log.target_id,
            "description": log.description,
            "created_at": log.created_at.isoformat() if log.created_at else None,
        }
        for log in rows
    ]
