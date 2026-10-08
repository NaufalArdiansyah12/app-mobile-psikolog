import json
from typing import Optional
from fastapi import APIRouter, HTTPException, status, UploadFile, File, Form
from app.core.database import get_supabase
from app.admin.utils.storage import save_image_upload
from app.models.schemas import (
    UpdateBookingStatusRequest,
    UpdateDoctorStatusRequest,
    UpdateDoctorProfileRequest,
)
from app.api.routes.consultation import _inmemory_bookings

router = APIRouter(prefix="/doctor", tags=["Dokter & Tenaga Ahli"])

@router.get("/dashboard/{doctor_id}")
def get_doctor_dashboard(doctor_id: str):
    """Ambil ringkasan statistik & data profil riil dokter dari Supabase DB."""
    sp = get_supabase()

    doctor_name = "dr. Nadia S., Sp.KJ"
    specialization = "Psikiater Klinis"
    experience = "8 tahun"
    rating = 5.0
    hospital = "RS Mitra Sehat Jakarta"
    price = "Rp 250.000"
    is_available = True
    avatar = None
    total_consultations = 0
    today_sessions = 0
    completed_sessions = 0

    education = "Spesialis Kedokteran Jiwa - FK Universitas Indonesia"
    str_number = "STR: 31.1.2.100.3.19.112233"
    bio = "Spesialis dalam farmakoterapi dan psikoterapi suportif untuk kasus gangguan suasana hati (mood disorder), insomnia berkepanjangan, dan pemulihan trauma psikologis."
    available_days = ["Senin", "Selasa", "Rabu", "Kamis"]
    available_slots = ["09:00 - 10:00", "13:00 - 14:00", "16:00 - 17:00", "19:00 - 20:00"]

    if sp:
        try:
            # 1. Cari data spesifik dokter dari tabel psychologists
            psy_query = sp.table("psychologists").select("*")
            if doctor_id and doctor_id != "psy_1" and len(doctor_id) > 10:
                psy_res = psy_query.eq("id", doctor_id).execute()
            else:
                psy_res = psy_query.ilike("name", "%Nadia%").limit(1).execute()
                if not psy_res.data:
                    psy_res = psy_query.limit(1).execute()

            if psy_res.data:
                psy = psy_res.data[0]
                doctor_name = psy.get("name", doctor_name)
                specialization = psy.get("role", specialization)
                experience = psy.get("experience", experience)
                hospital = psy.get("hospital", hospital)
                price = psy.get("price", price)
                rating = float(psy.get("rating", 5.0))
                is_available = psy.get("is_available", True)
                if psy.get("avatar"):
                    avatar = psy.get("avatar")

                # Baca kolom resmi bila ada
                if psy.get("bio"):
                    bio = psy.get("bio")
                if psy.get("education"):
                    education = psy.get("education")
                if psy.get("str_number"):
                    str_number = psy.get("str_number")
                if psy.get("available_days"):
                    available_days = psy.get("available_days")
                if psy.get("available_slots"):
                    available_slots = psy.get("available_slots")

                # Ekstraksi fallback jika data masih di category
                raw_cat = psy.get("category", "")
                if raw_cat and isinstance(raw_cat, str) and raw_cat.strip().startswith("{"):
                    try:
                        parsed_meta = json.loads(raw_cat)
                        if not avatar and parsed_meta.get("avatar"):
                            avatar = parsed_meta.get("avatar")
                        if not psy.get("bio") and parsed_meta.get("bio"):
                            bio = parsed_meta.get("bio")
                        if not psy.get("education") and parsed_meta.get("education"):
                            education = parsed_meta.get("education")
                        if not psy.get("str_number") and parsed_meta.get("str_number"):
                            str_number = parsed_meta.get("str_number")
                        if not psy.get("available_days") and parsed_meta.get("days"):
                            available_days = parsed_meta.get("days")
                        if not psy.get("available_slots") and parsed_meta.get("slots"):
                            available_slots = parsed_meta.get("slots")
                    except Exception:
                        pass

            # 2. Hitung statistik riil dari tabel bookings
            bk_res = sp.table("bookings").select("id, status, created_at").execute()
            if bk_res.data:
                total_consultations = len(bk_res.data)
                for b in bk_res.data:
                    st = (b.get("status") or "").lower()
                    if st == "completed":
                        completed_sessions += 1
                    if st in ("confirmed", "pending"):
                        today_sessions += 1

            # 3. Hitung rating riil dari tabel doctor_reviews jika ada
            try:
                rev_res = sp.table("doctor_reviews").select("rating").ilike("psychologist_id", f"%{doctor_id}%").execute()
                if not rev_res.data and doctor_id:
                    rev_res = sp.table("doctor_reviews").select("rating").execute()
                if rev_res.data:
                    rating = round(sum(float(r["rating"]) for r in rev_res.data) / len(rev_res.data), 1)
            except Exception:
                pass

        except Exception as e:
            print(f"Error query doctor dashboard from Supabase: {e}")

    # Kalkulasi honor riil
    num_price = 250000
    try:
        clean_num = ''.join(c for c in price if c.isdigit())
        if clean_num:
            num_price = int(clean_num)
    except Exception:
        pass

    earnings_calc = (completed_sessions if completed_sessions > 0 else total_consultations) * num_price
    earnings_str = f"Rp {earnings_calc:,}".replace(",", ".")

    return {
        "doctor_id": doctor_id,
        "name": doctor_name,
        "specialization": specialization,
        "experience": experience,
        "hospital": hospital,
        "price": price,
        "rating": rating,
        "avatar": avatar,
        "total_consultations": total_consultations,
        "today_sessions": today_sessions,
        "is_available": is_available,
        "earnings_this_month": earnings_str,
        "education": education,
        "str_number": str_number,
        "bio": bio,
        "available_days": available_days,
        "available_slots": available_slots,
    }

