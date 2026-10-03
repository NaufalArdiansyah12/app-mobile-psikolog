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
import { formatDate, formatDateTime, initials, roleLabel, verificationLabel } from "@/lib/utils";
import type { User } from "@/types/user";

function Row({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div className="grid grid-cols-1 gap-1 border-b border-slate-100 py-3 sm:grid-cols-3 sm:gap-4">
      <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
        {label}
      </dt>
      <dd className="text-sm text-slate-800 sm:col-span-2">{value ?? "-"}</dd>
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
      setError(err instanceof ApiError ? err.message : "Gagal memuat data user");
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    load();
  }, [load]);

  const toggleActive = async () => {
    if (!user) return;
    setBusy(true);
    try {
      const nextActive = user.status !== "active";
      const res = await apiPut<User>(
        `/users/${user.id}/${nextActive ? "activate" : "deactivate"}`
      );
      setUser(res.data);
      toast.success(nextActive ? "Akun user diaktifkan" : "Akun user dinonaktifkan");
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Terjadi kesalahan");
    } finally {
      setBusy(false);
    }
  };

  return (
    <AdminLayout>
      <div className="mb-4">
        <Link href="/users" className="text-sm font-medium text-primary-600 hover:underline">
          ← Kembali ke daftar user
        </Link>
      </div>

      {loading ? (
        <LoadingState label="Memuat detail user..." />
      ) : error || !user ? (
        <ErrorState message={error ?? "User tidak ditemukan"} onRetry={load} />
      ) : (
        <div className="space-y-4">
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
              <span className="flex h-16 w-16 items-center justify-center rounded-full bg-slate-200 text-xl font-bold text-slate-700">
                {initials(user.name)}
              </span>
              <div className="min-w-0 flex-1">
                <h2 className="text-lg font-semibold text-slate-900">{user.name}</h2>
                <p className="text-sm text-slate-500">{user.email}</p>
                <div className="mt-2 flex flex-wrap items-center gap-2">
                  <Badge value={user.status} />
                  <span className="rounded-md bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-600">
                    {roleLabel(user.role)}
                  </span>
                </div>
              </div>
              {user.role !== "admin" && (
                <Button
                  size="sm"
                  variant={user.status === "active" ? "secondary" : "success"}
                  loading={busy}
                  onClick={toggleActive}
                >
                  {user.status === "active" ? "Nonaktifkan" : "Aktifkan"}
                </Button>
              )}
            </div>
          </div>

          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h3 className="mb-2 text-sm font-semibold text-slate-900">
              Informasi User
            </h3>
            <dl className="divide-y divide-slate-100">
              <Row label="ID" value={`#${user.id}`} />
              <Row label="Nama" value={user.name} />
              <Row label="Email" value={user.email} />
              <Row label="Nomor Telepon" value={user.phone} />
              <Row label="Role" value={roleLabel(user.role)} />
              <Row
                label="Status"
                value={<Badge value={user.status} />}
              />
              <Row label="Tanggal Registrasi" value={formatDateTime(user.created_at)} />
              <Row label="Terakhir Diperbarui" value={formatDate(user.updated_at)} />
              {user.doctor && (
                <Row
                  label="Info Dokter"
                  value={
                    <span>
                      {user.doctor.specialization || "-"} · STR:{" "}
                      {user.doctor.license_number || "-"} ·{" "}
                      {verificationLabel(user.doctor.verification_status)}
                    </span>
                  }
                />
              )}
            </dl>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}
