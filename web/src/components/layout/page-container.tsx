// 🧩 KOMPONEN: Struktural - Pembungkus konten halaman
export function PageContainer({ children }: { children: React.ReactNode }) {
  return <main className="p-4">{children}</main>;
}