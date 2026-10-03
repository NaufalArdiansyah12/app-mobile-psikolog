/** Utility umum frontend (format tanggal, angka, classnames, dll.). */

/** Gabungkan conditional className (pengganti clsx sederhana). */
export function cx(...classes: Array<string | false | null | undefined>): string {
  return classes.filter(Boolean).join(" ");
}

/** Base URL backend (tanpa /api atau /api/admin) untuk membangun URL file upload. */
const API_ORIGIN = (
  process.env.NEXT_PUBLIC_API_URL || "http://127.0.0.1:8000/api/admin"
).replace(/\/api(\/admin)?$/, "");

/** Mengubah path /uploads/... menjadi URL lengkap yang bisa ditampilkan. */
export function assetUrl(path?: string | null): string {
  if (!path) return "";
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  return `${API_ORIGIN}${path.startsWith("/") ? "" : "/"}${path}`;
}

/** Format ISO date -> "02 Okt 2026". */
export function formatDate(value?: string | null): string {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleDateString("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

/** Format ISO date -> "02 Okt 2026, 14.30". */
export function formatDateTime(value?: string | null): string {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return date.toLocaleString("id-ID", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/** Format angka -> "1.250". */
export function formatNumber(value?: number | null): string {
  if (value === undefined || value === null) return "0";
  return value.toLocaleString("id-ID");
}

/** Inisial nama untuk avatar (maks 2 huruf). */
export function initials(name?: string | null): string {
  if (!name) return "?";
  const parts = name
    .replace(/^(dr\.?|drs\.?|drh\.?)\s+/i, "")
    .split(/\s+/)
    .filter(Boolean);
  if (parts.length === 0) return "?";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/** Label & warna badge untuk status umum. */
export type BadgeVariant =
  | "success"
  | "warning"
  | "danger"
  | "info"
  | "neutral"
  | "accent";

export function statusBadge(value: string): { label: string; variant: BadgeVariant } {
  switch (value) {
    case "approved":
      return { label: "Disetujui", variant: "success" };
    case "active":
      return { label: "Aktif", variant: "success" };
    case "resolved":
      return { label: "Selesai", variant: "success" };
    case "pending":
      return { label: "Menunggu", variant: "warning" };
    case "reviewing":
      return { label: "Direview", variant: "info" };
    case "rejected":
      return { label: "Ditolak", variant: "danger" };
    case "inactive":
      return { label: "Nonaktif", variant: "neutral" };
    case "suspended":
      return { label: "Ditangguhkan", variant: "danger" };
    default:
      return { label: value || "-", variant: "neutral" };
  }
}

/** Label Indonesia untuk status verifikasi dokter. */
export function verificationLabel(status: string): string {
  switch (status) {
    case "pending":
      return "Menunggu Verifikasi";
    case "approved":
      return "Terverifikasi";
    case "rejected":
      return "Ditolak";
    default:
      return status;
  }
}

/** Label Indonesia untuk status laporan. */
export function reportStatusLabel(status: string): string {
  switch (status) {
    case "pending":
      return "Belum Ditangani";
    case "reviewing":
      return "Sedang Direview";
    case "resolved":
      return "Selesai";
    case "rejected":
      return "Ditolak";
    default:
      return status;
  }
}

/** Label Indonesia untuk role. */
export function roleLabel(role: string): string {
  switch (role) {
    case "admin":
      return "Admin";
    case "doctor":
      return "Dokter";
    case "user":
      return "User";
    default:
      return role;
  }
}
