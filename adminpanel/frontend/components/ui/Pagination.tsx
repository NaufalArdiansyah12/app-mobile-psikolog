"use client";

/** Pagination reusable (mengikuti pagination dari API). */

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
    <div className="flex flex-col items-center justify-between gap-3 border-t border-slate-200 px-4 py-3 sm:flex-row">
      <p className="text-xs text-slate-500">
        Menampilkan <span className="font-medium text-slate-700">{first}-{last}</span>{" "}
        dari <span className="font-medium text-slate-700">{total}</span> data
      </p>

      <div className="flex items-center gap-1">
        <button
          type="button"
          disabled={page <= 1}
          onClick={() => onPageChange(page - 1)}
          className="rounded-md border border-slate-300 px-2.5 py-1.5 text-xs text-slate-600 transition-colors hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
        >
          ‹ Sebelumnya
        </button>

        {pageRange(page, total_pages).map((p, idx) =>
          p === "..." ? (
            <span key={`gap-${idx}`} className="px-1.5 text-xs text-slate-400">
              …
            </span>
          ) : (
            <button
              key={p}
              type="button"
              onClick={() => onPageChange(p)}
              className={cx(
                "min-w-8 rounded-md border px-2.5 py-1.5 text-xs transition-colors",
                p === page
                  ? "border-primary-600 bg-primary-600 text-white"
                  : "border-slate-300 text-slate-600 hover:bg-slate-50"
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
          className="rounded-md border border-slate-300 px-2.5 py-1.5 text-xs text-slate-600 transition-colors hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
        >
          Berikutnya ›
        </button>
      </div>
    </div>
  );
}
