"use client";

/** Badge status MindPal style. */

import { cx, statusBadge, type BadgeVariant } from "@/lib/utils";

const VARIANT_CLASSES: Record<BadgeVariant, string> = {
  success: "bg-emerald-50 text-emerald-700 ring-emerald-500/25",
  warning: "bg-amber-50 text-amber-700 ring-amber-500/25",
  danger: "bg-rose-50 text-rose-600 ring-rose-500/25",
  info: "bg-[#CCFBF1] text-[#0F766E] ring-[#0D9488]/30",
  neutral: "bg-[#F8FAF9] text-[#64748B] ring-[#64748B]/20",
  accent: "bg-[#F0FDFA] text-[#0D9488] ring-[#0D9488]/30",
};

interface BadgeProps {
  value?: string;
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
        "inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[11px] font-semibold ring-1 ring-inset transition-colors",
        VARIANT_CLASSES[finalVariant],
        className
      )}
    >
      <span className="w-1.5 h-1.5 rounded-full bg-current opacity-70" />
      {finalLabel}
    </span>
  );
}
