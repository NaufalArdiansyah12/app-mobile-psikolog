"use client";

/**
 * Detail laporan + form pengubahan status oleh admin.
 * CATATAN: dokter TIDAK otomatis dihukum - admin review dulu sebelum
 * mengubah status; tidak ada aksi otomatis ke akun dokter.
 */

import { useEffect, useState, type FormEvent } from "react";
import Link from "next/link";
import Image from "next/image";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { FieldLabel, TextArea } from "@/components/ui/Form";
import { assetUrl, formatDateTime, reportStatusLabel } from "@/lib/utils";
import type { Report, ReportStatus } from "@/types/report";

const STATUS_OPTIONS: { value: ReportStatus; label: string }[] = [
  { value: "pending", label: "Pending (belum ditangani)" },
  { value: "reviewing", label: "Reviewing (sedang direview)" },
  { value: "resolved", label: "Resolved (selesai)" },
  { value: "rejected", label: "Rejected (ditolak)" },
];

interface ReportDetailProps {
  report: Report;
  saving: boolean;
  onSave: (status: ReportStatus, adminNote: string) => void | Promise<void>;
}

export function ReportDetail({ report, saving, onSave }: ReportDetailProps) {
  const [status, setStatus] = useState<ReportStatus>(report.status);
  const [adminNote, setAdminNote] = useState(report.admin_note ?? "");

  // Sinkron saat data report berubah dari luar
  useEffect(() => {
    setStatus(report.status);
    setAdminNote(report.admin_note ?? "");
  }, [report]);

  const dirty = status !== report.status || adminNote !== (report.admin_note ?? "");

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!dirty) return;
    void onSave(status, adminNote.trim());
  };

  return (
    <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
      {/* Kolom kiri: isi laporan */}
      <div className="space-y-4 xl:col-span-2">
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
            <h3 className="text-sm font-semibold text-slate-900">
              Laporan #{report.id}
            </h3>
            <Badge value={report.status} label={reportStatusLabel(report.status)} />
          </div>

          <dl className="divide-y divide-slate-100">
            <div className="grid grid-cols-1 gap-1 py-3 sm:grid-cols-3 sm:gap-4">
              <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                Pelapor
              </dt>
              <dd className="sm:col-span-2">
                <p className="text-sm font-medium text-slate-800">
                  {report.reporter?.name ?? "-"}
                </p>
                <p className="text-xs text-slate-500">
                  {report.reporter?.email} · {report.reporter?.phone}
                </p>
              </dd>
            </div>

            <div className="grid grid-cols-1 gap-1 py-3 sm:grid-cols-3 sm:gap-4">
              <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                Dokter Dilaporkan
              </dt>
              <dd className="sm:col-span-2">
                <Link
                  href={`/doctors/${report.doctor_id}`}
                  className="text-sm font-medium text-primary-600 hover:underline"
                >
                  {report.doctor?.name ?? "-"}
                </Link>
                <p className="text-xs text-slate-500">
                  {report.doctor?.specialization} · STR: {report.doctor?.license_number}
                </p>
              </dd>
            </div>

            <div className="grid grid-cols-1 gap-1 py-3 sm:grid-cols-3 sm:gap-4">
              <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                Kategori
              </dt>
              <dd className="text-sm text-slate-800 sm:col-span-2">
                {report.category?.name ?? "Tanpa kategori"}
              </dd>
            </div>

            <div className="grid grid-cols-1 gap-1 py-3 sm:grid-cols-3 sm:gap-4">
              <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                Deskripsi
              </dt>
              <dd className="text-sm leading-6 whitespace-pre-wrap text-slate-800 sm:col-span-2">
                {report.description}
              </dd>
            </div>

            <div className="grid grid-cols-1 gap-1 py-3 sm:grid-cols-3 sm:gap-4">
              <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                Bukti
              </dt>
              <dd className="sm:col-span-2">
                {report.evidence ? (
                  <a
                    href={assetUrl(report.evidence)}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-block"
                  >
                    <span className="relative block h-40 w-64 overflow-hidden rounded-lg border border-slate-200">
                      <Image
                        src={assetUrl(report.evidence)}
                        alt="Bukti laporan"
                        fill
                        unoptimized
                        className="object-cover"
                      />
                    </span>
                  </a>
                ) : (
                  <span className="text-sm text-slate-500">
                    Tidak ada bukti diunggah
                  </span>
                )}
              </dd>
            </div>

            <div className="grid grid-cols-1 gap-1 py-3 sm:grid-cols-3 sm:gap-4">
              <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                Tanggal Laporan
              </dt>
              <dd className="text-sm text-slate-800 sm:col-span-2">
                {formatDateTime(report.created_at)}
              </dd>
            </div>

            <div className="grid grid-cols-1 gap-1 py-3 sm:grid-cols-3 sm:gap-4">
              <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                Terakhir Diperbarui
              </dt>
              <dd className="text-sm text-slate-800 sm:col-span-2">
                {formatDateTime(report.updated_at)}
              </dd>
            </div>

            {report.resolved_at && (
              <div className="grid grid-cols-1 gap-1 py-3 sm:grid-cols-3 sm:gap-4">
                <dt className="text-xs font-medium tracking-wide text-slate-500 uppercase">
                  Selesai Pada
                </dt>
                <dd className="text-sm text-slate-800 sm:col-span-2">
                  {formatDateTime(report.resolved_at)}
                </dd>
              </div>
            )}
          </dl>
        </div>
      </div>

      {/* Kolom kanan: ubah status */}
      <form onSubmit={handleSubmit} className="h-fit rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h3 className="mb-4 text-sm font-semibold text-slate-900">
          Proses Laporan
        </h3>

        <div className="mb-4 rounded-lg border border-primary-200 bg-primary-50 px-4 py-3 text-xs leading-5 text-primary-700">
          Admin meninjau laporan terlebih dahulu. Mengubah status laporan{" "}
          <strong>tidak otomatis menghukum dokter</strong> - keputusan tindakan
          lebih lanjut tetap melalui review admin.
        </div>

        <div className="mb-4">
          <FieldLabel htmlFor="report-status" required>
            Status Laporan
          </FieldLabel>
          <select
            id="report-status"
            value={status}
            onChange={(e) => setStatus(e.target.value as ReportStatus)}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 focus:border-primary-500 focus:ring-2 focus:ring-primary-100 focus:outline-none"
          >
            {STATUS_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        </div>

        <div className="mb-5">
          <FieldLabel htmlFor="admin-note">Catatan Admin</FieldLabel>
          <TextArea
            id="admin-note"
            rows={5}
            value={adminNote}
            onChange={(e) => setAdminNote(e.target.value)}
            placeholder="Catatan internal / hasil review, mis. 'Sedang dikonfirmasi ke dokter.'"
            maxLength={2000}
          />
        </div>

        <div className="flex items-center justify-between gap-2 border-t border-slate-100 pt-4">
          <span className="text-xs text-slate-400">
            Status saat ini: {reportStatusLabel(report.status)}
          </span>
          <Button type="submit" loading={saving} disabled={!dirty}>
            Simpan Status
          </Button>
        </div>
      </form>
    </div>
  );
}
