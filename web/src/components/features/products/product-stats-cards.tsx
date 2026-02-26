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
        <div className="bg-gray-100 rounded-3xl p-5 h-28 animate-pulse" />
        <div className="bg-gray-100 rounded-3xl p-5 h-28 animate-pulse" />
        <div className="bg-gray-100 rounded-3xl p-5 h-28 animate-pulse" />
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {/* Total Products */}
      <div className="bg-[#A4BFEB] rounded-3xl p-5 flex flex-col justify-between h-32 relative group transition-transform hover:scale-[1.02]">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <Package size={16} className="text-app-text" />
          </div>
          <span className="font-medium text-app-text/90 text-sm">
            Total Produk
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text mb-1">
            {stats?.total || 0}
          </h3>
          <p className="text-xs text-app-text/70">Produk Terdaftar</p>
        </div>
      </div>

      {/* Low Stock */}
      <div className="bg-[#FFED66] rounded-3xl p-5 flex flex-col justify-between h-32 relative group transition-transform hover:scale-[1.02]">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <AlertTriangle size={16} className="text-app-text" />
          </div>
          <span className="font-medium text-app-text/90 text-sm">
            Stok Menipis
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text mb-1">
            {stats?.low_stock || 0}
          </h3>
          <p className="text-xs text-app-text/70">Sisa stok 1-5 pcs</p>
        </div>
      </div>

      {/* Out of Stock */}
      <div className="bg-[#FFB5A7] rounded-3xl p-5 flex flex-col justify-between h-32 relative group transition-transform hover:scale-[1.02]">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <XCircle size={16} className="text-app-text" />
          </div>
          <span className="font-medium text-app-text/90 text-sm">
            Stok Habis
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text mb-1">
            {stats?.out_of_stock || 0}
          </h3>
          <p className="text-xs text-app-text/70">Perlu restock segera</p>
        </div>
      </div>
    </div>
  );
}
