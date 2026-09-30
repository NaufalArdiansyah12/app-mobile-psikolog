from fastapi import APIRouter
from app.core.database import get_supabase
from app.api.routes.mood import _inmemory_moods
from app.api.routes.consultation import _inmemory_bookings

router = APIRouter(prefix="/user", tags=["User & Privacy"])

@router.delete("/{user_uuid}/data")
def purge_user_data(user_uuid: str):
    """Hard delete seluruh data pengguna (FR-04 Panic Clear Data)."""
    sp = get_supabase()
    if sp:
        try:
            # ON DELETE CASCADE otomatis menghapus chat, mood_logs, dan bookings
            sp.table("users").delete().eq("device_uuid", user_uuid).execute()
        except Exception as e:
            print(f"Supabase purge user failed: {e}")

    # Bersihkan in-memory juga
    global _inmemory_moods, _inmemory_bookings
    _inmemory_moods[:] = [m for m in _inmemory_moods if m.get("user_uuid") != user_uuid]
    _inmemory_bookings[:] = [b for b in _inmemory_bookings if b.get("user_uuid") != user_uuid]

    return {
        "status": "success",
        "message": f"Seluruh data user {user_uuid} telah dihapus permanen (hard delete)."
    }
