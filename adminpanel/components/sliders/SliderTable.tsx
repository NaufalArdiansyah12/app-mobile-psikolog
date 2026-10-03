"use client";

/** Tabel daftar slider/banner estetika MindPal. */

import Image from "next/image";
import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/State";
import { IconImage } from "@/components/ui/Icons";
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
        description="Belum ada banner promosi yang dibuat. Klik tombol Tambah Slider."
        icon={<IconImage className="w-6 h-6" />}
      />
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-[#E2E8F0] text-xs">
        <thead>
          <tr className="border-b border-[#E2E8F0] bg-[#F8FAF9]/80 text-[#64748B]">
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Preview
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Judul & Info
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Target URL
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Urutan
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Status
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Dibuat
            </th>
            <th className="px-4 py-3 text-right font-bold uppercase tracking-wider">
              Aksi
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-[#E2E8F0] bg-white">
          {sliders.map((slider) => {
            const busy = busyId === slider.id;
            return (
              <tr key={slider.id} className="transition-colors hover:bg-[#F8FAF9]/70">
                <td className="px-4 py-3.5">
                  <div className="relative h-12 w-20 overflow-hidden rounded-2xl border border-[#E2E8F0] bg-[#F8FAF9] shadow-2xs">
                    <Image
                      src={assetUrl(slider.image)}
                      alt={slider.title}
                      fill
                      unoptimized
                      className="object-cover"
                    />
                  </div>
                </td>
                <td className="px-4 py-3.5">
                  <p className="font-bold text-[#0F172A]">{slider.title}</p>
                  <p className="line-clamp-1 max-w-xs text-[11px] text-[#64748B] font-medium">
                    {slider.description || "-"}
                  </p>
                </td>
                <td className="px-4 py-3.5 font-mono text-[11px] text-[#64748B] font-semibold">
                  {slider.link || "-"}
                </td>
                <td className="px-4 py-3.5 font-bold text-[#0F172A]">
                  {slider.sort_order}
                </td>
                <td className="px-4 py-3.5">
                  <Badge
                    value={slider.status}
                    label={slider.status === "active" ? "Aktif" : "Nonaktif"}
                  />
                </td>
                <td className="px-4 py-3.5 text-[#64748B] font-medium">
                  {formatDate(slider.created_at)}
                </td>
                <td className="px-4 py-3.5 text-right">
                  <div className="flex flex-wrap items-center justify-end gap-1.5">
                    <Link href={`/sliders/${slider.id}/edit`}>
                      <Button size="sm" variant="secondary">
                        Edit
                      </Button>
                    </Link>
                    <Button
                      size="sm"
                      variant={slider.status === "active" ? "ghost" : "primary"}
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
