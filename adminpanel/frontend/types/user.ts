/** Tipe untuk data user. */

import type { Role, UserStatus } from "@/types/auth";

export interface User {
  id: number;
  name: string;
  email: string;
  phone?: string | null;
  role: Role;
  status: UserStatus;
  avatar?: string | null;
  created_at?: string | null;
  updated_at?: string | null;
  doctor?: {
    id: number;
    specialization?: string | null;
    license_number?: string | null;
    verification_status: string;
    is_active: boolean;
  };
}
