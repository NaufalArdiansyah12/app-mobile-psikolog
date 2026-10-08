# Havenly Mobile Client

Aplikasi mobile Flutter cross-platform (Android & iOS) untuk **Havenly** — platform kesehatan mental holistik, konseling AI CBT, dan telekonseling 1-on-1 dengan dokter & psikolog.

---

## Arsitektur Fitur

1. **Role Pasien (Sobat Havenly)**:
   - **Beranda (HomeScreen)**: Latihan pernapasan interaktif (*Breathing Bubble*), teknik grounding 5-4-3-2-1, artikel rekomendasi, katalog dokter terpopuler.
   - **Jurnal & Mood (MoodScreen)**: Catatan harian emosi, pemilihan pemicu (*triggers*), statistik grafik suasana hati yang tersinkron otomatis ke Supabase.
   - **Havenly AI (ChatScreen)**: Konseling chat interaktif berbasis Cognitive Behavioral Therapy (CBT) dengan streaming real-time & interseptor darurat krisis.
   - **Telekonsultasi (ConsultationScreen)**: Pemilihan dokter/psikolog spesialis, screening kuesioner awal AI, integrasi pembayaran Midtrans Sandbox.
   - **Chat Dokter**: Konsultasi chat privat 1-on-1 dengan riwayat tersimpan permanen.
   - **Profil Pengguna (SettingsScreen)**: Ganti nama, bio, dan upload foto profil/avatar langsung ke server cloud.

2. **Role Dokter / Tenaga Ahli**:
   - **Portal Dokter (DoctorMainScreen)**: Beralih antarmuka otomatis saat login sebagai akun dokter.
   - **Daftar Booking & Pasien**: Manajemen jadwal konsultasi, persetujuan booking, serta peninjauan hasil screening AI pra-sesi pasien.
   - **Chat Pasien**: Komunikasi langsung dengan pasien dan fitur penyelesaian sesi.
   - **Pengaturan Praktik**: Atur ketersediaan hari praktik, slot jam sesi, tarif konsultasi, STR, dan profil tenaga medis.

---

## Menjalankan Aplikasi

```bash
flutter pub get
flutter run
```

### Konfigurasi Endpoint:
Konfigurasi URL backend berada pada file `lib/services/api_service.dart`:
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator / Desktop Web: `http://localhost:8000`
- Perangkat Fisik (HP): Gunakan IP LAN komputer host (contoh: `http://192.168.1.xxx:8000`)

---

## Analisa & Pengujian

```bash
flutter analyze
flutter test
```
