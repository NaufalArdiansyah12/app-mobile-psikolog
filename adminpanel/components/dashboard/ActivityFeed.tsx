"use client";

import { EmptyState } from "@/components/ui/State";
import { formatDateTime } from "@/lib/utils";
import type { ActivityLog } from "@/types/common";

function ActivityIcon({ action }: { action: string }) {
  const cls = "w-3.5 h-3.5";
  if (action === "login") {
    return (
      <svg className={cls} fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" />
        <polyline points="10 17 15 12 10 7" strokeLinecap="round" strokeLinejoin="round" />
        <line x1="15" y1="12" x2="3" y2="12" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    );
  }
  if (action === "logout") {
    return (
      <svg className={cls} fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
        <polyline points="16 17 21 12 16 7" strokeLinecap="round" strokeLinejoin="round" />
        <line x1="21" y1="12" x2="9" y2="12" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    );
  }
  if (action.includes("approve") || action.includes("activate")) {
    return (
      <svg className={cls} fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <polyline points="20 6 9 17 4 12" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    );
  }
  if (action.includes("reject") || action.includes("deactivate") || action.includes("suspend") || action.includes("delete")) {
    return (
      <svg className={cls} fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <line x1="18" y1="6" x2="6" y2="18" strokeLinecap="round" strokeLinejoin="round" />
        <line x1="6" y1="6" x2="18" y2="18" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    );
  }
  if (action.includes("slider") || action.includes("create")) {
    return (
      <svg className={cls} fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <line x1="12" y1="5" x2="12" y2="19" strokeLinecap="round" strokeLinejoin="round" />
        <line x1="5" y1="12" x2="19" y2="12" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    );
  }
  return (
    <svg className={cls} fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
      <circle cx="12" cy="12" r="3" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

const ACTION_COLORS: Record<string, string> = {
  login: "bg-[#CCFBF1] text-[#0D9488]",
  logout: "bg-[#F8FAF9] text-[#64748B]",
  approve_doctor: "bg-emerald-50 text-emerald-600",
  reject_doctor: "bg-rose-50 text-rose-600",
  activate_doctor: "bg-emerald-50 text-emerald-600",
  deactivate_doctor: "bg-amber-50 text-amber-700",
  activate_user: "bg-emerald-50 text-emerald-600",
  deactivate_user: "bg-amber-50 text-amber-700",
  suspend_user: "bg-rose-50 text-rose-600",
  delete_user: "bg-rose-50 text-rose-600",
  create_slider: "bg-[#CCFBF1] text-[#0D9488]",
  update_slider: "bg-[#CCFBF1] text-[#0D9488]",
  edit_slider: "bg-[#CCFBF1] text-[#0D9488]",
  delete_slider: "bg-rose-50 text-rose-600",
  activate_slider: "bg-emerald-50 text-emerald-600",
  deactivate_slider: "bg-[#F8FAF9] text-[#64748B]",
  update_report_status: "bg-[#CCFBF1] text-[#0D9488]",
};

export function ActivityFeed({ activities }: { activities: ActivityLog[] }) {
  if (activities.length === 0) {
    return (
      <EmptyState
        title="Belum ada aktivitas"
        description="Belum ada catatan aktivitas admin."
      />
    );
  }

  return (
    <ul className="max-h-[22rem] divide-y divide-[#E2E8F0] overflow-y-auto pr-1">
      {activities.map((log) => {
        const color = ACTION_COLORS[log.action] ?? "bg-[#F8FAF9] text-[#64748B]";
        return (
          <li key={log.id} className="flex items-start gap-3 py-2.5">
            <span
              className={`mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-xl ${color}`}
            >
              <ActivityIcon action={log.action} />
            </span>
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-bold text-[#0F172A]">
                {log.description || log.action}
              </p>
              <p className="text-[10px] font-semibold text-[#64748B] mt-0.5">
                {formatDateTime(log.created_at)}
              </p>
            </div>
          </li>
        );
      })}
    </ul>
  );
}
