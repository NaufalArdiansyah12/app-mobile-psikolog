"use client";

/**
 * AdminLayout (Full Screen Browser Layout):
 * - Halaman memenuhi 100% viewport (`h-screen w-screen overflow-hidden`)
 * - Sidebar fixed di sebelah kiri dengan fitur Expand / Minimize (Collapse)
 * - Area konten utama memiliki scrollbar independen (sidebarnya terkunci dan tidak ikut bergeser)
 * - Warna tema: Teal (#0D9488) solid selaras dengan mobile app
 */

import { type ReactNode } from "react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Navbar } from "@/components/layout/Navbar";
import { AdminAuthProvider, useAdmin } from "@/components/layout/AdminAuthProvider";

function AdminShell({ children }: { children: ReactNode }) {
  const { user, sidebarOpen, setSidebarOpen, sidebarCollapsed, setSidebarCollapsed } = useAdmin();

  return (
    <div className="h-screen w-screen bg-[#F8FAF9] text-[#0F172A] flex overflow-hidden select-none p-3 sm:p-4 gap-3 sm:gap-4">
      {/* Mobile Drawer */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div
            className="fixed inset-0 bg-[#0F172A]/40 backdrop-blur-xs"
            onClick={() => setSidebarOpen(false)}
            aria-hidden
          />
          <aside className="fixed inset-y-0 left-0 z-50 w-72 p-4">
            <Sidebar onNavigate={() => setSidebarOpen(false)} collapsed={false} />
          </aside>
        </div>
      )}

      {/* Desktop Fixed Left Sidebar (Terkunci, tidak ikut scroll) */}
      <div
        className={`hidden lg:flex flex-shrink-0 h-full transition-all duration-300 ${
          sidebarCollapsed ? "w-20" : "w-60"
        }`}
      >
        <Sidebar
          collapsed={sidebarCollapsed}
          onToggleCollapse={() => setSidebarCollapsed(!sidebarCollapsed)}
        />
      </div>

      {/* Main Workspace (Scrollable Independen) */}
      <div className="flex-1 min-w-0 h-full flex flex-col bg-white rounded-[28px] border border-[#E2E8F0] shadow-[0_10px_30px_-10px_rgba(13,148,136,0.14)] overflow-hidden">
        {/* Fixed Top Navbar inside container */}
        <div className="px-5 sm:px-7 pt-4 pb-2 border-b border-[#E2E8F0] bg-white z-20 flex-shrink-0">
          <Navbar user={user} onOpenSidebar={() => setSidebarOpen(true)} />
        </div>

        {/* Scrollable Content Body */}
        <main className="flex-1 overflow-y-auto px-5 sm:px-7 py-5 scroll-smooth">
          {children}
        </main>
      </div>
    </div>
  );
}

export function AdminLayout({ children }: { children: ReactNode }) {
  return (
    <AdminAuthProvider>
      <AdminShell>{children}</AdminShell>
    </AdminAuthProvider>
  );
}
