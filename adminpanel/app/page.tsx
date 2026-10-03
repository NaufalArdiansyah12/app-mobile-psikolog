/**
 * Halaman utama -> redirect ke dashboard admin.
 */
import { redirect } from "next/navigation";

export default function Home() {
  redirect("/dashboard");
}
