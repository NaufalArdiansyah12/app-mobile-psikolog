"use client";

/**
 * Sidebar Rail (MindPal Teal Palette):
 * - Background Primary Teal solid (#0D9488) identik dengan Mobile App
 * - Squircle active tab (white bg + text #0D9488)
 * - Mendukung Mode Full & Minimize
 */

import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { logout } from "@/lib/auth";
import { cx } from "@/lib/utils";

interface SidebarProps {
  onNavigate?: () => void;
  collapsed?: boolean;
  onToggleCollapse?: () => void;
}

interface MenuItem {
  href: string;
  label: string;
  match?: (pathname: string) => boolean;
  svgIcon: React.ReactNode;
}

const MENU: MenuItem[] = [
  {
    href: "/dashboard",
    label: "Dashboard",
    svgIcon: (
      <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
        <polyline points="9 22 9 12 15 12 15 22" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    href: "/doctors",
    label: "Kelola Dokter",
    match: (p) => p === "/doctors" || p.startsWith("/doctors/"),
    svgIcon: (
      <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" />
        <rect x="8" y="2" width="8" height="4" rx="1" ry="1" strokeLinecap="round" strokeLinejoin="round" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M12 11v6" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 14h6" />
      </svg>
    ),
  },
  {
    href: "/users",
    label: "Kelola User",
    match: (p) => p === "/users" || p.startsWith("/users/"),
    svgIcon: (
      <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
        <circle cx="9" cy="7" r="4" strokeLinecap="round" strokeLinejoin="round" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M22 21v-2a4 4 0 0 0-3-3.87" />
        <path strokeLinecap="round" strokeLinejoin="round" d="M16 3.13a4 4 0 0 1 0 7.75" />
      </svg>
    ),
  },
  {
    href: "/sliders",
    label: "Banner Slider",
    match: (p) => p === "/sliders" || p.startsWith("/sliders/"),
    svgIcon: (
      <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <rect width="18" height="18" x="3" y="3" rx="2" ry="2" strokeLinecap="round" strokeLinejoin="round" />
        <circle cx="9" cy="9" r="2" strokeLinecap="round" strokeLinejoin="round" />
        <path strokeLinecap="round" strokeLinejoin="round" d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21" />
      </svg>
    ),
  },
  {
    href: "/reports",
    label: "Laporan User",
    match: (p) => p === "/reports" || p.startsWith("/reports/"),
    svgIcon: (
      <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z" />
        <line x1="12" y1="9" x2="12" y2="13" strokeLinecap="round" strokeLinejoin="round" />
        <line x1="12" y1="17" x2="12.01" y2="17" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    href: "/settings",
    label: "Pengaturan",
    match: (p) => p === "/settings",
    svgIcon: (
      <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
        <circle cx="12" cy="12" r="3" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
];

export function Sidebar({ onNavigate, collapsed = true, onToggleCollapse }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();

  const isActive = (item: MenuItem) =>
    item.match ? item.match(pathname) : pathname === item.href;

  const handleLogout = async () => {
    await logout();
    router.replace("/login");
  };

  return (
    <aside
      className={cx(
        "flex flex-col justify-between bg-[#0D9488] py-5 h-full rounded-[24px] shadow-sm select-none transition-all duration-300 overflow-hidden",
        collapsed ? "items-center px-2 w-20" : "items-stretch px-4 w-60"
      )}
    >
      {/* Top Header / Logo & Collapse Toggle */}
      <div className="flex flex-col gap-6 w-full">
        {/* Brand Bar */}
        <div className={cx("flex items-center w-full", collapsed ? "justify-center" : "justify-between px-1")}>
          <Link
            href="/dashboard"
            onClick={onNavigate}
            className="flex items-center gap-3 group"
            title="Hevenly Admin"
          >
            <div className="w-11 h-11 bg-white rounded-full flex items-center justify-center relative shadow-sm group-hover:scale-105 transition-transform flex-shrink-0 overflow-hidden ring-2 ring-white/40">
              <Image
                src="/logo-2.jpeg"
                alt="Hevenly Logo"
                width={44}
                height={44}
                className="object-cover w-full h-full"
                priority
              />
            </div>
            {!collapsed && (
              <div className="flex flex-col animate-toast-in overflow-hidden">
                <span className="font-extrabold text-sm text-white tracking-tight leading-none whitespace-nowrap">
                  Hevenly
                </span>
                <span className="text-[10px] font-bold text-[#CCFBF1] uppercase tracking-widest mt-1">
                  Panel Psikolog
                </span>
              </div>
            )}
          </Link>

          {/* Desktop Toggle Button */}
          {onToggleCollapse && !collapsed && (
            <button
              type="button"
              onClick={onToggleCollapse}
              aria-label="Kecilkan Sidebar"
              className="p-1.5 rounded-xl bg-white/20 hover:bg-white text-white hover:text-[#0D9488] transition-all"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                <polyline points="15 18 9 12 15 6" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          )}
        </div>

        {/* Expand button saat sidebar compact */}
        {onToggleCollapse && collapsed && (
          <button
            type="button"
            onClick={onToggleCollapse}
            aria-label="Perluas Sidebar"
            title="Perluas Sidebar"
            className="w-10 h-10 rounded-2xl bg-white/15 hover:bg-white text-white hover:text-[#0D9488] flex items-center justify-center transition-all mx-auto active:scale-95"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
              <polyline points="9 18 15 12 9 6" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </button>
        )}

        {/* Navigation List */}
        <nav className="flex flex-col gap-2 w-full mt-1">
          {MENU.map((item) => {
            const active = isActive(item);
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onNavigate}
                title={item.label}
                className={cx(
                  "group flex items-center transition-all duration-200 active:scale-98",
                  collapsed
                    ? "flex-col justify-center w-14 h-15 mx-auto rounded-2xl"
                    : "flex-row gap-3.5 px-3.5 py-3 rounded-2xl w-full",
                  active
                    ? "bg-white text-[#0D9488] shadow-sm font-bold"
                    : "text-white/90 hover:bg-white/15 hover:text-white font-semibold"
                )}
              >
                <div className="transition-transform group-hover:scale-110 flex items-center justify-center">
                  {item.svgIcon}
                </div>
                {collapsed ? (
                  active && (
                    <span className="text-[10px] tracking-tight mt-1 leading-none text-center">
                      {item.label}
                    </span>
                  )
                ) : (
                  <span className="text-xs tracking-tight whitespace-nowrap">
                    {item.label}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Footer / Sign Out */}
      <div className={cx("w-full pt-4 border-t border-white/20", collapsed ? "flex justify-center" : "px-2")}>
        <button
          type="button"
          onClick={handleLogout}
          aria-label="Keluar"
          title="Keluar dari Admin"
          className={cx(
            "flex items-center rounded-2xl text-white/90 hover:bg-white/15 hover:text-white active:scale-95 transition-all",
            collapsed
              ? "w-11 h-11 justify-center"
              : "w-full gap-3 px-3 py-2.5 text-xs font-bold"
          )}
        >
          <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
            <polyline points="16 17 21 12 16 7" strokeLinecap="round" strokeLinejoin="round" />
            <line x1="21" y1="12" x2="9" y2="12" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          {!collapsed && <span>Keluar</span>}
        </button>
      </div>
    </aside>
  );
}
