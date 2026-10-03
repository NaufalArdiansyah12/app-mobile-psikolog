"use client";

import { ReactNode } from "react";
import { IconInbox, IconAlertTriangle } from "@/components/ui/Icons";

interface EmptyStateProps {
  title: string;
  description: string;
  icon?: ReactNode;
  action?: ReactNode;
}

export function EmptyState({ title, description, icon, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center p-8 text-center sm:p-12 select-none">
      <div className="mb-3 flex h-14 w-14 items-center justify-center rounded-2xl bg-[#CCFBF1] text-[#0D9488]">
        {icon ?? <IconInbox className="w-7 h-7" />}
      </div>
      <h3 className="text-sm font-extrabold text-[#0F172A]">{title}</h3>
      <p className="mt-1 max-w-sm text-xs font-medium text-[#64748B]">{description}</p>
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

interface ErrorStateProps {
  title?: string;
  message: string;
  onRetry?: () => void;
}

export function ErrorState({
  title = "Terjadi Kesalahan",
  message,
  onRetry,
}: ErrorStateProps) {
  return (
    <div className="flex flex-col items-center justify-center rounded-2xl border border-rose-100 bg-rose-50/60 p-6 text-center">
      <div className="mb-2 flex h-10 w-10 items-center justify-center rounded-xl bg-rose-100 text-rose-600">
        <IconAlertTriangle className="w-5 h-5" />
      </div>
      <h3 className="text-sm font-bold text-rose-900">{title}</h3>
      <p className="mt-1 max-w-md text-xs font-medium text-rose-700">{message}</p>
      {onRetry && (
        <button
          type="button"
          onClick={onRetry}
          className="mt-3 rounded-xl bg-rose-600 px-3.5 py-1.5 text-xs font-bold text-white transition-colors hover:bg-rose-700"
        >
          Coba Lagi
        </button>
      )}
    </div>
  );
}
