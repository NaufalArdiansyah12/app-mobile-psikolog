/** Tipe untuk autentikasi & profil admin. */

export type Role = "admin" | "doctor" | "user";
export type UserStatus = "active" | "inactive" | "suspended";

export interface AuthUser {
  id: number;
  name: string;
  email: string;
  role: Role;
  status: UserStatus;
  avatar?: string | null;
  phone?: string | null;
}

export interface LoginPayload {
  email: string;
  password: string;
  remember_me?: boolean;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
  user: AuthUser;
}
