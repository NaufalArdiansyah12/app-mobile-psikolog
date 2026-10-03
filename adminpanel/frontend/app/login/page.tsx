"use client";

/**
 * Halaman login admin: /login
 * - Validasi: email wajib, format email valid, password wajib
 * - Hanya role admin yang diterima
 * - Sukses -> redirect /dashboard
 */

import { useEffect, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { FieldLabel, TextInput } from "@/components/ui/Form";
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

  // Jika sudah punya sesi -> langsung ke dashboard
  useEffect(() => {
    if (!hasToken()) return;

    // Cookie hilang = sesi sudah berakhir (logout/401). Bersihkan agar
    // tidak terjadi redirect loop dengan proxy.
    if (!document.cookie.includes("admin_dokter_token")) {
      clearToken();
      return;
    }

    fetchMe()
      .then((u) => {
        if (u.role === "admin") router.replace("/dashboard");
      })
      .catch(() => {
        // token basi - biarkan di halaman login
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
        setFormError("Terjadi kesalahan tak terduga. Coba lagi.");
      }
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-primary-950 px-4 py-10">
      {/*latar dekoratif */}
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="absolute -top-32 -left-32 h-96 w-96 rounded-full bg-accent-500/20 blur-3xl" />
        <div className="absolute -right-32 -bottom-32 h-96 w-96 rounded-full bg-primary-500/30 blur-3xl" />
      </div>

      <div className="relative w-full max-w-md">
        {/* Brand */}
        <div className="mb-6 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-accent-500 text-2xl font-bold text-primary-950 shadow-lg shadow-accent-500/30">
            D
          </div>
          <h1 className="text-2xl font-bold text-white">ADMIN DOKTER</h1>
          <p className="mt-1 text-sm text-slate-400">
            Masuk untuk mengelola aplikasi dokter
          </p>
        </div>

        {/* Card */}
        <form
          onSubmit={handleSubmit}
          noValidate
          className="rounded-2xl border border-primary-900 bg-primary-900/80 p-8 shadow-2xl backdrop-blur"
        >
          {formError && (
            <div
              role="alert"
              className="mb-5 rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300"
            >
              {formError}
            </div>
          )}

          <div className="mb-4">
            <FieldLabel htmlFor="email" required>
              Email
            </FieldLabel>
            <TextInput
              id="email"
              type="email"
              autoComplete="email"
              placeholder="admin@admindoctor.id"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              aria-invalid={Boolean(errors.email)}
              className={errors.email ? "border-red-500 focus:border-red-500 focus:ring-red-200" : ""}
            />
            {errors.email && (
              <p className="mt-1.5 text-xs text-red-400">{errors.email}</p>
            )}
          </div>

          <div className="mb-4">
            <FieldLabel htmlFor="password" required>
              Password
            </FieldLabel>
            <TextInput
              id="password"
              type="password"
              autoComplete="current-password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              aria-invalid={Boolean(errors.password)}
              className={errors.password ? "border-red-500 focus:border-red-500 focus:ring-red-200" : ""}
            />
            {errors.password && (
              <p className="mt-1.5 text-xs text-red-400">{errors.password}</p>
            )}
          </div>

          <label className="mb-6 flex cursor-pointer items-center gap-2 text-sm text-slate-300">
            <input
              type="checkbox"
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              className="h-4 w-4 rounded border-slate-600 bg-slate-800 text-primary-500 focus:ring-primary-500"
            />
            Remember me
          </label>

          <Button type="submit" loading={loading} className="w-full">
            {loading ? "Memeriksa..." : "Login"}
          </Button>

          <p className="mt-5 text-center text-xs text-slate-500">
            Belum punya akses admin? Hubungi pengelola sistem.
          </p>
        </form>
      </div>
    </div>
  );
}
