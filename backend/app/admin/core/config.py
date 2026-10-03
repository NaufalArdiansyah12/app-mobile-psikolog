"""Konfigurasi modul Admin."""

import os
from functools import lru_cache
from pathlib import Path
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent
ENV_FILE = BASE_DIR / ".env"


class AdminSettings(BaseSettings):
    """Pengaturan modul Admin Panel."""

    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Database URL SQLAlchemy (PostgreSQL Supabase atau SQLite lokal)
    DATABASE_URL: str = os.getenv(
        "ADMIN_DATABASE_URL",
        os.getenv("DATABASE_URL", f"sqlite:///{BASE_DIR}/admin.db")
    )

    # JWT
    JWT_SECRET: str = os.getenv("JWT_SECRET", "mindpal-super-secret-admin-key-2026")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 1 hari

    # CORS Origins
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ]

    # Uploads
    MAX_UPLOAD_SIZE: int = 5 * 1024 * 1024  # 5 MB
    UPLOAD_DIR: str = str(BASE_DIR / "uploads")


@lru_cache
def get_admin_settings() -> AdminSettings:
    return AdminSettings()


admin_settings = get_admin_settings()
