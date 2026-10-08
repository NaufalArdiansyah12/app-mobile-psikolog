"""Script untuk membuat 5 data dummy dokter beserta akun login dokter di Supabase & Admin."""

import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__))))

from app.core.database import get_supabase
from app.admin.core.database import SessionLocal, init_admin_db
from app.admin.models.user import User as AdminUser
from app.admin.models.doctor import Doctor as AdminDoctor
from app.admin.core.security import hash_password

DOCTORS = [
    {
        "email": "nadia@mindpal.id",
        "alias_email": "dokter@mindpal.id",
        "password": "password123",
        "name": "dr. Nadia S., Sp.KJ",
        "role": "Psikiater Klinis",
        "experience": "8 tahun",
        "rating": 4.9,
        "price": "Rp 250.000",
        "category": "Trauma & Depresi",
        "hospital": "RS Mitra Sehat Jakarta",
        "avatar": "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300",
        "bio": "Spesialis dalam farmakoterapi dan psikoterapi suportif untuk kasus gangguan suasana hati (mood disorder), insomnia berkepanjangan, dan pemulihan trauma psikologis.",
        "education": "Spesialis Kedokteran Jiwa - FK Universitas Indonesia",
        "str_number": "STR: 31.1.2.100.3.19.112233",
        "available_days": ["Senin", "Selasa", "Rabu", "Kamis", "Jumat"],
        "available_slots": ["09:00 - 10:00", "13:00 - 14:00", "16:00 - 17:00", "19:00 - 20:00"],
        "phone": "081298765401",
    },
    {
        "email": "dimas@mindpal.id",
        "password": "password123",
        "name": "Dimas Pratama, M.Psi., Psikolog",
        "role": "Psikolog Klinis Dewasa",
        "experience": "5 tahun",
        "rating": 4.8,
        "price": "Rp 180.000",
        "category": "Karir & Burnout",
        "hospital": "Praktek Mandiri Harmoni Jiwa",
        "avatar": "https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300",
        "bio": "Fokus mendampingi profesional muda dalam manajemen stres kerja, burnout eksekutif, quarter-life crisis, serta restrukturisasi kognitif dengan metode CBT.",
        "education": "Magister Profesi Psikologi Klinis Dewasa - Universitas Gadjah Mada",
        "str_number": "STR: 33.2.1.200.4.21.445566",
        "available_days": ["Senin", "Rabu", "Kamis", "Sabtu"],
        "available_slots": ["10:00 - 11:00", "14:00 - 15:00", "16:30 - 17:30", "20:00 - 21:00"],
        "phone": "081298765402",
    },
    {
        "email": "sarah@mindpal.id",
        "password": "password123",
        "name": "Sarah Amalia, M.Psi., Psikolog",
        "role": "Psikolog Hubungan & Keluarga",
        "experience": "6 tahun",
        "rating": 4.9,
        "price": "Rp 200.000",
        "category": "Hubungan & Asmara",
        "hospital": "Klinik Tumbuh Bahagia Bandung",
        "avatar": "https://images.unsplash.com/photo-1594824813583-05b184ef47e6?auto=format&fit=crop&q=80&w=300",
        "bio": "Membantu individu dan pasangan membangun komunikasi interpersonal yang sehat, menyelesaikan konflik hubungan, regulasi emosi pasca perpisahan, serta konseling pranikah.",
        "education": "Magister Psikologi Profesi Klinis - Universitas Padjadjaran",
        "str_number": "STR: 32.1.3.150.2.20.778899",
        "available_days": ["Selasa", "Rabu", "Jumat", "Sabtu"],
        "available_slots": ["09:00 - 10:00", "11:00 - 12:00", "15:00 - 16:00", "18:30 - 19:30"],
        "phone": "081298765403",
    },
    {
        "email": "budi.santoso@mindpal.id",
        "password": "password123",
        "name": "Budi Santoso, M.Psi., Psikolog",
        "role": "Spesialis Regulasi Emosi & CBT",
        "experience": "7 tahun",
        "rating": 4.7,
        "price": "Rp 175.000",
        "category": "Kecemasan & Stres",
        "hospital": "Layanan Telekonseling Sejahtera",
        "avatar": "https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&q=80&w=300",
        "bio": "Pakar Cognitive Behavioral Therapy untuk Generalized Anxiety Disorder (GAD), kecemasan sosial, serangan panik, serta latihan regulasi emosi berbasis mindfulness.",
        "education": "Magister Psikologi Profesi - Universitas Airlangga",
        "str_number": "STR: 35.1.2.300.5.18.990011",
        "available_days": ["Senin", "Selasa", "Kamis", "Jumat"],
        "available_slots": ["08:30 - 09:30", "13:00 - 14:00", "15:30 - 16:30", "19:00 - 20:00"],
        "phone": "081298765404",
    },
    {
        "email": "farhan@mindpal.id",
        "password": "password123",
        "name": "dr. Farhan Malik, Sp.KJ",
        "role": "Psikiater Adiksi & Mood Disorder",
        "experience": "9 tahun",
        "rating": 5.0,
        "price": "Rp 275.000",
        "category": "Adiksi & Kesehatan Jiwa",
        "hospital": "RS Jiwa Dharma Graha Jakarta",
        "avatar": "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=300",
        "bio": "Memberikan pendampingan psikiatris komprehensif untuk adiksi perilaku dan zat kimia, gangguan afektif bipolar, psikofarmakologi, serta konsultasi kesehatan mental keluarga.",
        "education": "Spesialis Ilmu Kedokteran Jiwa - FK Universitas Sebelas Maret",
        "str_number": "STR: 33.1.5.400.1.16.554433",
        "available_days": ["Selasa", "Kamis", "Jumat", "Sabtu"],
        "available_slots": ["09:00 - 10:00", "14:00 - 15:00", "17:00 - 18:00", "20:00 - 21:00"],
        "phone": "081298765405",
    },
]


