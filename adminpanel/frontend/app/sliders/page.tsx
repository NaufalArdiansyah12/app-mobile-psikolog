"use client";

/**
 * Halaman Kelola Slider: /sliders
 * Fitur: search, filter status, pagination, tambah, edit, hapus,
 *        aktifkan/nonaktifkan.
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { SliderTable } from "@/components/sliders/SliderTable";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Button } from "@/components/ui/Button";
import { SearchInput, SelectFilter } from "@/components/ui/Form";
import { Pagination } from "@/components/ui/Pagination";
import { EmptyState, ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { useToast } from "@/components/ui/Toast";
import { apiDelete, apiGet, apiPut, ApiError } from "@/lib/api";
import type { Pagination as PaginationType } from "@/types/common";
import type { Slider } from "@/types/slider";

export default function SlidersPage() {
  const toast = useToast();

  const [sliders, setSliders] = useState<Slider[]>([]);
  const [pagination, setPagination] = useState<PaginationType | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [page, setPage] = useState(1);

  const [busyId, setBusyId] = useState<number | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Slider | null>(null);
  const [deactivateTarget, setDeactivateTarget] = useState<Slider | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<Slider[]>("/sliders", {
        page,
        limit: 10,
        search: search.trim() || undefined,
        status: status || undefined,
      });
      setSliders(res.data ?? []);
      setPagination(res.pagination ?? null);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal memuat data slider");
    } finally {
      setLoading(false);
    }
  }, [page, search, status]);

  useEffect(() => {
    load();
  }, [load]);

  const runAction = async (
    slider: Slider,
    action: () => Promise<unknown>,
    successMessage: string
  ) => {
    setBusyId(slider.id);
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

  const handleToggleActive = (slider: Slider) => {
    if (slider.status === "active") {
      setDeactivateTarget(slider);
    } else {
      runAction(
        slider,
        () => apiPut(`/sliders/${slider.id}/activate`),
        "Slider diaktifkan"
      );
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-base font-semibold text-slate-900">Kelola Slider</h2>
            <p className="text-sm text-slate-500">
              Banner yang tampil di halaman user aplikasi.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <SearchInput
              value={search}
              onChange={(v) => {
                setSearch(v);
                setPage(1);
              }}
              placeholder="Cari judul slider..."
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
              ]}
            />
            <Link href="/sliders/create">
              <Button size="sm">+ Tambah Slider</Button>
            </Link>
          </div>
        </div>

        <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          {loading ? (
            <LoadingState label="Memuat data slider..." />
          ) : error ? (
            <div className="p-5">
              <ErrorState message={error} onRetry={load} />
            </div>
          ) : sliders.length === 0 ? (
            <EmptyState
              title="Belum ada slider"
              description="Belum ada slider yang cocok dengan filter Anda."
              action={
                <Link href="/sliders/create">
                  <Button size="sm">+ Tambah Slider</Button>
                </Link>
              }
            />
          ) : (
            <>
              <SliderTable
                sliders={sliders}
                busyId={busyId}
                onToggleActive={handleToggleActive}
                onDelete={(s) => setDeleteTarget(s)}
              />
              <Pagination pagination={pagination} onPageChange={setPage} />
            </>
          )}
        </div>
      </div>

      {/* Konfirmasi nonaktifkan */}
      <ConfirmDialog
        open={Boolean(deactivateTarget)}
        title="Nonaktifkan Slider"
        message={`Apakah Anda yakin ingin menonaktifkan slider "${
          deactivateTarget?.title ?? ""
        }"? Slider tidak akan tampil di halaman user.`}
        confirmLabel="Nonaktifkan"
        loading={busyId !== null}
        onCancel={() => setDeactivateTarget(null)}
        onConfirm={async () => {
          if (!deactivateTarget) return;
          await runAction(
            deactivateTarget,
            () => apiPut(`/sliders/${deactivateTarget.id}/deactivate`),
            "Slider dinonaktifkan"
          );
        }}
      />

      {/* Konfirmasi hapus */}
      <ConfirmDialog
        open={Boolean(deleteTarget)}
        title="Hapus Slider"
        message={`Apakah Anda yakin ingin menghapus slider "${
          deleteTarget?.title ?? ""
        }"? Data yang dihapus TIDAK dapat dikembalikan.`}
        confirmLabel="Ya, Hapus"
        loading={busyId !== null}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={async () => {
          if (!deleteTarget) return;
          await runAction(
            deleteTarget,
            () => apiDelete(`/sliders/${deleteTarget.id}`),
            "Slider berhasil dihapus"
          );
        }}
      />
    </AdminLayout>
  );
}
