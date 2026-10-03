"use client";

/**
 * Halaman Pengaturan: /settings
 * Menampilkan profil admin, info sistem, dan aksi logout.
 */

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { IconLogout } from "@/components/ui/Icons";
import { useToast } from "@/components/ui/Toast";
import { apiGet, ApiError } from "@/lib/api";
import { logout } from "@/lib/auth";
import { formatDateTime, initials, roleLabel } from "@/lib/utils";
import type { AuthUser } from "@/types/auth";

export default function SettingsPage() {
  const router = useRouter();
  const toast = useToast();

  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [loggingOut, setLoggingOut] = useState(false);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await apiGet<AuthUser>("/auth/me");
        if (!cancelled) setUser(res.data);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof ApiError ? err.message : "Gagal memuat profil");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const handleLogout = async () => {
    setLoggingOut(true);
    await logout();
    toast.success("Anda berhasil logout");
    router.replace("/login");
  };

  const apiUrl = process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:8000/api/admin";

  return (
    <AdminLayout>
      {loading ? (
        <LoadingState label="Memuat pengaturan..." />
      ) : error ? (
        <ErrorState message={error} />
      ) : (
        <div className="grid grid-cols-1 gap-6 xl:grid-cols-2">
          {/* Profil admin */}
          <div className="rounded-[28px] border border-[#E2E8F0] bg-white p-7 shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
            <h2 className="mb-5 text-sm font-extrabold text-[#0F172A] tracking-tight">
              Profil Administrator
            </h2>

            <div className="mb-6 flex items-center gap-4">
              <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-[#0D9488] text-lg font-extrabold text-white shadow-[0_8px_18px_-4px_rgba(13,148,136,0.35)]">
                {initials(user?.name)}
              </span>
              <div>
                <p className="text-base font-extrabold text-[#0F172A]">{user?.name}</p>
                <p className="text-xs text-[#64748B] font-medium">{user?.email}</p>
                <div className="mt-1.5 flex items-center gap-2">
                  <Badge
                    label={user ? roleLabel(user.role) : "-"}
                    variant="accent"
                  />
                  <Badge value={user?.status ?? "active"} />
                </div>
              </div>
            </div>

            <dl className="divide-y divide-[#E2E8F0]">
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-bold text-[#64748B] uppercase">
                  ID Admin
                </dt>
                <dd className="col-span-2 text-xs font-bold text-[#0F172A]">
                  #{user?.id ?? "-"}
                </dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-bold text-[#64748B] uppercase">
                  Telepon
                </dt>
                <dd className="col-span-2 text-xs font-medium text-[#0F172A]">
                  {user?.phone || "-"}
                </dd>
              </div>
            </dl>

            <div className="mt-6">
              <Button variant="danger" loading={loggingOut} onClick={handleLogout}>
                <IconLogout className="w-4 h-4" />
                <span>Keluar dari Sistem</span>
              </Button>
            </div>
          </div>

          {/* Info sistem */}
          <div className="rounded-[28px] border border-[#E2E8F0] bg-white p-7 shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
            <h2 className="mb-5 text-sm font-extrabold text-[#0F172A] tracking-tight">
              Informasi Lingkungan Sistem
            </h2>

            <dl className="divide-y divide-[#E2E8F0]">
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-bold text-[#64748B] uppercase">
                  Aplikasi
                </dt>
                <dd className="col-span-2 text-xs font-bold text-[#0F172A]">Hevenly Admin v1.0.0 (Teal Theme)</dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-bold text-[#64748B] uppercase">
                  Frontend
                </dt>
                <dd className="col-span-2 text-xs font-medium text-[#0F172A]">
                  Next.js 16 (App Router) · http://localhost:3000
                </dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-bold text-[#64748B] uppercase">
                  Backend API
                </dt>
                <dd className="col-span-2 break-all font-mono text-xs font-semibold text-[#0D9488]">
                  {apiUrl}
                </dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-bold text-[#64748B] uppercase">
                  API Docs
                </dt>
                <dd className="col-span-2 text-xs">
                  <a
                    href="http://127.0.0.1:8000/docs"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="font-bold text-[#0D9488] hover:underline"
                  >
                    http://127.0.0.1:8000/docs
                  </a>
                </dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-bold text-[#64748B] uppercase">
                  Sesi Login
                </dt>
                <dd
                  suppressHydrationWarning
                  className="col-span-2 text-xs font-medium text-[#64748B]"
                >
                  {formatDateTime(new Date().toISOString())}
                </dd>
              </div>
            </dl>

            <div className="mt-6 rounded-2xl border border-[#0D9488]/20 bg-[#F0FDFA] px-4 py-3.5 text-xs font-medium text-[#0D9488]">
              Perubahan password dan hak akses admin diproses langsung melalui database/backend.
              Jaga kerahasiaan kredensial admin Anda.
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}