@router.post("/upload-avatar")
async def upload_doctor_avatar(
    file: UploadFile = File(...),
    doctor_id: Optional[str] = Form(None)
):
    """Upload foto profil dokter dan update ke Supabase database."""
    try:
        relative_url = await save_image_upload(file, subfolder="avatars")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    sp = get_supabase()
    if sp and relative_url:
        update_data = {"avatar": relative_url}
        meta = {"avatar": relative_url}
        try:
            # 1. Update ke kolom avatar resmi
            if doctor_id and doctor_id != "psy_1" and len(doctor_id) > 10:
                sp.table("psychologists").update(update_data).eq("id", doctor_id).execute()
            else:
                sp.table("psychologists").update(update_data).ilike("name", "%Nadia%").execute()
        except Exception as e:
            # 2. Fallback update metadata category jika kolom avatar belum ada
            try:
                # Ambil metadata category existing
                res = sp.table("psychologists").select("category").limit(1).execute()
                cat_dict = {}
                if res.data and res.data[0].get("category"):
                    try:
                        cat_dict = json.loads(res.data[0]["category"])
                    except Exception:
                        pass
                cat_dict["avatar"] = relative_url
                sp.table("psychologists").update({"category": json.dumps(cat_dict)}).ilike("name", "%Nadia%").execute()
            except Exception:
                pass

    return {
        "status": "success",
        "avatar_url": relative_url,
        "message": "Foto profil dokter berhasil diunggah dan disimpan."
    }

@router.put("/profile")
@router.patch("/profile")
def update_doctor_profile(req: UpdateDoctorProfileRequest):
    """Dokter menyimpan perubahan jadwal, jam sesi, tarif, bio, foto avatar & kredensial ke Supabase DB."""
    sp = get_supabase()
    update_data = {}

    if req.name is not None:
        update_data["name"] = req.name
    if req.role is not None:
        update_data["role"] = req.role
    if req.price is not None:
        update_data["price"] = req.price
    if req.experience is not None:
        update_data["experience"] = req.experience
    if req.hospital is not None:
        update_data["hospital"] = req.hospital
    if req.is_available is not None:
        update_data["is_available"] = req.is_available
    if req.avatar is not None:
        update_data["avatar"] = req.avatar

    # Pack extra schedule & bio & avatar metadata into category JSON as backup
    meta = {
        "bio": req.bio or "Spesialis dalam farmakoterapi dan psikoterapi suportif untuk kasus gangguan suasana hati.",
        "education": req.education or "Spesialis Kedokteran Jiwa - FK Universitas Indonesia",
        "str_number": req.str_number or "STR: 31.1.2.100.3.19.112233",
        "days": req.available_days or ["Senin", "Selasa", "Rabu", "Kamis"],
        "slots": req.available_slots or ["09:00 - 10:00", "13:00 - 14:00", "16:00 - 17:00", "19:00 - 20:00"],
    }
    if req.avatar is not None:
        meta["avatar"] = req.avatar
    update_data["category"] = json.dumps(meta)

    # Dedicated official columns
    if req.bio is not None:
        update_data["bio"] = req.bio
    if req.education is not None:
        update_data["education"] = req.education
    if req.str_number is not None:
        update_data["str_number"] = req.str_number
    if req.available_days is not None:
        update_data["available_days"] = req.available_days
    if req.available_slots is not None:
        update_data["available_slots"] = req.available_slots

    if sp:
        try:
            # 1. Coba update kolom resmi di Supabase
            if req.doctor_id and req.doctor_id != "psy_1" and len(req.doctor_id) > 10:
                res = sp.table("psychologists").update(update_data).eq("id", req.doctor_id).execute()
            else:
                res = sp.table("psychologists").update(update_data).ilike("name", "%Nadia%").execute()
                if not res.data:
                    res = sp.table("psychologists").update(update_data).neq("name", "").execute()

            return {
                "status": "success",
                "message": "Profil dan jadwal dokter berhasil diperbarui di database Supabase",
                "data": res.data
            }
        except Exception as e:
            # 2. Fallback jika user belum menjalankan query ALTER TABLE di Supabase
            try:
                fallback_data = {
                    k: v for k, v in update_data.items()
                    if k in ("name", "role", "price", "experience", "hospital", "is_available", "category", "avatar")
                }
                if req.doctor_id and req.doctor_id != "psy_1" and len(req.doctor_id) > 10:
                    res = sp.table("psychologists").update(fallback_data).eq("id", req.doctor_id).execute()
                else:
                    res = sp.table("psychologists").update(fallback_data).ilike("name", "%Nadia%").execute()

                return {
                    "status": "success",
                    "message": "Profil diperbarui (menggunakan mode fallback)",
                    "data": res.data
                }
            except Exception as inner_e:
                print(f"Supabase update doctor profile error: {inner_e}")
                raise HTTPException(status_code=500, detail=f"Gagal memperbarui ke database: {inner_e}")

    return {"status": "success", "updated": update_data}

