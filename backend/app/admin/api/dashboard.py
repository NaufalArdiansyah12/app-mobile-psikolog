"""Endpoint dashboard admin."""

from typing import Any, Dict
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.admin.core.database import get_admin_db
from app.admin.core.security import require_admin
from app.admin.services import dashboard_service
from app.admin.utils import ok, ok_list

router = APIRouter(prefix="/dashboard", tags=["Admin Dashboard"])


@router.get("/stats")
def stats(admin=Depends(require_admin), db: Session = Depends(get_admin_db)) -> Dict[str, Any]:
    return ok("Berhasil", dashboard_service.get_stats(db))


@router.get("/recent-doctors")
def recent_doctors(
    limit: int = Query(5, ge=1, le=20),
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = dashboard_service.recent_doctors(db, limit=limit)
    return ok_list(data, page=1, limit=limit, total=len(data), message="Berhasil")


@router.get("/recent-reports")
def recent_reports(
    limit: int = Query(5, ge=1, le=20),
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = dashboard_service.recent_reports(db, limit=limit)
    return ok_list(data, page=1, limit=limit, total=len(data), message="Berhasil")


@router.get("/recent-activities")
def recent_activities(
    limit: int = Query(8, ge=1, le=50),
    admin=Depends(require_admin),
    db: Session = Depends(get_admin_db),
) -> Dict[str, Any]:
    data = dashboard_service.recent_activities(db, limit=limit)
    return ok_list(data, page=1, limit=limit, total=len(data), message="Berhasil")
