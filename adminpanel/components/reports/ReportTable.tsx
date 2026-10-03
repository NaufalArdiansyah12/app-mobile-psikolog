"use client";

/** Tabel daftar laporan estetika MindPal. */

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/State";
import { IconAlertTriangle } from "@/components/ui/Icons";
import { formatDate } from "@/lib/utils";
import type { Report } from "@/types/report";

interface ReportTableProps {
  reports: Report[];
  onDetail?: (report: Report) => void;
}

export function ReportTable({ reports }: ReportTableProps) {
  if (reports.length === 0) {
    return (
      <EmptyState
        title="Tidak ada laporan"
        description="Coba ubah kata kunci pencarian atau filter status."
        icon={<IconAlertTriangle className="w-6 h-6" />}
      />
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-[#E2E8F0] text-xs">
        <thead>
          <tr className="border-b border-[#E2E8F0] bg-[#F8FAF9]/80 text-[#64748B]">
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              ID
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Pelapor
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Dokter Terlapor
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Kategori & Detail
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Status
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Tanggal
            </th>
            <th className="px-4 py-3 text-right font-bold uppercase tracking-wider">
              Aksi
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-[#E2E8F0] bg-white">
          {reports.map((report) => (
            <tr key={report.id} className="transition-colors hover:bg-[#F8FAF9]/70">
              <td className="px-4 py-3.5 font-mono text-[11px] text-[#64748B] font-bold">
                #{report.id}
              </td>
              <td className="px-4 py-3.5">
                <p className="font-bold text-[#0F172A]">
                  {report.reporter?.name ?? "Pengguna Anonim"}
                </p>
                <p className="text-[11px] text-[#64748B] font-medium">
                  {report.reporter?.email ?? "-"}
                </p>
              </td>
              <td className="px-4 py-3.5">
                <p className="font-bold text-[#0F172A]">
                  {report.doctor?.name ?? "Dokter"}
                </p>
                <p className="text-[11px] text-[#64748B] font-medium">
                  {report.doctor?.specialization ?? "Psikolog"}
                </p>
              </td>
              <td className="px-4 py-3.5">
                <span className="rounded-full bg-[#F8FAF9] px-2.5 py-0.5 text-[10px] font-bold text-[#64748B]">
                  {report.category?.name ?? "Pengaduan Umum"}
                </span>
                <p className="mt-1 line-clamp-1 max-w-xs text-[11px] text-[#64748B] font-medium">
                  {report.description}
                </p>
              </td>
              <td className="px-4 py-3.5">
                <Badge value={report.status} />
              </td>
              <td className="px-4 py-3.5 text-[#64748B] font-medium">
                {formatDate(report.created_at)}
              </td>
              <td className="px-4 py-3.5 text-right">
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
