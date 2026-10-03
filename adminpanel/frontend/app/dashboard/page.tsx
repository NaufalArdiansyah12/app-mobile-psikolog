"use client";

/**
 * Halaman Dashboard: /dashboard
 * Statistik & data terbaru diambil LANGSUNG dari API FastAPI (data nyata).
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { StatCard } from "@/components/dashboard/StatCard";
import { RecentDoctors } from "@/components/dashboard/RecentDoctors";
import { RecentReports } from "@/components/dashboard/RecentReports";
import { ActivityFeed } from "@/components/dashboard/ActivityFeed";
import { ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
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
        <LoadingState label="Memuat statistik dashboard..." />
      ) : error ? (
        <ErrorState message={error} onRetry={load} />
      ) : (
        <div className="space-y-6">
          {/* Sapaan */}
          <div className="rounded-xl bg-gradient-to-r from-primary-600 to-primary-700 px-6 py-5 text-white shadow-sm">
            <h2 className="text-lg font-semibold">Selamat datang di Admin DOKTER 👋</h2>
            <p className="mt-1 text-sm text-primary-100">
              Berikut ringkasan aktivitas aplikasi terkini.
            </p>
          </div>

          {/* Kartu statistik */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-6">
            <StatCard
              title="Total User"
              value={stats?.total_users ?? 0}
              icon="👥"
              accent="primary"
              hint="User biasa terdaftar"
            />
            <StatCard
              title="Total Dokter"
              value={stats?.total_doctors ?? 0}
              icon="🩺"
              accent="accent"
              hint="Semua dokter terdaftar"
            />
            <StatCard
              title="Menunggu Verifikasi"
              value={stats?.pending_verification ?? 0}
              icon="⏳"
              accent="amber"
              hint="Perlu tindakan admin"
            />
            <StatCard
              title="Dokter Terverifikasi"
              value={stats?.verified_doctors ?? 0}
              icon="✅"
              accent="emerald"
              hint="Disetujui admin"
            />
            <StatCard
              title="Total Laporan"
              value={stats?.total_reports ?? 0}
              icon="📋"
              accent="slate"
              hint="Laporan dari user"
            />
            <StatCard
              title="Belum Ditangani"
              value={stats?.unhandled_reports ?? 0}
              icon="🚨"
              accent="red"
              hint="Pending & sedang direview"
            />
          </div>

          {/* Section bawah */}
          <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
            <RecentDoctors doctors={doctors} />
            <RecentReports reports={reports} />
            <ActivityFeed activities={activities} />
          </div>

          {/* Aksi cepat */}
          <div className="flex flex-wrap gap-3">
            <Link
              href="/doctors?status=pending"
              className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-2 text-sm font-medium text-amber-700 transition-colors hover:bg-amber-100"
            >
              ⏳ Review verifikasi dokter
            </Link>
            <Link
              href="/reports?status=pending"
              className="rounded-lg border border-red-200 bg-red-50 px-4 py-2 text-sm font-medium text-red-700 transition-colors hover:bg-red-100"
            >
              🚨 Tangani laporan user
            </Link>
            <Link
              href="/sliders/create"
              className="rounded-lg border border-primary-200 bg-primary-50 px-4 py-2 text-sm font-medium text-primary-700 transition-colors hover:bg-primary-100"
            >
              ➕ Tambah slider baru
            </Link>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}
