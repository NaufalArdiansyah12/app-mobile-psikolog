from pathlib import Path
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.database import get_supabase
from app.api.routes import chat, mood, consultation, user, auth, doctor
from app.admin.core.database import init_admin_db
from app.admin.core.config import admin_settings
from app.admin.api import (
    auth as admin_auth,
    dashboard as admin_dashboard,
    doctors as admin_doctors,
    users as admin_users,
    sliders as admin_sliders,
    reports as admin_reports,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Inisialisasi DB Admin saat startup
    try:
        init_admin_db()
        print("Admin database tables initialized.")
    except Exception as e:
        print(f"Admin database init warning: {e}")
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title="MindPal Backend & Admin API",
        version="2.0.0",
        description="Unified Clean Architecture Backend: MindPal Mobile + Admin Panel",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Mount static files upload (slider / dokumen)
    upload_dir = Path(admin_settings.UPLOAD_DIR)
    upload_dir.mkdir(parents=True, exist_ok=True)
    app.mount("/uploads", StaticFiles(directory=str(upload_dir)), name="uploads")

    # Health check
    @app.get("/health", tags=["Health"])
    @app.get("/api/health", tags=["Health"])
    def health_check():
        sp = get_supabase()
        return {
            "status": "healthy",
            "supabase_connected": sp is not None,
            "version": "2.0.0",
        }

    # Register Mobile App Routers
    app.include_router(auth.router, prefix="/api")
    app.include_router(chat.router, prefix="/api")
    app.include_router(mood.router, prefix="/api")
    app.include_router(consultation.router, prefix="/api")
    app.include_router(doctor.router, prefix="/api")
    app.include_router(user.router, prefix="/api")

    # Register Admin Panel Routers (prefix /api/admin/...)
    app.include_router(admin_auth.router, prefix="/api/admin")
    app.include_router(admin_dashboard.router, prefix="/api/admin")
    app.include_router(admin_doctors.router, prefix="/api/admin")
    app.include_router(admin_users.router, prefix="/api/admin")
    app.include_router(admin_sliders.router, prefix="/api/admin")
    app.include_router(admin_reports.router, prefix="/api/admin")

    # Backward-compatibility alias routes untuk frontend yang sudah ada
    @app.get("/api/psychologists", tags=["Compatibility"])
    def get_psychologists_alias():
        return consultation.get_psychologists()

    @app.post("/api/bookings", tags=["Compatibility"])
    def create_booking_alias(booking: consultation.BookingRequest):
        return consultation.create_booking(booking)

    return app


app = create_app()
