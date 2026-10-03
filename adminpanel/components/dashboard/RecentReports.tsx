"use client";

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { EmptyState } from "@/components/ui/State";
import { IconAlertTriangle } from "@/components/ui/Icons";
import { formatDate } from "@/lib/utils";
import type { Report } from "@/types/report";

export function RecentReports({ reports }: { reports: Report[] }) {
  if (reports.length === 0) {
    return (
      <EmptyState
        title="Belum ada laporan"
        description="Belum ada tiket laporan dari pengguna."
        icon={<IconAlertTriangle className="w-6 h-6" />}
      />
    );
  }

  return (
    <ul className="divide-y divide-[#E2E8F0]">
      {reports.map((report) => (
        <li key={report.id}>
          <Link
            href={`/reports/${report.id}`}
            className="block py-3 hover:bg-[#F8FAF9] px-2 rounded-2xl transition-all"
          >
            <div className="flex items-center justify-between gap-3">
              <p className="truncate text-xs font-bold text-[#0F172A]">
                #{report.id} · {report.reporter?.name ?? "Pengguna"} →{" "}
                {report.doctor?.name ?? "Dokter"}
              </p>
              <Badge value={report.status} />
            </div>
            <p className="mt-1 line-clamp-1 text-[11px] text-[#64748B] font-medium">
              {report.description}
            </p>
            <p className="mt-1 text-[10px] text-[#94A3B8] font-semibold">
              {report.category?.name ?? "Pengaduan Layanan"} · {formatDate(report.created_at)}
            </p>
          </Link>
        </li>
      ))}
    </ul>
  );
}
