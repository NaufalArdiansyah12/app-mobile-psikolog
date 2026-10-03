"""Service manajemen user admin."""

from typing import Any, Dict, List, Optional, Tuple
from fastapi import HTTPException
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.admin.models.user import User
from app.admin.utils.activity import log_admin_activity
from app.admin.utils import PaginationParams


def serialize(user: User) -> Dict[str, Any]:
    data: Dict[str, Any] = {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "phone": user.phone,
        "role": user.role,
        "status": user.status,
        "avatar": user.avatar,
        "created_at": user.created_at.isoformat() if user.created_at else None,
        "updated_at": user.updated_at.isoformat() if user.updated_at else None,
    }
    if user.role == "doctor" and getattr(user, "doctor", None) is not None:
        data["doctor"] = {
            "id": user.doctor.id,
            "specialization": user.doctor.specialization,
            "license_number": user.doctor.license_number,
            "verification_status": user.doctor.verification_status,
            "is_active": bool(user.doctor.is_active),
        }
    return data


def list_users(
    db: Session,
    pagination: PaginationParams,
    search: Optional[str] = None,
    status: Optional[str] = None,
    role: Optional[str] = None,
) -> Tuple[List[Dict[str, Any]], int]:
    query = select(User)

    if search:
        like = f"%{search.strip()}%"
        query = query.where(
            or_(User.name.ilike(like), User.email.ilike(like), User.phone.ilike(like))
        )
    if status:
        query = query.where(User.status == status)
    if role:
        query = query.where(User.role == role)

    total = db.execute(
        select(func.count()).select_from(query.order_by(None).subquery())
    ).scalar_one()

    rows = (
        db.execute(
            query.order_by(User.created_at.desc())
            .offset(pagination.offset)
            .limit(pagination.limit)
        )
        .scalars()
        .all()
    )
    return [serialize(u) for u in rows], total


def get_user(db: Session, user_id: int) -> Dict[str, Any]:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    data = serialize(user)

    if user.role == "doctor" and user.doctor is not None:
        data["doctor"] = {
            "id": user.doctor.id,
            "specialization": user.doctor.specialization,
            "license_number": user.doctor.license_number,
            "verification_status": user.doctor.verification_status,
            "is_active": bool(user.doctor.is_active),
        }
    return data


def set_user_status(
    db: Session, user_id: int, admin_id: int, status: str
) -> Dict[str, Any]:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    if user.role == "admin":
        raise HTTPException(status_code=403, detail="Status akun admin tidak boleh diubah dari panel ini")

    user.status = status

    if user.role == "doctor" and user.doctor is not None:
        user.doctor.is_active = status == "active"

    action_map = {"active": "activate_user", "inactive": "deactivate_user", "suspended": "suspend_user"}
    log_admin_activity(
        db, admin_id, action_map.get(status, "update_user_status"), "user", user_id,
        f"Mengubah status {user.email} menjadi {status}",
    )
    db.commit()
    db.refresh(user)
    return serialize(user)


def delete_user(db: Session, user_id: int, admin_id: int) -> None:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User tidak ditemukan")
    if user.role == "admin":
        raise HTTPException(status_code=403, detail="Akun admin tidak boleh dihapus")

    log_admin_activity(
        db, admin_id, "delete_user", "user", user_id,
        f"Menghapus akun {user.email}",
    )
    db.delete(user)
    db.commit()
