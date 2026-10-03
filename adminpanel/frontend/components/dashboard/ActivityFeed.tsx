"use client";

/** Section "Aktivitas Terbaru" di dashboard (dari admin_activity_logs). */

import { EmptyState } from "@/components/ui/State";
import { formatDateTime } from "@/lib/utils";
import type { ActivityLog } from "@/types/common";

const ACTION_META: Record<string, { icon: string; color: string }> = {
  login: { icon: "🔑", color: "bg-primary-50 text-primary-600" },
  logout: { icon: "🚪", color: "bg-slate-100 text-slate-600" },
  approve_doctor: { icon: "✅", color: "bg-emerald-50 text-emerald-600" },
  reject_doctor: { icon: "⛔", color: "bg-red-50 text-red-600" },
  activate_doctor: { icon: "🩺", color: "bg-emerald-50 text-emerald-600" },
  deactivate_doctor: { icon: "⏸️", color: "bg-amber-50 text-amber-600" },
  activate_user: { icon: "👤", color: "bg-emerald-50 text-emerald-600" },
  deactivate_user: { icon: "🚫", color: "bg-amber-50 text-amber-600" },
  suspend_user: { icon: "⛔", color: "bg-red-50 text-red-600" },
  delete_user: { icon: "🗑️", color: "bg-red-50 text-red-600" },
  create_slider: { icon: "➕", color: "bg-primary-50 text-primary-600" },
  update_slider: { icon: "✏️", color: "bg-primary-50 text-primary-600" },
  edit_slider: { icon: "✏️", color: "bg-primary-50 text-primary-600" },
  delete_slider: { icon: "🗑️", color: "bg-red-50 text-red-600" },
  activate_slider: { icon: "🟢", color: "bg-emerald-50 text-emerald-600" },
  deactivate_slider: { icon: "⚪", color: "bg-slate-100 text-slate-600" },
  update_report_status: { icon: "📋", color: "bg-accent-50 text-accent-600" },
};

interface ActivityFeedProps {
  activities: ActivityLog[];
}

export function ActivityFeed({ activities }: ActivityFeedProps) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-200 px-5 py-4">
        <h3 className="text-sm font-semibold text-slate-900">Aktivitas Terbaru</h3>
      </div>

      {activities.length === 0 ? (
        <EmptyState title="Belum ada aktivitas" description="Belum ada aktivitas admin." icon="🕓" />
      ) : (
        <ul className="max-h-[26rem] divide-y divide-slate-100 overflow-y-auto">
          {activities.map((log) => {
            const meta = ACTION_META[log.action] ?? {
              icon: "📌",
              color: "bg-slate-100 text-slate-600",
            };
            return (
              <li key={log.id} className="flex items-start gap-3 px-5 py-3">
                <span
                  className={`mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-sm ${meta.color}`}
                >
                  {meta.icon}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm text-slate-700">
                    {log.description || log.action}
                  </p>
                  <p className="text-[11px] text-slate-400">
                    {formatDateTime(log.created_at)}
                  </p>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
