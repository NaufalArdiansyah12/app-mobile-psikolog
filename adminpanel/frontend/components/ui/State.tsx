"use client";

/** Empty state & Error state reusable untuk setiap halaman. */

import { Button } from "@/components/ui/Button";
import { cx } from "@/lib/utils";

interface EmptyStateProps {
  title?: string;
  description?: string;
  icon?: string;
  action?: React.ReactNode;
  className?: string;
}

export function EmptyState({
  title = "Belum ada data",
  description = "Belum ada data yang tersedia untuk ditampilkan.",
  icon = "📭",
  action,
  className,
}: EmptyStateProps) {
  return (
    <div className={cx("flex flex-col items-center justify-center gap-2 py-14 text-center", className)}>
      <span className="text-4xl">{icon}</span>
      <h3 className="text-sm font-semibold text-slate-700">{title}</h3>
      <p className="max-w-sm text-sm text-slate-500">{description}</p>
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}

interface ErrorStateProps {
  message?: string;
  onRetry?: () => void;
  className?: string;
}

export function ErrorState({
  message = "Terjadi kesalahan saat memuat data.",
  onRetry,
  className,
}: ErrorStateProps) {
  return (
    <div
      className={cx(
        "flex flex-col items-center justify-center gap-2 rounded-lg border border-red-200 bg-red-50 py-12 text-center",
        className
      )}
      role="alert"
    >
      <span className="text-3xl">⚠️</span>
      <h3 className="text-sm font-semibold text-red-700">Gagal memuat data</h3>
      <p className="max-w-md text-sm text-red-600">{message}</p>
      {onRetry && (
        <div className="mt-2">
          <Button variant="danger" size="sm" onClick={onRetry}>
            Coba Lagi
          </Button>
        </div>
      )}
    </div>
  );
}
