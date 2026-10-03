"use client";

/**
 * Halaman Laporan: /reports
 * Fitur: search, filter status, pagination, lihat detail.
 */

import { useCallback, useEffect, useState } from "react";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { ReportTable } from "@/components/reports/ReportTable";
import { Button } from "@/components/ui/Button";
import { SearchInput, SelectFilter } from "@/components/ui/Form";
import { Pagination } from "@/components/ui/Pagination";
import { EmptyState, ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { apiGet, ApiError } from "@/lib/api";
import { reportStatusLabel } from "@/lib/utils";
import type { Pagination as PaginationType } from "@/types/common";
import type { Report } from "@/types/report";
import { useRouter } from "next/navigation";

export default function ReportsPage() {
  const router = useRouter();

  const [reports, setReports] = useState<Report[]>([]);
  const [pagination, setPagination] = useState<PaginationType | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [page, setPage] = useState(1);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<Report[]>("/reports", {
        page,
        limit: 10,
        search: search.trim() || undefined,
        status: status || undefined,
      });
      setReports(res.data ?? []);
      setPagination(res.pagination ?? null);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal memuat data laporan");
    } finally {
      setLoading(false);
    }
  }, [page, search, status]);

  useEffect(() => {
    load();
  }, [load]);

  // Baca query ?status=pending dari shortcut dashboard
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const s = params.get("status");
    if (s) setStatus(s);
  }, []);

  return (
    <AdminLayout>
      <div className="space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-base font-semibold text-slate-900">
              Laporan User → Dokter
            </h2>
            <p className="text-sm text-slate-500">
              Tinjau laporan sebelum mengambil keputusan. Dokter tidak otomatis
              dihukum.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <SearchInput
              value={search}
              onChange={(v) => {
                setSearch(v);
                setPage(1);
              }}
              placeholder="Cari pelapor/dokter/isi..."
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
                { value: "pending", label: reportStatusLabel("pending") },
                { value: "reviewing", label: reportStatusLabel("reviewing") },
                { value: "resolved", label: reportStatusLabel("resolved") },
                { value: "rejected", label: reportStatusLabel("rejected") },
              ]}
            />
            <Button variant="secondary" size="sm" onClick={load}>
              Muat Ulang
            </Button>
          </div>
        </div>

        <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          {loading ? (
            <LoadingState label="Memuat data laporan..." />
          ) : error ? (
            <div className="p-5">
              <ErrorState message={error} onRetry={load} />
            </div>
          ) : reports.length === 0 ? (
            <EmptyState
              title="Tidak ada laporan"
              description="Belum ada laporan yang cocok dengan filter Anda."
              icon="📋"
            />
          ) : (
            <>
              <ReportTable reports={reports} onDetail={(r) => router.push(`/reports/${r.id}`)} />
              <Pagination pagination={pagination} onPageChange={setPage} />
            </>
          )}
        </div>
      </div>
    </AdminLayout>
  );
}
