"use client";

/** Section "Laporan Terbaru" di dashboard. */

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { EmptyState } from "@/components/ui/State";
import { formatDate } from "@/lib/utils";
import type { Report } from "@/types/report";

interface RecentReportsProps {
  reports: Report[];
}

export function RecentReports({ reports }: RecentReportsProps) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div className="flex items-center justify-between border-b border-slate-200 px-5 py-4">
        <h3 className="text-sm font-semibold text-slate-900">Laporan Terbaru</h3>
        <Link href="/reports" className="text-xs font-medium text-primary-600 hover:underline">
          Lihat semua
        </Link>
      </div>

      {reports.length === 0 ? (
        <EmptyState title="Belum ada laporan" description="Belum ada laporan dari user." icon="🚨" />
      ) : (
        <ul className="divide-y divide-slate-100">
          {reports.map((report) => (
            <li key={report.id}>
              <Link
                href={`/reports/${report.id}`}
                className="block px-5 py-3 transition-colors hover:bg-slate-50"
              >
                <div className="flex items-center justify-between gap-3">
                  <p className="truncate text-sm font-medium text-slate-800">
                    #{report.id} · {report.reporter?.name ?? "User"} →{" "}
                    {report.doctor?.name ?? "Dokter"}
                  </p>
                  <Badge value={report.status} />
                </div>
                <p className="mt-0.5 line-clamp-1 text-xs text-slate-500">
                  {report.description}
                </p>
                <p className="mt-1 text-[11px] text-slate-400">
                  {report.category?.name ?? "Tanpa kategori"} · {formatDate(report.created_at)}
                </p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
