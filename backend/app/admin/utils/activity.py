"""Helper pencatatan aktivitas admin."""

from typing import Optional
from sqlalchemy.orm import Session
from app.admin.models.admin_log import AdminActivityLog


def log_admin_activity(
    db: Session,
    admin_id: Optional[int],
    action: str,
    target_type: Optional[str] = None,
    target_id: Optional[int] = None,
    description: Optional[str] = None,
) -> None:
    log = AdminActivityLog(
        admin_id=admin_id,
        action=action,
        target_type=target_type,
        target_id=target_id,
        description=description,
    )
    db.add(log)
