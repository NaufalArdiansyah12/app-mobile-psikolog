from fastapi import APIRouter
from app.core.database import get_supabase
from app.models.schemas import BookingRequest

router = APIRouter(prefix="/consultation", tags=["Konsultasi & Booking"])

_default_psychologists = [
    {"id": "psy_1", "name": "dr. Nadia S., Sp.KJ", "role": "Psikiater Klinis", "experience": "8 tahun",
     "rating": 4.9, "price": "Rp 250.000", "category": "Trauma & Depresi",
     "hospital": "RS Mitra Sehat Jakarta", "available": "Hari ini, 19:00", "is_available": True},
    {"id": "psy_2", "name": "Dimas Pratama, M.Psi., Psikolog", "role": "Psikolog Klinis Dewasa",
     "experience": "5 tahun", "rating": 4.8, "price": "Rp 180.000", "category": "Karir & Burnout",
     "hospital": "Praktek Mandiri Online", "available": "Besok, 14:00", "is_available": True},
    {"id": "psy_3", "name": "Sarah Amalia, M.Psi., Psikolog", "role": "Psikolog Hubungan & Keluarga",
     "experience": "6 tahun", "rating": 4.9, "price": "Rp 200.000", "category": "Hubungan & Asmara",
     "hospital": "Klinik Tumbuh Bahagia", "available": "Hari ini, 20:30", "is_available": True},
    {"id": "psy_4", "name": "Budi Santoso, M.Psi., Psikolog", "role": "Spesialis Regulasi Emosi & CBT",
     "experience": "7 tahun", "rating": 4.7, "price": "Rp 175.000", "category": "Kecemasan & Stres",
     "hospital": "Layanan Telekonseling", "available": "Besok, 10:00", "is_available": True},
]

_inmemory_bookings = []

def _ensure_user(sp, device_uuid: str) -> str:
    user_res = sp.table("users").select("id").eq("device_uuid", device_uuid).execute()
    if not user_res.data:
        new_user = sp.table("users").insert({"device_uuid": device_uuid}).execute()
        return new_user.data[0]["id"]
    return user_res.data[0]["id"]

@router.get("/psychologists")
def get_psychologists():
    sp = get_supabase()
    if sp:
        try:
            res = sp.table("psychologists").select("*").eq("is_available", True).execute()
            if res.data:
                return {"count": len(res.data), "psychologists": res.data}
        except Exception as e:
            print(f"Supabase query psychologists failed: {e}")
    return {"count": len(_default_psychologists), "psychologists": _default_psychologists}

@router.post("/bookings")
def create_booking(booking: BookingRequest):
    sp = get_supabase()
    if sp:
        try:
            user_id = _ensure_user(sp, booking.user_uuid)
            res = sp.table("bookings").insert({
                "user_id": user_id,
                "psychologist_id": booking.psychologist_id,
                "schedule_time": booking.schedule_time,
                "status": "confirmed"
            }).execute()
            return {"status": "success", "booking": res.data}
        except Exception as e:
            print(f"Supabase booking failed: {e}")

    _inmemory_bookings.append(booking.model_dump())
    return {"status": "success", "source": "in-memory", "booking": booking}

@router.get("/bookings/{user_uuid}")
def get_user_bookings(user_uuid: str):
    sp = get_supabase()
    if sp:
        try:
            user_res = sp.table("users").select("id").eq("device_uuid", user_uuid).execute()
            if user_res.data:
                user_id = user_res.data[0]["id"]
                res = sp.table("bookings").select("*, psychologists(name, role, price)").eq("user_id", user_id).order("created_at", desc=True).execute()
                return {"user_uuid": user_uuid, "count": len(res.data), "bookings": res.data}
        except Exception as e:
            print(f"Supabase bookings query failed: {e}")

    user_bookings = [b for b in _inmemory_bookings if b.get("user_uuid") == user_uuid]
    return {"user_uuid": user_uuid, "count": len(user_bookings), "bookings": user_bookings}
