"use client";

/**
 * Topbar/Navbar MindPal Theme:
 * - Current Date & Bold Title
 * - Full Rounded Pill Search Input
 * - Notification Bell & Avatar with Ring + Dropdown Menu
 */

import { useEffect, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { logout } from "@/lib/auth";
import { cx, initials, roleLabel } from "@/lib/utils";
import type { AuthUser } from "@/types/auth";

interface NavbarProps {
  user: AuthUser | null;
  onOpenSidebar: () => void;
}

const TITLES: { match: (p: string) => boolean; title: string }[] = [
  { match: (p) => p === "/dashboard", title: "Dashboard" },
  { match: (p) => p === "/doctors", title: "Kelola Dokter & Psikolog" },
  { match: (p) => p.startsWith("/doctors/"), title: "Detail & Verifikasi Dokter" },
  { match: (p) => p === "/users", title: "Kelola Pengguna" },
  { match: (p) => p.startsWith("/users/"), title: "Detail Pengguna" },
  { match: (p) => p === "/sliders", title: "Banner & Promo" },
  { match: (p) => p === "/sliders/create", title: "Tambah Slider" },
  { match: (p) => p.startsWith("/sliders/") && p.endsWith("/edit"), title: "Edit Slider" },
  { match: (p) => p === "/reports", title: "Laporan Pengguna" },
  { match: (p) => p.startsWith("/reports/"), title: "Detail Laporan" },
  { match: (p) => p === "/settings", title: "Pengaturan Sistem" },
];

export function Navbar({ user, onOpenSidebar }: NavbarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [menuOpen, setMenuOpen] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  const title = TITLES.find((t) => t.match(pathname))?.title ?? "Dashboard";

  const currentDate = new Date().toLocaleDateString("id-ID", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  });

  useEffect(() => {
    if (!menuOpen) return;
    const handler = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setMenuOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [menuOpen]);

  const handleLogout = async () => {
    setLoggingOut(true);
    await logout();
    router.replace("/login");
  };

  return (
    <header className="pb-3">
      {/* Mobile Top Header */}
      <div className="flex lg:hidden items-center justify-between pb-3 mb-3 border-b border-[#E2E8F0]">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onOpenSidebar}
            aria-label="Buka Menu"
            className="p-2 rounded-xl bg-[#CCFBF1] text-[#0D9488] active:scale-95 transition-all"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
              <line x1="4" x2="20" y1="12" y2="12" strokeLinecap="round" />
              <line x1="4" x2="20" y1="6" y2="6" strokeLinecap="round" />
              <line x1="4" x2="20" y1="18" y2="18" strokeLinecap="round" />
            </svg>
          </button>
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full overflow-hidden relative shadow-xs ring-2 ring-[#0D9488]/30 flex-shrink-0">
              <Image
                src="/logo-2.jpeg"
                alt="Hevenly Logo"
                width={32}
                height={32}
                className="object-cover w-full h-full"
              />
            </div>
            <span className="font-bold text-base text-[#0F172A] tracking-tight">Hevenly Admin</span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full ring-2 ring-[#0D9488]/40 overflow-hidden bg-[#CCFBF1] flex items-center justify-center text-xs font-bold text-[#0D9488]">
            {initials(user?.name)}
          </div>
        </div>
      </div>

      {/* Desktop Top Filter & Search Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl sm:text-2xl font-extrabold text-[#0F172A] tracking-tight">{title}</h1>
          <p
            suppressHydrationWarning
            className="text-xs font-semibold text-[#64748B] mt-0.5 capitalize"
          >
            {currentDate}
          </p>
        </div>

        <div className="flex items-center gap-3 w-full sm:w-auto">
          {/* Full Rounded Pill Search */}
          <div className="relative flex-1 sm:w-64">
            <input
              type="text"
              placeholder="Cari data..."
              className="w-full bg-[#F8FAF9] border border-[#E2E8F0] text-xs font-medium text-[#0F172A] placeholder-[#94A3B8] rounded-full pl-5 pr-10 py-2.5 outline-none focus:ring-2 focus:ring-[#0D9488]/40 focus:border-[#0D9488] focus:bg-white transition-all"
            />
            <button
              type="button"
              aria-label="Cari"
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#94A3B8] hover:text-[#0D9488] transition-colors"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
                <circle cx="11" cy="11" r="8" strokeLinecap="round" strokeLinejoin="round" />
                <path d="m21 21-4.3-4.3" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          </div>

          {/* User Profile Pill & Dropdown */}
          <div ref={menuRef} className="relative hidden sm:block">
            <button
              type="button"
              onClick={() => setMenuOpen((v) => !v)}
              className="flex items-center gap-2.5 bg-[#F8FAF9] border border-[#E2E8F0] hover:bg-white rounded-full pl-3.5 pr-1.5 py-1 transition-all active:scale-98"
            >
              <span className="text-left leading-none">
                <span className="block text-xs font-bold text-[#0F172A] truncate max-w-[120px]">
                  {user?.name ?? "Admin"}
                </span>
                <span className="block text-[10px] font-semibold text-[#0D9488] mt-0.5">
                  {user ? roleLabel(user.role) : "Staff"}
                </span>
              </span>
              <div className="w-8 h-8 rounded-full ring-2 ring-[#0D9488]/30 bg-[#0D9488] text-white flex items-center justify-center text-xs font-bold shadow-xs">
                {initials(user?.name)}
              </div>
            </button>

            {menuOpen && (
              <div className="absolute right-0 mt-2 w-56 overflow-hidden rounded-2xl border border-[#E2E8F0] bg-white py-1.5 shadow-xl z-50 animate-toast-in">
                <div className="border-b border-[#E2E8F0] px-4 py-3">
                  <p className="truncate text-xs font-bold text-[#0F172A]">{user?.name}</p>
                  <p className="truncate text-[11px] text-[#64748B] mt-0.5">{user?.email}</p>
                </div>
                <Link
                  href="/settings"
                  onClick={() => setMenuOpen(false)}
                  className="flex items-center gap-2 px-4 py-2.5 text-xs font-semibold text-[#0F172A] hover:bg-[#F0FDFA] hover:text-[#0D9488] transition-colors"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
                    <circle cx="12" cy="12" r="3" />
                  </svg>
                  <span>Pengaturan Profil</span>
                </Link>
                <button
                  type="button"
                  onClick={handleLogout}
                  disabled={loggingOut}
                  className={cx(
                    "flex items-center gap-2 w-full px-4 py-2.5 text-left text-xs font-semibold text-rose-600 hover:bg-rose-50 transition-colors",
                    loggingOut && "opacity-50"
                  )}
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                    <polyline points="16 17 21 12 16 7" />
                    <line x1="21" y1="12" x2="9" y2="12" />
                  </svg>
                  <span>{loggingOut ? "Keluar..." : "Keluar"}</span>
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
}
