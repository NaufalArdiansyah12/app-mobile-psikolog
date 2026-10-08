import time
import uuid
from typing import Dict, List, Any, Optional
from datetime import datetime
from fastapi import APIRouter, HTTPException, status
from app.core.database import get_supabase
from app.models.schemas import BookingRequest, ChargeRequest, DoctorMessageRequest, DoctorReviewRequest
from app.services.midtrans_service import MidtransService

router = APIRouter(prefix="/consultation", tags=["Konsultasi, Midtrans & Chat Dokter"])

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

# In-memory storage untuk tracking pembayaran dan chat dokter
_inmemory_bookings: List[Dict[str, Any]] = []
_inmemory_payments: Dict[str, Dict[str, Any]] = {} # order_id -> payment details
_inmemory_doctor_chats: Dict[str, List[Dict[str, Any]]] = {} # conversation_key / booking_id -> messages


def _resolve_conversation_key(sp, booking_id: str, doctor_id: Optional[str] = None, user_uuid: Optional[str] = None, user_id: Optional[str] = None):
    """Menemukan pair (user_id, psychologist_id) dan semua booking_id terkait untuk kontinuitas chat."""
    uid = user_id
    pid = doctor_id
    related_booking_ids = [booking_id]

    if sp:
        try:
            if not uid or not pid:
                b_res = sp.table("bookings").select("user_id, psychologist_id").eq("id", booking_id).limit(1).execute()
                if b_res.data:
                    uid = uid or str(b_res.data[0].get("user_id"))
                    pid = pid or str(b_res.data[0].get("psychologist_id"))
            if not uid and user_uuid:
                u_res = sp.table("users").select("id").eq("device_uuid", user_uuid).limit(1).execute()
                if u_res.data:
                    uid = str(u_res.data[0].get("id"))

            if uid and pid:
                all_b = sp.table("bookings").select("id").eq("user_id", uid).eq("psychologist_id", pid).execute()
                if all_b.data:
                    related_booking_ids = [str(r["id"]) for r in all_b.data if "id" in r]
                    if booking_id not in related_booking_ids:
                        related_booking_ids.append(booking_id)
        except Exception as e:
            print(f"Supabase resolve conversation error: {e}")

    # Fallback cek memory
    if not uid or not pid:
        for mem_b in _inmemory_bookings:
            if mem_b.get("id") == booking_id:
                uid = uid or mem_b.get("user_uuid")
                pid = pid or mem_b.get("psychologist_id")
                break

    conv_key = f"conv_{uid or user_uuid or 'user'}_{pid or 'doctor'}"
    return conv_key, uid, pid, related_booking_ids


def _get_chat_session(sp, booking_id: str, create: bool = False, doctor_id: Optional[str] = None, user_uuid: Optional[str] = None, user_id: Optional[str] = None):
    """Gunakan sesi chat yang konsisten per pasangan user & dokter agar percakapan terus bersambung."""
    _, uid, pid, _ = _resolve_conversation_key(sp, booking_id, doctor_id, user_uuid, user_id)
    title = f"consultation:{uid or 'user'}:{pid or 'doctor'}"
    try:
        found = sp.table("chat_sessions").select("id").eq("title", title).limit(1).execute()
        if found.data:
            return found.data[0]["id"]
        if not create:
            return None

        actual_user_id = uid
        if not actual_user_id:
            booking = sp.table("bookings").select("user_id").eq("id", booking_id).limit(1).execute()
            if booking.data:
                actual_user_id = booking.data[0]["user_id"]

        if not actual_user_id:
            return None

        created = sp.table("chat_sessions").insert({
            "user_id": actual_user_id,
            "title": title,
        }).execute()
        return created.data[0]["id"] if created.data else None
    except Exception as e:
        print(f"Supabase legacy chat session error: {e}")
        return None


