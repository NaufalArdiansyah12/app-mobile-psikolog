"use client";

/**
 * Halaman Detail Laporan: /reports/[id]
 * Ubah status + catatan admin (review sebelum keputusan).
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { ReportDetail } from "@/components/reports/ReportDetail";
import { ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { useToast } from "@/components/ui/Toast";
import { apiGet, apiPut, ApiError } from "@/lib/api";
import type { Report, ReportStatus } from "@/types/report";

export default function ReportDetailPage() {
  const params = useParams<{ id: string }>();
  const toast = useToast();

  const [report, setReport] = useState<Report | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reportId = Number(params.id);

  const load = useCallback(async () => {
    if (!Number.isFinite(reportId)) {
      setError("ID laporan tidak valid");
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<Report>(`/reports/${reportId}`);
      setReport(res.data);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal memuat laporan");
    } finally {
      setLoading(false);
    }
  }, [reportId]);

  useEffect(() => {
    load();
  }, [load]);

  const handleSave = async (status: ReportStatus, adminNote: string) => {
    setSaving(true);
    try {
      const res = await apiPut<Report>(`/reports/${reportId}/status`, {
        status,
        admin_note: adminNote,
      });
      setReport(res.data);
      toast.success("Status laporan berhasil diperbarui");
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Gagal memperbarui status");
    } finally {
      setSaving(false);
    }
  };

  return (
    <AdminLayout>
      <div className="mb-4">
        <Link
          href="/reports"
          className="text-sm font-medium text-primary-600 hover:underline"
        >
          ← Kembali ke daftar laporan
        </Link>
      </div>

      {loading ? (
        <LoadingState label="Memuat detail laporan..." />
      ) : error || !report ? (
        <ErrorState message={error ?? "Laporan tidak ditemukan"} onRetry={load} />
      ) : (
        <ReportDetail report={report} saving={saving} onSave={handleSave} />
      )}
    </AdminLayout>
  );
}
