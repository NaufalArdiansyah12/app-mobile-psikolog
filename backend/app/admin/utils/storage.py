"""Helper penyimpanan file upload."""

import os
import uuid
from pathlib import Path
from typing import Optional

from fastapi import UploadFile
from app.admin.core.config import admin_settings

ALLOWED_IMAGE_MIME = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}


def _ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def _safe_name() -> str:
    return uuid.uuid4().hex


async def save_image_upload(file: UploadFile, subfolder: str = "sliders") -> Optional[str]:
    if file is None or file.filename in (None, ""):
        return None

    content_type = (file.content_type or "").lower()
    if content_type not in ALLOWED_IMAGE_MIME:
        raise ValueError("Format file tidak didukung. Gunakan JPG, PNG, WEBP, atau GIF.")

    content = await file.read()
    if len(content) > admin_settings.MAX_UPLOAD_SIZE:
        raise ValueError("Ukuran gambar maksimal 5 MB.")

    ext = ALLOWED_IMAGE_MIME[content_type]
    folder = Path(admin_settings.UPLOAD_DIR) / subfolder
    _ensure_dir(folder)

    filename = f"{_safe_name()}{ext}"
    (folder / filename).write_bytes(content)
    return f"/uploads/{subfolder}/{filename}"


def delete_uploaded_file(relative_path: Optional[str]) -> None:
    if not relative_path or not relative_path.startswith("/uploads/"):
        return
    try:
        base = Path(admin_settings.UPLOAD_DIR).resolve()
        target = (base / relative_path.replace("/uploads/", "", 1)).resolve()
        if str(target).startswith(str(base)) and os.path.isfile(target):
            os.remove(target)
    except OSError:
        pass
