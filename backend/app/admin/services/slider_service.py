"""Service manajemen slider/banner admin."""

from typing import Any, Dict, List, Optional, Tuple
from fastapi import HTTPException, UploadFile
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.admin.models.slider import Slider
from app.admin.utils.activity import log_admin_activity
from app.admin.utils import PaginationParams
from app.admin.utils.storage import delete_uploaded_file, save_image_upload

ALLOWED_STATUS = {"active", "inactive"}


def serialize(slider: Slider) -> Dict[str, Any]:
    return {
        "id": slider.id,
        "title": slider.title,
        "description": slider.description,
        "image": slider.image,
        "link": slider.link,
        "sort_order": slider.sort_order,
        "status": slider.status,
        "created_at": slider.created_at.isoformat() if slider.created_at else None,
        "updated_at": slider.updated_at.isoformat() if slider.updated_at else None,
    }


def list_sliders(
    db: Session,
    pagination: PaginationParams,
    search: Optional[str] = None,
    status: Optional[str] = None,
) -> Tuple[List[Dict[str, Any]], int]:
    query = select(Slider)

    if search:
        like = f"%{search.strip()}%"
        query = query.where(or_(Slider.title.ilike(like), Slider.description.ilike(like)))
    if status:
        query = query.where(Slider.status == status)

    total = db.execute(
        select(func.count()).select_from(query.order_by(None).subquery())
    ).scalar_one()

    rows = (
        db.execute(
            query.order_by(Slider.sort_order.asc(), Slider.created_at.desc())
            .offset(pagination.offset)
            .limit(pagination.limit)
        )
        .scalars()
        .all()
    )
    return [serialize(s) for s in rows], total


def get_slider(db: Session, slider_id: int) -> Dict[str, Any]:
    slider = db.get(Slider, slider_id)
    if slider is None:
        raise HTTPException(status_code=404, detail="Slider tidak ditemukan")
    return serialize(slider)


async def create_slider(
    db: Session,
    admin_id: int,
    *,
    title: str,
    description: Optional[str],
    link: Optional[str],
    sort_order: int,
    status: str,
    image: Optional[UploadFile],
) -> Dict[str, Any]:
    if status not in ALLOWED_STATUS:
        raise HTTPException(status_code=422, detail="Status harus active atau inactive")

    saved_path = await save_image_upload(image, subfolder="sliders")
    if saved_path is None:
        raise HTTPException(status_code=422, detail="Gambar slider wajib diunggah")

    slider = Slider(
        title=title.strip(),
        description=description.strip() if description else None,
        image=saved_path,
        link=link.strip() if link else None,
        sort_order=sort_order,
        status=status,
    )
    db.add(slider)
    db.flush()

    log_admin_activity(
        db, admin_id, "create_slider", "slider", slider.id,
        f"Membuat slider {slider.title}",
    )
    db.commit()
    db.refresh(slider)
    return serialize(slider)


async def update_slider(
    db: Session,
    admin_id: int,
    slider_id: int,
    *,
    title: str,
    description: Optional[str],
    link: Optional[str],
    sort_order: int,
    status: str,
    image: Optional[UploadFile],
) -> Dict[str, Any]:
    slider = db.get(Slider, slider_id)
    if slider is None:
        raise HTTPException(status_code=404, detail="Slider tidak ditemukan")
    if status not in ALLOWED_STATUS:
        raise HTTPException(status_code=422, detail="Status harus active atau inactive")

    slider.title = title.strip()
    slider.description = description.strip() if description else None
    slider.link = link.strip() if link else None
    slider.sort_order = sort_order
    slider.status = status

    new_path = await save_image_upload(image, subfolder="sliders")
    if new_path is not None:
        delete_uploaded_file(slider.image)
        slider.image = new_path

    log_admin_activity(
        db, admin_id, "update_slider", "slider", slider_id,
        f"Mengedit slider {slider.title}",
    )
    db.commit()
    db.refresh(slider)
    return serialize(slider)


def delete_slider(db: Session, admin_id: int, slider_id: int) -> None:
    slider = db.get(Slider, slider_id)
    if slider is None:
        raise HTTPException(status_code=404, detail="Slider tidak ditemukan")

    log_admin_activity(
        db, admin_id, "delete_slider", "slider", slider_id,
        f"Menghapus slider {slider.title}",
    )
    delete_uploaded_file(slider.image)
    db.delete(slider)
    db.commit()


def set_slider_status(
    db: Session, admin_id: int, slider_id: int, active: bool
) -> Dict[str, Any]:
    slider = db.get(Slider, slider_id)
    if slider is None:
        raise HTTPException(status_code=404, detail="Slider tidak ditemukan")

    slider.status = "active" if active else "inactive"
    action = "activate_slider" if active else "deactivate_slider"
    log_admin_activity(
        db, admin_id, action, "slider", slider_id,
        f"{'Mengaktifkan' if active else 'Menonaktifkan'} slider {slider.title}",
    )
    db.commit()
    db.refresh(slider)
    return serialize(slider)
