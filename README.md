# Havenly (AI Mental Health & Telekonseling Platform)

Aplikasi kesehatan mental holistik berbasis AI CBT (*Cognitive Behavioral Therapy*) dan layanan telekonseling 1-on-1 bersama psikolog serta psikiater terverifikasi.

---

## Arsitektur Monorepo

```
app_mobile_pesikolog/
├── backend/      ← FastAPI (Python 3.10+) Backend API, AI Gateway, Supabase & Midtrans
├── mobile/       ← Flutter (Dart) Mobile App (Pasien & Dokter) Android/iOS
└── adminpanel/   ← Next.js 15 (React 19 + Tailwind CSS) Dashboard Manajemen Admin
```

---

## 1. Backend (`backend/`)

FastAPI server melayani aplikasi mobile pasien, portal dokter, integrasi gateway AI, pembayaran Midtrans, dan API Admin Panel.

### Fitur Utama Backend:
- **AI Streaming SSE & Guardrail Krisis**: Respon AI streaming dengan interseptor regex pencegahan krisis (<10ms).
- **Integrasi Supabase DB**: Penyimpanan data pengguna, katalog psikolog, riwayat booking, log mood harian, dan ulasan dokter.
- **Midtrans Payment Gateway**: Integrasi pembayaran Bank Transfer (BCA, BNI, BRI, Mandiri), GoPay, dan QRIS sandbox.
- **Konsultasi & Chat 1-on-1**: Ruang chat privat real-time antara pasien dan dokter.
- **Admin Panel API**: Manajemen dokter, verifikasi berkas STR, slider promo, laporan pelanggaran, serta audit log.
- **Upload File**: Upload foto profil/avatar pasien dan dokter secara aman.

### Menjalankan Backend:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Menjalankan server
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Seeding Data Dokter & Admin:

```bash
# Seed 5 akun dokter dummy (Supabase & Admin DB)
python3 seed_doctors.py
```

### Akun Login Bawaan:

| Peran | Email | Password | Keterangan |
|---|---|---|---|
| **Admin** | `admin@mindpal.id` | `admin123` | Login Dashboard Web Admin |
| **Dokter 1** | `nadia@mindpal.id` *(alias: `dokter@mindpal.id`)* | `password123` | dr. Nadia S., Sp.KJ (Psikiater Klinis) |
| **Dokter 2** | `dimas@mindpal.id` | `password123` | Dimas Pratama, M.Psi., Psikolog |
| **Dokter 3** | `sarah@mindpal.id` | `password123` | Sarah Amalia, M.Psi., Psikolog |
| **Dokter 4** | `budi.santoso@mindpal.id` | `password123` | Budi Santoso, M.Psi., Psikolog |
| **Dokter 5** | `farhan@mindpal.id` | `password123` | dr. Farhan Malik, Sp.KJ |

---

## 2. Mobile App (`mobile/`)

Aplikasi Flutter cross-platform untuk Pasien dan Tenaga Medis/Dokter dengan switch role otomatis berdasarkan otentikasi.

### Fitur Pasien:
- **Home**: Rekomendasi psikolog, latihan pernapasan (*Breathing Bubble*), teknik grounding 5-4-3-2-1, artikel edukasi.
- **AI Chat Companion**: Sesi konseling interaktif dengan AI CBT, deteksi kata kunci krisis & rujukan darurat.
- **Jurnal & Mood Tracker**: Pelacakan suasana hati harian tersinkronisasi ke cloud.
- **Katalog & Booking Konsultasi**: Filter spesialisasi, jadwal praktik, screening AI pra-sesi, dan checkout Midtrans.
- **Ruang Chat Dokter**: Chat 1-on-1 langsung dengan dokter spesialis pilihan.
- **Edit Profil**: Perbarui nama, bio, dan unggah foto profil langsung dari kamera/galeri yang tersimpan di cloud.

### Fitur Dokter:
- **Dashboard Dokter**: Ringkasan jadwal konsultasi, sesi aktif, dan pendapatan.
- **Jadwal & Booking Pasien**: Terima/konfirmasi booking, lihat catatan screening AI pasien, dan foto profil pasien.
- **Ruang Chat Pasien**: Chat real-time dengan pasien, kirim catatan medis, akhiri sesi konsultasi.
- **Kelola Profil Dokter**: Atur jadwal praktik hari & jam, ubah tarif konsultasi, dan foto profil.

### Menjalankan Mobile App:

```bash
cd mobile
flutter pub get
flutter run
```

*Catatan: Konfigurasi default `ApiService.baseUrl` adalah `http://10.0.2.2:8000` untuk Android Emulator, atau `http://localhost:8000` untuk iOS Simulator/Web.*

---

## 3. Web Admin Panel (`adminpanel/`)

Dashboard web modern Next.js 15 dengan autentikasi berbasis role untuk tim administrator.

### Fitur Admin Panel:
- **Dashboard Metrik**: Statistik pengguna, dokter terverifikasi, booking, dan revenue.
- **Manajemen Dokter**: Verifikasi akun dokter, periksa nomor STR, dokumen sertifikasi, aktivasi/suspend akun.
- **Manajemen Pengguna**: Pantau daftar pengguna terdaftar dan status akun.
- **Manajemen Slider & Banner**: Kelola banner promo aplikasi mobile.
- **Laporan & Keluhan**: Tangani aduan pelanggaran dari pengguna/dokter.

### Menjalankan Admin Panel:

```bash
cd adminpanel
npm install
npm run dev
```

Buka [http://localhost:3000](http://localhost:3000) lalu masuk dengan akun `admin@mindpal.id` / `admin123`.

---

## Pengujian (Testing)

```bash
# Test Guardrail Krisis Backend
python3 backend/test_safety.py

# Test Integrasi Admin API
python3 backend/test_admin_integration.py

# Analisa Kode Flutter
cd mobile && flutter analyze
```
