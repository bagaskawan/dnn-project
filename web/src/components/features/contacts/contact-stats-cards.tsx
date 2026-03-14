import { ContactSummary } from "../../../types/contact";
import { Users, Truck } from "lucide-react";

interface ContactStatsCardsProps {
  summary: ContactSummary | null;
  loading: boolean;
}

export function ContactStatsCards({
  summary,
  loading,
}: ContactStatsCardsProps) {
  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-gray-100 dark:bg-white/10 rounded-3xl p-5 h-28 animate-pulse" />
        <div className="bg-gray-100 dark:bg-white/10 rounded-3xl p-5 h-28 animate-pulse" />
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {/* Total Customers */}
      <div className="bg-[#A4BFEB] dark:bg-blue-500/10 dark:border-blue-500/20 border border-transparent rounded-3xl p-5 flex flex-col justify-between h-32 relative group">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <Users size={16} className="text-app-text dark:text-blue-400" />
          </div>
          <span className="font-medium text-app-text/90 dark:text-gray-200 text-sm">
            Total Pelanggan
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text dark:text-white mb-1">
            {summary?.total_customers || 0}
          </h3>
          <p className="text-xs text-app-text/70 dark:text-gray-400">
            Kontak Customer Terdaftar
          </p>
        </div>
      </div>

      {/* Total Suppliers */}
      <div className="bg-[#FFED66] dark:bg-yellow-500/10 dark:border-yellow-500/20 border border-transparent rounded-3xl p-5 flex flex-col justify-between h-32 relative group">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <Truck size={16} className="text-app-text dark:text-yellow-400" />
          </div>
          <span className="font-medium text-app-text/90 dark:text-gray-200 text-sm">
            Total Supplier
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text dark:text-white mb-1">
            {summary?.total_suppliers || 0}
          </h3>
          <p className="text-xs text-app-text/70 dark:text-gray-400">
            Kontak Supplier Terdaftar
          </p>
        </div>
      </div>
    </div>
  );
}
