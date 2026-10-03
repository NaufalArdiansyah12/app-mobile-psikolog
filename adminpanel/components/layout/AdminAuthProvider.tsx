"use client";

/**
 * AdminAuthProvider:
 * Menyimpan state admin, layout drawer, dan collapse sidebar secara konsisten
 * antara Server SSR dan Client Hydration untuk mencegah hydration mismatch.
 */

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { getCachedAuthUser, requireAdmin } from "@/lib/auth";
import { clearToken } from "@/lib/token";
import { UNAUTHORIZED_EVENT } from "@/lib/api";
import type { AuthUser } from "@/types/auth";

interface AdminContextValue {
  user: AuthUser | null;
  sidebarOpen: boolean;
  setSidebarOpen: (open: boolean) => void;
  sidebarCollapsed: boolean;
  setSidebarCollapsed: (collapsed: boolean) => void;
}

const AdminContext = createContext<AdminContextValue>({
  user: null,
  sidebarOpen: false,
  setSidebarOpen: () => {},
  sidebarCollapsed: false,
  setSidebarCollapsed: () => {},
});

export function useAdmin() {
  return useContext(AdminContext);
}

export function AdminAuthProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  // State konsisten null saat initial SSR & hydration
  const [user, setUser] = useState<AuthUser | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  useEffect(() => {
    let cancelled = false;

    // Baca user dari cache localStorage di client setelah hydration
    const cached = getCachedAuthUser();
    if (cached) {
      setUser(cached);
    }

    const verify = async () => {
      try {
        const admin = await requireAdmin();
        if (!cancelled) {
          setUser(admin);
        }
      } catch {
        if (!cancelled) {
          clearToken();
          router.replace("/login");
        }
      }
    };

    verify();

    const onUnauthorized = () => {
      clearToken();
      router.replace("/login");
    };

    window.addEventListener(UNAUTHORIZED_EVENT, onUnauthorized);
    return () => {
      cancelled = true;
      window.removeEventListener(UNAUTHORIZED_EVENT, onUnauthorized);
    };
  }, [router]);

  return (
    <AdminContext.Provider
      value={{
        user,
        sidebarOpen,
        setSidebarOpen,
        sidebarCollapsed,
        setSidebarCollapsed,
      }}
    >
      {children}
    </AdminContext.Provider>
  );
}
