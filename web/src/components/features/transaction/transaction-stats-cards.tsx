import { TransactionStats } from "../../../types/transaction";
import { formatRupiah } from "../../../lib/format";
import { Receipt, TrendingDown, TrendingUp } from "lucide-react";

interface TransactionStatsCardsProps {
  stats: TransactionStats | null;
  loading: boolean;
}

export function TransactionStatsCards({
  stats,
  loading,
}: TransactionStatsCardsProps) {
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
      {/* Total Transaksi */}
      <div className="bg-[#A4BFEB] rounded-3xl p-5 flex flex-col justify-between h-32 relative group transition-transform hover:scale-[1.02]">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <Receipt size={16} className="text-app-text" />
          </div>
          <span className="font-medium text-app-text/90 text-sm">
            Total Transaksi
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text mb-1">
            {stats?.total_count || 0}
          </h3>
          <p className="text-xs text-app-text/70">Sesuai filter terpilih</p>
        </div>
      </div>

      {/* Pengadaan / Uang Keluar */}
      <div className="bg-[#FFB5A7] rounded-3xl p-5 flex flex-col justify-between h-32 relative group transition-transform hover:scale-[1.02]">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <TrendingUp size={16} className="text-app-text" />
          </div>
          <span className="font-medium text-app-text/90 text-sm">
            Total Pengadaan
          </span>
        </div>
        <div>
          <h3 className="text-2xl font-bold text-app-text mb-1">
            {formatRupiah(stats?.total_amount_in || 0)}
          </h3>
          <p className="text-xs text-app-text/70">Uang keluar untuk belanja</p>
        </div>
      </div>

      {/* Penjualan / Uang Masuk */}
      <div className="bg-[#B9FBC0] rounded-3xl p-5 flex flex-col justify-between h-32 relative group transition-transform hover:scale-[1.02]">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <TrendingDown size={16} className="text-app-text" />
          </div>
          <span className="font-medium text-app-text/90 text-sm">
            Total Penjualan
          </span>
        </div>
        <div>
          <h3 className="text-2xl font-bold text-app-text mb-1">
            {formatRupiah(stats?.total_amount_out || 0)}
          </h3>
          <p className="text-xs text-app-text/70">Pendapatan kotor</p>
        </div>
      </div>
    </div>
  );
}
