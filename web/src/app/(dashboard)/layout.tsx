import { Header } from "../../components/layout/header";

// 🚀 APP ROUTER: Layout utama (Toolbar/Header + Konten)
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-app-bg flex flex-col font-sans">
      <div className="mx-auto w-full flex-1 flex flex-col pt-4 pb-8 px-4">
        {/* Main Content Card mimicking the design card */}
        <div className="bg-app-surface flex-1 rounded-[32px] shadow-sm flex flex-col overflow-hidden relative border border-[#f3eee4]">
          <Header />
          <main className="flex-1 p-8 overflow-y-auto">
            {children}
          </main>
        </div>
      </div>
    </div>
  );
}