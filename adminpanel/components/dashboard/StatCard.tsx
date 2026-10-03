"use client";

/**
 * StatCard (MindPal Teal Palette):
 * - Squircle Icon Container with soft Teal elevation
 * - Status Micro-Dots & Progress Line
 */

import { formatNumber } from "@/lib/utils";

interface StatCardProps {
  title: string;
  value: number;
  icon: string | React.ReactNode;
  accent: "teal" | "emerald" | "amber" | "rose" | "slate" | "sky" | "coral" | "primary" | "accent";
  hint?: string;
  progressPercent?: number;
}

const THEMES: Record<
  string,
  {
    iconBg: string;
    iconText: string;
    dotActive: string;
    dotSubtle: string;
    progressBar: string;
    shadow: string;
  }
> = {
  teal: {
    iconBg: "bg-[#0D9488]",
    iconText: "text-white",
    dotActive: "bg-[#0D9488]",
    dotSubtle: "bg-[#0D9488]/30",
    progressBar: "bg-[#0D9488]",
    shadow: "shadow-[0_8px_18px_-4px_rgba(13,148,136,0.35)]",
  },
  primary: {
    iconBg: "bg-[#0D9488]",
    iconText: "text-white",
    dotActive: "bg-[#0D9488]",
    dotSubtle: "bg-[#0D9488]/30",
    progressBar: "bg-[#0D9488]",
    shadow: "shadow-[0_8px_18px_-4px_rgba(13,148,136,0.35)]",
  },
  sky: {
    iconBg: "bg-[#0D9488]",
    iconText: "text-white",
    dotActive: "bg-[#0D9488]",
    dotSubtle: "bg-[#0D9488]/30",
    progressBar: "bg-[#0D9488]",
    shadow: "shadow-[0_8px_18px_-4px_rgba(13,148,136,0.35)]",
  },
  coral: {
    iconBg: "bg-[#0F766E]",
    iconText: "text-white",
    dotActive: "bg-[#0F766E]",
    dotSubtle: "bg-[#0F766E]/30",
    progressBar: "bg-[#0F766E]",
    shadow: "shadow-[0_8px_18px_-4px_rgba(15,118,110,0.35)]",
  },
  accent: {
    iconBg: "bg-[#0F766E]",
    iconText: "text-white",
    dotActive: "bg-[#0F766E]",
    dotSubtle: "bg-[#0F766E]/30",
    progressBar: "bg-[#0F766E]",
    shadow: "shadow-[0_8px_18px_-4px_rgba(15,118,110,0.35)]",
  },
  amber: {
    iconBg: "bg-[#D97706]",
    iconText: "text-white",
    dotActive: "bg-[#D97706]",
    dotSubtle: "bg-[#D97706]/30",
    progressBar: "bg-[#D97706]",
    shadow: "shadow-[0_8px_18px_-4px_rgba(217,119,6,0.35)]",
  },
  emerald: {
    iconBg: "bg-[#10B981]",
    iconText: "text-white",
    dotActive: "bg-[#10B981]",
    dotSubtle: "bg-[#10B981]/30",
    progressBar: "bg-[#10B981]",
    shadow: "shadow-[0_8px_18px_-4px_rgba(16,185,129,0.35)]",
  },
  rose: {
    iconBg: "bg-[#F43F5E]",
    iconText: "text-white",
    dotActive: "bg-[#F43F5E]",
    dotSubtle: "bg-[#F43F5E]/30",
    progressBar: "bg-[#F43F5E]",
    shadow: "shadow-[0_8px_18px_-4px_rgba(244,63,94,0.35)]",
  },
  slate: {
    iconBg: "bg-[#64748B]",
    iconText: "text-white",
    dotActive: "bg-[#64748B]",
    dotSubtle: "bg-[#64748B]/30",
    progressBar: "bg-[#64748B]",
    shadow: "shadow-xs",
  },
};

export function StatCard({
  title,
  value,
  icon,
  accent,
  hint,
  progressPercent = 65,
}: StatCardProps) {
  const theme = THEMES[accent] || THEMES.teal;

  return (
    <div className="group relative bg-white rounded-[20px] p-4 border border-[#E2E8F0] shadow-[0_2px_10px_0_rgba(15,23,42,0.03)] hover:shadow-[0_12px_28px_-8px_rgba(13,148,136,0.18)] hover:-translate-y-0.5 transition-all duration-300">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          {/* Squircle Container */}
          <div
            className={`w-11 h-11 rounded-2xl ${theme.iconBg} ${theme.iconText} ${theme.shadow} flex items-center justify-center text-lg flex-shrink-0 group-hover:scale-105 transition-transform`}
          >
            {icon}
          </div>
          <div>
            <h3 className="text-base font-extrabold text-[#0F172A] leading-tight">
              {formatNumber(value)}
            </h3>
            <span className="text-[11px] font-semibold text-[#64748B] mt-0.5 block truncate max-w-[110px]">
              {title}
            </span>
          </div>
        </div>

        {/* Micro Status Dots */}
        <div className="flex flex-col gap-1 items-end self-start">
          <div className="flex gap-1">
            <span className={`w-1.5 h-1.5 rounded-full ${theme.dotActive}`} />
            <span className={`w-1.5 h-1.5 rounded-full ${theme.dotSubtle}`} />
          </div>
        </div>
      </div>

      {/* Micro Progress Line */}
      <div className="w-full bg-[#F8FAF9] h-1.5 rounded-full mt-3 overflow-hidden">
        <div
          className={`${theme.progressBar} h-full rounded-full transition-all duration-500`}
          style={{ width: `${Math.min(100, Math.max(15, progressPercent))}%` }}
        />
      </div>

      {hint && (
        <p className="text-[10px] font-medium text-[#64748B] mt-1.5 truncate">
          {hint}
        </p>
      )}
    </div>
  );
}
