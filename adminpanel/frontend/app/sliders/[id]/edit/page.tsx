"use client";

/**
 * Halaman Edit Slider: /sliders/[id]/edit
 */

import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import Link from "next/link";
import { AdminLayout } from "@/components/layout/AdminLayout";
import {
  SliderForm,
  type SliderFormValues,
} from "@/components/sliders/SliderForm";
import { ErrorState } from "@/components/ui/State";
import { LoadingState } from "@/components/ui/Loading";
import { useToast } from "@/components/ui/Toast";
import { apiGet, apiPutUpload, ApiError } from "@/lib/api";
import type { Slider } from "@/types/slider";

export default function EditSliderPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const toast = useToast();

  const [slider, setSlider] = useState<Slider | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
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

  const handleSubmit = async (values: SliderFormValues) => {
    setSubmitting(true);
    setError(null);
    try {
      const form = new FormData();
      form.append("title", values.title);
      form.append("description", values.description);
      form.append("link", values.link);
      form.append("sort_order", String(values.sort_order));
      form.append("status", values.status);
      // image opsional: bila tidak dipilih, backend mempertahankan gambar lama
      if (values.image) form.append("image", values.image);

      await apiPutUpload(`/sliders/${sliderId}`, form);
      toast.success("Slider berhasil diperbarui");
      router.push("/sliders");
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "Gagal memperbarui slider";
      setError(message);
      toast.error(message);
      setSubmitting(false);
    }
  };

  return (
    <AdminLayout>
      <div className="mb-4">
        <Link
          href="/sliders"
          className="text-sm font-medium text-primary-600 hover:underline"
        >
          ← Kembali ke daftar slider
        </Link>
      </div>

      <div className="mb-4">
        <h2 className="text-base font-semibold text-slate-900">Edit Slider</h2>
        <p className="text-sm text-slate-500">Perbarui informasi banner slider.</p>
      </div>

      {loading ? (
        <LoadingState label="Memuat data slider..." />
      ) : error || !slider ? (
        <ErrorState message={error ?? "Slider tidak ditemukan"} onRetry={load} />
      ) : (
        <SliderForm
          slider={slider}
          loading={submitting}
          error={error}
          submitLabel="Simpan Perubahan"
          onSubmit={handleSubmit}
          onCancel={() => router.push("/sliders")}
        />
      )}
    </AdminLayout>
  );
}
