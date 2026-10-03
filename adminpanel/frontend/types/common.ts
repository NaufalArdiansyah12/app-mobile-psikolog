/** Tipe umum untuk response API & statistik dashboard. */

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  total_pages: number;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  pagination?: Pagination;
}

export interface DashboardStats {
  total_users: number;
  total_admins: number;
  total_doctors: number;
  pending_verification: number;
  verified_doctors: number;
  total_reports: number;
  unhandled_reports: number;
  total_sliders: number;
  active_sliders: number;
  suspended_users: number;
}

export interface ActivityLog {
  id: number;
  admin_id?: number | null;
  action: string;
  target_type?: string | null;
  target_id?: number | null;
  description?: string | null;
  created_at?: string | null;
}
