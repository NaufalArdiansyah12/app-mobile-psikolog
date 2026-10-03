-- =====================================================================
-- ADMIN PANEL SCHEMA UNTUK SUPABASE (POSTGRESQL)
-- =====================================================================

-- 1. Tabel users (khusus akun admin & staf jika terpisah dari tabel users mobile)
--    atau untuk sinkronisasi akun dengan email/password hash bcrypt
create table if not exists admin_users (
    id serial primary key,
    name varchar(120) not null,
    email varchar(160) not null unique,
    password varchar(255) not null,
    phone varchar(30) default null,
    role varchar(20) not null default 'admin', -- admin | doctor | staff
    status varchar(20) not null default 'active', -- active | inactive | suspended
    avatar varchar(255) default null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_admin_users_role on admin_users(role);
create index if not exists idx_admin_users_email on admin_users(email);

-- 2. Tabel Sliders / Banner Promo
create table if not exists sliders (
    id serial primary key,
    title varchar(150) not null,
    description varchar(500) default null,
    image varchar(255) not null,
    link varchar(255) default null,
    sort_order integer not null default 0,
    status varchar(20) not null default 'active', -- active | inactive
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_sliders_status on sliders(status);
create index if not exists idx_sliders_sort on sliders(sort_order);

-- 3. Tabel Report Categories
create table if not exists report_categories (
    id serial primary key,
    name varchar(100) not null unique,
    description varchar(255) default null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Seed kategori default
insert into report_categories (name, description) values
('Pelanggaran Etika', 'Tindakan atau ucapan tidak pantas saat sesi konsultasi'),
('Keterlambatan/Tidak Hadir', 'Dokter tidak hadir sesuai jadwal tanpa konfirmasi'),
('Masalah Teknis', 'Gangguan koneksi berulang dari pihak dokter'),
('Lainnya', 'Laporan umum lainnya')
on conflict (name) do nothing;

-- 4. Tabel Doctors (verifikasi oleh admin)
create table if not exists admin_doctors (
    id serial primary key,
    user_id integer references admin_users(id) on delete cascade,
    psychologist_id uuid references psychologists(id) on delete set null,
    name varchar(120) not null,
    email varchar(160) default null,
    phone varchar(30) default null,
    avatar varchar(255) default null,
    specialization varchar(120) default null,
    license_number varchar(80) default null,
    education varchar(255) default null,
    experience varchar(255) default null,
    bio text default null,
    verification_status varchar(20) not null default 'pending', -- pending | approved | rejected
    rejection_reason text default null,
    verified_at timestamp with time zone default null,
    is_active boolean not null default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_admin_doctors_status on admin_doctors(verification_status);

-- 5. Tabel Doctor Documents
create table if not exists doctor_documents (
    id serial primary key,
    doctor_id integer references admin_doctors(id) on delete cascade not null,
    document_type varchar(30) not null default 'lainnya', -- str | sip | ijazah | sertifikat | lainnya
    document_path varchar(255) not null,
    verification_status varchar(20) not null default 'pending',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 6. Tabel Reports
create table if not exists reports (
    id serial primary key,
    user_id integer default null,
    doctor_id integer references admin_doctors(id) on delete cascade not null,
    category_id integer references report_categories(id) on delete set null,
    description text not null,
    evidence varchar(255) default null,
    status varchar(20) not null default 'pending', -- pending | reviewing | resolved | rejected
    admin_note text default null,
    resolved_at timestamp with time zone default null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_reports_status on reports(status);

-- 7. Tabel Admin Activity Logs
create table if not exists admin_activity_logs (
    id serial primary key,
    admin_id integer references admin_users(id) on delete set null,
    action varchar(60) not null,
    target_type varchar(40) default null,
    target_id integer default null,
    description varchar(255) default null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_admin_logs_action on admin_activity_logs(action);
create index if not exists idx_admin_logs_created on admin_activity_logs(created_at);
