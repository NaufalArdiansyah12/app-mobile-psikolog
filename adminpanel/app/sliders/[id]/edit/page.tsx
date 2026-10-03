"use client";

/**
 * Halaman Edit Slider: /sliders/[id]/edit
 */

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { SliderForm, type SliderFormValues } from "@/components/sliders/SliderForm";
import { ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { useToast } from "@/components/ui/Toast";
import { apiGet, apiPut, ApiError } from "@/lib/api";
import type { Slider } from "@/types/slider";

export default function EditSliderPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const toast = useToast();

  const [slider, setSlider] = useState<Slider | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const sliderId = Number(params.id);

  const load = useCallback(async () => {
    if (!Number.isFinite(sliderId)) {
      setError("ID slider tidak valid");
      setLoading(false);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<Slider>(`/sliders/${sliderId}`);
      setSlider(res.data);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Gagal memuat data slider");
    } finally {
      setLoading(false);
    }
  }, [sliderId]);

  useEffect(() => {
    load();
  }, [load]);

  const handleSubmit = async (data: SliderFormValues) => {
    if (!slider) return;
    setSaving(true);
    setError(null);
    try {
      const form = new FormData();
      form.append("title", data.title.trim());
      if (data.description !== undefined) {
        form.append("description", data.description.trim());
      }
      if (data.link !== undefined) {
        form.append("link", data.link.trim());
      }
      form.append("sort_order", String(data.sort_order));
      form.append("status", data.status);
      if (data.image) {
        form.append("image", data.image);
      }

      await apiPut(`/sliders/${slider.id}`, form);
      toast.success("Slider berhasil diperbarui");
      router.push("/sliders");
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : "Gagal memperbarui slider";
      setError(msg);
      toast.error(msg);
    } finally {
      setSaving(false);
    }
  };

  return (
    <AdminLayout>
      <div className="space-y-4">
        <Link
          href="/sliders"
          className="inline-flex items-center gap-1.5 text-xs font-bold text-[#0D9488] hover:underline"
        >
          <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
            <line x1="19" y1="12" x2="5" y2="12" strokeLinecap="round" strokeLinejoin="round" />
            <polyline points="12 19 5 12 12 5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          Kembali ke daftar slider
        </Link>

        <div className="rounded-[28px] border border-[#E2E8F0] bg-white p-6 sm:p-8 shadow-[0_2px_10px_0_rgba(15,23,42,0.03)]">
          <h2 className="mb-1 text-base font-extrabold text-[#0F172A] tracking-tight">
            Edit Slider #{sliderId}
          </h2>
          <p className="mb-6 text-xs text-[#64748B] font-medium">
            Perbarui data judul, urutan, atau ganti file gambar.
          </p>

          {loading ? (
            <LoadingState label="Memuat data slider..." />
          ) : error || !slider ? (
            <ErrorState message={error ?? "Slider tidak ditemukan"} onRetry={load} />
          ) : (
            <SliderForm
              slider={slider}
              loading={saving}
              error={error}
              submitLabel="Simpan Perubahan"
              onSubmit={handleSubmit}
              onCancel={() => router.push("/sliders")}
            />
          )}
        </div>
      </div>
    </AdminLayout>
  );
}