def _load_persisted_chat(booking_id: str, doctor_id: Optional[str] = None, user_uuid: Optional[str] = None, user_id: Optional[str] = None) -> List[Dict[str, Any]]:
    """Memuat seluruh riwayat chat konsultasi antara user dan dokter yang sama."""
    sp = get_supabase()
    if not sp:
        return []

    conv_key, uid, pid, related_bids = _resolve_conversation_key(sp, booking_id, doctor_id, user_uuid, user_id)

    try:
        res = (
            sp.table("consultation_messages")
            .select("id, booking_id, sender_id, sender_name, sender_role, message, created_at")
            .in_("booking_id", related_bids)
            .order("created_at")
            .execute()
        )
        if res.data:
            return list(res.data)
    except Exception:
        pass

    # Existing chat_messages table fallback
    try:
        session_id = _get_chat_session(sp, booking_id, create=False, doctor_id=doctor_id, user_uuid=user_uuid, user_id=user_id)
        if not session_id:
            return []
        res = (
            sp.table("chat_messages")
            .select("id, role, content, created_at")
            .eq("session_id", session_id)
            .order("created_at")
            .execute()
        )
        return [{
            "id": row["id"],
            "booking_id": booking_id,
            "sender_id": "doctor_id" if row.get("role") == "assistant" else "user",
            "sender_name": "Dokter Spesialis" if row.get("role") == "assistant" else "Pasien",
            "sender_role": "doctor" if row.get("role") == "assistant" else "user",
            "message": row.get("content", ""),
            "created_at": row.get("created_at"),
        } for row in (res.data or [])]
    except Exception as e:
        print(f"Supabase consultation chat read failed: {e}")
        return []


def _persist_chat_message(message: Dict[str, Any], doctor_id: Optional[str] = None, user_uuid: Optional[str] = None) -> None:
    sp = get_supabase()
    if not sp:
        return
    try:
        sp.table("consultation_messages").insert(message).execute()
        return
    except Exception:
        pass

    try:
        session_id = _get_chat_session(sp, message["booking_id"], create=True, doctor_id=doctor_id, user_uuid=user_uuid)
        if session_id:
            sp.table("chat_messages").insert({
                "session_id": session_id,
                "role": "assistant" if message["sender_role"] == "doctor" else "user",
                "content": message["message"],
            }).execute()
    except Exception as e:
        print(f"Supabase legacy chat write failed: {e}")


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
                # Ambil semua data reviews sekaligus untuk perhitungan agregat
                all_revs_map = {}
                try:
                    revs_res = sp.table("doctor_reviews").select("psychologist_id, rating").execute()
                    if revs_res.data:
                        for r in revs_res.data:
                            pid = str(r.get("psychologist_id"))
                            if pid not in all_revs_map:
                                all_revs_map[pid] = []
                            all_revs_map[pid].append(float(r.get("rating", 0)))
                except Exception:
                    pass

                cleaned = []
                for p in res.data:
                    doc = dict(p)
                    doc_id = str(doc.get("id"))
                    
                    # Hitung rating riil jika ada review di DB
                    if doc_id in all_revs_map and len(all_revs_map[doc_id]) > 0:
                        ratings_list = all_revs_map[doc_id]
                        doc["rating"] = round(sum(ratings_list) / len(ratings_list), 1)
                        doc["reviews"] = len(ratings_list)
                    else:
                        doc["rating"] = None  # Belum ada rating
                        doc["reviews"] = 0

                    raw_cat = doc.get("category", "")
                    if raw_cat and isinstance(raw_cat, str) and raw_cat.strip().startswith("{"):
                        try:
                            import json
                            meta = json.loads(raw_cat)
                            if "bio" in meta:
                                doc["bio"] = meta["bio"]
                            if "education" in meta:
                                doc["education"] = meta["education"]
                            if "str_number" in meta:
                                doc["str"] = meta["str_number"]
                            if "days" in meta:
                                doc["available_days"] = meta["days"]
                            if "slots" in meta:
                                doc["available_slots"] = meta["slots"]
                            if not doc.get("avatar") and "avatar" in meta:
                                doc["avatar"] = meta["avatar"]
                        except Exception:
                            pass
                    cleaned.append(doc)
                return {"count": len(cleaned), "psychologists": cleaned}
        except Exception as e:
            print(f"Supabase query psychologists failed: {e}")
    return {"count": len(_default_psychologists), "psychologists": _default_psychologists}

