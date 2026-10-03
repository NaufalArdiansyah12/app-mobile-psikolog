"""Endpoint slider admin."""

from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, File, Form, Query, UploadFile
from sqlalchemy.orm import Session

from app.admin.core.database import get_admin_db
from app.admin.core.security import require_admin
from app.admin.services import slider_service
from app.admin.utils import PaginationParams, ok, ok_list

router = APIRouter(prefix="/sliders", tags=["Admin Sliders"])


@router.get("")
def list_sliders(
    search: Optional[str] = Query(None, description="Cari judul/deskripsi"),
    status: Optional[str] = Query(None, description="Filter: active | inactive"),
    pagination: PaginationParams = Depends(),
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    items, total = slider_service.list_sliders(db, pagination, search=search, status=status)
    return ok_list(items, page=pagination.page, limit=pagination.limit, total=total)


@router.get("/{slider_id}")
def get_slider(
    slider_id: int,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    return ok("Berhasil", slider_service.get_slider(db, slider_id))


@router.post("")
async def create_slider(
    title: str = Form(..., min_length=1, max_length=150),
    description: Optional[str] = Form(None),
    link: Optional[str] = Form(None),
    sort_order: int = Form(0),
    status: str = Form("active"),
    image: UploadFile = File(...),
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = await slider_service.create_slider(
        db, admin.id, title=title, description=description, link=link,
        sort_order=sort_order, status=status, image=image,
    )
    return ok("Slider berhasil dibuat", data)


@router.put("/{slider_id}")
async def update_slider(
    slider_id: int,
    title: str = Form(..., min_length=1, max_length=150),
    description: Optional[str] = Form(None),
    link: Optional[str] = Form(None),
    sort_order: int = Form(0),
    status: str = Form("active"),
    image: Optional[UploadFile] = File(None),
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = await slider_service.update_slider(
        db, admin.id, slider_id, title=title, description=description, link=link,
        sort_order=sort_order, status=status, image=image,
    )
    return ok("Slider berhasil diperbarui", data)


@router.delete("/{slider_id}")
def delete_slider(
    slider_id: int,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    slider_service.delete_slider(db, admin.id, slider_id)
    return ok("Slider berhasil dihapus")


@router.put("/{slider_id}/activate")
def activate_slider(
    slider_id: int,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = slider_service.set_slider_status(db, admin.id, slider_id, active=True)
    return ok("Slider diaktifkan", data)


@router.put("/{slider_id}/deactivate")
def deactivate_slider(
    slider_id: int,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = slider_service.set_slider_status(db, admin.id, slider_id, active=False)
    return ok("Slider dinonaktifkan", data)
