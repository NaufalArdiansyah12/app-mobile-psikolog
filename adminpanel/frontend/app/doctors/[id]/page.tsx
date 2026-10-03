"use client";

/**
 * Halaman Detail Dokter: /doctors/[id]
 * Menampilkan info lengkap + aksi: Setujui, Tolak, Nonaktifkan/Aktifkan.
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
      setError(err instanceof ApiError ? err.message : "Gagal memuat data dokter");
    } finally {
      setLoading(false);
    }
  }, [doctorId]);

  useEffect(() => {
    load();
  }, [load]);

  const runAction = async (
    action: () => Promise<unknown>,
    successMessage: string
  ) => {
    setBusy(true);
    try {
      await action();
      toast.success(successMessage);
      setVerifyMode(null);
      setDeactivateOpen(false);
      await load();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Terjadi kesalahan");
    } finally {
      setBusy(false);
    }
  };

  return (
    <AdminLayout>
      <div className="mb-4 flex items-center justify-between gap-3">
        <Link
          href="/doctors"
          className="text-sm font-medium text-primary-600 hover:underline"
        >
          ← Kembali ke daftar dokter
        </Link>
      </div>

      {loading ? (
        <LoadingState label="Memuat detail dokter..." />
      ) : error || !doctor ? (
        <ErrorState message={error ?? "Dokter tidak ditemukan"} onRetry={load} />
      ) : (
        <div className="space-y-4">
          {/* Aksi admin */}
          <div className="flex flex-wrap items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-sm">
            <span className="mr-2 text-sm font-medium text-slate-600">Aksi:</span>

            {doctor.verification_status === "pending" && (
              <>
                <Button
                  size="sm"
                  variant="success"
                  loading={busy}
                  onClick={() => setVerifyMode("approve")}
                >
                  ✅ Setujui
                </Button>
                <Button
                  size="sm"
                  variant="danger"
                  disabled={busy}
                  onClick={() => setVerifyMode("reject")}
                >
                  ⛔ Tolak
                </Button>
              </>
            )}

            <Button
              size="sm"
              variant={doctor.is_active ? "secondary" : "success"}
              loading={busy}
              onClick={() =>
                doctor.is_active
                  ? setDeactivateOpen(true)
                  : runAction(
                      () => apiPut(`/doctors/${doctor.id}/activate`),
                      "Akun dokter diaktifkan"
                    )
              }
            >
              {doctor.is_active ? "⏸ Nonaktifkan" : "▶ Aktifkan"}
            </Button>
          </div>

          <DoctorDetail doctor={doctor} />
        </div>
      )}

      {/* Modal verifikasi */}
      <DoctorVerification
        doctor={doctor}
        mode={verifyMode}
        loading={busy}
        onCancel={() => setVerifyMode(null)}
        onApprove={() =>
          runAction(() => apiPut(`/doctors/${doctorId}/approve`), "Dokter berhasil diverifikasi")
        }
        onReject={(reason) =>
          runAction(
            () => apiPut(`/doctors/${doctorId}/reject`, { reason }),
            "Verifikasi dokter ditolak"
          )
        }
      />

      {/* Konfirmasi nonaktifkan */}
      <ConfirmDialog
        open={deactivateOpen}
        title="Nonaktifkan Akun Dokter"
        message={`Apakah Anda yakin ingin menonaktifkan akun ${
          doctor?.name ?? ""
        }? Dokter tidak akan bisa login sampai diaktifkan kembali.`}
        confirmLabel="Nonaktifkan"
        loading={busy}
        onCancel={() => setDeactivateOpen(false)}
        onConfirm={() =>
          runAction(
            () => apiPut(`/doctors/${doctorId}/deactivate`),
            "Akun dokter dinonaktifkan"
          )
        }
      />
    </AdminLayout>
  );
}
