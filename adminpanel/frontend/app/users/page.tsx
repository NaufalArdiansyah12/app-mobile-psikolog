"use client";

/**
 * Halaman Kelola User: /users
 * Fitur: search, filter status, pagination, detail, aktifkan,
 *        nonaktifkan, hapus (dengan confirmation dialog).
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
import { useToast } from "@/components/ui/Toast";
import { apiDelete, apiGet, apiPut, ApiError } from "@/lib/api";
import type { Pagination as PaginationType } from "@/types/common";
import type { User } from "@/types/user";

export default function UsersPage() {
  const toast = useToast();

  const [users, setUsers] = useState<User[]>([]);
  const [pagination, setPagination] = useState<PaginationType | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
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
        status: status || undefined,
      });
      setUsers(res.data ?? []);
      setPagination(res.pagination ?? null);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal memuat data user");
    } finally {
      setLoading(false);
    }
  }, [page, search, status]);

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
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-base font-semibold text-slate-900">Kelola User</h2>
            <p className="text-sm text-slate-500">
              Cari, filter, dan kelola akun pengguna aplikasi.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <SearchInput
              value={search}
              onChange={(v) => {
                setSearch(v);
                setPage(1);
              }}
              placeholder="Cari nama/email/telepon..."
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

        <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          {loading ? (
            <LoadingState label="Memuat data user..." />
          ) : error ? (
            <div className="p-5">
              <ErrorState message={error} onRetry={load} />
            </div>
          ) : users.length === 0 ? (
            <EmptyState
              title="Tidak ada user"
              description="Belum ada user yang cocok dengan filter Anda."
              icon="👥"
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
        title="Nonaktifkan Akun User"
        message={`Apakah Anda yakin ingin menonaktifkan akun ${
          deactivateTarget?.name ?? ""
        }? User tidak akan bisa login sampai akun diaktifkan kembali.`}
        confirmLabel="Nonaktifkan"
        loading={busyId !== null}
        onCancel={() => setDeactivateTarget(null)}
        onConfirm={async () => {
          if (!deactivateTarget) return;
          await runAction(
            deactivateTarget,
            () => apiPut(`/users/${deactivateTarget.id}/deactivate`),
            "Akun user dinonaktifkan"
          );
        }}
      />

      {/* Konfirmasi hapus (operasi berbahaya) */}
      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Hapus User"
        message={`Apakah Anda yakin ingin menghapus user "${
          deleteTarget?.name ?? ""
        }"? Data yang dihapus TIDAK dapat dikembalikan.`}
        confirmLabel="Ya, Hapus"
        loading={busyId !== null}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={async () => {
          if (!deleteTarget) return;
          await runAction(
            deleteTarget,
            () => apiDelete(`/users/${deleteTarget.id}`),
            "User berhasil dihapus"
          );
        }}
      />
    </AdminLayout>
  );
}
