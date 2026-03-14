import { ProductStats } from "../../../types/product";
import { Package, AlertTriangle, XCircle } from "lucide-react";

interface ProductStatsCardsProps {
  stats: ProductStats | null;
  loading: boolean;
}

export function ProductStatsCards({ stats, loading }: ProductStatsCardsProps) {
  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-gray-200 dark:bg-white/10 rounded-3xl p-5 h-28 animate-pulse" />
        <div className="bg-gray-200 dark:bg-white/10 rounded-3xl p-5 h-28 animate-pulse" />
        <div className="bg-gray-200 dark:bg-white/10 rounded-3xl p-5 h-28 animate-pulse" />
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {/* Total Products */}
      <div className="bg-[#A4BFEB] dark:bg-blue-500/10 dark:border-blue-500/20 border border-transparent rounded-3xl p-5 flex flex-col justify-between h-32 relative group">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <Package size={16} className="text-app-text dark:text-blue-400" />
          </div>
          <span className="font-medium text-app-text/90 dark:text-gray-200 text-sm">
            Total Produk
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text dark:text-white mb-1">
            {stats?.total || 0}
          </h3>
          <p className="text-xs text-app-text/70 dark:text-gray-400">
            Produk Terdaftar
          </p>
        </div>
      </div>

      {/* Low Stock */}
      <div className="bg-[#FFED66] dark:bg-yellow-500/10 dark:border-yellow-500/20 border border-transparent rounded-3xl p-5 flex flex-col justify-between h-32 relative group">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <AlertTriangle
              size={16}
              className="text-app-text dark:text-yellow-400"
            />
          </div>
          <span className="font-medium text-app-text/90 dark:text-gray-200 text-sm">
            Stok Menipis
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text dark:text-white mb-1">
            {stats?.low_stock || 0}
          </h3>
          <p className="text-xs text-app-text/70 dark:text-gray-400">
            Sisa stok 1-5 pcs
          </p>
        </div>
      </div>

      {/* Out of Stock */}
      <div className="bg-[#FFB5A7] dark:bg-red-500/10 dark:border-red-500/20 border border-transparent rounded-3xl p-5 flex flex-col justify-between h-32 relative group">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <XCircle size={16} className="text-app-text dark:text-red-400" />
          </div>
          <span className="font-medium text-app-text/90 dark:text-gray-200 text-sm">
            Stok Habis
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text dark:text-white mb-1">
            {stats?.out_of_stock || 0}
          </h3>
          <p className="text-xs text-app-text/70 dark:text-gray-400">
            Perlu restock segera
          </p>
        </div>
      </div>
    </div>
  );
}
