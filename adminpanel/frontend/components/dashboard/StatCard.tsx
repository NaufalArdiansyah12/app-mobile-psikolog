"use client";

/** Kartu statistik dashboard. */

import { formatNumber } from "@/lib/utils";

interface StatCardProps {
  title: string;
  value: number;
  icon: string;
  accent: "primary" | "amber" | "emerald" | "red" | "accent" | "slate";
  hint?: string;
}

const ACCENT: Record<StatCardProps["accent"], { wrapper: string; icon: string }> = {
  primary: { wrapper: "bg-primary-50 text-primary-600", icon: "text-primary-600" },
  amber: { wrapper: "bg-amber-50 text-amber-600", icon: "text-amber-600" },
  emerald: { wrapper: "bg-emerald-50 text-emerald-600", icon: "text-emerald-600" },
  red: { wrapper: "bg-red-50 text-red-600", icon: "text-red-600" },
  accent: { wrapper: "bg-accent-50 text-accent-700", icon: "text-accent-600" },
  slate: { wrapper: "bg-slate-100 text-slate-600", icon: "text-slate-600" },
};

export function StatCard({ title, value, icon, accent, hint }: StatCardProps) {
  const style = ACCENT[accent];

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition-shadow hover:shadow-md">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-medium tracking-wide text-slate-500 uppercase">
            {title}
          </p>
          <p className={`mt-2 text-3xl font-bold ${style.icon}`}>
            {formatNumber(value)}
          </p>
          {hint && <p className="mt-1 text-xs text-slate-400">{hint}</p>}
        </div>
        <div
          className={`flex h-11 w-11 items-center justify-center rounded-lg text-xl ${style.wrapper}`}
        >
          {icon}
        </div>
      </div>
    </div>
  );
}
