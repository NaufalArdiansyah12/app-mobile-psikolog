"use client";

/** Tombol reusable dengan tema warna MindPal. */

import type { ButtonHTMLAttributes, ReactNode } from "react";
import { cx } from "@/lib/utils";

type Variant = "primary" | "secondary" | "danger" | "success" | "ghost" | "sky";
type Size = "sm" | "md" | "lg";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
  children: ReactNode;
}

const VARIANT_CLASSES: Record<Variant, string> = {
  primary:
    "bg-[#0D9488] text-white hover:bg-[#0F766E] shadow-[0_8px_18px_-4px_rgba(13,148,136,0.35)] focus-visible:ring-[#0D9488]/40 disabled:opacity-50",
  sky:
    "bg-[#0D9488] text-white hover:bg-[#0F766E] shadow-[0_8px_18px_-4px_rgba(13,148,136,0.35)] focus-visible:ring-[#0D9488]/40 disabled:opacity-50",
  secondary:
    "border border-[#E2E8F0] bg-[#F8FAF9] text-[#0F172A] hover:bg-white hover:border-[#0D9488]/40 focus-visible:ring-[#0D9488]/40 disabled:text-[#64748B]",
  danger:
    "bg-rose-500 text-white hover:bg-rose-600 shadow-sm focus-visible:ring-rose-500 disabled:opacity-50",
  success:
    "bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm focus-visible:ring-emerald-500 disabled:opacity-50",
  ghost:
    "text-[#64748B] hover:text-[#0F172A] hover:bg-[#F8FAF9] disabled:opacity-40",
};

const SIZE_CLASSES: Record<Size, string> = {
  sm: "px-3 py-1.5 text-xs rounded-xl",
  md: "px-4 py-2.5 text-xs font-bold rounded-2xl",
  lg: "px-6 py-3 text-sm font-bold rounded-2xl",
};

export function Button({
  variant = "primary",
  size = "md",
  loading = false,
  disabled,
  className,
  children,
  ...rest
}: ButtonProps) {
  return (
    <button
      type="button"
      disabled={disabled || loading}
      className={cx(
        "inline-flex items-center justify-center gap-2 font-bold tracking-tight transition-all duration-200 active:scale-95",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-1",
        "disabled:cursor-not-allowed disabled:transform-none",
        VARIANT_CLASSES[variant],
        SIZE_CLASSES[size],
        className
      )}
      {...rest}
    >
      {loading && (
        <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-current border-t-transparent" />
      )}
      {children}
    </button>
  );
}
