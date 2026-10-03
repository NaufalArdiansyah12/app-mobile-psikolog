"use client";

/**
 * Halaman Semua Dokter: /doctors
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { DoctorTable } from "@/components/doctors/DoctorTable";
import { DoctorVerification } from "@/components/doctors/DoctorVerification";
import { DoctorCreateModal } from "@/components/doctors/DoctorCreateModal";
import { DoctorDetailModal } from "@/components/doctors/DoctorDetailModal";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Button } from "@/components/ui/Button";
import { SearchInput, SelectFilter } from "@/components/ui/Form";
import { Pagination } from "@/components/ui/Pagination";
import { ErrorState, EmptyState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { IconDoctor } from "@/components/ui/Icons";
import { useToast } from "@/components/ui/Toast";
import { apiGet, apiPut, ApiError } from "@/lib/api";
import { verificationLabel } from "@/lib/utils";
import type { Pagination as PaginationType } from "@/types/common";
import type { Doctor } from "@/types/doctor";

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
  const [detailDoctor, setDetailDoctor] = useState<Doctor | null>(null);
  const [createModalOpen, setCreateModalOpen] = useState(false);
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
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between bg-white rounded-[24px] p-5 border border-[#E2E8F0] shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
          <div>
            <h2 className="text-base font-extrabold text-[#0F172A] tracking-tight">Daftar Dokter</h2>
            <p className="text-xs text-[#64748B] font-medium">
              Verifikasi STR dan kelola akun profesional kesehatan mental.
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
            <Button size="sm" onClick={() => setCreateModalOpen(true)}>
              + Tambah Dokter
            </Button>
          </div>
        </div>

        {/* Konten */}
        <div className="overflow-hidden rounded-[24px] border border-[#E2E8F0] bg-white shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
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
              icon={<IconDoctor className="w-6 h-6" />}
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
                onDetail={(d) => setDetailDoctor(d)}
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

      {/* Modal verifikasi / penolakan */}
      {verifyTarget && verifyMode && (
        <DoctorVerification
          mode={verifyMode}
          doctor={verifyTarget}
          loading={busyId !== null}
          onCancel={() => {
            setVerifyTarget(null);
            setVerifyMode(null);
          }}
          onApprove={() => handleApprove(verifyTarget)}
          onReject={(reason) => handleReject(verifyTarget, reason)}
        />
      )}

      {/* Modal Tambah Dokter Baru & Akun Login */}
      <DoctorCreateModal
        open={createModalOpen}
        onClose={() => setCreateModalOpen(false)}
        onSuccess={async () => {
          setCreateModalOpen(false);
          toast.success("Dokter dan akun login berhasil ditambahkan");
          await load();
        }}
      />

      {/* Modal Detail Profil & Akun Dokter */}
      <DoctorDetailModal
        doctor={detailDoctor}
        open={Boolean(detailDoctor)}
        onClose={() => setDetailDoctor(null)}
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

      {/* Konfirmasi nonaktifkan */}
      <ConfirmDialog
        open={Boolean(deactivateTarget)}
        title="Nonaktifkan Dokter"
        message={`Apakah Anda yakin ingin menonaktifkan akun dokter "${
          deactivateTarget?.name ?? ""
        }"? Dokter tidak akan tampil di aplikasi user.`}
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
