"use client";

/**
 * Halaman Kelola Pengguna: /users
 * Menampilkan seluruh akun: Admin, Dokter, dan Pengguna Biasa (Pasien)
 */

import { useCallback, useEffect, useState } from "react";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { UserTable } from "@/components/users/UserTable";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Button } from "@/components/ui/Button";
import { SearchInput, SelectFilter } from "@/components/ui/Form";
import { Pagination } from "@/components/ui/Pagination";
import { EmptyState, ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { IconUsers } from "@/components/ui/Icons";
import { useToast } from "@/components/ui/Toast";
import { apiDelete, apiGet, apiPut, ApiError } from "@/lib/api";
import type { Pagination as PaginationType } from "@/types/common";
import type { User } from "@/types/user";

const ROLE_TABS = [
  { id: "", label: "Semua Peran" },
  { id: "admin", label: "Admin" },
  { id: "doctor", label: "Dokter" },
  { id: "user", label: "Pengguna Biasa" },
];

export default function UsersPage() {
  const toast = useToast();

  const [users, setUsers] = useState<User[]>([]);
  const [pagination, setPagination] = useState<PaginationType | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [role, setRole] = useState("");
  const [status, setStatus] = useState("");
  const [page, setPage] = useState(1);

  const [busyId, setBusyId] = useState<number | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<User | null>(null);
  const [deactivateTarget, setDeactivateTarget] = useState<User | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<User[]>("/users", {
        page,
        limit: 10,
        search: search.trim() || undefined,
        role: role || undefined,
        status: status || undefined,
      });
      setUsers(res.data ?? []);
      setPagination(res.pagination ?? null);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal memuat data user");
    } finally {
      setLoading(false);
    }
  }, [page, search, role, status]);

  useEffect(() => {
    load();
  }, [load]);

  const runAction = async (
    user: User,
    action: () => Promise<unknown>,
    successMessage: string
  ) => {
    setBusyId(user.id);
    try {
      await action();
      toast.success(successMessage);
      await load();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Terjadi kesalahan");
    } finally {
      setBusyId(null);
      setDeleteTarget(null);
      setDeactivateTarget(null);
    }
  };

  const handleToggleActive = (user: User) => {
    if (user.status === "active") {
      setDeactivateTarget(user);
    } else {
      runAction(user, () => apiPut(`/users/${user.id}/activate`), "Akun user diaktifkan");
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-4">
        {/* Header & Controls */}
        <div className="flex flex-col gap-4 bg-white rounded-[24px] p-5 border border-[#E2E8F0] shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div>
              <h2 className="text-base font-extrabold text-[#0F172A] tracking-tight">
                Semua Pengguna Aplikasi
              </h2>
              <p className="text-xs text-[#64748B] font-medium">
                Kelola akun administrator sistem, dokter psikolog, dan pasien pengguna biasa.
              </p>
            </div>
            
            <div className="flex flex-wrap items-center gap-2">
              <SearchInput
                value={search}
                onChange={(v) => {
                  setSearch(v);
                  setPage(1);
                }}
                placeholder="Cari nama, email, no telepon..."
              />
              <SelectFilter
                value={status}
                onChange={(v) => {
                  setStatus(v);
                  setPage(1);
                }}
                label="Filter status"
                options={[
                  { value: "", label: "Semua Status" },
                  { value: "active", label: "Aktif" },
                  { value: "inactive", label: "Nonaktif" },
                  { value: "suspended", label: "Ditangguhkan" },
                ]}
              />
              <Button variant="secondary" size="sm" onClick={load}>
                Muat Ulang
              </Button>
            </div>
          </div>

          {/* Role Filter Tabs */}
          <div className="flex items-center gap-2 pt-2 border-t border-[#E2E8F0] overflow-x-auto">
            <span className="text-xs font-bold text-[#64748B] mr-1">Peran:</span>
            {ROLE_TABS.map((tab) => {
              const active = role === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => {
                    setRole(tab.id);
                    setPage(1);
                  }}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer ${
                    active
                      ? "bg-[#0D9488] text-white shadow-2xs"
                      : "bg-[#F8FAF9] text-[#64748B] hover:bg-[#CCFBF1]/50 hover:text-[#0D9488] border border-[#E2E8F0]"
                  }`}
                >
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Tabel Data */}
        <div className="overflow-hidden rounded-[24px] border border-[#E2E8F0] bg-white shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
          {loading ? (
            <LoadingState label="Memuat data pengguna..." />
          ) : error ? (
            <div className="p-5">
              <ErrorState message={error} onRetry={load} />
            </div>
          ) : users.length === 0 ? (
            <EmptyState
              title="Tidak ada pengguna ditemukan"
              description="Belum ada pengguna yang sesuai dengan kriteria pencarian dan filter."
              icon={<IconUsers className="w-6 h-6" />}
              action={
                role || status || search ? (
                  <Button
                    variant="secondary"
                    size="sm"
                    onClick={() => {
                      setRole("");
                      setStatus("");
                      setSearch("");
                      setPage(1);
                    }}
                  >
                    Reset Semua Filter
                  </Button>
                ) : undefined
              }
            />
          ) : (
            <>
              <UserTable
                users={users}
                busyId={busyId}
                onToggleActive={handleToggleActive}
                onDelete={(u) => setDeleteTarget(u)}
              />
              <Pagination pagination={pagination} onPageChange={setPage} />
            </>
          )}
        </div>
      </div>

      {/* Konfirmasi nonaktifkan */}
      <ConfirmDialog
        open={Boolean(deactivateTarget)}
        title="Nonaktifkan Pengguna"
        message={`Apakah Anda yakin ingin menonaktifkan akun "${
          deactivateTarget?.name ?? ""
        }" (${deactivateTarget?.email ?? ""})? Pengguna tidak akan dapat login ke aplikasi.`}
        confirmLabel="Nonaktifkan"
        loading={busyId !== null}
        onCancel={() => setDeactivateTarget(null)}
        onConfirm={async () => {
          if (!deactivateTarget) return;
          await runAction(
            deactivateTarget,
            () => apiPut(`/users/${deactivateTarget.id}/deactivate`),
            "Akun pengguna dinonaktifkan"
          );
        }}
      />

      {/* Konfirmasi hapus */}
      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Hapus Pengguna"
        message={`Apakah Anda yakin ingin menghapus akun "${
          deleteTarget?.name ?? ""
        }" (${deleteTarget?.email ?? ""})? Data yang dihapus TIDAK dapat dipulihkan.`}
        confirmLabel="Ya, Hapus"
        loading={busyId !== null}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={async () => {
          if (!deleteTarget) return;
          await runAction(
            deleteTarget,
            () => apiDelete(`/users/${deleteTarget.id}`),
            "Akun pengguna berhasil dihapus"
          );
        }}
      />
    </AdminLayout>
  );
}
