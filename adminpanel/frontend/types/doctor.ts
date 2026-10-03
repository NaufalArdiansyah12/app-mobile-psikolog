/** Tipe untuk data dokter. */

export type VerificationStatus = "pending" | "approved" | "rejected";

export interface DoctorDocument {
  id: number;
  document_type: string;
  document_path: string;
  verification_status: VerificationStatus;
  created_at?: string | null;
}

export interface Doctor {
  id: number;
  user_id: number;
  name: string;
  email: string;
  phone?: string | null;
  avatar?: string | null;
  specialization?: string | null;
  license_number?: string | null;
  education?: string | null;
  experience?: string | null;
  bio?: string | null;
  verification_status: VerificationStatus;
  rejection_reason?: string | null;
  verified_at?: string | null;
  is_active: boolean;
  created_at?: string | null;
  updated_at?: string | null;
  documents: DoctorDocument[];
}
