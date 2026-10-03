"""Endpoint dokter admin."""

from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.admin.core.database import get_admin_db
from app.admin.core.security import require_admin
from app.admin.schemas.doctor import DoctorCreateRequest, DoctorRejectRequest
from app.admin.services import doctor_service
from app.admin.utils import PaginationParams, ok, ok_list

router = APIRouter(prefix="/doctors", tags=["Admin Doctors"])


@router.post("", status_code=201)
def create_doctor(
    payload: DoctorCreateRequest,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = doctor_service.create_doctor(db, admin.id, payload)
    return ok("Dokter berhasil ditambahkan beserta akun login", data)


@router.get("")
def list_doctors(
    search: Optional[str] = Query(None, description="Cari nama/email/spesialisasi/STR"),
    status: Optional[str] = Query(None, description="Filter: pending | approved | rejected"),
    pagination: PaginationParams = Depends(),
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    items, total = doctor_service.list_doctors(db, pagination, search=search, status=status)
    return ok_list(items, page=pagination.page, limit=pagination.limit, total=total)


@router.get("/{doctor_id}")
def get_doctor(
    doctor_id: int,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    return ok("Berhasil", doctor_service.get_doctor(db, doctor_id))


@router.put("/{doctor_id}/approve")
def approve_doctor(
    doctor_id: int,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = doctor_service.approve_doctor(db, doctor_id, admin.id)
    return ok("Dokter berhasil diverifikasi", data)


@router.put("/{doctor_id}/reject")
def reject_doctor(
    doctor_id: int,
    payload: DoctorRejectRequest,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = doctor_service.reject_doctor(db, doctor_id, admin.id, payload)
    return ok("Verifikasi dokter ditolak", data)


@router.put("/{doctor_id}/activate")
def activate_doctor(
    doctor_id: int,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = doctor_service.set_doctor_active(db, doctor_id, admin.id, active=True)
    return ok("Akun dokter diaktifkan", data)


@router.put("/{doctor_id}/deactivate")
def deactivate_doctor(
    doctor_id: int,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = doctor_service.set_doctor_active(db, doctor_id, admin.id, active=False)
    return ok("Akun dokter dinonaktifkan", data)