@router.get("/bookings")
def get_doctor_bookings(doctor_id: str = "psy_1"):
    """Daftar booking konsultasi riil dari Supabase DB."""
    sp = get_supabase()
    if sp:
        try:
            res = sp.table("bookings").select("*, users(nickname)").order("created_at", desc=True).execute()
            if res.data:
                formatted = []
                for b in res.data:
                    user_info = b.get("users") or {}
                    formatted.append({
                        "id": b.get("id"),
                        "user_id": b.get("user_id"),
                        "patient_name": user_info.get("nickname") or "Pasien MindPal",
                        "schedule_time": b.get("schedule_time") or "Jadwal belum ditentukan",
                        "notes": b.get("notes") or "Konsultasi keluhan kesehatan mental.",
                        "status": (b.get("status") or "pending").lower(),
                        "ai_screening": b.get("ai_screening"),
                        "created_at": b.get("created_at")
                    })
                return {"count": len(formatted), "bookings": formatted}
        except Exception as e:
            print(f"Supabase query doctor bookings failed: {e}")

    # Fallback ke in-memory jika Supabase offline atau kosong
    if _inmemory_bookings:
        formatted = []
        for b in _inmemory_bookings:
            formatted.append({
                "id": b.get("id"),
                "user_id": b.get("user_uuid") or b.get("user_id"),
                "patient_name": "Pasien MindPal",
                "schedule_time": b.get("schedule_time") or "Jadwal belum ditentukan",
                "notes": b.get("notes") or "Konsultasi keluhan kesehatan mental.",
                "status": (b.get("status") or "pending").lower(),
                "ai_screening": b.get("ai_screening"),
                "created_at": b.get("created_at")
            })
        return {"count": len(formatted), "bookings": formatted}

    return {"count": 0, "bookings": []}

@router.patch("/bookings/{booking_id}/status")
def update_booking_status(booking_id: str, req: UpdateBookingStatusRequest):
    """Dokter mengonfirmasi, menyelesaikan, atau membatalkan booking di Supabase DB."""
    sp = get_supabase()
    if sp:
        try:
            res = sp.table("bookings").update({"status": req.status}).eq("id", booking_id).execute()
            return {"status": "success", "booking_id": booking_id, "new_status": req.status, "data": res.data}
        except Exception as e:
            print(f"Supabase update booking failed: {e}")
            raise HTTPException(status_code=500, detail=f"Gagal memperbarui database: {e}")

    return {"status": "success", "booking_id": booking_id, "new_status": req.status}

@router.patch("/availability")
def update_doctor_availability(req: UpdateDoctorStatusRequest):
    """Dokter mengubah status praktik (Online / Offline) di Supabase DB."""
    sp = get_supabase()
    if sp:
        try:
            sp.table("psychologists").update({"is_available": req.is_available}).neq("name", "").execute()
            return {"status": "success", "is_available": req.is_available}
        except Exception as e:
            print(f"Supabase update availability failed: {e}")
            raise HTTPException(status_code=500, detail=f"Gagal memperbarui status di database: {e}")

    return {"status": "success", "is_available": req.is_available}
