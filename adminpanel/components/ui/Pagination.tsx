"use client";

/** Pagination PulseFit Bento. */

import type { Pagination } from "@/types/common";
import { cx } from "@/lib/utils";

interface PaginationProps {
  pagination?: Pagination | null;
  onPageChange: (page: number) => void;
}

function pageRange(current: number, totalPages: number): (number | "...")[] {
  if (totalPages <= 7) {
    return Array.from({ length: totalPages }, (_, i) => i + 1);
  }
  const pages: (number | "...")[] = [1];
  const start = Math.max(2, current - 1);
  const end = Math.min(totalPages - 1, current + 1);
  if (start > 2) pages.push("...");
  for (let p = start; p <= end; p += 1) pages.push(p);
  if (end < totalPages - 1) pages.push("...");
  pages.push(totalPages);
  return pages;
}

export function Pagination({ pagination, onPageChange }: PaginationProps) {
  if (!pagination || pagination.total_pages <= 1) return null;

  const { page, total_pages, total, limit } = pagination;
  const first = total === 0 ? 0 : (page - 1) * limit + 1;
  const last = Math.min(page * limit, total);

  return (
    <div className="flex flex-col items-center justify-between gap-3 border-t border-[#F1F4F9] px-4 py-3.5 sm:flex-row">
      <p className="text-xs font-semibold text-[#8F9CA9]">
        Menampilkan <span className="font-bold text-[#1F2937]">{first}-{last}</span>{" "}
        dari <span className="font-bold text-[#1F2937]">{total}</span> data
      </p>

      <div className="flex items-center gap-1.5">
        <button
          type="button"
          disabled={page <= 1}
          onClick={() => onPageChange(page - 1)}
          className="rounded-xl border border-[#F1F4F9] bg-[#F4F7FC] px-3 py-1.5 text-xs font-bold text-[#1F2937] transition-all hover:bg-white disabled:cursor-not-allowed disabled:opacity-40"
        >
          ‹ Sebelumnya
        </button>

        {pageRange(page, total_pages).map((p, idx) =>
          p === "..." ? (
            <span key={`gap-${idx}`} className="px-1.5 text-xs text-[#8F9CA9]">
              …
            </span>
          ) : (
            <button
              key={p}
              type="button"
              onClick={() => onPageChange(p)}
              className={cx(
                "min-w-8 rounded-xl px-2.5 py-1.5 text-xs font-bold transition-all",
                p === page
                  ? "bg-[#FA7643] text-white shadow-xs"
                  : "border border-[#F1F4F9] bg-[#F4F7FC] text-[#1F2937] hover:bg-white"
              )}
            >
              {p}
            </button>
          )
        )}

        <button
          type="button"
          disabled={page >= total_pages}
          onClick={() => onPageChange(page + 1)}
          className="rounded-xl border border-[#F1F4F9] bg-[#F4F7FC] px-3 py-1.5 text-xs font-bold text-[#1F2937] transition-all hover:bg-white disabled:cursor-not-allowed disabled:opacity-40"
        >
          Berikutnya ›
        </button>
      </div>
    </div>
  );
}
