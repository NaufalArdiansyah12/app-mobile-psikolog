import os
import uuid
from typing import Optional, Dict, Any
from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from app.core.database import get_supabase
from app.admin.utils.storage import save_image_upload
from app.models.schemas import UpdateUserProfileRequest, UserProfileResponse
from app.api.routes.mood import _inmemory_moods
from app.api.routes.consultation import _inmemory_bookings
from app.admin.core.database import SessionLocal
from app.admin.models.user import User as AdminUser

router = APIRouter(prefix="/user", tags=["User & Privacy"])

# In-memory store untuk metadata profil tambahan pasien
_user_profile_meta: Dict[str, Dict[str, Any]] = {}


def _is_valid_uuid(val: str) -> bool:
    try:
        uuid.UUID(str(val))
        return True
    except (ValueError, AttributeError, TypeError):
        return False


@router.post("/upload-avatar")
async def upload_user_avatar(
    file: UploadFile = File(...),
    user_uuid: Optional[str] = Form(None)
):
    """Upload foto profil pengguna / pasien dan kembalikan URL file."""
    try:
        relative_url = await save_image_upload(file, subfolder="avatars")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    if not relative_url:
        raise HTTPException(status_code=400, detail="Gagal menyimpan gambar.")

    if user_uuid:
        if user_uuid not in _user_profile_meta:
            _user_profile_meta[user_uuid] = {}
        _user_profile_meta[user_uuid]["avatar"] = relative_url

        # Coba update Supabase jika terhubung
        sp = get_supabase()
        if sp:
            try:
                # Update nickname/avatar di users jika ada kolom avatar
                if _is_valid_uuid(user_uuid):
                    sp.table("users").update({"avatar": relative_url}).or_(
                        f"id.eq.{user_uuid},device_uuid.eq.{user_uuid}"
                    ).execute()
                else:
                    sp.table("users").update({"avatar": relative_url}).eq(
                        "device_uuid", user_uuid
                    ).execute()
            except Exception:
                pass

    return {
        "status": "success",
        "avatar_url": relative_url,
        "url": relative_url,
        "message": "Foto profil berhasil diunggah."
    }


@router.put("/profile", response_model=UserProfileResponse)
@router.post("/profile", response_model=UserProfileResponse)
def update_user_profile(req: UpdateUserProfileRequest):
    """Perbarui profil user (nama, foto profil, bio, email, no telepon) ke Supabase DB."""
    user_uuid = req.user_uuid.strip()
    if not user_uuid:
        raise HTTPException(status_code=400, detail="user_uuid wajib disertakan.")

    clean_nickname = req.nickname.strip() if req.nickname else None
    clean_bio = req.bio.strip() if req.bio else None
    clean_email = req.email.strip().lower() if req.email else None
    clean_phone = req.phone.strip() if req.phone else None
    clean_avatar = req.avatar.strip() if req.avatar else None

    # Simpan di memory cache
    if user_uuid not in _user_profile_meta:
        _user_profile_meta[user_uuid] = {}

    if clean_nickname:
        _user_profile_meta[user_uuid]["nickname"] = clean_nickname
    if clean_avatar:
        _user_profile_meta[user_uuid]["avatar"] = clean_avatar
    if clean_bio is not None:
        _user_profile_meta[user_uuid]["bio"] = clean_bio
    if clean_email:
        _user_profile_meta[user_uuid]["email"] = clean_email
    if clean_phone is not None:
        _user_profile_meta[user_uuid]["phone"] = clean_phone

    resolved_user_id = user_uuid
    sp = get_supabase()

    if sp:
        try:
            # 1. Cari atau buat user di tabel public.users
            if _is_valid_uuid(user_uuid):
                existing_user = sp.table("users").select("*").or_(
                    f"id.eq.{user_uuid},device_uuid.eq.{user_uuid}"
                ).execute()
            else:
                existing_user = sp.table("users").select("*").eq(
                    "device_uuid", user_uuid
                ).execute()

            if existing_user.data:
                resolved_user_id = existing_user.data[0]["id"]
                # Update nickname di tabel public.users
                update_fields = {}
                if clean_nickname:
                    update_fields["nickname"] = clean_nickname

                # Coba update kolom avatar/bio/email jika ada
                if clean_avatar:
                    update_fields["avatar"] = clean_avatar
                if clean_bio:
                    update_fields["bio"] = clean_bio

                try:
                    sp.table("users").update(update_fields).eq("id", resolved_user_id).execute()
                except Exception:
                    # Fallback hanya update nickname jika kolom lain belum ada di schema
                    if clean_nickname:
                        sp.table("users").update({"nickname": clean_nickname}).eq("id", resolved_user_id).execute()
            else:
                # Insert baru jika belum ada
                insert_data = {"device_uuid": user_uuid}
                if clean_nickname:
                    insert_data["nickname"] = clean_nickname
                try:
                    ins_res = sp.table("users").insert(insert_data).execute()
                    if ins_res.data:
                        resolved_user_id = ins_res.data[0]["id"]
                except Exception as e:
                    print(f"Insert new user to Supabase error: {e}")

            # 2. Update Supabase Auth user_metadata jika terdaftar di Auth
            try:
                auth_users = sp.auth.admin.list_users()
                matched_auth = [
                    u for u in auth_users
                    if u.id == resolved_user_id or (clean_email and u.email == clean_email)
                ]
                if matched_auth:
                    auth_target = matched_auth[0]
                    existing_meta = auth_target.user_metadata or {}
                    if clean_nickname:
                        existing_meta["nickname"] = clean_nickname
                    if clean_avatar:
                        existing_meta["avatar"] = clean_avatar
                    if clean_bio:
                        existing_meta["bio"] = clean_bio
                    if clean_phone:
                        existing_meta["phone"] = clean_phone

                    sp.auth.admin.update_user_by_id(
                        auth_target.id,
                        {"user_metadata": existing_meta}
                    )
            except Exception as e:
                print(f"Supabase auth metadata update note: {e}")

        except Exception as e:
            print(f"Update user profile Supabase error: {e}")

    # 3. Update nama di database Admin (SQLite admin_users) jika ada
    try:
        with SessionLocal() as db:
            admin_u = None
            if clean_email:
                admin_u = db.query(AdminUser).filter(AdminUser.email == clean_email).first()
            if admin_u:
                if clean_nickname:
                    admin_u.name = clean_nickname
                if clean_avatar:
                    admin_u.avatar = clean_avatar
                if clean_phone:
                    admin_u.phone = clean_phone
                db.commit()
    except Exception:
        pass

    # 4. Sinkronkan juga riwayat booking in-memory agar nama dokter melihat nama baru
    if clean_nickname:
        for b in _inmemory_bookings:
            if b.get("user_uuid") == user_uuid or b.get("user_id") == resolved_user_id:
                b["patient_name"] = clean_nickname

    current = _user_profile_meta.get(user_uuid, {})
    return UserProfileResponse(
        status="success",
        user_id=resolved_user_id,
        device_uuid=user_uuid,
        nickname=current.get("nickname") or clean_nickname or "Sobat MindPal",
        avatar=current.get("avatar") or clean_avatar,
        bio=current.get("bio") or clean_bio,
        email=current.get("email") or clean_email,
        phone=current.get("phone") or clean_phone,
        message="Profil berhasil diperbarui dan tersimpan di database."
    )


