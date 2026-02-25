import Link from "next/link";
import { Home, Search, Mail, Bell, Sun } from "lucide-react";

const NAV_ITEMS = [
  { label: "Dashboard", href: "/", active: true },
  { label: "Inventory", href: "/inventory" },
  { label: "Financial", href: "/financial" },
  { label: "Transaction", href: "/transaction" },
  { label: "Product", href: "/product" },
  { label: "Contact", href: "/contact" },
];

export function Header() {
  return (
    <header className="flex items-center justify-between px-8 py-4 bg-app-surface border-b border-app-surface shadow-sm rounded-t-[32px] mx-4 mt-4">
      {/* Brand */}
      <div className="flex items-center gap-2">
        <span className="font-semibold text-xl tracking-tight text-app-text">
          Dnn Project <span className="text-orange-500 text-3xl">.</span>
        </span>
      </div>

      {/* Center Navigation */}
      <nav className="flex items-center gap-2 bg-app-bg px-2 py-1.5 rounded-full border border-gray-100">
        {NAV_ITEMS.map((item) => (
          <Link
            key={item.label}
            href={item.href}
            className={`px-6 py-2 rounded-full text-sm font-medium transition-colors ${item.active
              ? "bg-white text-app-text shadow-sm"
              : "text-app-muted hover:text-app-text hover:bg-white/50"
              }`}
          >
            {item.label}
          </Link>
        ))}
      </nav>

      {/* Right Actions */}
      <div className="flex items-center gap-3">
        {/* dark light mode button */}
        <button className="w-10 h-10 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
          <Sun className="w-5 h-5" />
        </button>
        <button className="w-10 h-10 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
          <Search className="w-5 h-5" />
        </button>
        <button className="w-10 h-10 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
          <Bell className="w-5 h-5" />
        </button>

        <div className="w-10 h-10 rounded-full bg-gray-300 ml-2 overflow-hidden border-2 border-white">
          <img src="https://i.pravatar.cc/150?u=a042581f4e29026024d" alt="Profile" className="w-full h-full object-cover" />
        </div>
      </div>
    </header >
  );
}