# 1. MIDTRANS CHARGE API (Custom Native Flow)
@router.post("/charge")
def charge_payment(req: ChargeRequest):
    """
    Membuat tagihan transaksi menggunakan Midtrans Core API (VA BCA/BNI/BRI/Mandiri & QRIS).
    Menghasilkan data VA/QRIS untuk tampilan custom di Flutter.
    """
    sp = get_supabase()
    booking_id = str(uuid.uuid4())
    order_id = f"MP-{int(time.time())}-{uuid.uuid4().hex[:4].upper()}"

    # Cari info dokter
    doctor_name = "dr. Spesialis Havenly"
    for doc in _default_psychologists:
        if str(doc.get("id")) == str(req.psychologist_id):
            doctor_name = doc.get("name", doctor_name)
            break

    # Panggil Midtrans Core API
    charge_result = MidtransService.create_charge(
        order_id=order_id,
        gross_amount=req.gross_amount,
        payment_type=req.payment_type,
        bank=req.bank or "bca",
        customer_name="Pasien Havenly"
    )

    # Simpan booking ke Supabase (status pending bayar)
    if sp:
        try:
            user_id = _ensure_user(sp, req.user_uuid)
            # Validasi UUID psychologist
            psy_id = req.psychologist_id
            if not (len(psy_id) == 36 and psy_id.count('-') == 4):
                psy_res = sp.table("psychologists").select("id").limit(1).execute()
                if psy_res.data:
                    psy_id = psy_res.data[0]["id"]
            insert_booking_data = {
                "id": booking_id,
                "user_id": user_id,
                "psychologist_id": psy_id,
                "schedule_time": req.schedule_time,
                "status": "pending"
            }
            if req.notes:
                insert_booking_data["notes"] = req.notes
            if req.ai_screening:
                insert_booking_data["ai_screening"] = req.ai_screening

            sp_booking = sp.table("bookings").insert(insert_booking_data).execute()
            if sp_booking.data:
                booking_id = sp_booking.data[0].get("id", booking_id)
        except Exception as e:
            print(f"Supabase charge booking insert fallback: {e}")

    # Simpan metadata transaksi
    payment_record = {
        "booking_id": booking_id,
        "order_id": order_id,
        "user_uuid": req.user_uuid,
        "psychologist_id": req.psychologist_id,
        "doctor_name": doctor_name,
        "schedule_time": req.schedule_time,
        "payment_type": req.payment_type,
        "bank": (req.bank or "bca").upper(),
        "gross_amount": req.gross_amount,
        "va_number": charge_result.get("va_number", ""),
        "bill_key": charge_result.get("bill_key", ""),
        "biller_code": charge_result.get("biller_code", ""),
        "qr_code_url": charge_result.get("qr_code_url", ""),
        "status": "pending",
        "notes": req.notes,
        "ai_screening": req.ai_screening,
        "created_at": datetime.utcnow().isoformat()
    }

    _inmemory_payments[order_id] = payment_record
    _inmemory_bookings.append({
        "id": booking_id,
        "order_id": order_id,
        "user_uuid": req.user_uuid,
        "psychologist_id": req.psychologist_id,
        "schedule_time": req.schedule_time,
        "notes": req.notes,
        "ai_screening": req.ai_screening,
        "status": "pending"
    })

    return {
        "status": "success",
        "booking_id": booking_id,
        "order_id": order_id,
        "payment_type": req.payment_type,
        "bank": (req.bank or "bca").upper(),
        "va_number": charge_result.get("va_number", ""),
        "bill_key": charge_result.get("bill_key", ""),
        "biller_code": charge_result.get("biller_code", ""),
        "qr_code_url": charge_result.get("qr_code_url", ""),
        "gross_amount": req.gross_amount,
        "expiry_time": charge_result.get("expiry_time", ""),
        "doctor_name": doctor_name,
        "schedule_time": req.schedule_time,
        "transaction_status": "pending",
        "is_live_midtrans": charge_result.get("is_live_midtrans", False)
    }

