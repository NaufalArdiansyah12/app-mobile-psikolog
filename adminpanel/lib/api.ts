/**
 * API client terpusat untuk seluruh request ke backend FastAPI.
 *
 * Semua halaman frontend WAJIB memanggil API lewat file ini.
 * Base URL dibaca dari NEXT_PUBLIC_API_URL (.env.local).
 *
 * Menangani: loading (caller), 401, 403, 404, 422, 500 dengan pesan yang jelas.
 */

import { clearToken, getToken } from "@/lib/token";
import type { ApiResponse } from "@/types/common";

const BASE_URL =
  process.env.NEXT_PUBLIC_API_URL?.replace(/\/$/, "") || "http://127.0.0.1:8000/api/admin";

/** Base URL backend (tanpa /api atau /api/admin) - dipakai untuk file upload (gambar slider). */
export const API_ORIGIN = BASE_URL.replace(/\/api(\/admin)?$/, "");

/** Event yang didengarkan AdminLayout untuk auto-logout saat 401. */
export const UNAUTHORIZED_EVENT = "admin-auth:unauthorized";

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

/** Mengubah query params object menjadi string "?a=1&b=2". */
function buildQuery(params?: Record<string, string | number | boolean | undefined | null>): string {
  if (!params) return "";
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value === undefined || value === null || value === "") continue;
    search.append(key, String(value));
  }
  const qs = search.toString();
  return qs ? `?${qs}` : "";
}

function authHeaders(): Record<string, string> {
  const token = getToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

/** Parse pesan error dari response backend. */
async function toApiError(res: Response): Promise<ApiError> {
  let message = `Terjadi kesalahan (${res.status})`;

  try {
    const body = await res.json();
    if (body && typeof body.message === "string" && body.message) {
      message = body.message;
    } else if (Array.isArray(body?.detail)) {
      message = body.detail
        .map((d: { msg?: string }) => d?.msg)
        .filter(Boolean)
        .join("; ");
    } else if (typeof body?.detail === "string") {
      message = body.detail;
    }
  } catch {
    // response bukan JSON - pakai pesan default
  }

  // Penanganan status khusus
  if (res.status === 401) {
    clearToken();
    if (typeof window !== "undefined") {
      window.dispatchEvent(new CustomEvent(UNAUTHORIZED_EVENT));
    }
    if (message === "Terjadi kesalahan (401)") {
      message = "Sesi Anda berakhir. Silakan login kembali.";
    }
  } else if (res.status === 403) {
    message = message || "Anda tidak punya akses ke resource ini.";
  } else if (res.status === 404) {
    message = message || "Data tidak ditemukan.";
  } else if (res.status === 422) {
    message = message || "Data yang dikirim tidak valid.";
  } else if (res.status >= 500) {
    message = message || "Server sedang bermasalah. Coba lagi nanti.";
  }

  return new ApiError(message, res.status);
}

async function request<T>(
  path: string,
  options: RequestInit & { params?: Record<string, string | number | boolean | undefined | null> } = {}
): Promise<ApiResponse<T>> {
  const { params, ...init } = options;
  const url = `${BASE_URL}${path}${buildQuery(params)}`;

  let res: Response;
  try {
    res = await fetch(url, {
      ...init,
      headers: {
        Accept: "application/json",
        ...authHeaders(),
        ...(init.body && !(init.body instanceof FormData)
          ? { "Content-Type": "application/json" }
          : {}),
        ...(init.headers || {}),
      },
      cache: "no-store",
    });
  } catch {
    throw new ApiError(
      "Tidak dapat terhubung ke server API. Pastikan backend berjalan di http://127.0.0.1:8000",
      0
    );
  }

  if (!res.ok) {
    throw await toApiError(res);
  }

  return (await res.json()) as ApiResponse<T>;
}

/** GET request. */
export function apiGet<T>(
  path: string,
  params?: Record<string, string | number | boolean | undefined | null>
): Promise<ApiResponse<T>> {
  return request<T>(path, { method: "GET", params });
}

/** POST request dengan JSON body. */
export function apiPost<T>(path: string, body?: unknown): Promise<ApiResponse<T>> {
  return request<T>(path, {
    method: "POST",
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

/** POST request dengan FormData (upload file). */
export function apiUpload<T>(path: string, formData: FormData): Promise<ApiResponse<T>> {
  return request<T>(path, { method: "POST", body: formData });
}

/** PUT request dengan JSON body. */
export function apiPut<T>(path: string, body?: unknown): Promise<ApiResponse<T>> {
  return request<T>(path, {
    method: "PUT",
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

/** PUT request dengan FormData (update + upload file). */
export function apiPutUpload<T>(path: string, formData: FormData): Promise<ApiResponse<T>> {
  return request<T>(path, { method: "PUT", body: formData });
}

/** DELETE request. */
export function apiDelete<T>(path: string): Promise<ApiResponse<T>> {
  return request<T>(path, { method: "DELETE" });
}
