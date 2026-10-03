"use client";

/** Loading state (spinner) reusable. */

import { cx } from "@/lib/utils";

interface LoadingStateProps {
  label?: string;
  className?: string;
}

export function LoadingState({ label = "Memuat data...", className }: LoadingStateProps) {
  return (
    <div
      className={cx(
        "flex flex-col items-center justify-center gap-3 py-14 text-slate-500",
        className
      )}
      role="status"
    >
      <span className="h-8 w-8 animate-spin rounded-full border-[3px] border-slate-200 border-t-primary-600" />
      <p className="text-sm">{label}</p>
    </div>
  );
}

/** Skeleton bar sederhana untuk konten yang sedang dimuat. */
export function Skeleton({ className }: { className?: string }) {
  return <div className={cx("animate-pulse rounded bg-slate-200", className)} />;
}