# 2. WEBHOOK NOTIFIKASI MIDTRANS
@router.post("/midtrans-webhook")
def midtrans_webhook(payload: Dict[str, Any]):
    """Menerima status pembaruan transaksi dari Midtrans Core API."""
    order_id = payload.get("order_id", "")
    transaction_status = payload.get("transaction_status", "")
    fraud_status = payload.get("fraud_status", "accept")

    is_paid = False
    if transaction_status in ("capture", "settlement"):
        if fraud_status == "accept":
            is_paid = True
    elif transaction_status in ("deny", "cancel", "expire"):
        is_paid = False

    if order_id in _inmemory_payments:
        _inmemory_payments[order_id]["status"] = "confirmed" if is_paid else transaction_status
        booking_id = _inmemory_payments[order_id].get("booking_id")
        if booking_id:
            for b in _inmemory_bookings:
                if b.get("id") == booking_id:
                    b["status"] = "confirmed" if is_paid else "pending"

            sp = get_supabase()
            if sp and is_paid:
                try:
                    sp.table("bookings").update({"status": "confirmed"}).eq("id", booking_id).execute()
                except Exception as e:
                    print(f"Supabase update booking webhook error: {e}")

    return {"status": "ok", "order_id": order_id, "is_paid": is_paid}

# 3. INSTANT SIMULATOR (Sandbox Testing dari Mobile App)
@router.post("/simulate-payment/{order_id}")
def simulate_payment(order_id: str, booking_id: Optional[str] = None):
    """Simulasi pembayaran lunas instan untuk sandbox test dari ponsel."""
    # Settle transaksi langsung di Midtrans Sandbox Simulator
    MidtransService.simulate_payment_settlement(order_id)

    target_booking_id = booking_id
    if order_id in _inmemory_payments:
        _inmemory_payments[order_id]["status"] = "confirmed"
        if not target_booking_id:
            target_booking_id = _inmemory_payments[order_id].get("booking_id")
    else:
        _inmemory_payments[order_id] = {
            "booking_id": target_booking_id or f"bk_{order_id}",
            "order_id": order_id,
            "doctor_name": "dr. Nadia S., Sp.KJ",
            "schedule_time": "Sesi Konsultasi",
            "status": "confirmed",
            "created_at": datetime.utcnow().isoformat()
        }

    resolved_id = target_booking_id or _inmemory_payments[order_id].get("booking_id", f"bk_{order_id}")

    found = False
    for b in _inmemory_bookings:
        if b.get("id") == resolved_id or b.get("order_id") == order_id:
            b["status"] = "confirmed"
            found = True
    if not found:
        _inmemory_bookings.append({
            "id": resolved_id,
            "order_id": order_id,
            "status": "confirmed"
        })

    sp = get_supabase()
    if sp and resolved_id:
        try:
            # Jika resolved_id berformat UUID, update status di Supabase
            if len(resolved_id) == 36 and resolved_id.count('-') == 4:
                sp.table("bookings").update({"status": "confirmed"}).eq("id", resolved_id).execute()
        except Exception as e:
            print(f"Supabase simulate payment update error: {e}")

    # Otomatis inisialisasi ruang chat dokter dengan sapaan hangat
    if resolved_id not in _inmemory_doctor_chats:
        doctor_name = _inmemory_payments[order_id].get("doctor_name", "Dokter")
        schedule = _inmemory_payments[order_id].get("schedule_time", "Sesi Konsultasi")
        _inmemory_doctor_chats[resolved_id] = [
            {
                "id": str(uuid.uuid4()),
                "booking_id": resolved_id,
                "sender_id": "doctor_id",
                "sender_name": doctor_name,
                "sender_role": "doctor",
                "message": f"Halo! Pembayaran sesi konsultasi ({schedule}) telah terkonfirmasi. Saya {doctor_name} siap mendengarkan cerita dan keluhan Anda. Silakan ceritakan apa yang saat ini Anda rasakan.",
                "created_at": datetime.utcnow().isoformat()
            }
        ]

    return {
        "status": "success",
        "order_id": order_id,
        "booking_id": resolved_id,
        "transaction_status": "confirmed",
        "message": "Pembayaran berhasil diverifikasi (Simulasi Midtrans Sandbox)."
    }

