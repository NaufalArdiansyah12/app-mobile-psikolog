"use client";

/** Topbar/Navbar: judul halaman, tombol menu mobile, dan menu user. */

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { logout } from "@/lib/auth";
import { cx, initials, roleLabel } from "@/lib/utils";
import type { AuthUser } from "@/types/auth";

interface NavbarProps {
  user: AuthUser | null;
  /** Membuka sidebar drawer di mobile. */
  onOpenSidebar: () => void;
}

const TITLES: { match: (p: string) => boolean; title: string }[] = [
  { match: (p) => p === "/dashboard", title: "Dashboard" },
  { match: (p) => p === "/doctors", title: "Semua Dokter" },
  { match: (p) => p.startsWith("/doctors/"), title: "Detail Dokter" },
  { match: (p) => p === "/users", title: "Kelola User" },
  { match: (p) => p.startsWith("/users/"), title: "Detail User" },
  { match: (p) => p === "/sliders", title: "Kelola Slider" },
  { match: (p) => p === "/sliders/create", title: "Tambah Slider" },
  { match: (p) => p.startsWith("/sliders/") && p.endsWith("/edit"), title: "Edit Slider" },
  { match: (p) => p === "/reports", title: "Laporan" },
  { match: (p) => p.startsWith("/reports/"), title: "Detail Laporan" },
  { match: (p) => p === "/settings", title: "Pengaturan" },
];

export function Navbar({ user, onOpenSidebar }: NavbarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [menuOpen, setMenuOpen] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  const title = TITLES.find((t) => t.match(pathname))?.title ?? "Admin Panel";

  // Tutup dropdown saat klik di luar
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
    <header className="sticky top-0 z-40 border-b border-slate-200 bg-white/90 backdrop-blur">
      <div className="flex h-16 items-center justify-between gap-4 px-4 sm:px-6">
        {/* Kiri: hamburger + judul */}
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onOpenSidebar}
            className="rounded-lg p-2 text-slate-600 transition-colors hover:bg-slate-100 lg:hidden"
            aria-label="Buka menu"
          >
            ☰
          </button>
          <div>
            <h1 className="text-lg font-semibold text-slate-900">{title}</h1>
            <p className="hidden text-xs text-slate-500 sm:block">
              Kelola data aplikasi dokter dari satu tempat
            </p>
          </div>
        </div>

        {/* Kanan: user menu */}
        <div ref={menuRef} className="relative">
          <button
            type="button"
            onClick={() => setMenuOpen((v) => !v)}
            className="flex items-center gap-3 rounded-lg px-2 py-1.5 transition-colors hover:bg-slate-100"
          >
            <span className="hidden text-right sm:block">
              <span className="block text-sm font-medium text-slate-800">
                {user?.name ?? "..."}
              </span>
              <span className="block text-xs text-slate-500">
                {user ? roleLabel(user.role) : ""}
              </span>
            </span>
            <span className="flex h-9 w-9 items-center justify-center rounded-full bg-primary-600 text-sm font-semibold text-white">
              {initials(user?.name)}
            </span>
          </button>

          {menuOpen && (
            <div className="absolute right-0 mt-2 w-56 overflow-hidden rounded-xl border border-slate-200 bg-white py-1 shadow-xl">
              <div className="border-b border-slate-100 px-4 py-3">
                <p className="truncate text-sm font-medium text-slate-800">
                  {user?.name}
                </p>
                <p className="truncate text-xs text-slate-500">{user?.email}</p>
              </div>
              <Link
                href="/settings"
                onClick={() => setMenuOpen(false)}
                className="block px-4 py-2.5 text-sm text-slate-700 hover:bg-slate-50"
              >
                ⚙️ Pengaturan
              </Link>
              <button
                type="button"
                onClick={handleLogout}
                disabled={loggingOut}
                className={cx(
                  "block w-full px-4 py-2.5 text-left text-sm text-red-600 hover:bg-red-50",
                  loggingOut && "opacity-60"
                )}
              >
                {loggingOut ? "Keluar..." : "🚪 Logout"}
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
