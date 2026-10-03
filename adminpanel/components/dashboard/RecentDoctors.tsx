"use client";

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { EmptyState } from "@/components/ui/State";
import { IconDoctor } from "@/components/ui/Icons";
import { formatDate, initials } from "@/lib/utils";
import type { Doctor } from "@/types/doctor";

export function RecentDoctors({ doctors }: { doctors: Doctor[] }) {
  if (doctors.length === 0) {
    return (
      <EmptyState
        title="Belum ada dokter"
        description="Belum ada dokter yang mendaftar di sistem."
        icon={<IconDoctor className="w-6 h-6" />}
      />
    );
  }

  return (
    <ul className="divide-y divide-[#E2E8F0]">
      {doctors.map((doc) => (
        <li key={doc.id}>
          <Link
            href={`/doctors/${doc.id}`}
            className="flex items-center gap-3.5 py-3 hover:bg-[#F8FAF9] px-2 rounded-2xl transition-all"
          >
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-[#CCFBF1] text-xs font-bold text-[#0D9488] shadow-2xs">
              {initials(doc.name)}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-bold text-[#0F172A]">
                {doc.name}
              </p>
              <p className="truncate text-[11px] text-[#64748B] font-medium mt-0.5">
                {doc.specialization || "Psikolog Klinis"} · {formatDate(doc.created_at)}
              </p>
            </div>
            <Badge value={doc.verification_status} />
          </Link>
        </li>
      ))}
    </ul>
  );
}
