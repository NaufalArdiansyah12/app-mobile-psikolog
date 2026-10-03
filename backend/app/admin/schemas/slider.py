"""Schema slider admin."""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class SliderOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: Optional[str] = None
    image: str
    link: Optional[str] = None
    sort_order: int = 0
    status: str = "active"
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
