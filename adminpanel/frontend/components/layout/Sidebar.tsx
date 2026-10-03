"use client";

/** Sidebar admin: brand, menu navigasi, dan tombol logout. */

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cx } from "@/lib/utils";

interface SidebarProps {
  /** Dipakai di mobile drawer. */
  onNavigate?: () => void;
}

interface MenuItem {
  href: string;
  label: string;
  icon: string;
  match?: (pathname: string) => boolean;
}

const MENU: MenuItem[] = [
  { href: "/dashboard", label: "Dashboard", icon: "📊" },
  {
    href: "/doctors",
    label: "Dokter",
    icon: "🩺",
    match: (p) => p === "/doctors" || p.startsWith("/doctors/"),
  },
  {
    href: "/users",
    label: "User",
    icon: "👥",
    match: (p) => p === "/users" || p.startsWith("/users/"),
  },
  {
    href: "/sliders",
    label: "Slider",
    icon: "🖼️",
    match: (p) => p === "/sliders" || p.startsWith("/sliders/"),
  },
  {
    href: "/reports",
    label: "Laporan",
    icon: "🚨",
    match: (p) => p === "/reports" || p.startsWith("/reports/"),
  },
  { href: "/settings", label: "Pengaturan", icon: "⚙️" },
];

export function Sidebar({ onNavigate }: SidebarProps) {
  const pathname = usePathname();

  const isActive = (item: MenuItem) =>
    item.match ? item.match(pathname) : pathname === item.href;

  return (
    <div className="flex h-full flex-col bg-primary-950 text-slate-200">
      {/* Brand */}
      <div className="flex items-center gap-3 border-b border-primary-900 px-5 py-5">
        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-accent-500 text-lg font-bold text-primary-950">
          D
        </div>
        <div>
          <p className="text-sm font-bold tracking-wide text-white">ADMIN DOKTER</p>
          <p className="text-[11px] text-slate-400">Panel Administrator</p>
        </div>
      </div>

      {/* Menu */}
      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
        <p className="px-3 pb-2 text-[11px] font-semibold tracking-wider text-slate-500 uppercase">
          Menu Utama
        </p>

        {MENU.map((item) => {
          const active = isActive(item);
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={onNavigate}
              className={cx(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm transition-colors",
                active
                  ? "bg-accent-500 font-semibold text-primary-950 shadow-sm"
                  : "text-slate-300 hover:bg-primary-900 hover:text-white"
              )}
            >
              <span className="text-base leading-none">{item.icon}</span>
              {item.label}
            </Link>
          );
        })}

        {/* Submenu Dokter */}
        <div className="mt-1 space-y-1 pl-4">
          <Link
            href="/doctors?status=pending"
            onClick={onNavigate}
            className={cx(
              "flex items-center gap-2 rounded-lg px-3 py-2 text-[13px] transition-colors",
              pathname === "/doctors" && "text-slate-100"
            )}
          >
            <span className="h-1.5 w-1.5 rounded-full bg-amber-400" />
            <span className="text-slate-400 hover:text-slate-200">Verifikasi Dokter</span>
          </Link>
        </div>
      </nav>

      {/* Footer: info versi */}
      <div className="border-t border-primary-900 px-5 py-3">
        <p className="text-[11px] text-slate-500">
          v1.0.0 · Next.js + FastAPI
        </p>
      </div>
    </div>
  );
}
