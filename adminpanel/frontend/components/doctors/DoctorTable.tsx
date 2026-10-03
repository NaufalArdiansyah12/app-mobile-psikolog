"use client";

/** Tabel daftar dokter dengan kolom, badge status, dan aksi admin. */

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/State";
import { formatDate, initials } from "@/lib/utils";
import type { Doctor } from "@/types/doctor";

interface DoctorTableProps {
  doctors: Doctor[];
  busyId: number | null;
  onApprove: (doctor: Doctor) => void;
  onReject: (doctor: Doctor) => void;
  onToggleActive: (doctor: Doctor) => void;
}

export function DoctorTable({
  doctors,
  busyId,
  onApprove,
  onReject,
  onToggleActive,
}: DoctorTableProps) {
  if (doctors.length === 0) {
    return (
      <EmptyState
        title="Tidak ada dokter ditemukan"
        description="Coba ubah kata kunci pencarian atau filter status."
        icon="🩺"
      />
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50">
          <tr>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Foto
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Nama
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Spesialisasi
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              No. STR/SIP
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Status
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Tanggal Daftar
            </th>
            <th className="px-4 py-3 text-right text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Action
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100 bg-white">
          {doctors.map((doctor) => {
            const busy = busyId === doctor.id;
            return (
              <tr key={doctor.id} className="transition-colors hover:bg-slate-50/70">
                <td className="px-4 py-3">
                  <span className="flex h-9 w-9 items-center justify-center rounded-full bg-primary-100 text-xs font-semibold text-primary-700">
                    {initials(doctor.name)}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <Link
                    href={`/doctors/${doctor.id}`}
                    className="font-medium text-slate-800 hover:text-primary-600 hover:underline"
                  >
                    {doctor.name}
                  </Link>
                  <p className="text-xs text-slate-500">{doctor.email}</p>
                  {!doctor.is_active && (
                    <span className="text-[11px] font-medium text-red-500">
                      (akun nonaktif)
                    </span>
                  )}
                </td>
                <td className="px-4 py-3 text-slate-600">
                  {doctor.specialization || "-"}
                </td>
                <td className="px-4 py-3 font-mono text-xs text-slate-600">
                  {doctor.license_number || "-"}
                </td>
                <td className="px-4 py-3">
                  <Badge value={doctor.verification_status} />
                </td>
                <td className="px-4 py-3 text-slate-600">
                  {formatDate(doctor.created_at)}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap items-center justify-end gap-1.5">
                    <Link href={`/doctors/${doctor.id}`}>
                      <Button size="sm" variant="secondary">
                        Detail
                      </Button>
                    </Link>

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
                          disabled={busy}
                          onClick={() => onReject(doctor)}
                        >
                          Tolak
                        </Button>
                      </>
                    )}

                    {doctor.verification_status === "approved" && (
                      <Button
                        size="sm"
                        variant={doctor.is_active ? "secondary" : "success"}
                        loading={busy}
                        onClick={() => onToggleActive(doctor)}
                      >
                        {doctor.is_active ? "Nonaktifkan" : "Aktifkan"}
                      </Button>
                    )}
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
