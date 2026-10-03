"use client";

/**
 * Modal Tambah Dokter Baru:
 * Sekaligus membuat akun login dokter (email & password) dan profil medisnya.
 */

import { useState, type FormEvent } from "react";
import { Modal } from "@/components/ui/Modal";
import { Button } from "@/components/ui/Button";
import { FieldLabel, TextArea, TextInput } from "@/components/ui/Form";
import { IconAlertTriangle, IconDoctor } from "@/components/ui/Icons";
import { apiPost, ApiError } from "@/lib/api";
import type { DoctorCreateInput, VerificationStatus } from "@/types/doctor";

interface DoctorCreateModalProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

const SPECIALIZATION_PRESETS = [
  "Psikolog Klinis Dewasa",
  "Psikolog Anak & Remaja",
  "Psikiater (Sp.KJ)",
  "Psikolog Klinis & Konselor Pernikahan",
  "Konselor Pendidikan & Karir",
  "Psikolog Industri & Organisasi",
];

export function DoctorCreateModal({ open, onClose, onSuccess }: DoctorCreateModalProps) {
  const [form, setForm] = useState<DoctorCreateInput>({
    name: "",
    email: "",
    password: "",
    phone: "",
    specialization: "Psikolog Klinis Dewasa",
    license_number: "",
    education: "",
    experience: "3 Tahun",
    bio: "",
    verification_status: "approved",
    is_active: true,
  });

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!open) return null;

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validasi sederhana
    if (!form.name.trim()) {
      setError("Nama lengkap dokter wajib diisi");
      return;
    }
    if (!form.email.trim() || !form.email.includes("@")) {
      setError("Email dokter tidak valid");
      return;
    }
    if (!form.password || form.password.length < 6) {
      setError("Kata sandi akun minimal 6 karakter");
      return;
    }

    setLoading(true);
    try {
      await apiPost("/doctors", {
        name: form.name.trim(),
        email: form.email.trim().toLowerCase(),
        password: form.password,
        phone: form.phone?.trim() || null,
        specialization: form.specialization.trim(),
        license_number: form.license_number?.trim() || null,
        education: form.education?.trim() || null,
        experience: form.experience?.trim() || null,
        bio: form.bio?.trim() || null,
        verification_status: form.verification_status,
        is_active: form.is_active,
      });

      onSuccess();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal menambahkan dokter baru");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal open={open} onClose={onClose} title="Tambah Dokter & Buat Akun Baru" contentClassName="max-w-2xl">
      <form onSubmit={handleSubmit} className="space-y-6">
        {error && (
          <div className="rounded-2xl border border-rose-200 bg-rose-50/90 p-3.5 text-xs font-bold text-rose-600 flex items-center gap-2">
            <IconAlertTriangle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Section 1: Akun & Login */}
        <div className="rounded-2xl border border-[#E2E8F0] bg-[#F8FAF9]/60 p-4 sm:p-5 space-y-4">
          <div className="flex items-center gap-2 pb-2 border-b border-[#E2E8F0]">
            <div className="w-6 h-6 rounded-lg bg-[#CCFBF1] text-[#0D9488] flex items-center justify-center font-bold text-xs">
              1
            </div>
            <h4 className="text-xs font-extrabold text-[#0F172A] uppercase tracking-wider">
              Kredensial Akun Login Dokter
            </h4>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <FieldLabel required htmlFor="doc-name">
                Nama Lengkap & Gelar
              </FieldLabel>
              <TextInput
                id="doc-name"
                required
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="dr. Nadia Safira, Sp.KJ / Fajar, M.Psi."
              />
            </div>

            <div>
              <FieldLabel required htmlFor="doc-email">
                Email Login Dokter
              </FieldLabel>
              <TextInput
                id="doc-email"
                type="email"
                required
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
                placeholder="dokter.nadia@mindpal.id"
              />
            </div>

            <div>
              <FieldLabel required htmlFor="doc-password">
                Kata Sandi Akun
              </FieldLabel>
              <TextInput
                id="doc-password"
                type="password"
                required
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                placeholder="Minimal 6 karakter"
              />
            </div>

            <div>
              <FieldLabel htmlFor="doc-phone">
                Nomor Kontak / WhatsApp
              </FieldLabel>
              <TextInput
                id="doc-phone"
                value={form.phone ?? ""}
                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                placeholder="081234567890"
              />
            </div>
          </div>
        </div>

        {/* Section 2: Profil Medis & Praktek */}
        <div className="rounded-2xl border border-[#E2E8F0] bg-white p-4 sm:p-5 space-y-4">
          <div className="flex items-center gap-2 pb-2 border-b border-[#E2E8F0]">
            <div className="w-6 h-6 rounded-lg bg-[#CCFBF1] text-[#0D9488] flex items-center justify-center font-bold text-xs">
              2
            </div>
            <h4 className="text-xs font-extrabold text-[#0F172A] uppercase tracking-wider">
              Profil Profesional & STR
            </h4>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <FieldLabel required htmlFor="doc-spec">
                Spesialisasi
              </FieldLabel>
              <div className="space-y-1.5">
                <TextInput
                  id="doc-spec"
                  required
                  value={form.specialization}
                  onChange={(e) => setForm({ ...form, specialization: e.target.value })}
                  placeholder="Contoh: Psikolog Klinis Dewasa"
                />
                <div className="flex flex-wrap gap-1">
                  {SPECIALIZATION_PRESETS.slice(0, 3).map((spec) => (
                    <button
                      key={spec}
                      type="button"
                      onClick={() => setForm({ ...form, specialization: spec })}
                      className="text-[10px] font-semibold bg-[#F0FDFA] hover:bg-[#CCFBF1] text-[#0D9488] px-2 py-0.5 rounded-lg border border-[#99F6E4]/60 transition-colors"
                    >
                      {spec}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div>
              <FieldLabel htmlFor="doc-str">
                No. STR / SIP
              </FieldLabel>
              <TextInput
                id="doc-str"
                value={form.license_number ?? ""}
                onChange={(e) => setForm({ ...form, license_number: e.target.value })}
                placeholder="STR-2024-SPKJ-099"
              />
            </div>

            <div>
              <FieldLabel htmlFor="doc-edu">
                Pendidikan Terakhir
              </FieldLabel>
              <TextInput
                id="doc-edu"
                value={form.education ?? ""}
                onChange={(e) => setForm({ ...form, education: e.target.value })}
                placeholder="Magister Psikologi Profesi UI"
              />
            </div>

            <div>
              <FieldLabel htmlFor="doc-exp">
                Pengalaman Praktik
              </FieldLabel>
              <TextInput
                id="doc-exp"
                value={form.experience ?? ""}
                onChange={(e) => setForm({ ...form, experience: e.target.value })}
                placeholder="5 Tahun"
              />
            </div>
          </div>

          <div>
            <FieldLabel htmlFor="doc-bio">
              Biografi Singkat & Pendekatan Konseling
            </FieldLabel>
            <TextArea
              id="doc-bio"
              rows={3}
              value={form.bio ?? ""}
              onChange={(e) => setForm({ ...form, bio: e.target.value })}
              placeholder="Berpengalaman menangani gangguan kecemasan (anxiety), depresi, dan trauma relasi dengan pendekatan CBT & Humanistic..."
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
            <div>
              <FieldLabel htmlFor="doc-status">
                Status Verifikasi Awal
              </FieldLabel>
              <select
                id="doc-status"
                value={form.verification_status}
                onChange={(e) =>
                  setForm({ ...form, verification_status: e.target.value as VerificationStatus })
                }
                className="w-full rounded-2xl border border-[#E2E8F0] bg-[#F8FAF9] px-3.5 py-2.5 text-xs font-bold text-[#0F172A] focus:border-[#0D9488] focus:bg-white focus:ring-2 focus:ring-[#0D9488]/30 focus:outline-none"
              >
                <option value="approved">Langsung Terverifikasi (Approved)</option>
                <option value="pending">Menunggu Verifikasi (Pending)</option>
              </select>
            </div>

            <div>
              <FieldLabel htmlFor="doc-active">
                Status Keaktifan
              </FieldLabel>
              <select
                id="doc-active"
                value={form.is_active ? "1" : "0"}
                onChange={(e) => setForm({ ...form, is_active: e.target.value === "1" })}
                className="w-full rounded-2xl border border-[#E2E8F0] bg-[#F8FAF9] px-3.5 py-2.5 text-xs font-bold text-[#0F172A] focus:border-[#0D9488] focus:bg-white focus:ring-2 focus:ring-[#0D9488]/30 focus:outline-none"
              >
                <option value="1">Aktif (Dapat Login & Menerima Pasien)</option>
                <option value="0">Nonaktif</option>
              </select>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center justify-end gap-2.5 pt-2">
          <Button type="button" variant="secondary" onClick={onClose} disabled={loading}>
            Batal
          </Button>
          <Button type="submit" variant="primary" loading={loading}>
            <IconDoctor className="w-4 h-4 mr-1" />
            Simpan & Buat Akun Dokter
          </Button>
        </div>
      </form>
    </Modal>
  );
}
