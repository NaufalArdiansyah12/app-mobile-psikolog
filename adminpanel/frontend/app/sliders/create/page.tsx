"use client";

/**
 * Halaman Tambah Slider: /sliders/create
 */

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { AdminLayout } from "@/components/layout/AdminLayout";
import {
  SliderForm,
  type SliderFormValues,
} from "@/components/sliders/SliderForm";
import { useToast } from "@/components/ui/Toast";
import { apiUpload, ApiError } from "@/lib/api";

export default function CreateSliderPage() {
  const router = useRouter();
  const toast = useToast();

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (values: SliderFormValues) => {
    setLoading(true);
    setError(null);
    try {
      // Endpoint backend menerima multipart/form-data
      const form = new FormData();
      form.append("title", values.title);
      form.append("description", values.description);
      form.append("link", values.link);
      form.append("sort_order", String(values.sort_order));
      form.append("status", values.status);
      if (values.image) form.append("image", values.image);

      await apiUpload("/sliders", form);
      toast.success("Slider berhasil dibuat");
      router.push("/sliders");
    } catch (err) {
      const message = err instanceof ApiError ? err.message : "Gagal membuat slider";
      setError(message);
      toast.error(message);
      setLoading(false);
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
        <h2 className="text-base font-semibold text-slate-900">Tambah Slider Baru</h2>
        <p className="text-sm text-slate-500">
          Buat banner baru untuk ditampilkan di halaman user.
        </p>
      </div>

      <SliderForm
        loading={loading}
        error={error}
        submitLabel="Simpan Slider"
        onSubmit={handleSubmit}
        onCancel={() => router.push("/sliders")}
      />
    </AdminLayout>
  );
}
