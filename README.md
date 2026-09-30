# MindPal (AI Mental Health & Emotional First-Aid Companion)

Implementasi MVP sesuai PRD Baseline Release v1.3.

## Struktur Direktori
- `backend/`: FastAPI + Pydantic + Google Gemini API + Safety Guardrail Interceptor (<10ms).
- `mobile/`: Flutter client (Chat AI SSE streaming, Action Chips, Breathing Bubble, Mood Tracker offline, Zero-KYC, Crisis Overlay, Panic Hard Delete).

---

## 1. Menjalankan Backend (FastAPI)

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Opsional: Pasang Google Gemini API Key jika ingin live LLM
export GEMINI_API_KEY="AIzaSy..."

# Jalankan server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Jika `GEMINI_API_KEY` tidak diisi, backend otomatis menggunakan internal mock streaming generator yang aman untuk testing dev.

### Menjalankan Unit Test Guardrail
```bash
python3 backend/test_safety.py
```

---

## 2. Menjalankan Frontend (Flutter Mobile)

Pastikan Flutter SDK terpasang di sistem (`flutter --version`).

```bash
cd mobile
flutter pub get
flutter run
```

Catatan: Untuk pengujian di Android Emulator, endpoint `ApiService.baseUrl` mengarah ke `http://10.0.2.2:8000`. Jika menggunakan perangkat fisik atau web, sesuaikan dengan IP LAN komputer host.
