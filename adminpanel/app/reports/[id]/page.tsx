"use client";

/**
 * Halaman Detail Laporan: /reports/[id]
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
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

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
      setError(err instanceof ApiError ? err.message : "Gagal memuat detail laporan");
    } finally {
      setLoading(false);
    }
  }, [reportId]);

  useEffect(() => {
    load();
  }, [load]);

  const handleSave = async (status: ReportStatus, adminNote: string) => {
    if (!report) return;
    setSaving(true);
    try {
      await apiPut(`/reports/${report.id}/status`, {
        status,
        admin_note: adminNote || undefined,
      });
      toast.success("Status laporan berhasil diperbarui");
      await load();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Gagal memperbarui status laporan");
    } finally {
      setSaving(false);
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-4">
        <Link
          href="/reports"
          className="inline-flex items-center gap-1.5 text-xs font-bold text-[#0D9488] hover:underline"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
            <line x1="19" y1="12" x2="5" y2="12" strokeLinecap="round" strokeLinejoin="round" />
            <polyline points="12 19 5 12 12 5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          Kembali ke daftar laporan
        </Link>

        {loading ? (
          <LoadingState label="Memuat detail laporan..." />
        ) : error || !report ? (
          <ErrorState message={error ?? "Laporan tidak ditemukan"} onRetry={load} />
        ) : (
          <ReportDetail report={report} saving={saving} onSave={handleSave} />
        )}
      </div>
    </AdminLayout>
  );
}
