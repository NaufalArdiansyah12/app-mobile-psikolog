"use client";

/**
 * Halaman Semua Dokter: /doctors
 * Fitur: search, filter status, pagination, lihat detail, setujui,
 *        tolak (dengan alasan), aktifkan/nonaktifkan.
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { DoctorTable } from "@/components/doctors/DoctorTable";
import { DoctorVerification } from "@/components/doctors/DoctorVerification";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Button } from "@/components/ui/Button";
import { SearchInput, SelectFilter } from "@/components/ui/Form";
import { Pagination } from "@/components/ui/Pagination";
import { ErrorState, EmptyState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { useToast } from "@/components/ui/Toast";
import { apiGet, apiPut, ApiError } from "@/lib/api";
import { verificationLabel } from "@/lib/utils";
import type { Pagination as PaginationType } from "@/types/common";
import type { Doctor, VerificationStatus } from "@/types/doctor";

type VerifyMode = "approve" | "reject" | null;

export default function DoctorsPage() {
  const toast = useToast();

  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [pagination, setPagination] = useState<PaginationType | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [page, setPage] = useState(1);

  const [busyId, setBusyId] = useState<number | null>(null);
  const [verifyTarget, setVerifyTarget] = useState<Doctor | null>(null);
  const [verifyMode, setVerifyMode] = useState<VerifyMode>(null);
  const [deactivateTarget, setDeactivateTarget] = useState<Doctor | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<Doctor[]>("/doctors", {
        page,
        limit: 10,
        search: search.trim() || undefined,
        status: status || undefined,
      });
      setDoctors(res.data ?? []);
      setPagination(res.pagination ?? null);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal memuat data dokter");
    } finally {
      setLoading(false);
    }
  }, [page, search, status]);

  useEffect(() => {
    load();
  }, [load]);

  // Baca query ?status=pending dari link "Verifikasi Dokter"
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const s = params.get("status");
    if (s) setStatus(s);
  }, []);

  const resetAndSearch = (nextSearch: string) => {
    setSearch(nextSearch);
    setPage(1);
  };

  const changeStatus = (next: string) => {
    setStatus(next);
    setPage(1);
  };

  // --- Aksi ---
  const runAction = async (
    doctor: Doctor,
    action: () => Promise<unknown>,
    successMessage: string
  ) => {
    setBusyId(doctor.id);
    try {
      await action();
      toast.success(successMessage);
      await load();
    } catch (err) {
      toast.error(err instanceof ApiError ? err.message : "Terjadi kesalahan");
    } finally {
      setBusyId(null);
      setVerifyTarget(null);
      setVerifyMode(null);
      setDeactivateTarget(null);
    }
  };

  const handleApprove = (doctor: Doctor) =>
    runAction(doctor, () => apiPut(`/doctors/${doctor.id}/approve`), "Dokter berhasil diverifikasi");

  const handleReject = (doctor: Doctor, reason: string) =>
    runAction(
      doctor,
      () => apiPut(`/doctors/${doctor.id}/reject`, { reason }),
      "Verifikasi dokter ditolak"
    );

  const handleToggleActive = (doctor: Doctor) => {
    if (doctor.is_active) {
      setDeactivateTarget(doctor);
    } else {
      runAction(
        doctor,
        () => apiPut(`/doctors/${doctor.id}/activate`),
        "Akun dokter diaktifkan"
      );
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-4">
        {/* Header + filter */}
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-base font-semibold text-slate-900">Daftar Dokter</h2>
            <p className="text-sm text-slate-500">
              Verifikasi dan kelola akun dokter aplikasi.
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <SearchInput
              value={search}
              onChange={resetAndSearch}
              placeholder="Cari nama/email/spesialisasi..."
            />
            <SelectFilter
              value={status}
              onChange={changeStatus}
              label="Filter status"
              options={[
                { value: "", label: "Semua Status" },
                { value: "pending", label: verificationLabel("pending") },
                { value: "approved", label: verificationLabel("approved") },
                { value: "rejected", label: verificationLabel("rejected") },
              ]}
            />
            <Button variant="secondary" size="sm" onClick={load}>
              Muat Ulang
            </Button>
          </div>
        </div>

        {/* Konten */}
        <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
          {loading ? (
            <LoadingState label="Memuat data dokter..." />
          ) : error ? (
            <div className="p-5">
              <ErrorState message={error} onRetry={load} />
            </div>
          ) : doctors.length === 0 ? (
            <EmptyState
              title="Tidak ada dokter"
              description="Belum ada dokter yang cocok dengan filter Anda."
              action={
                <Link href="/doctors?status=pending">
                  <Button size="sm" variant="secondary">
                    Lihat yang menunggu verifikasi
                  </Button>
                </Link>
              }
            />
          ) : (
            <>
              <DoctorTable
                doctors={doctors}
                busyId={busyId}
                onApprove={(d) => {
                  setVerifyTarget(d);
                  setVerifyMode("approve");
                }}
                onReject={(d) => {
                  setVerifyTarget(d);
                  setVerifyMode("reject");
                }}
                onToggleActive={handleToggleActive}
              />
              <Pagination pagination={pagination} onPageChange={setPage} />
            </>
          )}
        </div>
      </div>

      {/* Modal verifikasi (setujui/tolak) */}
      <DoctorVerification
        doctor={verifyTarget}
        mode={verifyMode}
        loading={busyId !== null}
        onCancel={() => {
          setVerifyTarget(null);
          setVerifyMode(null);
        }}
        onApprove={() => verifyTarget && handleApprove(verifyTarget)}
        onReject={(reason) => verifyTarget && handleReject(verifyTarget, reason)}
      />

      {/* Konfirmasi nonaktifkan */}
      <ConfirmDialog
        open={Boolean(deactivateTarget)}
        title="Nonaktifkan Akun Dokter"
        message={`Apakah Anda yakin ingin menonaktifkan akun ${
          deactivateTarget?.name ?? ""
        }? Dokter tidak akan bisa login sampai akun diaktifkan kembali.`}
        confirmLabel="Nonaktifkan"
        loading={busyId !== null}
        onCancel={() => setDeactivateTarget(null)}
        onConfirm={async () => {
          if (!deactivateTarget) return;
          await runAction(
            deactivateTarget,
            () => apiPut(`/doctors/${deactivateTarget.id}/deactivate`),
            "Akun dokter dinonaktifkan"
          );
        }}
      />
    </AdminLayout>
  );
}