# 4. CEK STATUS PEMBAYARAN & BOOKING
@router.get("/booking/{booking_id}/status")
def check_booking_status(booking_id: str):
    # Cek Supabase
    sp = get_supabase()
    status_str = "pending"
    if sp:
        try:
            res = sp.table("bookings").select("status").eq("id", booking_id).execute()
            if res.data:
                status_str = res.data[0].get("status", "pending")
        except Exception:
            pass

    if status_str == "pending":
        for b in _inmemory_bookings:
            if b.get("id") == booking_id and b.get("status") == "confirmed":
                status_str = "confirmed"
                break

    return {
        "booking_id": booking_id,
        "status": status_str,
        "is_paid": status_str in ("confirmed", "completed")
    }

# 5. CHAT 1-ON-1 PASIEN & DOKTER
@router.get("/chat/{booking_id}/messages")
def get_doctor_chat_messages(
    booking_id: str,
    doctor_id: Optional[str] = None,
    user_uuid: Optional[str] = None,
    user_id: Optional[str] = None
):
    """Mengambil pesan obrolan 1-on-1 untuk booking yang sudah lunas (bersambung terus)."""
    sp = get_supabase()
    conv_key, _, _, _ = _resolve_conversation_key(sp, booking_id, doctor_id, user_uuid, user_id)

    persisted = _load_persisted_chat(booking_id, doctor_id, user_uuid, user_id)
    if persisted:
        _inmemory_doctor_chats[conv_key] = persisted
        _inmemory_doctor_chats[booking_id] = persisted
    elif conv_key in _inmemory_doctor_chats and len(_inmemory_doctor_chats[conv_key]) > 0:
        _inmemory_doctor_chats[booking_id] = _inmemory_doctor_chats[conv_key]
    elif booking_id not in _inmemory_doctor_chats:
        init_msgs = [
            {
                "id": f"welcome_{booking_id}",
                "booking_id": booking_id,
                "sender_id": "doctor_id",
                "sender_name": "dr. Nadia S., Sp.KJ",
                "sender_role": "doctor",
                "message": "Halo! Selamat datang di sesi konsultasi privat Havenly. Saya dr. Nadia. Bagaimana kabar Anda hari ini? Ceritakan apa yang sedang Anda rasakan.",
                "created_at": datetime.utcnow().isoformat()
            }
        ]
        _inmemory_doctor_chats[conv_key] = init_msgs
        _inmemory_doctor_chats[booking_id] = init_msgs

    messages = _inmemory_doctor_chats.get(conv_key) or _inmemory_doctor_chats.get(booking_id, [])
    return {
        "booking_id": booking_id,
        "count": len(messages),
        "messages": messages
    }

@router.post("/chat/{booking_id}/send")
def send_doctor_message(booking_id: str, req: DoctorMessageRequest):
    """Kirim pesan dalam ruang chat 1-on-1 dengan dokter (bersambung terus)."""
    sp = get_supabase()
    conv_key, _, _, _ = _resolve_conversation_key(sp, booking_id)

    if conv_key not in _inmemory_doctor_chats:
        _inmemory_doctor_chats[conv_key] = _inmemory_doctor_chats.get(booking_id, [])

    user_msg_id = str(uuid.uuid4())
    user_msg = {
        "id": user_msg_id,
        "booking_id": booking_id,
        "sender_id": req.sender_id,
        "sender_name": req.sender_name,
        "sender_role": req.sender_role,
        "message": req.message,
        "created_at": datetime.utcnow().isoformat()
    }
    _inmemory_doctor_chats[conv_key].append(user_msg)
    _inmemory_doctor_chats[booking_id] = _inmemory_doctor_chats[conv_key]
    _persist_chat_message(user_msg)

    return {
        "status": "success",
        "message": user_msg
    }

