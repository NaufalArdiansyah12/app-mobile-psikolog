-- Skema Database MindPal (Supabase / PostgreSQL)

-- 1. Ekstensi
create extension if not exists vector;
create extension if not exists "uuid-ossp";

-- 2. Tabel Pengguna (Zero-KYC)
create table if not exists users (
    id uuid primary key default uuid_generate_v4(),
    device_uuid text unique not null,
    nickname text default 'Sobat MindPal',
    role text default 'user' check (role in ('user', 'doctor')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 3. Tabel Sesi Obrolan & Riwayat Chat
create table if not exists chat_sessions (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade not null,
    title text default 'Obrolan Baru',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists chat_messages (
    id uuid primary key default uuid_generate_v4(),
    session_id uuid references chat_sessions(id) on delete cascade not null,
    role text not null check (role in ('user', 'assistant')),
    content text not null,
    is_crisis boolean default false,
    embedding vector(768),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 4. Tabel Mood & Jurnal Harian
create table if not exists mood_logs (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade not null,
    score int not null check (score between 1 and 5),
    label text not null,
    triggers jsonb default '[]'::jsonb,
    notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. Tabel Psikolog & Booking Konsultasi
create table if not exists psychologists (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete set null,
    name text not null,
    role text not null,
    experience text not null,
    rating numeric(2,1) default 5.0,
    price text not null,
    category text not null,
    hospital text not null,
    is_available boolean default true,
    bio text,
    education text,
    str_number text,
    available_days jsonb default '["Senin", "Selasa", "Rabu", "Kamis"]'::jsonb,
    available_slots jsonb default '["09:00 - 10:00", "13:00 - 14:00", "16:00 - 17:00", "19:00 - 20:00"]'::jsonb,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Migrasi kolom baru jika tabel sudah ada sebelumnya:
alter table psychologists add column if not exists bio text;
alter table psychologists add column if not exists education text;
alter table psychologists add column if not exists str_number text;
alter table psychologists add column if not exists available_days jsonb default '["Senin", "Selasa", "Rabu", "Kamis"]'::jsonb;
alter table psychologists add column if not exists available_slots jsonb default '["09:00 - 10:00", "13:00 - 14:00", "16:00 - 17:00", "19:00 - 20:00"]'::jsonb;

create table if not exists bookings (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade not null,
    psychologist_id uuid references psychologists(id) on delete cascade not null,
    schedule_time text not null,
    notes text,
    status text default 'pending' check (status in ('pending', 'confirmed', 'completed', 'cancelled')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Chat konsultasi dokter-pasien, terikat ke booking
create table if not exists consultation_messages (
    id uuid primary key default uuid_generate_v4(),
    booking_id uuid references bookings(id) on delete cascade not null,
    sender_id text not null,
    sender_name text not null,
    sender_role text not null check (sender_role in ('user', 'doctor')),
    message text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_consultation_messages_booking_created
    on consultation_messages(booking_id, created_at);

-- Index performa pencarian
create index if not exists idx_chat_messages_session on chat_messages(session_id);
create index if not exists idx_mood_logs_user on mood_logs(user_id);
create index if not exists idx_bookings_user on bookings(user_id);

create table if not exists doctor_reviews (
    id uuid primary key default uuid_generate_v4(),
    booking_id uuid references bookings(id) on delete set null,
    psychologist_id uuid references psychologists(id) on delete cascade not null,
    user_name text default 'Pasien',
    rating int not null check (rating between 1 and 5),
    comment text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_doctor_reviews_psy on doctor_reviews(psychologist_id, created_at);

-- Dummy data psikolog awal
insert into psychologists (name, role, experience, rating, price, category, hospital, is_available)
values
('dr. Nadia S., Sp.KJ', 'Psikiater Klinis', '8 tahun', 4.9, 'Rp 250.000', 'Trauma & Depresi', 'RS Mitra Sehat Jakarta', true),
('Dimas Pratama, M.Psi., Psikolog', 'Psikolog Klinis Dewasa', '5 tahun', 4.8, 'Rp 180.000', 'Karir & Burnout', 'Praktek Mandiri Online', true),
('Sarah Amalia, M.Psi., Psikolog', 'Psikolog Hubungan & Keluarga', '6 tahun', 4.9, 'Rp 200.000', 'Hubungan & Asmara', 'Klinik Tumbuh Bahagia', true),
('Budi Santoso, M.Psi., Psikolog', 'Spesialis Regulasi Emosi & CBT', '7 tahun', 4.7, 'Rp 175.000', 'Kecemasan & Stres', 'Layanan Telekonseling', true)
on conflict do nothing;
