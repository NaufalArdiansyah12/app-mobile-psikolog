"use client";

/**
 * Halaman Detail User: /users/[id]
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { useToast } from "@/components/ui/Toast";
import { apiGet, apiPut, ApiError } from "@/lib/api";
import { formatDate, formatDateTime, initials, roleBadgeStyle, roleLabel, verificationLabel } from "@/lib/utils";
import type { User } from "@/types/user";

function Row({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div className="grid grid-cols-1 gap-1 border-b border-[#E2E8F0] py-3 sm:grid-cols-3 sm:gap-4">
      <dt className="text-xs font-bold text-[#64748B] uppercase">
        {label}
      </dt>
      <dd className="text-xs font-semibold text-[#0F172A] sm:col-span-2">{value ?? "-"}</dd>
    </div>
  );
}

export default function UserDetailPage() {
  const params = useParams<{ id: string }>();
  const toast = useToast();

  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const userId = Number(params.id);

  const load = useCallback(async () => {
    if (!Number.isFinite(userId)) {
      setError("ID user tidak valid");
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<User>(`/users/${userId}`);
      setUser(res.data);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal memuat detail user");
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    load();
  }, [load]);

  const handleToggleStatus = async (targetStatus: "active" | "inactive" | "suspended") => {
    if (!user) return;
    setBusy(true);
    try {
      await apiPut(`/users/${user.id}/${targetStatus === "active" ? "activate" : "deactivate"}`);
      toast.success(`Status user diubah menjadi ${targetStatus}`);
      await load();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Gagal mengubah status user");
    } finally {
      setBusy(false);
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <Link
            href="/users"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-[#0D9488] hover:underline"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
              <line x1="19" y1="12" x2="5" y2="12" strokeLinecap="round" strokeLinejoin="round" />
              <polyline points="12 19 5 12 12 5" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            Kembali ke daftar user
          </Link>

          {user && user.role !== "admin" && (
            <div className="flex items-center gap-2">
              {user.status !== "active" ? (
                <Button
                  size="sm"
                  variant="success"
                  loading={busy}
                  onClick={() => handleToggleStatus("active")}
                >
                  Aktifkan User
                </Button>
              ) : (
                <Button
                  size="sm"
                  variant="secondary"
                  loading={busy}
                  onClick={() => handleToggleStatus("inactive")}
                >
                  Nonaktifkan User
                </Button>
              )}
            </div>
          )}
        </div>

        {loading ? (
          <LoadingState label="Memuat detail user..." />
        ) : error || !user ? (
          <ErrorState message={error ?? "User tidak ditemukan"} onRetry={load} />
        ) : (
          <div className="rounded-[28px] border border-[#E2E8F0] bg-white p-6 sm:p-8 shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
            <div className="mb-6 flex flex-wrap items-center gap-4">
              <span className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#CCFBF1] text-lg font-extrabold text-[#0D9488] shadow-xs">
                {initials(user.name)}
              </span>
              <div>
                <h2 className="text-lg font-extrabold text-[#0F172A]">{user.name}</h2>
                <p className="text-xs text-[#64748B] font-medium">{user.email}</p>
                <div className="mt-1.5 flex items-center gap-2">
                  <span className={`rounded-full px-2.5 py-0.5 text-[10px] font-bold ${roleBadgeStyle(user.role)}`}>
                    {roleLabel(user.role)}
                  </span>
                  <Badge value={user.status} />
                </div>
              </div>
            </div>

            <dl className="space-y-1">
              <Row label="ID User" value={`#${user.id}`} />
              <Row label="Nama Lengkap" value={user.name} />
              <Row label="Email" value={user.email} />
              <Row label="No. Telepon" value={user.phone || "-"} />
              <Row label="Tanggal Registrasi" value={formatDateTime(user.created_at)} />
              <Row label="Terakhir Diperbarui" value={formatDateTime(user.updated_at)} />

              {user.doctor && (
                <Row
                  label="Profil Dokter Terhubung"
                  value={
                    <div className="flex items-center gap-3">
                      <div>
                        <p className="text-xs font-bold text-[#0F172A]">{user.name}</p>
                        <p className="text-[11px] text-[#64748B] font-medium">
                          {user.doctor.specialization || "Psikolog"} · STR: {user.doctor.license_number || "-"} ·{" "}
                          <span className="font-bold text-[#0D9488]">
                            {verificationLabel(user.doctor.verification_status)}
                          </span>
                        </p>
                      </div>
                      <Link
                        href={`/doctors/${user.doctor.id}`}
                        className="text-xs font-bold text-[#0D9488] hover:underline"
                      >
                        Buka Profil Dokter →
                      </Link>
                    </div>
                  }
                />
              )}
            </dl>
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
