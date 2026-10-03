"use client";

/**
 * Form slider (create & edit) - multipart/form-data dengan upload gambar.
 * Validasi di sisi klien: judul wajib, gambar wajib saat create,
 * ukuran gambar maks 5 MB, tipe JPG/PNG/WEBP/GIF.
 */

import { useEffect, useState, type FormEvent } from "react";
import Image from "next/image";
import { Button } from "@/components/ui/Button";
import { FieldLabel, TextArea, TextInput } from "@/components/ui/Form";
import { assetUrl, cx } from "@/lib/utils";
import type { Slider } from "@/types/slider";

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"];
const MAX_SIZE = 5 * 1024 * 1024; // 5 MB

export interface SliderFormValues {
  title: string;
  description: string;
  link: string;
  sort_order: number;
  status: string;
  image: File | null;
}

interface SliderFormProps {
  /** undefined = mode create. */
  slider?: Slider;
  loading: boolean;
  error?: string | null;
  submitLabel: string;
  onSubmit: (values: SliderFormValues) => void | Promise<void>;
  onCancel: () => void;
}

export function SliderForm({
  slider,
  loading,
  error,
  submitLabel,
  onSubmit,
  onCancel,
}: SliderFormProps) {
  const isEdit = Boolean(slider);

  const [title, setTitle] = useState(slider?.title ?? "");
  const [description, setDescription] = useState(slider?.description ?? "");
  const [link, setLink] = useState(slider?.link ?? "");
  const [sortOrder, setSortOrder] = useState(slider?.sort_order ?? 0);
  const [status, setStatus] = useState<string>(slider?.status ?? "active");
  const [image, setImage] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [errors, setErrors] = useState<{ title?: string; image?: string }>({});

  // Sinkron bila data slider berubah (mis. selesai load)
  useEffect(() => {
    if (!slider) return;
    setTitle(slider.title);
    setDescription(slider.description ?? "");
    setLink(slider.link ?? "");
    setSortOrder(slider.sort_order);
    setStatus(slider.status);
  }, [slider]);

  // Preview gambar terpilih
  useEffect(() => {
    if (!image) {
      setPreview(null);
      return;
    }
    const url = URL.createObjectURL(image);
    setPreview(url);
    return () => URL.revokeObjectURL(url);
  }, [image]);

  const handlePickImage = (file: File | null) => {
    setErrors((prev) => ({ ...prev, image: undefined }));
    if (!file) {
      setImage(null);
      return;
    }
    if (!ALLOWED_TYPES.includes(file.type)) {
      setErrors((prev) => ({
        ...prev,
        image: "Format file tidak didukung. Gunakan JPG, PNG, WEBP, atau GIF.",
      }));
      setImage(null);
      return;
    }
    if (file.size > MAX_SIZE) {
      setErrors((prev) => ({ ...prev, image: "Ukuran gambar maksimal 5 MB." }));
      setImage(null);
      return;
    }
    setImage(file);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    const next: { title?: string; image?: string } = {};

    if (!title.trim()) next.title = "Judul wajib diisi";
    if (!isEdit && !image) next.image = "Gambar wajib diunggah";
    if (image && !ALLOWED_TYPES.includes(image.type)) {
      next.image = "Format file tidak didukung.";
    }

    setErrors(next);
    if (Object.keys(next).length > 0) return;

    await onSubmit({
      title: title.trim(),
      description: description.trim(),
      link: link.trim(),
      sort_order: Number(sortOrder) || 0,
      status,
      image,
    });
  };

  const currentImage = preview ?? (isEdit && slider ? assetUrl(slider.image) : null);

  return (
    <form
      onSubmit={handleSubmit}
      noValidate
      className="max-w-2xl rounded-xl border border-slate-200 bg-white p-6 shadow-sm"
    >
      {error && (
        <div className="mb-5 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {error}
        </div>
      )}

      {/* Judul */}
      <div className="mb-4">
        <FieldLabel required htmlFor="slider-title">
          Judul
        </FieldLabel>
        <TextInput
          id="slider-title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Contoh: Konsultasi Dokter Online"
          maxLength={150}
          className={errors.title ? "border-red-500" : ""}
        />
        {errors.title && <p className="mt-1.5 text-xs text-red-500">{errors.title}</p>}
      </div>

      {/* Deskripsi */}
      <div className="mb-4">
        <FieldLabel htmlFor="slider-description">Deskripsi</FieldLabel>
        <TextArea
          id="slider-description"
          rows={3}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Deskripsi singkat yang tampil di bawah judul slider"
          maxLength={500}
        />
      </div>

      {/* Link */}
      <div className="mb-4">
        <FieldLabel htmlFor="slider-link">Link</FieldLabel>
        <TextInput
          id="slider-link"
          value={link}
          onChange={(e) => setLink(e.target.value)}
          placeholder="/doctors atau https://..."
          maxLength={255}
        />
      </div>

      {/* Urutan + status */}
      <div className="mb-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <FieldLabel htmlFor="slider-sort">Urutan</FieldLabel>
          <TextInput
            id="slider-sort"
            type="number"
            min={0}
            value={sortOrder}
            onChange={(e) => setSortOrder(Number(e.target.value))}
          />
          <p className="mt-1 text-xs text-slate-400">Angka kecil tampil lebih dulu.</p>
        </div>
        <div>
          <FieldLabel htmlFor="slider-status">Status</FieldLabel>
          <select
            id="slider-status"
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 focus:border-primary-500 focus:ring-2 focus:ring-primary-100 focus:outline-none"
          >
            <option value="active">Aktif (tampil di halaman user)</option>
            <option value="inactive">Nonaktif (tidak tampil)</option>
          </select>
        </div>
      </div>

      {/* Upload gambar */}
      <div className="mb-6">
        <FieldLabel required={!isEdit} htmlFor="slider-image">
          Gambar {isEdit && "(kosongkan untuk mempertahankan gambar)"}
        </FieldLabel>
        <input
          id="slider-image"
          type="file"
          accept="image/jpeg,image/png,image/webp,image/gif"
          onChange={(e) => handlePickImage(e.target.files?.[0] ?? null)}
          className={cx(
            "block w-full cursor-pointer rounded-lg border border-dashed border-slate-300 bg-slate-50 px-3 py-2.5 text-sm text-slate-600",
            "file:mr-3 file:cursor-pointer file:rounded-md file:border-0 file:bg-white file:px-3 file:py-1.5 file:text-xs file:font-medium file:text-slate-700",
            errors.image && "border-red-400 bg-red-50"
          )}
        />
        {errors.image && <p className="mt-1.5 text-xs text-red-500">{errors.image}</p>}
        <p className="mt-1 text-xs text-slate-400">
          Format: JPG, PNG, WEBP, GIF · Maksimal 5 MB
        </p>

        {currentImage && (
          <div className="relative mt-3 h-40 w-full overflow-hidden rounded-lg border border-slate-200">
            <Image
              src={currentImage}
              alt="Preview slider"
              fill
              unoptimized
              className="object-cover"
            />
          </div>
        )}
      </div>

      {/* Aksi */}
      <div className="flex items-center justify-end gap-2 border-t border-slate-100 pt-4">
        <Button variant="secondary" type="button" onClick={onCancel} disabled={loading}>
          Batal
        </Button>
        <Button type="submit" loading={loading}>
          {submitLabel}
        </Button>
      </div>
    </form>
  );
}
