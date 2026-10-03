/**
 * Penyimpanan token JWT.
 * - localStorage: dipakai oleh client untuk request API
 * - cookie: dipakai oleh proxy.ts untuk proteksi rute (guard awal)
 */

const TOKEN_KEY = "admin_dokter_token";
const USER_KEY = "admin_dokter_user";
const COOKIE_NAME = "admin_dokter_token";
const COOKIE_MAX_AGE = 60 * 60 * 24; // 1 hari (detik)

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return window.localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(TOKEN_KEY, token);
  // Cookie agar bisa dibaca proxy.ts (Next.js) untuk proteksi rute
  document.cookie = `${COOKIE_NAME}=${encodeURIComponent(token)}; path=/; max-age=${COOKIE_MAX_AGE}; SameSite=Lax`;
}

export function clearToken(): void {
  if (typeof window === "undefined") return;
  window.localStorage.removeItem(TOKEN_KEY);
  window.localStorage.removeItem(USER_KEY);
  document.cookie = `${COOKIE_NAME}=; path=/; max-age=0; SameSite=Lax`;
}

export function getCachedUser<T>(): T | null {
  if (typeof window === "undefined") return null;
  const raw = window.localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export function setCachedUser<T>(user: T): void {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(USER_KEY, JSON.stringify(user));
}
