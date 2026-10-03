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
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-sm font-semibold text-slate-900">
              Profil Admin
            </h2>

            <div className="mb-6 flex items-center gap-4">
              <span className="flex h-14 w-14 items-center justify-center rounded-full bg-primary-600 text-lg font-bold text-white">
                {initials(user?.name)}
              </span>
              <div>
                <p className="text-base font-semibold text-slate-900">{user?.name}</p>
                <p className="text-sm text-slate-500">{user?.email}</p>
                <div className="mt-1 flex items-center gap-2">
                  <Badge
                    label={user ? roleLabel(user.role) : "-"}
                    variant="accent"
                  />
                  <Badge value={user?.status ?? "active"} />
                </div>
              </div>
            </div>

            <dl className="divide-y divide-slate-100">
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                  ID Admin
                </dt>
                <dd className="col-span-2 text-sm text-slate-800">
                  #{user?.id ?? "-"}
                </dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                  Telepon
                </dt>
                <dd className="col-span-2 text-sm text-slate-800">
                  {user?.phone || "-"}
                </dd>
              </div>
            </dl>

            <div className="mt-6">
              <Button variant="danger" loading={loggingOut} onClick={handleLogout}>
                🚪 Logout
              </Button>
            </div>
          </div>

          {/* Info sistem */}
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-sm font-semibold text-slate-900">
              Info Sistem
            </h2>

            <dl className="divide-y divide-slate-100">
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                  Aplikasi
                </dt>
                <dd className="col-span-2 text-sm text-slate-800">ADMIN DOKTER v1.0.0</dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                  Frontend
                </dt>
                <dd className="col-span-2 text-sm text-slate-800">
                  Next.js 16 (App Router) · http://localhost:3000
                </dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                  Backend API
                </dt>
                <dd className="col-span-2 break-all font-mono text-xs text-slate-800">
                  {apiUrl}
                </dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                  API Docs
                </dt>
                <dd className="col-span-2 text-sm">
                  <a
                    href="http://127.0.0.1:8000/docs"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary-600 hover:underline"
                  >
                    http://127.0.0.1:8000/docs
                  </a>
                </dd>
              </div>
              <div className="grid grid-cols-3 gap-4 py-3">
                <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                  Sesi Login
                </dt>
                <dd className="col-span-2 text-sm text-slate-800">
                  {formatDateTime(new Date().toISOString())}
                </dd>
              </div>
            </dl>

            <div className="mt-6 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-xs leading-5 text-amber-800">
              Perubahan password dan profil dilakukan melalui database/backend.
              Jangan bagikan akun admin Anda kepada orang lain.
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}

