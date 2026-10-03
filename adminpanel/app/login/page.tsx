"use client";

/**
 * Halaman Login Admin (MindPal Theme):
 * - Canvas Background #F8FAF9 with Teal Soft Glow
 * - Bento Login Card (rounded-[32px])
 * - MindPal Color Scheme: Primary Teal (#0D9488) & Soft Aqua Tint (#CCFBF1)
 */

import { useEffect, useState, type FormEvent } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { IconAlertTriangle } from "@/components/ui/Icons";
import { login, hasToken, fetchMe } from "@/lib/auth";
import { clearToken } from "@/lib/token";
import { ApiError } from "@/lib/api";

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function LoginPage() {
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(true);

  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!hasToken()) return;

    if (!document.cookie.includes("admin_dokter_token")) {
      clearToken();
      return;
    }

    fetchMe()
      .then((u) => {
        if (u.role === "admin") router.replace("/dashboard");
      })
      .catch(() => {
        // biarkan tetap di form login jika token expired
      });
  }, [router]);

  const validate = (): boolean => {
    const next: { email?: string; password?: string } = {};

    if (!email.trim()) {
      next.email = "Email wajib diisi";
    } else if (!EMAIL_REGEX.test(email.trim())) {
      next.email = "Format email tidak valid";
    }

    if (!password) {
      next.password = "Password wajib diisi";
    }

    setErrors(next);
    return Object.keys(next).length === 0;
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (!validate()) return;

    setLoading(true);
    try {
      await login({
        email: email.trim(),
        password,
        remember_me: rememberMe,
      });
      router.replace("/dashboard");
    } catch (err) {
      if (err instanceof ApiError) {
        setFormError(err.message);
      } else {
        setFormError("Email atau password tidak sesuai. Coba lagi.");
      }
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#F8FAF9] px-4 py-8 relative overflow-hidden select-none">
      {/* Ambient Glow Lights */}
      <div className="pointer-events-none absolute -top-24 -left-24 w-96 h-96 rounded-full bg-[#CCFBF1] blur-3xl opacity-60" />
      <div className="pointer-events-none absolute -bottom-24 -right-24 w-96 h-96 rounded-full bg-[#99F6E4] blur-3xl opacity-40" />

      <div className="relative w-full max-w-md">
        {/* Brand Logo & Header */}
        <div className="mb-6 text-center">
          <div className="mx-auto mb-3 w-16 h-16 rounded-full overflow-hidden relative shadow-[0_8px_18px_-4px_rgba(13,148,136,0.25)] ring-4 ring-[#CCFBF1]">
            <Image
              src="/logo-2.jpeg"
              alt="Hevenly Logo"
              width={64}
              height={64}
              className="object-cover w-full h-full"
              priority
            />
          </div>
          <h1 className="text-2xl font-extrabold text-[#0F172A] tracking-tight">Hevenly Admin</h1>
          <p className="mt-1 text-xs font-semibold text-[#64748B]">
            Panel Pengelola Layanan Psikolog & Konseling
          </p>
        </div>

        {/* Bento White Card */}
        <form
          onSubmit={handleSubmit}
          noValidate
          className="rounded-[32px] border border-[#E2E8F0] bg-white p-7 sm:p-9 shadow-[0_14px_34px_-10px_rgba(13,148,136,0.18)]"
        >
          {formError && (
            <div
              role="alert"
              className="mb-5 rounded-2xl border border-rose-100 bg-rose-50/80 p-3.5 text-xs font-bold text-rose-600 flex items-center gap-2"
            >
              <IconAlertTriangle className="w-4 h-4 shrink-0 text-rose-600" />
              <span>{formError}</span>
            </div>
          )}

          <div className="space-y-4">
            {/* Email Field */}
            <div>
              <label className="block text-xs font-bold text-[#0F172A] mb-1.5">
                Email Administrator
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@mindpal.id"
                autoComplete="email"
                required
                className="w-full bg-[#F8FAF9] border border-[#E2E8F0] rounded-2xl px-4 py-3 text-xs font-semibold text-[#0F172A] placeholder-[#94A3B8] outline-none focus:ring-2 focus:ring-[#0D9488]/40 focus:border-[#0D9488] focus:bg-white transition-all"
              />
              {errors.email && (
                <p className="mt-1 text-[11px] font-semibold text-rose-500">{errors.email}</p>
              )}
            </div>

            {/* Password Field */}
            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="block text-xs font-bold text-[#0F172A]">
                  Kata Sandi
                </label>
              </div>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                autoComplete="current-password"
                required
                className="w-full bg-[#F8FAF9] border border-[#E2E8F0] rounded-2xl px-4 py-3 text-xs font-semibold text-[#0F172A] placeholder-[#94A3B8] outline-none focus:ring-2 focus:ring-[#0D9488]/40 focus:border-[#0D9488] focus:bg-white transition-all"
              />
              {errors.password && (
                <p className="mt-1 text-[11px] font-semibold text-rose-500">{errors.password}</p>
              )}
            </div>

            {/* Remember Me Checkbox */}
            <div className="flex items-center justify-between pt-1">
              <label className="flex items-center gap-2 text-xs font-semibold text-[#64748B] cursor-pointer">
                <input
                  type="checkbox"
                  checked={rememberMe}
                  onChange={(e) => setRememberMe(e.target.checked)}
                  className="h-4 w-4 rounded-lg border-[#E2E8F0] text-[#0D9488] focus:ring-[#0D9488]/30"
                />
                <span>Ingat sesi masuk</span>
              </label>
            </div>

            {/* Submit Button */}
            <div className="pt-2">
              <Button
                type="submit"
                variant="primary"
                size="lg"
                loading={loading}
                className="w-full"
              >
                Masuk ke Dashboard
              </Button>
            </div>
          </div>

          {/* Quick Helper Credentials */}
          <div className="mt-6 pt-5 border-t border-[#E2E8F0] text-center">
            <p className="text-[11px] font-semibold text-[#64748B]">
              Default Admin: <span className="font-bold text-[#0F172A]">admin@mindpal.id</span> · <span className="font-bold text-[#0F172A]">admin123</span>
            </p>
          </div>
        </form>
      </div>
    </div>
  );
}