@router.get("/{user_uuid}/profile", response_model=UserProfileResponse)
def get_user_profile(user_uuid: str):
    """Ambil data profil pengguna terbaru dari database."""
    user_uuid = user_uuid.strip()
    nickname = None
    avatar = None
    bio = None
    email = None
    phone = None
    resolved_user_id = user_uuid

    # 1. Dari cache memory
    cached = _user_profile_meta.get(user_uuid, {})
    if cached:
        nickname = cached.get("nickname")
        avatar = cached.get("avatar")
        bio = cached.get("bio")
        email = cached.get("email")
        phone = cached.get("phone")

    # 2. Dari Supabase DB
    sp = get_supabase()
    if sp:
        try:
            if _is_valid_uuid(user_uuid):
                res = sp.table("users").select("*").or_(
                    f"id.eq.{user_uuid},device_uuid.eq.{user_uuid}"
                ).execute()
            else:
                res = sp.table("users").select("*").eq(
                    "device_uuid", user_uuid
                ).execute()
            if res.data:
                row = res.data[0]
                resolved_user_id = row.get("id")
                if row.get("nickname"):
                    nickname = row.get("nickname")
                if row.get("avatar"):
                    avatar = row.get("avatar")
                if row.get("bio"):
                    bio = row.get("bio")

            # Cek Auth metadata
            try:
                auth_users = sp.auth.admin.list_users()
                matched = [u for u in auth_users if u.id == resolved_user_id]
                if matched:
                    meta = matched[0].user_metadata or {}
                    if not nickname and meta.get("nickname"):
                        nickname = meta.get("nickname")
                    if not avatar and meta.get("avatar"):
                        avatar = meta.get("avatar")
                    if not bio and meta.get("bio"):
                        bio = meta.get("bio")
                    if not email and matched[0].email:
                        email = matched[0].email
            except Exception:
                pass
        except Exception as e:
            print(f"Supabase get user profile error: {e}")

    return UserProfileResponse(
        status="success",
        user_id=resolved_user_id,
        device_uuid=user_uuid,
        nickname=nickname or "Sobat MindPal",
        avatar=avatar,
        bio=bio,
        email=email,
        phone=phone
    )


@router.delete("/{user_uuid}/data")
def purge_user_data(user_uuid: str):
    """Hard delete seluruh data pengguna (FR-04 Panic Clear Data)."""
    sp = get_supabase()
    if sp:
        try:
            # ON DELETE CASCADE otomatis menghapus chat, mood_logs, dan bookings
            if _is_valid_uuid(user_uuid):
                sp.table("users").delete().or_(
                    f"device_uuid.eq.{user_uuid},id.eq.{user_uuid}"
                ).execute()
            else:
                sp.table("users").delete().eq("device_uuid", user_uuid).execute()
        except Exception as e:
            print(f"Supabase purge user failed: {e}")

    # Bersihkan in-memory juga
    global _inmemory_moods, _inmemory_bookings
    _inmemory_moods[:] = [m for m in _inmemory_moods if m.get("user_uuid") != user_uuid]
    _inmemory_bookings[:] = [b for b in _inmemory_bookings if b.get("user_uuid") != user_uuid]
    if user_uuid in _user_profile_meta:
        del _user_profile_meta[user_uuid]

    return {
        "status": "success",
        "message": f"Seluruh data user {user_uuid} telah dihapus permanen (hard delete)."
    }
