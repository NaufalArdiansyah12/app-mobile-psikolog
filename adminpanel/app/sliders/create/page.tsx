"use client";

/**
 * Halaman Tambah Slider: /sliders/create
 */

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { AdminLayout } from "@/components/layout/AdminLayout";
import { SliderForm, type SliderFormValues } from "@/components/sliders/SliderForm";
import { useToast } from "@/components/ui/Toast";
import { apiPost, ApiError } from "@/lib/api";

export default function CreateSliderPage() {
  const router = useRouter();
  const toast = useToast();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (data: SliderFormValues) => {
    setLoading(true);
    setError(null);
    try {
      const form = new FormData();
      form.append("title", data.title.trim());
      if (data.description) form.append("description", data.description.trim());
      if (data.link) form.append("link", data.link.trim());
      form.append("sort_order", String(data.sort_order));
      form.append("status", data.status);
      if (data.image) form.append("image", data.image);

      await apiPost("/sliders", form);
      toast.success("Slider baru berhasil dibuat");
      router.push("/sliders");
    } catch (err) {
      const msg = err instanceof ApiError ? err.message : "Gagal membuat slider";
      setError(msg);
      toast.error(msg);
    } finally {
      setLoading(false);
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
            Tambah Slider Baru
          </h2>
          <p className="mb-6 text-xs text-[#64748B] font-medium">
            Upload banner promosi dan atur target tautan aplikasi.
          </p>

          <SliderForm
            loading={loading}
            error={error}
            submitLabel="Simpan Slider"
            onSubmit={handleSubmit}
            onCancel={() => router.push("/sliders")}
          />
        </div>
      </div>
    </AdminLayout>
  );
}
