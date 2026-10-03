# AGENTS.md — MindPal

## Struktur Repo

Monorepo:

```
backend/     ← FastAPI (Python) terpadu: Mobile API + Admin Panel API
mobile/      ← Flutter (Dart) cross-platform Android/iOS client
adminpanel/  ← Next.js 15 (React 19) Dashboard Web Admin
```

## Backend (FastAPI)

### Struktur Modul `backend/app/`

```
backend/
├── app/
│   ├── api/routes/
│   │   ├── chat.py           ← SSE streaming chat & crisis guardrail
│   │   ├── mood.py           ← Log mood & sinkronisasi Supabase
│   │   ├── consultation.py   ← Katalog psikolog & booking sesi
│   │   └── user.py           ← Hard delete user (FR-04 Panic Clear)
│   ├── core/
│   │   ├── config.py         ← Env vars loader (.env)
│   │   ├── database.py       ← Supabase client initialization
│   │   └── prompts.py        ← CBT system prompt
│   ├── models/
│   │   └── schemas.py        ← Pydantic request/response models
│   ├── services/
│   │   ├── chat_service.py   ← 9router (OpenAI-compatible) streaming & mock fallback
│   │   └── safety_service.py ← Crisis regex interceptor (<10ms)
│   └── main.py               ← App factory & router registration
├── main.py                   ← Uvicorn entrypoint (`main:app`)
├── schema.sql                ← DDL skema Supabase PostgreSQL + seed data
├── test_safety.py            ← Unit test crisis regex
├── test_supabase.py          ← Integration test koneksi Supabase
├── test_ai_gateway.py        ← Integration test live AI streaming via 9router
└── .env                      ← Kredensial lokal (gitignored)
```

### Setup & Jalankan

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Menjalankan server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Test

```bash
python3 backend/test_safety.py       # Unit test regex guardrail (<1ms)
python3 backend/test_supabase.py     # Test koneksi cloud Supabase
python3 backend/test_ai_gateway.py   # Test live stream LLM via 9router
```

### Quirks Backend

- **AI Gateway**: Menggunakan client OpenAI-compatible terhubung ke 9router (`http://localhost:20128/v1`), model `ag/gemini-3.8-flash-high`.
- Jika `AI_GATEWAY_KEY` kosong di `.env`, otomatis memakai `generate_mock_stream()` (fallback dev aman).
- Jika `SUPABASE_URL` tidak aktif, otomatis fallback ke in-memory store.
- Endpoint chat SSE: `POST /api/chat/stream`.
- Endpoint konsultasi: `GET /api/consultation/psychologists` (alias `/api/psychologists` tersedia untuk backward compatibility).
- Endpoint booking: `POST /api/consultation/bookings` (alias `/api/bookings`).
- Panic wipe endpoint: `DELETE /api/user/{user_uuid}/data`.

## Mobile (Flutter)

### Setup & Jalankan

```bash
cd mobile
flutter pub get
flutter run
```

### Test & Analisa

```bash
cd mobile
flutter analyze          # Wajib 0 issues
flutter test             # Widget test
```

### Navigasi Tab (index 0–4)
- 0: `HomeScreen` — Beranda
- 1: `MoodScreen` — Jurnal & Mood (sync otomatis ke Supabase)
- 2: `ChatScreen` — MindPal AI (Floating gradient button tengah)
- 3: `ConsultationScreen` — Katalog & booking psikolog
- 4: `SettingsScreen` — Profil, PIN, Zero-KYC UUID, Panic delete
