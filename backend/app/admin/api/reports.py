"""Endpoint laporan admin."""

from typing import Any, Dict, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.admin.core.database import get_admin_db
from app.admin.core.security import require_admin
from app.admin.schemas.report import ReportStatusUpdateRequest
from app.admin.services import report_service
from app.admin.utils import PaginationParams, ok, ok_list

router = APIRouter(prefix="/reports", tags=["Admin Reports"])


@router.get("")
def list_reports(
    search: Optional[str] = Query(None, description="Cari deskripsi/nama pelapor/dokter"),
    status: Optional[str] = Query(None, description="Filter: pending | reviewing | resolved | rejected"),
    pagination: PaginationParams = Depends(),
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    items, total = report_service.list_reports(db, pagination, search=search, status=status)
    return ok_list(items, page=pagination.page, limit=pagination.limit, total=total)


@router.get("/categories")
def list_categories(
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = report_service.list_categories(db)
    return ok_list(data, page=1, limit=len(data) or 1, total=len(data), message="Berhasil")


@router.get("/{report_id}")
def get_report(
    report_id: int,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    return ok("Berhasil", report_service.get_report(db, report_id))


@router.put("/{report_id}/status")
def update_report_status(
    report_id: int,
    payload: ReportStatusUpdateRequest,
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = report_service.update_report_status(db, admin.id, report_id, payload)
    return ok("Status laporan berhasil diperbarui", data)
