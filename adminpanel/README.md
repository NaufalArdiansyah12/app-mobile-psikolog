# Havenly Admin Panel

Dashboard manajemen web resmi untuk platform **Havenly** dibangun menggunakan **Next.js 15 (App Router)**, **React 19**, dan **Tailwind CSS**.

---

## Fitur Utama

- **Otentikasi Admin**: Proteksi rute dengan JSON Web Token (JWT) dan cookie session.
- **Dashboard Metrik**: Ringkasan jumlah dokter, pasien aktif, sesi konsultasi, dan aktivitas terkini.
- **Manajemen & Verifikasi Dokter**:
  - Tinjau berkas dokter (STR, SIP, KTP, Ijazah).
  - Persetujuan (*approve*), penolakan (*reject*), dan penangguhan (*suspend*) dokter.
- **Manajemen Pengguna**: Kelola status aktif/nonaktif akun pasien.
- **Manajemen Banner Promo / Slider**: Tambah, ubah urutan, dan unggah gambar slider promosi aplikasi mobile.
- **Laporan Pelanggaran**: Monitor pengaduan dari sesi konsultasi.
- **Audit Log**: Jejak riwayat aktivitas seluruh administrator.

---

## Kredensial Login Bawaan

- **URL Login**: `http://localhost:3000/login`
- **Email**: `admin@mindpal.id`
- **Password**: `admin123`

---

## Menjalankan Server

1. Pastikan dependensi terpasang:
```bash
npm install
```

2. Jalankan development server:
```bash
npm run dev
```

Buka [http://localhost:3000](http://localhost:3000) di browser. Pastikan server Backend FastAPI (`http://localhost:8000`) sudah aktif.
