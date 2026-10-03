"use client";

/** Tabel daftar dokter dengan estetika MindPal. */

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/State";
import { IconDoctor } from "@/components/ui/Icons";
import { formatDate, initials } from "@/lib/utils";
import type { Doctor } from "@/types/doctor";

interface DoctorTableProps {
  doctors: Doctor[];
  busyId: number | null;
  onDetail: (doctor: Doctor) => void;
  onApprove: (doctor: Doctor) => void;
  onReject: (doctor: Doctor) => void;
  onToggleActive: (doctor: Doctor) => void;
}

export function DoctorTable({
  doctors,
  busyId,
  onDetail,
  onApprove,
  onReject,
  onToggleActive,
}: DoctorTableProps) {
  if (doctors.length === 0) {
    return (
      <EmptyState
        title="Tidak ada dokter ditemukan"
        description="Coba ubah kata kunci pencarian atau filter status."
        icon={<IconDoctor className="w-6 h-6" />}
      />
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-[#E2E8F0] text-xs">
        <thead>
          <tr className="border-b border-[#E2E8F0] bg-[#F8FAF9]/80 text-[#64748B]">
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Dokter
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Spesialisasi
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              No. STR/SIP
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Status STR
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Terdaftar
            </th>
            <th className="px-4 py-3 text-right font-bold uppercase tracking-wider">
              Aksi
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-[#E2E8F0] bg-white">
          {doctors.map((doctor) => {
            const busy = busyId === doctor.id;
            return (
              <tr key={doctor.id} className="transition-colors hover:bg-[#F8FAF9]/70">
                <td className="px-4 py-3.5">
                  <div className="flex items-center gap-3">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-[#CCFBF1] text-xs font-bold text-[#0D9488] shadow-2xs">
                      {initials(doctor.name)}
                    </div>
                    <div>
                      <button
                        type="button"
                        onClick={() => onDetail(doctor)}
                        className="text-left font-bold text-[#0F172A] hover:text-[#0D9488] transition-colors cursor-pointer"
                      >
                        {doctor.name}
                      </button>
                      <p className="text-[11px] text-[#64748B] font-medium">{doctor.email}</p>
                      {!doctor.is_active && (
                        <span className="text-[10px] font-bold text-rose-500">
                          (akun nonaktif)
                        </span>
                      )}
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3.5 font-semibold text-[#0F172A]">
                  {doctor.specialization || "Psikolog Klinis"}
                </td>
                <td className="px-4 py-3.5 font-mono text-[11px] text-[#64748B] font-semibold">
                  {doctor.license_number || "-"}
                </td>
                <td className="px-4 py-3.5">
                  <Badge value={doctor.verification_status} />
                </td>
                <td className="px-4 py-3.5 text-[#64748B] font-medium">
                  {formatDate(doctor.created_at)}
                </td>
                <td className="px-4 py-3.5 text-right">
                  <div className="flex flex-wrap items-center justify-end gap-1.5">
                    <Button size="sm" variant="secondary" onClick={() => onDetail(doctor)}>
                      Detail
                    </Button>

                    {doctor.verification_status === "pending" && (
                      <>
                        <Button
                          size="sm"
                          variant="success"
                          loading={busy}
                          onClick={() => onApprove(doctor)}
                        >
                          Setujui
                        </Button>
                        <Button
                          size="sm"
                          variant="danger"
                          loading={busy}
                          onClick={() => onReject(doctor)}
                        >
                          Tolak
                        </Button>
                      </>
                    )}

                    <Button
                      size="sm"
                      variant={doctor.is_active ? "ghost" : "primary"}
                      loading={busy}
                      onClick={() => onToggleActive(doctor)}
                    >
                      {doctor.is_active ? "Nonaktifkan" : "Aktifkan"}
                    </Button>
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
