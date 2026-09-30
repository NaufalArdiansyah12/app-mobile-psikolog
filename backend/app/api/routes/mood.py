from fastapi import APIRouter
from app.core.database import get_supabase
from app.models.schemas import MoodEntry

router = APIRouter(prefix="/mood", tags=["Mood & Jurnal"])

# Fallback in-memory
_inmemory_moods = []

def _ensure_user(sp, device_uuid: str) -> str:
    user_res = sp.table("users").select("id").eq("device_uuid", device_uuid).execute()
    if not user_res.data:
        new_user = sp.table("users").insert({"device_uuid": device_uuid}).execute()
        return new_user.data[0]["id"]
    return user_res.data[0]["id"]

@router.post("")
def record_mood(entry: MoodEntry):
    sp = get_supabase()
    if sp:
        try:
            user_id = _ensure_user(sp, entry.user_uuid)
            res = sp.table("mood_logs").insert({
                "user_id": user_id,
                "score": entry.score,
                "label": entry.label,
                "triggers": entry.triggers,
                "notes": entry.notes,
            }).execute()
            return {"status": "success", "source": "supabase", "recorded": res.data}
        except Exception as e:
            print(f"Supabase mood insert failed: {e}")

    _inmemory_moods.append(entry.model_dump())
    return {"status": "success", "source": "in-memory", "recorded": entry}

@router.get("/{user_uuid}")
def get_user_moods(user_uuid: str):
    sp = get_supabase()
    if sp:
        try:
            user_res = sp.table("users").select("id").eq("device_uuid", user_uuid).execute()
            if user_res.data:
                user_id = user_res.data[0]["id"]
                logs = sp.table("mood_logs").select("*").eq("user_id", user_id).order("created_at", desc=True).execute()
                return {"user_uuid": user_uuid, "count": len(logs.data), "records": logs.data}
        except Exception as e:
            print(f"Supabase mood query failed: {e}")

    user_records = [m for m in _inmemory_moods if m["user_uuid"] == user_uuid]
    return {"user_uuid": user_uuid, "count": len(user_records), "records": user_records}