# 6. Backward Compatibility Booking API
@router.post("/bookings")
def create_booking(booking: BookingRequest):
    sp = get_supabase()
    if sp:
        try:
            user_id = _ensure_user(sp, booking.user_uuid)
            insert_data = {
                "user_id": user_id,
                "psychologist_id": booking.psychologist_id,
                "schedule_time": booking.schedule_time,
                "status": "confirmed"
            }
            if booking.notes:
                insert_data["notes"] = booking.notes
            if booking.ai_screening:
                insert_data["ai_screening"] = booking.ai_screening

            res = sp.table("bookings").insert(insert_data).execute()
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
            return {"user_uuid": user_uuid, "count": 0, "bookings": []}
        except Exception as e:
            print(f"Supabase bookings query failed: {e}")
            return {"user_uuid": user_uuid, "count": 0, "bookings": []}

    user_bookings = [b for b in _inmemory_bookings if b.get("user_uuid") == user_uuid]
    return {"user_uuid": user_uuid, "count": len(user_bookings), "bookings": user_bookings}

# 7. JADWAL TERISI (BOOKED SLOTS) DOKTER
@router.get("/psychologist/{psychologist_id}/booked-schedules")
def get_booked_schedules(psychologist_id: str):
    """Mengambil daftar jadwal yang sudah terisi dan terkonfirmasi untuk dokter."""
    sp = get_supabase()
    schedules = []

    # 1. Supabase (Database riil realtime)
    if sp:
        try:
            psy_id = psychologist_id
            if psy_id in ("psy_1", "ce2677f2-6831-4769-adb2-b29f27359aa9"):
                res = sp.table("bookings").select("schedule_time").eq("status", "confirmed").execute()
            else:
                res = sp.table("bookings").select("schedule_time").eq("psychologist_id", psy_id).eq("status", "confirmed").execute()
            if res.data:
                for r in res.data:
                    sched = r.get("schedule_time")
                    if sched and sched not in schedules:
                        schedules.append(sched)
            return {"psychologist_id": psychologist_id, "count": len(schedules), "schedules": schedules}
        except Exception as e:
            print(f"Supabase booked schedules query error: {e}")
            return {"psychologist_id": psychologist_id, "count": 0, "schedules": []}

    # 2. In-memory (Hanya jika Supabase tidak terhubung)
    for b in _inmemory_bookings:
        if b.get("status") == "confirmed":
            sched = b.get("schedule_time")
            if sched and sched not in schedules:
                schedules.append(sched)

    return {"psychologist_id": psychologist_id, "count": len(schedules), "schedules": schedules}

# 8. SESI KONSULTASI AKTIF USER (UNTUK AKSES CHAT 1-ON-1)
@router.get("/user/{user_uuid}/active-sessions")
def get_user_active_sessions(user_uuid: str):
    """Mengambil daftar sesi konsultasi aktif yang sudah dibayar oleh pasien."""
    sp = get_supabase()
    active_sessions = []

    if sp:
        try:
            u_res = sp.table("users").select("id").eq("device_uuid", user_uuid).execute()
            if not u_res.data:
                # User tidak ada di database, kembalikan kosong realtime
                return {"user_uuid": user_uuid, "count": 0, "sessions": []}

            user_id = u_res.data[0]["id"]
            res = sp.table("bookings").select("id, schedule_time, status, created_at, psychologists(*)").eq("user_id", user_id).eq("status", "confirmed").order("created_at", desc=True).execute()
            if res.data:
                seen_doc_ids = set()
                for b in res.data:
                    doc = dict(b.get("psychologists") or {})
                    doc_id = str(doc.get("id", ""))
                    if doc_id and doc_id in seen_doc_ids:
                        continue
                    if doc_id:
                        seen_doc_ids.add(doc_id)

                    raw_cat = doc.get("category", "")
                    if raw_cat and isinstance(raw_cat, str) and raw_cat.strip().startswith("{"):
                        try:
                            import json
                            meta = json.loads(raw_cat)
                            if "bio" in meta:
                                doc["bio"] = meta["bio"]
                            if "education" in meta:
                                doc["education"] = meta["education"]
                            if "str_number" in meta:
                                doc["str"] = meta["str_number"]
                            if "days" in meta:
                                doc["available_days"] = meta["days"]
                            if "slots" in meta:
                                doc["available_slots"] = meta["slots"]
                            if not doc.get("avatar") and "avatar" in meta:
                                doc["avatar"] = meta["avatar"]
                        except Exception:
                            pass

                    active_sessions.append({
                        "booking_id": b.get("id"),
                        "schedule_time": b.get("schedule_time"),
                        "status": b.get("status"),
                        "created_at": b.get("created_at"),
                        "doctor": doc
                    })
            # Kembalikan data realtime dari Supabase
            return {"user_uuid": user_uuid, "count": len(active_sessions), "sessions": active_sessions}
        except Exception as e:
            print(f"Supabase user active sessions query error: {e}")
            return {"user_uuid": user_uuid, "count": 0, "sessions": []}

    return {"user_uuid": user_uuid, "count": len(active_sessions), "sessions": active_sessions}

