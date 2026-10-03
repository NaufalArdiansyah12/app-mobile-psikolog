"""Koneksi database SQLAlchemy untuk modul Admin."""

from typing import Generator
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.admin.core.config import admin_settings

# Opsi engine disesuaikan dengan tipe database
engine_kwargs = {"pool_pre_ping": True, "future": True}
if admin_settings.DATABASE_URL.startswith("sqlite"):
    engine_kwargs["connect_args"] = {"check_same_thread": False}
else:
    engine_kwargs["pool_recycle"] = 3600

engine = create_engine(admin_settings.DATABASE_URL, **engine_kwargs)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """Base class deklaratif untuk seluruh model ORM Admin."""
    pass


def get_admin_db() -> Generator[Session, None, None]:
    """Dependency FastAPI: menyediakan database session per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_admin_db():
    """Inisialisasi tabel dan seed akun admin default jika belum ada."""
    import app.admin.models.user  # noqa: F401
    import app.admin.models.doctor  # noqa: F401
    import app.admin.models.doctor_document  # noqa: F401
    import app.admin.models.slider  # noqa: F401
    import app.admin.models.report  # noqa: F401
    import app.admin.models.admin_log  # noqa: F401

    Base.metadata.create_all(bind=engine)
    _seed_default_data()


def _seed_default_data():
    from app.admin.models.user import User
    from app.admin.models.doctor import Doctor
    from app.admin.models.report import ReportCategory
    from app.admin.models.slider import Slider
    from app.admin.core.security import hash_password

    with SessionLocal() as db:
        # 1. Akun Admin Default
        admin_user = db.query(User).filter(User.email == "admin@mindpal.id").first()
        if not admin_user:
            admin_user = User(
                name="Super Administrator",
                email="admin@mindpal.id",
                password=hash_password("admin123"),
                role="admin",
                status="active",
                phone="081234567890",
            )
            db.add(admin_user)
            db.commit()
            print("Default admin created: admin@mindpal.id / admin123")

        # 2. Akun Dokter Default jika belum ada
        doctor_user = db.query(User).filter(User.email == "dokter@mindpal.id").first()
        if not doctor_user:
            doctor_user = User(
                name="dr. Nadia S., Sp.KJ",
                email="dokter@mindpal.id",
                password=hash_password("password123"),
                role="doctor",
                status="active",
                phone="081298765432",
            )
            db.add(doctor_user)
            db.flush()

            doctor_profile = Doctor(
                user_id=doctor_user.id,
                specialization="Psikiater Klinis",
                license_number="STR-2024-SPKJ-001",
                education="Spesialis Kedokteran Jiwa UI",
                experience="8 tahun",
                bio="Berpengalaman menangani trauma, depresi, kecemasan, dan gangguan mood.",
                verification_status="approved",
                is_active=True,
            )
            db.add(doctor_profile)
            db.commit()

        # 3. Kategori Laporan Default
        categories = [
            ("Pelanggaran Etika", "Tindakan atau ucapan tidak pantas saat sesi konsultasi"),
            ("Keterlambatan/Tidak Hadir", "Dokter tidak hadir sesuai jadwal tanpa konfirmasi"),
            ("Masalah Teknis", "Gangguan koneksi berulang dari pihak dokter"),
            ("Lainnya", "Laporan umum lainnya"),
        ]
        for cat_name, cat_desc in categories:
            exists = db.query(ReportCategory).filter(ReportCategory.name == cat_name).first()
            if not exists:
                db.add(ReportCategory(name=cat_name, description=cat_desc))
        db.commit()

        # 4. Slider Default jika kosong
        if db.query(Slider).count() == 0:
            db.add(
                Slider(
                    title="Konsultasi Kesehatan Mental Jadi Lebih Nyaman",
                    description="Temukan psikolog & psikiater terpercaya untuk mendengarkan ceritamu.",
                    image="/uploads/sliders/default-banner.jpg",
                    link="",
                    sort_order=1,
                    status="active",
                )
            )
            db.commit()
