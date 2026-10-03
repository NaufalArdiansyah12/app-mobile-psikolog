import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

/**
 * Proteksi rute admin (Next.js 16: middleware -> proxy).
 *
 * Lapisan pertama: halaman admin hanya dibuka bila ada token (cookie).
 * Lapisan kedua: AdminLayout memverifikasi token + role admin via API /auth/me.
 * Lapisan ketiga: SEMUA endpoint backend dilindungi require_admin (otorisasi
 * sesungguhnya ada di backend - jangan mengandalkan frontend saja).
 */

const COOKIE_NAME = "admin_dokter_token";

const PROTECTED_PATHS = [
  "/dashboard",
  "/doctors",
  "/users",
  "/sliders",
  "/reports",
  "/settings",
];

function isProtected(pathname: string): boolean {
  return PROTECTED_PATHS.some(
    (p) => pathname === p || pathname.startsWith(`${p}/`)
  );
}

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hasToken = Boolean(request.cookies.get(COOKIE_NAME)?.value);

  // Halaman admin tanpa token -> arahkan ke login
  if (isProtected(pathname) && !hasToken) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.search = "";
    return NextResponse.redirect(url);
  }

  // Sudah login tapi membuka /login -> arahkan ke dashboard
  if (pathname === "/login" && hasToken) {
    const url = request.nextUrl.clone();
    url.pathname = "/dashboard";
    url.search = "";
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/doctors/:path*",
    "/users/:path*",
    "/sliders/:path*",
    "/reports/:path*",
    "/settings/:path*",
    "/login",
  ],
};
