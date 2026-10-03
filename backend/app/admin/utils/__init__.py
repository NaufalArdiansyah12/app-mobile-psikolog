"""Helper response, pagination, dan utilitas umum admin."""

from typing import Any, Dict, List
from fastapi import Query
from sqlalchemy.orm import Session


def ok(message: str = "Berhasil", data: Any = None) -> Dict[str, Any]:
    return {"success": True, "message": message, "data": data}


def ok_list(
    items: List[Any],
    page: int,
    limit: int,
    total: int,
    message: str = "Berhasil",
) -> Dict[str, Any]:
    total_pages = max(1, -(-total // limit)) if limit > 0 else 1
    return {
        "success": True,
        "message": message,
        "data": items,
        "pagination": {
            "page": page,
            "limit": limit,
            "total": total,
            "total_pages": total_pages,
        },
    }


def fail(message: str) -> Dict[str, Any]:
    return {"success": False, "message": message}


class PaginationParams:
    def __init__(
        self,
        page: int = Query(1, ge=1, description="Nomor halaman"),
        limit: int = Query(10, ge=1, le=100, description="Jumlah data per halaman"),
    ):
        self.page = page
        self.limit = limit
        self.offset = (page - 1) * limit
