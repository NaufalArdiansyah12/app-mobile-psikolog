"""Service autentikasi admin."""

from typing import Optional
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.admin.core.security import create_access_token, verify_password
from app.admin.models.user import User
from app.admin.schemas.auth import LoginRequest
from app.admin.utils.activity import log_admin_activity


def authenticate(db: Session, payload: LoginRequest) -> User:
    user = db.execute(select(User).where(User.email == payload.email)).scalar_one_or_none()
    if user is None or not verify_password(payload.password, user.password):
        raise HTTPException(status_code=401, detail="Email atau password salah")
    if user.status != "active":
        raise HTTPException(status_code=403, detail="Akun Anda tidak aktif. Hubungi administrator.")
    return user


def issue_token(db: Session, user: User) -> str:
    token = create_access_token(user_id=user.id, role=user.role)
    log_admin_activity(
        db, admin_id=user.id, action="login", target_type="user", target_id=user.id,
        description=f"{user.email} login ke aplikasi",
    )
    db.commit()
    return token


def logout(db: Session, user: Optional[User]) -> None:
    if user is not None:
        log_admin_activity(
            db, admin_id=user.id, action="logout", target_type="user", target_id=user.id,
            description=f"{user.email} logout",
        )
        db.commit()