# In-memory storage reviews fallback
_inmemory_reviews: List[Dict[str, Any]] = []

@router.post("/reviews")
def submit_doctor_review(req: DoctorReviewRequest):
    """Menyimpan rating dan ulasan pasien untuk dokter setelah sesi selesai."""
    sp = get_supabase()
    review_data = {
        "id": str(uuid.uuid4()),
        "booking_id": req.booking_id,
        "psychologist_id": req.psychologist_id,
        "user_id": req.user_id,
        "user_name": req.user_name or "Pasien",
        "rating": req.rating,
        "comment": req.comment or "",
        "created_at": datetime.utcnow().isoformat(),
    }

    if sp:
        try:
            # 1. Pastikan tabel doctor_reviews siap di Supabase
            sp.table("doctor_reviews").insert({
                "id": review_data["id"],
                "booking_id": review_data["booking_id"],
                "psychologist_id": review_data["psychologist_id"],
                "user_name": review_data["user_name"],
                "rating": review_data["rating"],
                "comment": review_data["comment"],
            }).execute()

            # 2. Recalculate average rating dokter di tabel psychologists
            all_revs = sp.table("doctor_reviews").select("rating").eq("psychologist_id", req.psychologist_id).execute()
            if all_revs.data and len(all_revs.data) > 0:
                avg = sum(float(r["rating"]) for r in all_revs.data) / len(all_revs.data)
                avg_rounded = round(avg, 1)
                try:
                    sp.table("psychologists").update({"rating": avg_rounded}).eq("id", req.psychologist_id).execute()
                except Exception:
                    pass

            return {"status": "success", "message": "Rating berhasil disimpan!", "data": review_data}
        except Exception as e:
            print(f"Supabase doctor_reviews insert error: {e}")
            # fallback jika tabel belum ada atau error DDL

    _inmemory_reviews.append(review_data)
    return {"status": "success", "message": "Rating berhasil disimpan (memori)!", "data": review_data}

@router.get("/reviews/{doctor_id}")
def get_doctor_reviews(doctor_id: str):
    """Mendapatkan daftar ulasan dan rating rata-rata untuk dokter."""
    sp = get_supabase()
    if sp:
        try:
            res = sp.table("doctor_reviews").select("*").eq("psychologist_id", doctor_id).order("created_at", desc=True).execute()
            if res.data is not None:
                revs = res.data
                avg_val = None
                if revs and len(revs) > 0:
                    avg_val = round(sum(float(r.get("rating", 0)) for r in revs) / len(revs), 1)
                return {
                    "doctor_id": doctor_id,
                    "rating": avg_val,
                    "total_reviews": len(revs),
                    "reviews": revs
                }
        except Exception as e:
            print(f"Supabase get_doctor_reviews error: {e}")

    # Fallback in-memory
    doc_revs = [r for r in _inmemory_reviews if str(r.get("psychologist_id")) == str(doctor_id)]
    avg_val = None
    if doc_revs and len(doc_revs) > 0:
        avg_val = round(sum(float(r.get("rating", 0)) for r in doc_revs) / len(doc_revs), 1)
    return {
        "doctor_id": doctor_id,
        "rating": avg_val,
        "total_reviews": len(doc_revs),
        "reviews": doc_revs
    }
