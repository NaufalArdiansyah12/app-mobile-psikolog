"use client";

import { useEffect, ReactNode } from "react";
import { IconClose } from "@/components/ui/Icons";
import { cx } from "@/lib/utils";

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  contentClassName?: string;
}

export function Modal({
  open,
  onClose,
  title,
  children,
  contentClassName,
}: ModalProps) {
  useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", handler);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", handler);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[90] flex items-center justify-center p-4 select-none">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-[#0F172A]/40 backdrop-blur-xs transition-opacity"
        onClick={onClose}
        aria-hidden
      />
      {/* Bento Panel */}
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className={cx(
          "relative w-full max-w-lg rounded-[28px] bg-white p-6 shadow-[0_14px_34px_-10px_rgba(13,148,136,0.25)] border border-[#E2E8F0]",
          "max-h-[90vh] overflow-y-auto animate-toast-in",
          contentClassName
        )}
      >
        <div className="flex items-center justify-between border-b border-[#E2E8F0] pb-4 mb-4">
          <h3 className="text-base font-extrabold text-[#0F172A] tracking-tight">{title}</h3>
          <button
            type="button"
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-xl bg-[#F8FAF9] text-[#64748B] transition-colors hover:bg-rose-50 hover:text-rose-600"
            aria-label="Tutup"
          >
            <IconClose className="w-4 h-4" />
          </button>
        </div>
        <div>{children}</div>
      </div>
    </div>
  );
}
