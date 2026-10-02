import uuid
from typing import Dict
from fastapi import APIRouter, HTTPException, status
from app.core.database import get_supabase
from app.core.config import SUPABASE_URL, SUPABASE_KEY
from app.models.schemas import RegisterRequest, LoginRequest, AuthResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])

# In-memory store fallback jika Supabase tidak aktif
_inmemory_users: Dict[str, dict] = {
    "dokter@mindpal.id": {
        "id": "c8d37edf-2ffd-4f19-b9dd-10033fbac9c4",
        "email": "dokter@mindpal.id",
        "password": "password123",
        "nickname": "dr. Nadia S., Sp.KJ",
        "role": "doctor",
        "psychologist_id": "psy_1"
    }
}

def _create_temp_auth_client():
    """Client terpisah agar tidak menimpa service_role token di client utama."""
    if SUPABASE_URL and SUPABASE_KEY and not SUPABASE_URL.startswith("https://your-project"):
        try:
            from supabase import create_client
            return create_client(SUPABASE_URL, SUPABASE_KEY)
        except Exception:
            return None
    return None

@router.post("/register", response_model=AuthResponse)
def register(req: RegisterRequest):
    email = req.email.strip().lower()
    password = req.password.strip()
    name = req.name.strip()

    if not email or "@" not in email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Format email tidak valid."
        )

    if len(password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Kata sandi minimal 6 karakter."
        )

    if not name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nama tidak boleh kosong."
        )

    admin_sp = get_supabase()

    if admin_sp:
        try:
            # 1. Buat user via Supabase Auth Admin (auto-confirm email)
            role = req.role if req.role in ("user", "doctor") else "user"
            auth_user = admin_sp.auth.admin.create_user({
                "email": email,
                "password": password,
                "email_confirm": True,
                "user_metadata": {"nickname": name, "role": role}
            })
            user_id = auth_user.user.id

            # 2. Simpan profil ke tabel public.users
            device_uuid = req.device_uuid if req.device_uuid else user_id
            try:
                admin_sp.table("users").upsert({
                    "id": user_id,
                    "device_uuid": device_uuid,
                    "nickname": name,
                    "role": role
                }).execute()
            except Exception as e:
                try:
                    admin_sp.table("users").upsert({
                        "id": user_id,
                        "device_uuid": device_uuid,
                        "nickname": name
                    }).execute()
                except Exception as inner_e:
                    print(f"Warning: Failed to insert public.users row: {inner_e}")

            # 3. Dapatkan session token via login
            token = None
            user_client = _create_temp_auth_client()
            if user_client:
                try:
                    login_res = user_client.auth.sign_in_with_password({
                        "email": email,
                        "password": password
                    })
                    if login_res.session:
                        token = login_res.session.access_token
                except Exception as e:
                    print(f"Login token retrieval warning: {e}")

            return AuthResponse(
                status="success",
                user_id=user_id,
                email=email,
                nickname=name,
                role=role,
                token=token,
                message="Pendaftaran berhasil."
            )
        except Exception as e:
            err_msg = str(e)
            if "already registered" in err_msg.lower() or "unique" in err_msg.lower():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email sudah terdaftar. Silakan masuk dengan akunmu."
                )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Gagal mendaftar: {err_msg}"
            )

    # Fallback in-memory
    if email in _inmemory_users:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email sudah terdaftar. Silakan masuk."
        )

    user_id = str(uuid.uuid4())
    role = req.role if req.role in ("user", "doctor") else "user"
    _inmemory_users[email] = {
        "id": user_id,
        "email": email,
        "password": password,
        "nickname": name,
        "role": role,
        "psychologist_id": "psy_1" if role == "doctor" else None
    }

    return AuthResponse(
        status="success",
        user_id=user_id,
        email=email,
        nickname=name,
        role=role,
        psychologist_id="psy_1" if role == "doctor" else None,
        token=f"mock_token_{user_id}",
        message="Pendaftaran berhasil (mode dev)."
    )

@router.post("/login", response_model=AuthResponse)
def login(req: LoginRequest):
    email = req.email.strip().lower()
    password = req.password.strip()

    if not email or not password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email dan kata sandi wajib diisi."
        )

    admin_sp = get_supabase()

    if admin_sp:
        user_client = _create_temp_auth_client()
        if user_client:
            try:
                login_res = user_client.auth.sign_in_with_password({
                    "email": email,
                    "password": password
                })
                if not login_res.user:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Email atau kata sandi salah."
                    )

                user_id = login_res.user.id
                user_meta = login_res.user.user_metadata or {}
                nickname = user_meta.get("nickname")
                role = user_meta.get("role", "user")

                # Coba ambil role & nickname dari public.users jika ada
                if admin_sp:
                    try:
                        u = admin_sp.table("users").select("*").eq("id", user_id).execute()
                        if u.data:
                            user_row = u.data[0]
                            if not nickname and user_row.get("nickname"):
                                nickname = user_row.get("nickname")
                            if user_row.get("role"):
                                role = user_row.get("role")
                    except Exception:
                        pass

                if not nickname:
                    nickname = email.split("@")[0]

                # Cari psychologist_id jika peran dokter
                psychologist_id = None
                if role == "doctor":
                    try:
                        p = admin_sp.table("psychologists").select("id").limit(1).execute()
                        if p.data:
                            psychologist_id = p.data[0].get("id")
                    except Exception:
                        psychologist_id = "psy_1"

                token = login_res.session.access_token if login_res.session else None

                return AuthResponse(
                    status="success",
                    user_id=user_id,
                    email=email,
                    nickname=nickname,
                    role=role,
                    token=token,
                    psychologist_id=psychologist_id,
                    message="Berhasil masuk."
                )
            except HTTPException:
                raise
            except Exception as e:
                err_msg = str(e)
                if "invalid login credentials" in err_msg.lower() or "invalid_grant" in err_msg.lower():
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Email atau kata sandi tidak cocok."
                    )
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Gagal masuk. Periksa kembali email dan kata sandi Anda."
                )

    # Fallback in-memory
    user_data = _inmemory_users.get(email)
    if not user_data or user_data["password"] != password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email atau kata sandi salah."
        )

    return AuthResponse(
        status="success",
        user_id=user_data["id"],
        email=email,
        nickname=user_data["nickname"],
        role=user_data.get("role", "user"),
        psychologist_id=user_data.get("psychologist_id"),
        token=f"mock_token_{user_data['id']}",
        message="Berhasil masuk (mode dev)."
    )
