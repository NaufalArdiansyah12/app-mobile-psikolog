"use client";

/**
 * Toast notification (success/error/info) - global via ToastProvider.
 * Dipakai di seluruh halaman: const toast = useToast(); toast.success("Tersimpan");
 */

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";

type ToastType = "success" | "error" | "info";

interface ToastItem {
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

const TYPE_STYLE: Record<ToastType, { icon: string; classes: string }> = {
  success: {
    icon: "✓",
    classes: "border-emerald-200 bg-emerald-50 text-emerald-800",
  },
  error: {
    icon: "✕",
    classes: "border-red-200 bg-red-50 text-red-800",
  },
  info: {
    icon: "i",
    classes: "border-primary-200 bg-primary-50 text-primary-800",
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
              className={`animate-toast-in pointer-events-auto flex items-start gap-3 rounded-lg border px-4 py-3 text-sm shadow-lg ${style.classes}`}
            >
              <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-white/70 text-xs font-bold">
                {style.icon}
              </span>
              <p className="flex-1">{item.message}</p>
              <button
                type="button"
                onClick={() => setItems((prev) => prev.filter((t) => t.id !== item.id))}
                className="text-current/60 hover:text-current"
                aria-label="Tutup notifikasi"
              >
                ✕
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
}
