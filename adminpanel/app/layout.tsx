import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";
import { ToastProvider } from "@/components/ui/Toast";

const jakartaSans = Plus_Jakarta_Sans({
  variable: "--font-jakarta",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
});

export const metadata: Metadata = {
  title: {
    default: "ADMIN DOKTER | Hevenly",
    template: "%s | ADMIN DOKTER",
  },
  description:
    "Admin panel untuk mengelola dokter, user, slider, dan laporan aplikasi Hevenly.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="id" className={`${jakartaSans.variable} h-full antialiased`}>
      <body className="min-h-full bg-[#F8FAF9] text-[#0F172A] font-sans">
        <ToastProvider>{children}</ToastProvider>
      </body>
    </html>
  );
}
