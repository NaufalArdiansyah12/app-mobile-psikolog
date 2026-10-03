"use client";

/** Komponen detail profil dokter (dipakai di halaman /doctors/[id]). */

import { Badge } from "@/components/ui/Badge";
import { formatDate, formatDateTime, initials, verificationLabel } from "@/lib/utils";
import type { Doctor } from "@/types/doctor";

function Row({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div className="grid grid-cols-1 gap-1 border-b border-slate-100 py-3 sm:grid-cols-3 sm:gap-4">
      <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
        {label}
      </dt>
      <dd className="text-sm text-slate-800 sm:col-span-2">{value ?? "-"}</dd>
    </div>
  );
}

const DOC_TYPE_LABEL: Record<string, string> = {
  str: "STR",
  sip: "SIP",
  ijazah: "Ijazah",
  sertifikat: "Sertifikat",
  lainnya: "Lainnya",
};

export function DoctorDetail({ doctor }: { doctor: Doctor }) {
  return (
    <div className="space-y-6">
      {/* Kartu profil */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
          <span className="flex h-16 w-16 items-center justify-center rounded-full bg-primary-100 text-xl font-bold text-primary-700">
            {initials(doctor.name)}
          </span>
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-semibold text-slate-900">{doctor.name}</h2>
            <p className="text-sm text-slate-500">{doctor.email}</p>
            <div className="mt-2 flex flex-wrap items-center gap-2">
              <Badge value={doctor.verification_status} />
              <Badge
                label={doctor.is_active ? "Akun Aktif" : "Akun Nonaktif"}
                variant={doctor.is_active ? "success" : "neutral"}
              />
              <span className="text-xs text-slate-400">
                Terdaftar {formatDate(doctor.created_at)}
              </span>
            </div>
          </div>
        </div>

        {doctor.verification_status === "rejected" && doctor.rejection_reason && (
          <div className="mt-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            <span className="font-semibold">Alasan penolakan:</span>{" "}
            {doctor.rejection_reason}
          </div>
        )}
      </div>

      {/* Informasi lengkap */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="mb-2 text-sm font-semibold text-slate-900">
          Informasi Dokter
        </h3>
        <dl className="divide-y divide-slate-100">
          <Row label="Nama Lengkap" value={doctor.name} />
          <Row label="Email" value={doctor.email} />
          <Row label="Nomor Telepon" value={doctor.phone} />
          <Row label="Spesialisasi" value={doctor.specialization} />
          <Row label="Pendidikan" value={doctor.education} />
          <Row label="Pengalaman" value={doctor.experience} />
          <Row
            label="Nomor STR/SIP"
            value={
              doctor.license_number ? (
                <span className="font-mono text-sm">{doctor.license_number}</span>
              ) : (
                "-"
              )
            }
          />
          <Row label="Bio" value={doctor.bio} />
          <Row label="Tanggal Pendaftaran" value={formatDateTime(doctor.created_at)} />
          <Row
            label="Status Verifikasi"
            value={
              <div className="flex flex-wrap items-center gap-2">
                <Badge value={doctor.verification_status} />
                <span className="text-xs text-slate-500">
                  {verificationLabel(doctor.verification_status)}
                </span>
                {doctor.verified_at && (
                  <span className="text-xs text-slate-400">
                    (diperiksa {formatDateTime(doctor.verified_at)})
                  </span>
                )}
              </div>
            }
          />
        </dl>
      </div>

      {/* Dokumen pendukung */}
      <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="mb-4 text-sm font-semibold text-slate-900">
          Dokumen Pendukung
        </h3>

        {doctor.documents.length === 0 ? (
          <p className="text-sm text-slate-500">
            Dokter belum mengunggah dokumen pendukung.
          </p>
        ) : (
          <ul className="space-y-2">
            {doctor.documents.map((doc) => (
              <li
                key={doc.id}
                className="flex flex-col gap-2 rounded-lg border border-slate-200 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
              >
                <div>
                  <p className="text-sm font-medium text-slate-800">
                    {DOC_TYPE_LABEL[doc.document_type] ?? doc.document_type}
                  </p>
                  <p className="truncate font-mono text-xs text-slate-400">
                    {doc.document_path}
                  </p>
                </div>
                <Badge value={doc.verification_status} />
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
