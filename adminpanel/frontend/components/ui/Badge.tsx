"use client";

/** Badge status (pending, approved, active, dst.) */

import { cx, statusBadge, type BadgeVariant } from "@/lib/utils";

const VARIANT_CLASSES: Record<BadgeVariant, string> = {
  success: "bg-emerald-50 text-emerald-700 ring-emerald-600/20",
  warning: "bg-amber-50 text-amber-700 ring-amber-600/20",
  danger: "bg-red-50 text-red-700 ring-red-600/20",
  info: "bg-primary-50 text-primary-700 ring-primary-600/20",
  neutral: "bg-slate-100 text-slate-600 ring-slate-500/20",
  accent: "bg-accent-50 text-accent-700 ring-accent-600/20",
};

interface BadgeProps {
  /** Nilai status (pending/approved/active/...). Label otomatis. */
  value?: string;
  /** Atau tulis label custom. */
  label?: string;
  variant?: BadgeVariant;
  className?: string;
}

export function Badge({ value, label, variant, className }: BadgeProps) {
  const auto = value ? statusBadge(value) : null;
  const finalLabel = label ?? auto?.label ?? "-";
  const finalVariant = variant ?? auto?.variant ?? "neutral";

  return (
    <span
      className={cx(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset",
        VARIANT_CLASSES[finalVariant],
        className
      )}
    >
      {finalLabel}
    </span>
  );
}
