"use client";

/**
 * Modal verifikasi dokter:
 * - Setujui (konfirmasi)
 * - Tolak (WAJIB mengisi alasan penolakan)
 */

import { useEffect, useState } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { FieldLabel, TextArea } from "@/components/ui/Form";
import type { Doctor } from "@/types/doctor";

interface DoctorVerificationProps {
  doctor: Doctor | null;
  mode: "approve" | "reject" | null;
  loading: boolean;
  onCancel: () => void;
  onApprove: () => void;
  onReject: (reason: string) => void;
}

export function DoctorVerification({
  doctor,
  mode,
  loading,
  onCancel,
  onApprove,
  onReject,
}: DoctorVerificationProps) {
  const [reason, setReason] = useState("");
  const [error, setError] = useState<string | null>(null);

  // Reset alasan setiap kali modal dibuka
  useEffect(() => {
    if (mode) {
      setReason("");
      setError(null);
    }
  }, [mode, doctor?.id]);

  if (!doctor || !mode) return null;

  const handleReject = () => {
    if (reason.trim().length < 5) {
      setError("Alasan penolakan wajib diisi (minimal 5 karakter).");
      return;
    }
    onReject(reason.trim());
  };

  if (mode === "approve") {
    return (
      <Modal
        open
        onClose={onCancel}
        title="Setujui Verifikasi Dokter"
        contentClassName="max-w-md"
      >
        <p className="text-sm leading-6 text-slate-600">
          Setujui verifikasi untuk{" "}
          <span className="font-semibold text-slate-900">{doctor.name}</span>?
          Dokter akan mendapat akses penuh ke fitur dokter setelah disetujui.
        </p>
        <div className="mt-6 flex justify-end gap-2">
          <Button variant="secondary" onClick={onCancel} disabled={loading}>
            Batal
          </Button>
          <Button variant="success" loading={loading} onClick={onApprove}>
            Setujui Sekarang
          </Button>
        </div>
      </Modal>
    );
  }

  return (
    <Modal open onClose={onCancel} title="Tolak Verifikasi Dokter" contentClassName="max-w-md">
      <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
        Anda menolak pendaftaran{" "}
        <span className="font-semibold">{doctor.name}</span>. Alasan wajib diisi
        dan akan dikirim ke dokter.
      </div>

      <FieldLabel required htmlFor="rejection-reason">
        Alasan Penolakan
      </FieldLabel>
      <TextArea
        id="rejection-reason"
        rows={4}
        value={reason}
        onChange={(e) => {
          setReason(e.target.value);
          if (error) setError(null);
        }}
        placeholder="Contoh: Nomor SIP tidak dapat diverifikasi dan dokumen ijazah tidak terbaca."
        className={error ? "border-red-500 focus:border-red-500 focus:ring-red-200" : ""}
      />
      {error && <p className="mt-1.5 text-xs text-red-500">{error}</p>}

      <div className="mt-6 flex justify-end gap-2">
        <Button variant="secondary" onClick={onCancel} disabled={loading}>
          Batal
        </Button>
        <Button variant="danger" loading={loading} onClick={handleReject}>
          Tolak Pendaftaran
        </Button>
      </div>
    </Modal>
  );
}
