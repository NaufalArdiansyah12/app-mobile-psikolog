/**
 * Helper autentikasi di sisi client: login, logout, dan guard role admin.
 */

import { apiGet, apiPost, ApiError } from "@/lib/api";
import {
  clearToken,
  getCachedUser,
  getToken,
  setCachedUser,
  setToken,
} from "@/lib/token";
import type { AuthUser, LoginPayload } from "@/types/auth";

/**
 * Login ke backend. Jika bukan admin, token tetap dibuang dan error dikembalikan.
 */
export async function login(payload: LoginPayload): Promise<AuthUser> {
  const res = await apiPost<{ access_token: string; token_type: string; user: AuthUser }>(
    "/auth/login",
    payload
  );

  const user = res.data.user;

  // HANYA role admin yang boleh masuk admin panel
  if (user.role !== "admin") {
    clearToken();
    throw new ApiError(
      "Akun ini bukan admin. Silakan gunakan akun admin untuk membuka panel ini.",
      403
    );
  }

  if (user.status !== "active") {
    clearToken();
    throw new ApiError("Akun admin Anda tidak aktif. Hubungi pengelola sistem.", 403);
  }

  setToken(res.data.access_token);
  setCachedUser(user);
  return user;
}

/** Logout: catat ke backend lalu bersihkan token di klien. */
export async function logout(): Promise<void> {
  try {
    await apiPost("/auth/logout");
  } catch {
    // diabaikan - token tetap dibersihkan di bawah
  } finally {
    clearToken();
  }
}

/** Ambil profil admin dari backend berdasarkan token yang tersimpan. */
export async function fetchMe(): Promise<AuthUser> {
  const res = await apiGet<AuthUser>("/auth/me");
  return res.data;
}

export function hasToken(): boolean {
  return Boolean(getToken());
}

export function getCachedAuthUser(): AuthUser | null {
  return getCachedUser<AuthUser>();
}

/**
 * Guard: memastikan user adalah admin.
 * Melempar ApiError bila token tidak ada, tidak valid, atau role bukan admin.
 */
export async function requireAdmin(): Promise<AuthUser> {
  if (!hasToken()) {
    throw new ApiError("Silakan login terlebih dahulu", 401);
  }

  const user = await fetchMe();

  if (user.role !== "admin") {
    clearToken();
    throw new ApiError("Akses ditolak: hanya admin yang diizinkan", 403);
  }

  setCachedUser(user);
  return user;
}
