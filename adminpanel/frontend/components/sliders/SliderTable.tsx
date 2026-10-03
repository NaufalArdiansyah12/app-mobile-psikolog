"use client";

/** Tabel daftar slider/banner. */

import Image from "next/image";
import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/State";
import { assetUrl, formatDate } from "@/lib/utils";
import type { Slider } from "@/types/slider";

interface SliderTableProps {
  sliders: Slider[];
  busyId: number | null;
  onToggleActive: (slider: Slider) => void;
  onDelete: (slider: Slider) => void;
}

export function SliderTable({ sliders, busyId, onToggleActive, onDelete }: SliderTableProps) {
  if (sliders.length === 0) {
    return (
      <EmptyState
        title="Belum ada slider"
        description="Belum ada slider/banner yang dibuat. Klik tombol Tambah Slider."
        icon="🖼️"
      />
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50">
          <tr>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Gambar
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Judul
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Link
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Urutan
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Status
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Tanggal Dibuat
            </th>
            <th className="px-4 py-3 text-right text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Action
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100 bg-white">
          {sliders.map((slider) => {
            const busy = busyId === slider.id;
            return (
              <tr key={slider.id} className="transition-colors hover:bg-slate-50/70">
                <td className="px-4 py-3">
                  <div className="relative h-12 w-20 overflow-hidden rounded-md border border-slate-200 bg-slate-100">
                    <Image
                      src={assetUrl(slider.image)}
                      alt={slider.title}
                      fill
                      unoptimized
                      className="object-cover"
                    />
                  </div>
                </td>
                <td className="px-4 py-3">
                  <p className="font-medium text-slate-800">{slider.title}</p>
                  <p className="line-clamp-1 max-w-xs text-xs text-slate-500">
                    {slider.description || "-"}
                  </p>
                </td>
                <td className="px-4 py-3 font-mono text-xs text-slate-600">
                  {slider.link || "-"}
                </td>
                <td className="px-4 py-3 text-slate-600">{slider.sort_order}</td>
                <td className="px-4 py-3">
                  <Badge
                    value={slider.status}
                    label={slider.status === "active" ? "Aktif" : "Nonaktif"}
                  />
                </td>
                <td className="px-4 py-3 text-slate-600">
                  {formatDate(slider.created_at)}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap items-center justify-end gap-1.5">
                    <Link href={`/sliders/${slider.id}/edit`}>
                      <Button size="sm" variant="secondary">
                        Edit
                      </Button>
                    </Link>
                    <Button
                      size="sm"
                      variant={slider.status === "active" ? "secondary" : "success"}
                      loading={busy}
                      onClick={() => onToggleActive(slider)}
                    >
                      {slider.status === "active" ? "Nonaktifkan" : "Aktifkan"}
                    </Button>
                    <Button
                      size="sm"
                      variant="danger"
                      disabled={busy}
                      onClick={() => onDelete(slider)}
                    >
                      Hapus
                    </Button>
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
