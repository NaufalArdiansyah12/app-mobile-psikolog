from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.database import get_supabase
from app.api.routes import chat, mood, consultation, user, auth, doctor

def create_app() -> FastAPI:
    app = FastAPI(
        title="MindPal Backend API",
        version="2.0.0",
        description="Clean Architecture Backend: AI Companion, Supabase DB & Safety Guardrail"
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Health check
    @app.get("/health", tags=["Health"])
    def health_check():
        sp = get_supabase()
        return {
            "status": "healthy",
            "supabase_connected": sp is not None,
            "version": "2.0.0"
        }

    # Register Routers
    app.include_router(auth.router, prefix="/api")
    app.include_router(chat.router, prefix="/api")
    app.include_router(mood.router, prefix="/api")
    app.include_router(consultation.router, prefix="/api")
    app.include_router(doctor.router, prefix="/api")
    app.include_router(user.router, prefix="/api")

    # Backward-compatibility alias routes untuk frontend yang sudah ada
    @app.get("/api/psychologists", tags=["Compatibility"])
    def get_psychologists_alias():
        return consultation.get_psychologists()

    @app.post("/api/bookings", tags=["Compatibility"])
    def create_booking_alias(booking: consultation.BookingRequest):
        return consultation.create_booking(booking)

    return app

app = create_app()
