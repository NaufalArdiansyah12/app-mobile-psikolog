"""Endpoint autentikasi admin: /api/admin/auth/login, /me, /logout."""

from typing import Any, Dict
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.admin.core.database import get_admin_db
from app.admin.core.security import get_current_user
from app.admin.schemas.auth import LoginRequest
from app.admin.services import auth_service
from app.admin.utils import ok

router = APIRouter(prefix="/auth", tags=["Admin Auth"])


@router.post("/login")
def login(payload: LoginRequest, db: Session = Depends(get_admin_db)) -> Dict[str, Any]:
    user = auth_service.authenticate(db, payload)
    token = auth_service.issue_token(db, user)
    return ok(
        "Login berhasil",
        {
            "access_token": token,
            "token_type": "bearer",
            "user": {
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "role": user.role,
                "status": user.status,
                "avatar": user.avatar,
                "phone": user.phone,
            },
        },
    )


@router.get("/me")
def me(user=Depends(get_current_user), db: Session = Depends(get_admin_db)) -> Dict[str, Any]:
    return ok(
        "Berhasil",
        {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role,
            "status": user.status,
            "avatar": user.avatar,
            "phone": user.phone,
        },
    )


@router.post("/logout")
def logout(user=Depends(get_current_user), db: Session = Depends(get_admin_db)) -> Dict[str, Any]:
    auth_service.logout(db, user)
    return ok("Logout berhasil")
