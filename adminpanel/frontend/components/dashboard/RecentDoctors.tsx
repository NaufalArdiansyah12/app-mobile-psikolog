"use client";

/** Section "Dokter Terbaru" di dashboard. */

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { EmptyState } from "@/components/ui/State";
import { formatDate, initials } from "@/lib/utils";
import type { Doctor } from "@/types/doctor";

interface RecentDoctorsProps {
  doctors: Doctor[];
}

export function RecentDoctors({ doctors }: RecentDoctorsProps) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div className="flex items-center justify-between border-b border-slate-200 px-5 py-4">
        <h3 className="text-sm font-semibold text-slate-900">Dokter Terbaru</h3>
        <Link href="/doctors" className="text-xs font-medium text-primary-600 hover:underline">
          Lihat semua
        </Link>
      </div>

      {doctors.length === 0 ? (
        <EmptyState title="Belum ada dokter" description="Belum ada dokter yang mendaftar." icon="🩺" />
      ) : (
        <ul className="divide-y divide-slate-100">
          {doctors.map((doc) => (
            <li key={doc.id}>
              <Link
                href={`/doctors/${doc.id}`}
                className="flex items-center gap-3 px-5 py-3 transition-colors hover:bg-slate-50"
              >
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-slate-200 text-xs font-semibold text-slate-600">
                  {initials(doc.name)}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-sm font-medium text-slate-800">
                    {doc.name}
                  </span>
                  <span className="block truncate text-xs text-slate-500">
                    {doc.specialization || "-"} · {formatDate(doc.created_at)}
                  </span>
                </span>
                <Badge value={doc.verification_status} />
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
