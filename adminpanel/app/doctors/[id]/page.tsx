"use client";

/**
 * Halaman Detail Dokter: /doctors/[id]
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { DoctorDetail } from "@/components/doctors/DoctorDetail";
import { DoctorVerification } from "@/components/doctors/DoctorVerification";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Button } from "@/components/ui/Button";
import { ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { useToast } from "@/components/ui/Toast";
import { apiGet, apiPut, ApiError } from "@/lib/api";
import type { Doctor } from "@/types/doctor";

type VerifyMode = "approve" | "reject" | null;

export default function DoctorDetailPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const toast = useToast();

  const [doctor, setDoctor] = useState<Doctor | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [busy, setBusy] = useState(false);
  const [verifyMode, setVerifyMode] = useState<VerifyMode>(null);
  const [deactivateOpen, setDeactivateOpen] = useState(false);

  const doctorId = Number(params.id);

  const load = useCallback(async () => {
    if (!Number.isFinite(doctorId)) {
      setError("ID dokter tidak valid");
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<Doctor>(`/doctors/${doctorId}`);
      setDoctor(res.data);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal memuat detail dokter");
    } finally {
      setLoading(false);
    }
  }, [doctorId]);

  useEffect(() => {
    load();
  }, [load]);

  const handleApprove = async () => {
    if (!doctor) return;
    setBusy(true);
    try {
      await apiPut(`/doctors/${doctor.id}/approve`);
      toast.success("Dokter berhasil disetujui");
      setVerifyMode(null);
      await load();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Gagal menyetujui dokter");
    } finally {
      setBusy(false);
    }
  };

  const handleReject = async (reason: string) => {
    if (!doctor) return;
    setBusy(true);
    try {
      await apiPut(`/doctors/${doctor.id}/reject`, { reason });
      toast.success("Verifikasi dokter ditolak");
      setVerifyMode(null);
      await load();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Gagal menolak verifikasi");
    } finally {
      setBusy(false);
    }
  };

  const handleToggleActive = async () => {
    if (!doctor) return;
    setBusy(true);
    try {
      const endpoint = doctor.is_active ? "deactivate" : "activate";
      await apiPut(`/doctors/${doctor.id}/${endpoint}`);
      toast.success(doctor.is_active ? "Akun dokter dinonaktifkan" : "Akun dokter diaktifkan");
      setDeactivateOpen(false);
      await load();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Gagal mengubah status aktif");
    } finally {
      setBusy(false);
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <Link
            href="/doctors"
            className="inline-flex items-center gap-1.5 text-xs font-bold text-[#0D9488] hover:underline"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
              <line x1="19" y1="12" x2="5" y2="12" strokeLinecap="round" strokeLinejoin="round" />
              <polyline points="12 19 5 12 12 5" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            Kembali ke daftar dokter
          </Link>

          {doctor && (
            <div className="flex flex-wrap items-center gap-2">
              {doctor.verification_status === "pending" && (
                <>
                  <Button
                    variant="success"
                    size="sm"
                    disabled={busy}
                    onClick={() => setVerifyMode("approve")}
                  >
                    Setujui
                  </Button>
                  <Button
                    variant="danger"
                    size="sm"
                    disabled={busy}
                    onClick={() => setVerifyMode("reject")}
                  >
                    Tolak
                  </Button>
                </>
              )}

              <Button
                variant={doctor.is_active ? "secondary" : "primary"}
                size="sm"
                loading={busy}
                onClick={() => {
                  if (doctor.is_active) {
                    setDeactivateOpen(true);
                  } else {
                    handleToggleActive();
                  }
                }}
              >
                {doctor.is_active ? "Nonaktifkan" : "Aktifkan"}
              </Button>
            </div>
          )}
        </div>

        {loading ? (
          <LoadingState label="Memuat detail dokter..." />
        ) : error || !doctor ? (
          <ErrorState message={error ?? "Dokter tidak ditemukan"} onRetry={load} />
        ) : (
          <DoctorDetail doctor={doctor} />
        )}
      </div>

      {doctor && verifyMode && (
        <DoctorVerification
          mode={verifyMode}
          doctor={doctor}
          loading={busy}
          onCancel={() => setVerifyMode(null)}
          onApprove={handleApprove}
          onReject={handleReject}
        />
      )}

      <ConfirmDialog
        open={deactivateOpen}
        title="Nonaktifkan Dokter"
        message={`Apakah Anda yakin ingin menonaktifkan akun "${doctor?.name ?? ""}"?`}
        confirmLabel="Nonaktifkan"
        loading={busy}
        onCancel={() => setDeactivateOpen(false)}
        onConfirm={handleToggleActive}
      />
    </AdminLayout>
  );
}
