"use client";

/** Tabel daftar laporan. */

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/State";
import { formatDate } from "@/lib/utils";
import type { Report } from "@/types/report";

interface ReportTableProps {
  reports: Report[];
  onDetail: (report: Report) => void;
}

export function ReportTable({ reports, onDetail }: ReportTableProps) {
  if (reports.length === 0) {
    return (
      <EmptyState
        title="Tidak ada laporan"
        description="Coba ubah kata kunci pencarian atau filter status."
        icon="📋"
      />
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50">
          <tr>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              ID
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Pelapor
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Dokter
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Alasan
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Status
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Tanggal Laporan
            </th>
            <th className="px-4 py-3 text-right text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Action
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100 bg-white">
          {reports.map((report) => (
            <tr key={report.id} className="transition-colors hover:bg-slate-50/70">
              <td className="px-4 py-3 text-slate-500">#{report.id}</td>
              <td className="px-4 py-3">
                <p className="font-medium text-slate-800">
                  {report.reporter?.name ?? "-"}
                </p>
                <p className="text-xs text-slate-500">{report.reporter?.email ?? ""}</p>
              </td>
              <td className="px-4 py-3">
                <p className="font-medium text-slate-800">
                  {report.doctor?.name ?? "-"}
                </p>
                <p className="text-xs text-slate-500">
                  {report.doctor?.specialization ?? ""}
                </p>
              </td>
              <td className="px-4 py-3">
                <p className="max-w-xs">
                  <span className="rounded-md bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-600">
                    {report.category?.name ?? "Tanpa kategori"}
                  </span>
                </p>
                <p className="mt-1 line-clamp-2 max-w-xs text-xs text-slate-500">
                  {report.description}
                </p>
              </td>
              <td className="px-4 py-3">
                <Badge value={report.status} />
              </td>
              <td className="px-4 py-3 text-slate-600">
                {formatDate(report.created_at)}
              </td>
              <td className="px-4 py-3 text-right">
                <Link href={`/reports/${report.id}`}>
                  <Button size="sm" variant="secondary">
                    Detail
                  </Button>
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
