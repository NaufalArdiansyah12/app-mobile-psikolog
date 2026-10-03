"use client";

/** Tabel daftar user dengan estetika MindPal: menampilkan Admin, Dokter, dan Pengguna Biasa. */

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/State";
import { IconUsers, IconDoctor } from "@/components/ui/Icons";
import { formatDate, initials, roleBadgeStyle, roleLabel } from "@/lib/utils";
import type { User } from "@/types/user";

interface UserTableProps {
  users: User[];
  busyId: number | null;
  onToggleActive: (user: User) => void;
  onDelete: (user: User) => void;
}

export function UserTable({ users, busyId, onToggleActive, onDelete }: UserTableProps) {
  if (users.length === 0) {
    return (
      <EmptyState
        title="Tidak ada pengguna ditemukan"
        description="Coba ubah kata kunci pencarian atau sesuaikan filter peran dan status."
        icon={<IconUsers className="w-6 h-6" />}
      />
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-[#E2E8F0] text-xs">
        <thead>
          <tr className="border-b border-[#E2E8F0] bg-[#F8FAF9]/80 text-[#64748B]">
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              ID
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Pengguna
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Peran (Role)
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Kontak
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Status Akun
            </th>
            <th className="px-4 py-3 text-left font-bold uppercase tracking-wider">
              Terdaftar
            </th>
            <th className="px-4 py-3 text-right font-bold uppercase tracking-wider">
              Aksi
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-[#E2E8F0] bg-white">
          {users.map((user) => {
            const busy = busyId === user.id;
            const isAdmin = user.role === "admin";
            const isDoctor = user.role === "doctor";

            return (
              <tr key={user.id} className="transition-colors hover:bg-[#F8FAF9]/70">
                <td className="px-4 py-3.5 font-mono text-[11px] text-[#64748B] font-bold">
                  #{user.id}
                </td>
                <td className="px-4 py-3.5">
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-2xl bg-[#CCFBF1] text-xs font-bold text-[#0D9488] shadow-2xs">
                      {initials(user.name)}
                    </div>
                    <div>
                      <Link
                        href={`/users/${user.id}`}
                        className="font-bold text-[#0F172A] hover:text-[#0D9488] transition-colors"
                      >
                        {user.name}
                      </Link>
                      <p className="text-[11px] text-[#64748B] font-medium">{user.email}</p>
                      {user.doctor?.specialization && (
                        <p className="text-[10px] text-[#0D9488] font-semibold mt-0.5">
                          {user.doctor.specialization}
                        </p>
                      )}
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3.5">
                  <span
                    className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-[11px] font-bold ${roleBadgeStyle(
                      user.role
                    )}`}
                  >
                    {user.role === "admin" && (
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                    )}
                    {user.role === "doctor" && (
                      <span className="w-1.5 h-1.5 rounded-full bg-[#0D9488]" />
                    )}
                    {user.role === "user" && (
                      <span className="w-1.5 h-1.5 rounded-full bg-slate-400" />
                    )}
                    {roleLabel(user.role)}
                  </span>
                </td>
                <td className="px-4 py-3.5 text-[#0F172A] font-medium font-mono text-[11px]">
                  {user.phone || "-"}
                </td>
                <td className="px-4 py-3.5">
                  <Badge value={user.status} />
                </td>
                <td className="px-4 py-3.5 text-[#64748B] font-medium">
                  {formatDate(user.created_at)}
                </td>
                <td className="px-4 py-3.5 text-right">
                  <div className="flex flex-wrap items-center justify-end gap-1.5">
                    <Link href={`/users/${user.id}`}>
                      <Button size="sm" variant="secondary">
                        Detail
                      </Button>
                    </Link>

                    {isDoctor && user.doctor?.id && (
                      <Link href={`/doctors/${user.doctor.id}`}>
                        <Button size="sm" variant="ghost" className="gap-1 text-[#0D9488]">
                          <IconDoctor className="w-3.5 h-3.5" />
                          <span>Dokter</span>
                        </Button>
                      </Link>
                    )}

                    {!isAdmin ? (
                      <>
                        <Button
                          size="sm"
                          variant={user.status === "active" ? "ghost" : "primary"}
                          loading={busy}
                          onClick={() => onToggleActive(user)}
                        >
                          {user.status === "active" ? "Nonaktifkan" : "Aktifkan"}
                        </Button>
                        <Button
                          size="sm"
                          variant="danger"
                          disabled={busy}
                          onClick={() => onDelete(user)}
                        >
                          Hapus
                        </Button>
                      </>
                    ) : (
                      <span className="text-[10px] font-semibold text-[#94A3B8] px-2 py-1">
                        Admin Utama
                      </span>
                    )}
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
