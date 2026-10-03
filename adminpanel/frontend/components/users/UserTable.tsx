"use client";

/** Tabel daftar user. */

import Link from "next/link";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/State";
import { formatDate, roleLabel } from "@/lib/utils";
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
        title="Tidak ada user ditemukan"
        description="Coba ubah kata kunci pencarian atau filter status."
        icon="👥"
      />
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50">
          <tr>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              ID
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Nama
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Email
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              No. Telepon
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Role
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Status
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Tanggal Registrasi
            </th>
            <th className="px-4 py-3 text-right text-xs font-semibold tracking-wide text-slate-500 uppercase">
              Action
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100 bg-white">
          {users.map((user) => {
            const busy = busyId === user.id;
            const isAdmin = user.role === "admin";
            return (
              <tr key={user.id} className="transition-colors hover:bg-slate-50/70">
                <td className="px-4 py-3 text-slate-500">#{user.id}</td>
                <td className="px-4 py-3">
                  <Link
                    href={`/users/${user.id}`}
                    className="font-medium text-slate-800 hover:text-primary-600 hover:underline"
                  >
                    {user.name}
                  </Link>
                </td>
                <td className="px-4 py-3 text-slate-600">{user.email}</td>
                <td className="px-4 py-3 text-slate-600">{user.phone || "-"}</td>
                <td className="px-4 py-3">
                  <span className="rounded-md bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-600">
                    {roleLabel(user.role)}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <Badge value={user.status} />
                </td>
                <td className="px-4 py-3 text-slate-600">
                  {formatDate(user.created_at)}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap items-center justify-end gap-1.5">
                    <Link href={`/users/${user.id}`}>
                      <Button size="sm" variant="secondary">
                        Detail
                      </Button>
                    </Link>

                    {!isAdmin && (
                      <>
                        <Button
                          size="sm"
                          variant={user.status === "active" ? "secondary" : "success"}
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