def seed():
    sp = get_supabase()
    if not sp:
        print("ERROR: Supabase client not initialized")
        return

    print("=== SEEDING 5 DOKTER KE SUPABASE & ADMIN PANEL ===")

    # 1. Bersihkan sisa data dokter lama di psychologists (jika ada)
    try:
        sp.table("psychologists").delete().neq("name", "").execute()
        print("Tabel psychologists dibersihkan.")
    except Exception as e:
        print(f"Catatan pembersihan psychologists: {e}")

    # Ambil list auth users
    existing_auth_users = {u.email: u for u in sp.auth.admin.list_users()}

    results = []

    for doc in DOCTORS:
        # A. Buat atau update di Supabase Auth
        email = doc["email"]
        password = doc["password"]
        name = doc["name"]
        
        auth_user_id = None
        if email in existing_auth_users:
            auth_user_id = existing_auth_users[email].id
            print(f"Auth user {email} sudah ada ({auth_user_id}), memperbarui password & metadata...")
            sp.auth.admin.update_user_by_id(
                auth_user_id,
                {
                    "password": password,
                    "user_metadata": {"nickname": name, "role": "doctor"},
                },
            )
        else:
            created = sp.auth.admin.create_user(
                {
                    "email": email,
                    "password": password,
                    "email_confirm": True,
                    "user_metadata": {"nickname": name, "role": "doctor"},
                }
            )
            auth_user_id = created.user.id
            print(f"Dibuat Auth user baru: {email} -> {auth_user_id}")

        # B. Upsert ke tabel public.users
        try:
            sp.table("users").upsert(
                {
                    "id": auth_user_id,
                    "device_uuid": auth_user_id,
                    "nickname": name,
                }
            ).execute()
            print(f"Berhasil upsert ke public.users: {name}")
        except Exception as e:
            print(f"Gagal upsert public.users untuk {name}: {e}")

        # C. Insert ke tabel public.psychologists
        psy_data = {
            "name": name,
            "role": doc["role"],
            "experience": doc["experience"],
            "rating": doc["rating"],
            "price": doc["price"],
            "category": doc["category"],
            "hospital": doc["hospital"],
            "is_available": True,
            "avatar": doc["avatar"],
            "bio": doc["bio"],
            "education": doc["education"],
            "str_number": doc["str_number"],
            "available_days": doc["available_days"],
            "available_slots": doc["available_slots"],
        }
        
        psy_res = sp.table("psychologists").insert(psy_data).execute()
        psychologist_id = None
        if psy_res.data:
            psychologist_id = psy_res.data[0]["id"]
            print(f"Berhasil insert psychologists: {name} (ID: {psychologist_id})")

            # Update Supabase Auth metadata dengan psychologist_id
            try:
                sp.auth.admin.update_user_by_id(
                    auth_user_id,
                    {
                        "user_metadata": {
                            "nickname": name,
                            "role": "doctor",
                            "psychologist_id": psychologist_id,
                        }
                    },
                )
            except Exception as e:
                print(f"Update auth metadata psychologist_id error: {e}")

        # D. Jika ada alias email (seperti dokter@mindpal.id untuk dr. Nadia)
        alias_email = doc.get("alias_email")
        if alias_email:
            alias_user_id = None
            if alias_email in existing_auth_users:
                alias_user_id = existing_auth_users[alias_email].id
                sp.auth.admin.update_user_by_id(
                    alias_user_id,
                    {
                        "password": password,
                        "user_metadata": {
                            "nickname": name,
                            "role": "doctor",
                            "psychologist_id": psychologist_id,
                        },
                    },
                )
            else:
                alias_created = sp.auth.admin.create_user(
                    {
                        "email": alias_email,
                        "password": password,
                        "email_confirm": True,
                        "user_metadata": {
                            "nickname": name,
                            "role": "doctor",
                            "psychologist_id": psychologist_id,
                        },
                    }
                )
                alias_user_id = alias_created.user.id
            try:
                sp.table("users").upsert(
                    {
                        "id": alias_user_id,
                        "device_uuid": alias_user_id,
                        "nickname": name,
                    }
                ).execute()
                print(f"Alias login {alias_email} berhasil didaftarkan.")
            except Exception:
                pass

        results.append({
            "name": name,
            "email": email,
            "password": password,
            "role": doc["role"],
            "category": doc["category"],
            "psychologist_id": psychologist_id,
            "auth_user_id": auth_user_id,
        })

    # 2. Sinkronisasi juga ke Admin Database (SQLite admin.db) jika ada
    try:
        init_admin_db()
        with SessionLocal() as db:
            # Pastikan Akun Admin aktif
            admin_user = db.query(AdminUser).filter(AdminUser.email == "admin@mindpal.id").first()
            if not admin_user:
                admin_user = AdminUser(
                    name="Super Administrator",
                    email="admin@mindpal.id",
                    password=hash_password("admin123"),
                    role="admin",
                    status="active",
                    phone="081234567890",
                )
                db.add(admin_user)
            else:
                admin_user.password = hash_password("admin123")
                admin_user.status = "active"
                admin_user.role = "admin"

            for doc in DOCTORS:
                doc_user = db.query(AdminUser).filter(AdminUser.email == doc["email"]).first()
                if not doc_user:
                    doc_user = AdminUser(
                        name=doc["name"],
                        email=doc["email"],
                        password=hash_password(doc["password"]),
                        role="doctor",
                        status="active",
                        phone=doc["phone"],
                    )
                    db.add(doc_user)
                    db.flush()

                    admin_doc = AdminDoctor(
                        user_id=doc_user.id,
                        specialization=doc["role"],
                        license_number=doc["str_number"],
                        education=doc["education"],
                        experience=doc["experience"],
                        bio=doc["bio"],
                        verification_status="approved",
                        is_active=True,
                    )
                    db.add(admin_doc)
            db.commit()
            print("Sinkronisasi 5 dokter dan Admin User ke Admin Database berhasil.")
    except Exception as e:
        print(f"Catatan admin DB sync: {e}")

    print("\n================ DATA DUMMY 5 DOKTER BERHASIL DIBUAT ================")
    for i, r in enumerate(results, 1):
        print(f"{i}. {r['name']}")
        print(f"   Email: {r['email']}")
        print(f"   Password: {r['password']}")
        print(f"   Role: {r['role']}")
        print(f"   Kategori: {r['category']}")
        print(f"   Psychologist ID: {r['psychologist_id']}")
        print(f"   User ID: {r['auth_user_id']}")
        print("-" * 60)


if __name__ == "__main__":
    seed()
