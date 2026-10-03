"use client";

/**
 * Halaman Laporan: /reports
 */

import { useCallback, useEffect, useState } from "react";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { ReportTable } from "@/components/reports/ReportTable";
import { Button } from "@/components/ui/Button";
import { SearchInput, SelectFilter } from "@/components/ui/Form";
import { Pagination } from "@/components/ui/Pagination";
import { EmptyState, ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { IconAlertTriangle } from "@/components/ui/Icons";
import { apiGet, ApiError } from "@/lib/api";
import { reportStatusLabel } from "@/lib/utils";
import type { Pagination as PaginationType } from "@/types/common";
import type { Report } from "@/types/report";

export default function ReportsPage() {
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

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const s = params.get("status");
    if (s) setStatus(s);
  }, []);

  return (
    <AdminLayout>
      <div className="space-y-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white rounded-[24px] p-5 border border-[#E2E8F0] shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
          <div>
            <h2 className="text-base font-extrabold text-[#0F172A] tracking-tight">
              Laporan Pengguna → Dokter
            </h2>
            <p className="text-xs text-[#64748B] font-medium">
              Tinjau pengaduan konsultasi dan lakukan investigasi objektif.
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

        <div className="overflow-hidden rounded-[24px] border border-[#E2E8F0] bg-white shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
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
              icon={<IconAlertTriangle className="w-6 h-6" />}
            />
          ) : (
            <>
              <ReportTable reports={reports} />
              <Pagination pagination={pagination} onPageChange={setPage} />
            </>
          )}
        </div>
      </div>
    </AdminLayout>
  );
}
