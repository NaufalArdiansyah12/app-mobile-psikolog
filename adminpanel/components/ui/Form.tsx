"use client";

/** Form components dengan palette MindPal. */

import { useEffect, useState, type ChangeEvent } from "react";
import { cx } from "@/lib/utils";

interface SearchInputProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  debounceMs?: number;
  className?: string;
}

export function SearchInput({
  value,
  onChange,
  placeholder = "Cari...",
  debounceMs = 400,
  className,
}: SearchInputProps) {
  const [local, setLocal] = useState(value);

  useEffect(() => setLocal(value), [value]);

  useEffect(() => {
    if (local === value) return;
    const t = window.setTimeout(() => onChange(local), debounceMs);
    return () => window.clearTimeout(t);
  }, [local, debounceMs, onChange, value]);

  return (
    <div className={cx("relative", className)}>
      <span className="pointer-events-none absolute top-1/2 left-3.5 -translate-y-1/2 text-[#94A3B8]">
        <svg className="w-4 h-4" fill="none" stroke="currentColor" strokeWidth="2.5" viewBox="0 0 24 24">
          <circle cx="11" cy="11" r="8" strokeLinecap="round" strokeLinejoin="round" />
          <path d="m21 21-4.3-4.3" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
      </span>
      <input
        type="search"
        value={local}
        onChange={(e: ChangeEvent<HTMLInputElement>) => setLocal(e.target.value)}
        placeholder={placeholder}
        className="w-full rounded-2xl border border-[#E2E8F0] bg-[#F8FAF9] py-2.5 pr-4 pl-10 text-xs font-semibold text-[#0F172A] placeholder-[#94A3B8] focus:border-[#0D9488] focus:bg-white focus:ring-2 focus:ring-[#0D9488]/30 focus:outline-none transition-all sm:w-64"
      />
    </div>
  );
}

interface SelectFilterProps {
  value: string;
  onChange: (value: string) => void;
  options: { value: string; label: string }[];
  label?: string;
  className?: string;
}

export function SelectFilter({
  value,
  onChange,
  options,
  label,
  className,
}: SelectFilterProps) {
  return (
    <select
      aria-label={label || "Filter"}
      value={value}
      onChange={(e: ChangeEvent<HTMLSelectElement>) => onChange(e.target.value)}
      className={cx(
        "rounded-2xl border border-[#E2E8F0] bg-[#F8FAF9] px-3.5 py-2.5 text-xs font-bold text-[#0F172A]",
        "focus:border-[#0D9488] focus:bg-white focus:ring-2 focus:ring-[#0D9488]/30 focus:outline-none transition-all",
        className
      )}
    >
      {options.map((opt) => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  );
}

export function FieldLabel({
  children,
  required,
  htmlFor,
}: {
  children: React.ReactNode;
  required?: boolean;
  htmlFor?: string;
}) {
  return (
    <label htmlFor={htmlFor} className="mb-1.5 block text-xs font-bold text-[#0F172A]">
      {children}
      {required && <span className="ml-1 text-[#0D9488]">*</span>}
    </label>
  );
}

export function TextInput({
  className,
  ...rest
}: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      className={cx(
        "w-full rounded-2xl border border-[#E2E8F0] bg-[#F8FAF9] px-4 py-3 text-xs font-semibold text-[#0F172A] placeholder-[#94A3B8]",
        "focus:border-[#0D9488] focus:bg-white focus:ring-2 focus:ring-[#0D9488]/30 focus:outline-none transition-all",
        "disabled:cursor-not-allowed disabled:bg-[#F8FAF9]/50 disabled:text-[#94A3B8]",
        className
      )}
      {...rest}
    />
  );
}

export function TextArea({
  className,
  ...rest
}: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      className={cx(
        "w-full rounded-2xl border border-[#E2E8F0] bg-[#F8FAF9] px-4 py-3 text-xs font-semibold text-[#0F172A] placeholder-[#94A3B8]",
        "focus:border-[#0D9488] focus:bg-white focus:ring-2 focus:ring-[#0D9488]/30 focus:outline-none transition-all",
        className
      )}
      {...rest}
    />
  );
}
