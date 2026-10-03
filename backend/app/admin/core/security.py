"""Security: bcrypt hashing, JWT, dan authorization (get_current_user / require_admin)."""

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

import bcrypt
import jwt
from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.admin.core.config import admin_settings
from app.admin.core.database import get_admin_db

bearer_scheme = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except (ValueError, TypeError):
        return False


def create_access_token(user_id: int, role: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=admin_settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload: Dict[str, Any] = {
        "sub": str(user_id),
        "role": role,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, admin_settings.JWT_SECRET, algorithm=admin_settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> Optional[Dict[str, Any]]:
    try:
        return jwt.decode(
            token,
            admin_settings.JWT_SECRET,
            algorithms=[admin_settings.JWT_ALGORITHM],
        )
    except jwt.PyJWTError:
        return None


def get_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: Session = Depends(get_admin_db),
):
    from fastapi import HTTPException
    from app.admin.models.user import User

    if credentials is None:
        raise HTTPException(status_code=401, detail="Token tidak ditemukan, silakan login terlebih dahulu")

    claims = decode_access_token(credentials.credentials)
    if claims is None or "sub" not in claims:
        raise HTTPException(status_code=401, detail="Token tidak valid atau sudah kedaluwarsa")

    user = db.get(User, int(claims["sub"]))
    if user is None:
        raise HTTPException(status_code=401, detail="Akun tidak ditemukan")
    if user.status != "active":
        raise HTTPException(status_code=403, detail="Akun Anda tidak aktif")

    return user


def require_admin(current_user=Depends(get_current_user)):
    from fastapi import HTTPException

    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Akses ditolak: hanya admin yang diizinkan")
    return current_user
