"use client";

/**
 * AdminLayout: guard autentikasi (role admin) + shell admin panel
 * (sidebar kiri, navbar atas, content area) dengan responsif mobile.
 */

import { useCallback, useEffect, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { Sidebar } from "@/components/layout/Sidebar";
import { Navbar } from "@/components/layout/Navbar";
import { LoadingState } from "@/components/ui/Loading";
import { UNAUTHORIZED_EVENT } from "@/lib/api";
import { getCachedAuthUser, requireAdmin } from "@/lib/auth";
import { clearToken } from "@/lib/token";
import { cx } from "@/lib/utils";
import type { AuthUser } from "@/types/auth";

export function AdminLayout({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [user, setUser] = useState<AuthUser | null>(() => getCachedAuthUser());
  const [checking, setChecking] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const redirectLogin = useCallback(() => {
    clearToken();
    router.replace("/login");
  }, [router]);

  // Verifikasi sesi + role admin via API /auth/me
  useEffect(() => {
    let cancelled = false;

    const verify = async () => {
      try {
        const admin = await requireAdmin();
        if (!cancelled) setUser(admin);
      } catch {
        if (!cancelled) redirectLogin();
      } finally {
        if (!cancelled) setChecking(false);
      }
    };

    verify();

    // Auto-logout saat API membalas 401
    const onUnauthorized = () => redirectLogin();
    window.addEventListener(UNAUTHORIZED_EVENT, onUnauthorized);

    return () => {
      cancelled = true;
      window.removeEventListener(UNAUTHORIZED_EVENT, onUnauthorized);
    };
  }, [redirectLogin]);

  if (checking) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-50">
        <LoadingState label="Memverifikasi akses admin..." />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Sidebar desktop */}
      <aside className="fixed inset-y-0 left-0 z-50 hidden w-64 lg:block">
        <Sidebar />
      </aside>

      {/* Sidebar mobile (drawer) */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div
            className="absolute inset-0 bg-slate-900/50"
            onClick={() => setSidebarOpen(false)}
            aria-hidden
          />
          <aside className="absolute inset-y-0 left-0 w-64 shadow-2xl">
            <Sidebar onNavigate={() => setSidebarOpen(false)} />
          </aside>
        </div>
      )}

      {/* Konten */}
      <div className="lg:pl-64">
        <Navbar user={user} onOpenSidebar={() => setSidebarOpen(true)} />
        <main className={cx("mx-auto w-full max-w-7xl px-4 py-6 sm:px-6 lg:px-8")}>
          {children}
        </main>
      </div>
    </div>
  );
}
