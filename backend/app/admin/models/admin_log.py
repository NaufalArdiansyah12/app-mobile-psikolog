"""Model tabel admin_activity_logs."""

from datetime import datetime
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.admin.core.database import Base


class AdminActivityLog(Base):
    __tablename__ = "admin_activity_logs"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    admin_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("admin_users.id", ondelete="SET NULL"),
        default=None,
        index=True,
    )
    action: Mapped[str] = mapped_column(String(60), nullable=False, index=True)
    target_type: Mapped[Optional[str]] = mapped_column(String(40), default=None)
    target_id: Mapped[Optional[int]] = mapped_column(default=None)
    description: Mapped[Optional[str]] = mapped_column(String(255), default=None)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.current_timestamp(), index=True
    )

    def __repr__(self) -> str:
        return f"<AdminActivityLog {self.action}>"
