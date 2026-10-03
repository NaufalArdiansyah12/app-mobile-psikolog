/** Tipe untuk slider/banner. */

export type SliderStatus = "active" | "inactive";

export interface Slider {
  id: number;
  title: string;
  description?: string | null;
  image: string;
  link?: string | null;
  sort_order: number;
  status: SliderStatus;
  created_at?: string | null;
  updated_at?: string | null;
}
