/** Tipe untuk laporan user terhadap dokter. */

export type ReportStatus = "pending" | "reviewing" | "resolved" | "rejected";

export interface ReportCategory {
  id: number;
  name: string;
  description?: string | null;
}

export interface Report {
  id: number;
  user_id: number;
  doctor_id: number;
  category_id?: number | null;
  description: string;
  evidence?: string | null;
  status: ReportStatus;
  admin_note?: string | null;
  resolved_at?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
  reporter: {
    id: number;
    name: string;
    email?: string | null;
    phone?: string | null;
  } | null;
  doctor: {
    id: number;
    name: string;
    specialization?: string | null;
    license_number?: string | null;
  } | null;
  category: {
    id?: number | null;
    name?: string | null;
  } | null;
}
