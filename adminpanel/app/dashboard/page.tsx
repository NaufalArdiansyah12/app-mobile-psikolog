"use client";

/**
 * Halaman Dashboard:
 * Menggunakan icon modern SVG selaras MindPal (tanpa emoji).
 */

import { useCallback, useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { StatCard } from "@/components/dashboard/StatCard";
import { RecentDoctors } from "@/components/dashboard/RecentDoctors";
import { RecentReports } from "@/components/dashboard/RecentReports";
import { ActivityFeed } from "@/components/dashboard/ActivityFeed";
import { ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import {
  IconUsers,
  IconDoctor,
  IconClock,
  IconCheckCircle,
  IconAlertTriangle,
  IconImage,
  IconSearch,
  IconSettings,
  IconBrain,
} from "@/components/ui/Icons";
import { apiGet, ApiError } from "@/lib/api";
import type { ActivityLog, DashboardStats } from "@/types/common";
import type { Doctor } from "@/types/doctor";
import type { Report } from "@/types/report";

interface DashboardData {
  stats: DashboardStats | null;
  doctors: Doctor[];
  reports: Report[];
  activities: ActivityLog[];
  loading: boolean;
  error: string | null;
}

export default function DashboardPage() {
  const [state, setState] = useState<DashboardData>({
    stats: null,
    doctors: [],
    reports: [],
    activities: [],
    loading: true,
    error: null,
  });

  const [activePlanToggle, setActivePlanToggle] = useState(true);

  const load = useCallback(async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));
    try {
      const [statsRes, doctorsRes, reportsRes, activitiesRes] = await Promise.all([
        apiGet<DashboardStats>("/dashboard/stats"),
        apiGet<Doctor[]>("/dashboard/recent-doctors", { limit: 5 }),
        apiGet<Report[]>("/dashboard/recent-reports", { limit: 5 }),
        apiGet<ActivityLog[]>("/dashboard/recent-activities", { limit: 8 }),
      ]);

      setState({
        stats: statsRes.data,
        doctors: doctorsRes.data ?? [],
        reports: reportsRes.data ?? [],
        activities: activitiesRes.data ?? [],
        loading: false,
        error: null,
      });
    } catch (err) {
      setState((prev) => ({
        ...prev,
        loading: false,
        error: err instanceof ApiError ? err.message : "Gagal memuat dashboard",
      }));
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const { stats, doctors, reports, activities, loading, error } = state;

  return (
    <AdminLayout>
      {loading ? (
        <LoadingState label="Memuat data dashboard..." />
      ) : error ? (
        <ErrorState message={error} onRetry={load} />
      ) : (
        <div className="space-y-6">
          
          {/* ================= HERO GREETING BANNER ================= */}
          <section className="relative bg-[#F0FDFA] rounded-[24px] lg:rounded-[28px] p-6 sm:p-7 border border-[#99F6E4] overflow-hidden flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="absolute -top-12 -left-12 w-40 h-40 bg-[#CCFBF1] rounded-full blur-2xl pointer-events-none" />
            <div className="absolute -bottom-8 right-1/3 w-36 h-36 bg-[#99F6E4]/40 rounded-full blur-xl pointer-events-none" />

            <div className="relative z-10 max-w-lg space-y-2.5 text-center md:text-left">
              <div className="inline-flex items-center gap-2 bg-white/90 backdrop-blur-xs px-3.5 py-1 rounded-full text-[11px] font-bold text-[#0D9488] border border-[#99F6E4] shadow-xs">
                <span className="w-2 h-2 rounded-full bg-[#0D9488] animate-pulse" />
                Sistem Hevenly Aktif & Terverifikasi
              </div>

              <h2 className="text-xl sm:text-2xl font-extrabold text-[#0F172A] tracking-tight">
                Halo, Administrator Hevenly
              </h2>
              <p className="text-xs text-[#64748B] font-medium leading-relaxed">
                Kelola data dokter psikolog, verifikasi kelengkapan STR, tangani tiket laporan, dan tinjau performa aplikasi kesehatan mental secara realtime.
              </p>

              <div className="pt-1 flex items-center justify-center md:justify-start gap-3">
                <button
                  type="button"
                  onClick={() => setActivePlanToggle(!activePlanToggle)}
                  className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                    activePlanToggle ? "bg-[#0D9488]" : "bg-[#CBD5E1]"
                  }`}
                >
                  <span
                    className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                      activePlanToggle ? "translate-x-5" : "translate-x-0"
                    }`}
                  />
                </button>
                <span className="text-[11px] font-bold text-[#0F172A]">
                  {activePlanToggle ? "Monitoring Realtime Aktif" : "Monitoring Dijeda"}
                </span>
              </div>
            </div>

            {/* Hevenly Graphic Motif with Real Logo */}
            <div className="relative z-10 w-full md:w-64 h-28 sm:h-32 flex items-center justify-center md:justify-end select-none">
              <div className="relative flex items-center gap-3 bg-white/80 backdrop-blur-xs p-3.5 rounded-3xl border border-[#99F6E4] shadow-sm">
                <div className="relative w-14 h-14 rounded-2xl overflow-hidden shadow-xs ring-2 ring-[#0D9488]/30 flex-shrink-0">
                  <Image
                    src="/logo-2.jpeg"
                    alt="Hevenly Logo"
                    fill
                    className="object-cover"
                    priority
                  />
                </div>
                <div className="pr-2">
                  <h3 className="text-sm font-extrabold text-[#0F172A] tracking-tight">Hevenly</h3>
                  <p className="text-[10px] font-bold text-[#0D9488] uppercase tracking-wider">
                    Care & Psychology
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* ================= 6 STAT CARDS SECTION ================= */}
          <section className="space-y-3">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-bold text-[#0F172A] tracking-tight">Statistik Utama</h2>
              <span className="text-[11px] font-semibold text-[#64748B]">Sinkronisasi Cloud Supabase</span>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3.5">
              <StatCard
                title="Total User"
                value={stats?.total_users ?? 0}
                icon={<IconUsers className="w-5 h-5" />}
                accent="teal"
                hint="Pasien & pengguna aktif"
                progressPercent={75}
              />
              <StatCard
                title="Total Dokter"
                value={stats?.total_doctors ?? 0}
                icon={<IconDoctor className="w-5 h-5" />}
                accent="teal"
                hint="Psikolog & Psikiater"
                progressPercent={60}
              />
              <StatCard
                title="Menunggu Review"
                value={stats?.pending_verification ?? 0}
                icon={<IconClock className="w-5 h-5" />}
                accent="amber"
                hint="Perlu diverifikasi"
                progressPercent={40}
              />
              <StatCard
                title="Dokter Disetujui"
                value={stats?.verified_doctors ?? 0}
                icon={<IconCheckCircle className="w-5 h-5" />}
                accent="emerald"
                hint="Status aktif praktek"
                progressPercent={85}
              />
              <StatCard
                title="Laporan Masuk"
                value={stats?.unhandled_reports ?? 0}
                icon={<IconAlertTriangle className="w-5 h-5" />}
                accent="rose"
                hint="Tiket butuh respons"
                progressPercent={50}
              />
              <StatCard
                title="Slider Promo"
                value={stats?.active_sliders ?? 0}
                icon={<IconImage className="w-5 h-5" />}
                accent="teal"
                hint="Banner aktif tayang"
                progressPercent={90}
              />
            </div>
          </section>

          {/* ================= 2-COLUMN WORKSPACE: DOKTER/LAPORAN & AKTIVITAS ================= */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            
            {/* Left Column (8 cols): Dokter & Laporan Terbaru */}
            <div className="lg:col-span-8 space-y-6">
              
              {/* Dokter Terbaru Card */}
              <div className="bg-white rounded-[24px] p-5 border border-[#E2E8F0] shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
                <div className="flex items-center justify-between pb-4 border-b border-[#E2E8F0]">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-xl bg-[#F0FDFA] text-[#0D9488] flex items-center justify-center font-bold text-sm">
                      <IconDoctor className="w-4 h-4" />
                    </div>
                    <div>
                      <h3 className="text-sm font-bold text-[#0F172A]">Dokter Baru Terdaftar</h3>
                      <p className="text-[11px] text-[#64748B] font-medium">Verifikasi STR dan kelengkapan dokumen</p>
                    </div>
                  </div>
                  <Link
                    href="/doctors"
                    className="text-xs font-bold text-[#0D9488] hover:underline"
                  >
                    Lihat Semua →
                  </Link>
                </div>
                <div className="pt-3">
                  <RecentDoctors doctors={doctors} />
                </div>
              </div>

              {/* Laporan Pengguna Terbaru Card */}
              <div className="bg-white rounded-[24px] p-5 border border-[#E2E8F0] shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
                <div className="flex items-center justify-between pb-4 border-b border-[#E2E8F0]">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-xl bg-[#F0FDFA] text-[#0D9488] flex items-center justify-center font-bold text-sm">
                      <IconAlertTriangle className="w-4 h-4" />
                    </div>
                    <div>
                      <h3 className="text-sm font-bold text-[#0F172A]">Laporan User Terbaru</h3>
                      <p className="text-[11px] text-[#64748B] font-medium">Pengaduan sesi konsultasi dokter</p>
                    </div>
                  </div>
                  <Link
                    href="/reports"
                    className="text-xs font-bold text-[#0D9488] hover:underline"
                  >
                    Lihat Semua →
                  </Link>
                </div>
                <div className="pt-3">
                  <RecentReports reports={reports} />
                </div>
              </div>

            </div>

            {/* Right Column (4 cols): Feed Aktivitas Admin & Quick Actions */}
            <div className="lg:col-span-4 space-y-6">
              
              {/* Quick Actions Bento Widget */}
              <div className="bg-[#F0FDFA] rounded-[24px] p-5 border border-[#99F6E4]">
                <h3 className="text-xs font-bold text-[#0F172A] uppercase tracking-wider mb-3">
                  Aksi Cepat
                </h3>
                <div className="grid grid-cols-2 gap-2.5">
                  <Link
                    href="/doctors?status=pending"
                    className="flex flex-col items-center justify-center p-3 rounded-2xl bg-white hover:bg-white/90 border border-[#E2E8F0] text-center shadow-2xs transition-all active:scale-95"
                  >
                    <IconSearch className="w-5 h-5 text-[#0D9488] mb-1" />
                    <span className="text-[11px] font-bold text-[#0F172A]">Verifikasi STR</span>
                  </Link>
                  <Link
                    href="/sliders/create"
                    className="flex flex-col items-center justify-center p-3 rounded-2xl bg-white hover:bg-white/90 border border-[#E2E8F0] text-center shadow-2xs transition-all active:scale-95"
                  >
                    <IconImage className="w-5 h-5 text-[#0D9488] mb-1" />
                    <span className="text-[11px] font-bold text-[#0F172A]">Tambah Slider</span>
                  </Link>
                  <Link
                    href="/users"
                    className="flex flex-col items-center justify-center p-3 rounded-2xl bg-white hover:bg-white/90 border border-[#E2E8F0] text-center shadow-2xs transition-all active:scale-95"
                  >
                    <IconUsers className="w-5 h-5 text-[#0D9488] mb-1" />
                    <span className="text-[11px] font-bold text-[#0F172A]">Kelola User</span>
                  </Link>
                  <Link
                    href="/settings"
                    className="flex flex-col items-center justify-center p-3 rounded-2xl bg-white hover:bg-white/90 border border-[#E2E8F0] text-center shadow-2xs transition-all active:scale-95"
                  >
                    <IconSettings className="w-5 h-5 text-[#0D9488] mb-1" />
                    <span className="text-[11px] font-bold text-[#0F172A]">Pengaturan</span>
                  </Link>
                </div>
              </div>

              {/* Riwayat Aktivitas Admin */}
              <div className="bg-white rounded-[24px] p-5 border border-[#E2E8F0] shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
                <div className="flex items-center justify-between pb-3 border-b border-[#E2E8F0]">
                  <h3 className="text-sm font-bold text-[#0F172A]">Aktivitas Terakhir</h3>
                  <span className="w-2 h-2 rounded-full bg-[#10B981]" />
                </div>
                <div className="pt-3">
                  <ActivityFeed activities={activities} />
                </div>
              </div>

            </div>

          </div>

        </div>
      )}
    </AdminLayout>
  );
}
