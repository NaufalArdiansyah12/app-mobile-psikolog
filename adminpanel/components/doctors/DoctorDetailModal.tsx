"use client";

/**
 * Modal Detail Dokter (Bento Style MindPal):
 * Menampilkan seluruh data profil dokter, akun login, STR, dan dokumen dalam format modal dialog.
 */

import { Modal } from "@/components/ui/Modal";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { IconDoctor, IconCheck, IconClose } from "@/components/ui/Icons";
import { formatDateTime, initials, verificationLabel } from "@/lib/utils";
import type { Doctor } from "@/types/doctor";

interface DoctorDetailModalProps {
  doctor: Doctor | null;
  open: boolean;
  onClose: () => void;
  onApprove?: (doctor: Doctor) => void;
  onReject?: (doctor: Doctor) => void;
  onToggleActive?: (doctor: Doctor) => void;
}

function DetailRow({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div className="grid grid-cols-1 gap-1 border-b border-[#E2E8F0] py-2.5 sm:grid-cols-3 sm:gap-4">
      <dt className="text-[11px] font-bold tracking-wide text-[#64748B] uppercase">
        {label}
      </dt>
      <dd className="text-xs font-semibold text-[#0F172A] sm:col-span-2">{value ?? "-"}</dd>
    </div>
  );
}

const DOC_TYPE_LABEL: Record<string, string> = {
  str: "Surat Tanda Registrasi (STR)",
  sip: "Surat Izin Praktik (SIP)",
  ijazah: "Ijazah Pendidikan",
  sertifikat: "Sertifikat Keahlian / Pelatihan",
  lainnya: "Dokumen Lainnya",
};

export function DoctorDetailModal({
  doctor,
  open,
  onClose,
  onApprove,
  onReject,
  onToggleActive,
}: DoctorDetailModalProps) {
  if (!open || !doctor) return null;

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Detail Profil & Akun Dokter"
      contentClassName="max-w-2xl"
    >
      <div className="space-y-5">
        {/* Header Profile Card */}
        <div className="rounded-2xl border border-[#99F6E4] bg-[#F0FDFA] p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center gap-4">
          <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-[#0D9488] text-base font-extrabold text-white shadow-xs">
            {initials(doctor.name)}
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <h3 className="text-base font-extrabold text-[#0F172A] tracking-tight">
                {doctor.name}
              </h3>
              <Badge value={doctor.verification_status} />
              <span
                className={`rounded-full px-2 py-0.5 text-[10px] font-bold ${
                  doctor.is_active
                    ? "bg-emerald-100 text-emerald-800"
                    : "bg-slate-100 text-slate-600"
                }`}
              >
                {doctor.is_active ? "Akun Aktif" : "Akun Nonaktif"}
              </span>
            </div>
            <p className="text-xs font-semibold text-[#0D9488] mt-0.5">
              {doctor.specialization || "Psikolog Klinis"}
            </p>
            <p className="text-[11px] text-[#64748B] font-medium mt-0.5">
              Email: {doctor.email} · Telp: {doctor.phone || "-"}
            </p>
          </div>
        </div>

        {/* Rejection Reason Alert if rejected */}
        {doctor.verification_status === "rejected" && doctor.rejection_reason && (
          <div className="rounded-2xl border border-rose-200 bg-rose-50 p-3.5 text-xs text-rose-700">
            <span className="font-bold">Alasan Penolakan STR: </span>
            {doctor.rejection_reason}
          </div>
        )}

        {/* Informasi Praktik & Akun */}
        <div className="rounded-2xl border border-[#E2E8F0] bg-white p-4 sm:p-5">
          <h4 className="text-xs font-extrabold uppercase tracking-wider text-[#0F172A] mb-2">
            Data Legalitas & Praktik
          </h4>
          <dl className="divide-y divide-[#E2E8F0]">
            <DetailRow label="ID Dokter / User ID" value={`#${doctor.id} (User #${doctor.user_id})`} />
            <DetailRow
              label="Nomor STR / SIP"
              value={
                doctor.license_number ? (
                  <span className="font-mono text-xs font-bold text-[#0D9488]">
                    {doctor.license_number}
                  </span>
                ) : (
                  "-"
                )
              }
            />
            <DetailRow label="Pendidikan Terakhir" value={doctor.education} />
            <DetailRow label="Pengalaman Praktik" value={doctor.experience} />
            <DetailRow
              label="Bio & Pendekatan"
              value={
                <p className="leading-relaxed whitespace-pre-wrap text-xs text-[#0F172A]">
                  {doctor.bio || "Belum ada biografi singkat."}
                </p>
              }
            />
            <DetailRow
              label="Status STR"
              value={
                <div className="flex items-center gap-2">
                  <span className="font-bold text-xs text-[#0F172A]">
                    {verificationLabel(doctor.verification_status)}
                  </span>
                  {doctor.verified_at && (
                    <span className="text-[10px] text-[#64748B]">
                      (Diverifikasi pada {formatDateTime(doctor.verified_at)})
                    </span>
                  )}
                </div>
              }
            />
            <DetailRow
              label="Terdaftar Sejak"
              value={formatDateTime(doctor.created_at)}
            />
          </dl>
        </div>

        {/* Dokumen Pendukung */}
        <div className="rounded-2xl border border-[#E2E8F0] bg-[#F8FAF9]/70 p-4 sm:p-5">
          <h4 className="text-xs font-extrabold uppercase tracking-wider text-[#0F172A] mb-3">
            Berkas & Dokumen STR
          </h4>

          {doctor.documents && doctor.documents.length > 0 ? (
            <ul className="space-y-2">
              {doctor.documents.map((doc) => (
                <li
                  key={doc.id}
                  className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 bg-white rounded-xl border border-[#E2E8F0] p-3 shadow-2xs"
                >
                  <div>
                    <p className="text-xs font-bold text-[#0F172A]">
                      {DOC_TYPE_LABEL[doc.document_type] ?? doc.document_type}
                    </p>
                    <p className="text-[11px] font-mono text-[#64748B] truncate max-w-sm">
                      {doc.document_path}
                    </p>
                  </div>
                  <Badge value={doc.verification_status} />
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-xs text-[#64748B] font-medium">
              Tidak ada dokumen lampiran yang diunggah.
            </p>
          )}
        </div>

        {/* Actions inside Modal */}
        <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-[#E2E8F0]">
          <div className="flex items-center gap-2">
            {doctor.verification_status === "pending" && onApprove && onReject && (
              <>
                <Button
                  size="sm"
                  variant="success"
                  onClick={() => {
                    onClose();
                    onApprove(doctor);
                  }}
                >
                  <IconCheck className="w-3.5 h-3.5 mr-1" />
                  Setujui Verifikasi
                </Button>
                <Button
                  size="sm"
                  variant="danger"
                  onClick={() => {
                    onClose();
                    onReject(doctor);
                  }}
                >
                  <IconClose className="w-3.5 h-3.5 mr-1" />
                  Tolak
                </Button>
              </>
            )}

            {onToggleActive && (
              <Button
                size="sm"
                variant={doctor.is_active ? "secondary" : "primary"}
                onClick={() => {
                  onClose();
                  onToggleActive(doctor);
                }}
              >
                {doctor.is_active ? "Nonaktifkan Akun" : "Aktifkan Akun"}
              </Button>
            )}
          </div>

          <Button variant="secondary" size="sm" onClick={onClose}>
            Tutup
          </Button>
        </div>
      </div>
    </Modal>
  );
}
