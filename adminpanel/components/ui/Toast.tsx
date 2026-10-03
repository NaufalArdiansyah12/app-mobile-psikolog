"use client";

/**
 * Toast Notification Provider:
 * Menggunakan clean SVG icon (tanpa emoji/karakter mentah).
 */

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  ReactNode,
} from "react";
import { IconCheck, IconClose, IconInfo } from "@/components/ui/Icons";

export type ToastType = "success" | "error" | "info";

export interface ToastItem {
  id: number;
  type: ToastType;
  message: string;
}

interface ToastContextValue {
  success: (message: string) => void;
  error: (message: string) => void;
  info: (message: string) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error("useToast harus dipakai di dalam <ToastProvider>");
  }
  return ctx;
}

const TYPE_STYLE: Record<ToastType, { icon: ReactNode; classes: string }> = {
  success: {
    icon: <IconCheck className="w-3.5 h-3.5 text-emerald-600" />,
    classes: "border-emerald-200 bg-emerald-50 text-emerald-900",
  },
  error: {
    icon: <IconClose className="w-3.5 h-3.5 text-rose-600" />,
    classes: "border-rose-200 bg-rose-50 text-rose-900",
  },
  info: {
    icon: <IconInfo className="w-3.5 h-3.5 text-[#0D9488]" />,
    classes: "border-[#99F6E4] bg-[#F0FDFA] text-[#0F766E]",
  },
};

export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<ToastItem[]>([]);
  const idRef = useRef(0);

  const push = useCallback((type: ToastType, message: string) => {
    idRef.current += 1;
    const id = idRef.current;
    setItems((prev) => [...prev, { id, type, message }]);
    window.setTimeout(() => {
      setItems((prev) => prev.filter((t) => t.id !== id));
    }, 4000);
  }, []);

  const value = useMemo<ToastContextValue>(
    () => ({
      success: (m) => push("success", m),
      error: (m) => push("error", m),
      info: (m) => push("info", m),
    }),
    [push]
  );

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div
        aria-live="polite"
        className="pointer-events-none fixed top-4 right-4 z-[100] flex w-[min(92vw,24rem)] flex-col gap-2"
      >
        {items.map((item) => {
          const style = TYPE_STYLE[item.type];
          return (
            <div
              key={item.id}
              className={`animate-toast-in pointer-events-auto flex items-start gap-3 rounded-2xl border px-4 py-3 text-xs font-semibold shadow-lg backdrop-blur-xs ${style.classes}`}
            >
              <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-xl bg-white/80 shadow-2xs">
                {style.icon}
              </span>
              <p className="flex-1 leading-relaxed">{item.message}</p>
              <button
                type="button"
                onClick={() => setItems((prev) => prev.filter((t) => t.id !== item.id))}
                className="text-current/60 hover:text-current mt-0.5"
                aria-label="Tutup notifikasi"
              >
                <IconClose className="w-3.5 h-3.5" />
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
}
