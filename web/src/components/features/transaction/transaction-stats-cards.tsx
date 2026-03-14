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
        <div className="bg-gray-100 dark:bg-white/10 rounded-3xl p-5 h-28 animate-pulse" />
        <div className="bg-gray-100 dark:bg-white/10 rounded-3xl p-5 h-28 animate-pulse" />
        <div className="bg-gray-100 dark:bg-white/10 rounded-3xl p-5 h-28 animate-pulse" />
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {/* Total Transaksi */}
      <div className="bg-[#A4BFEB] dark:bg-blue-500/10 dark:border-blue-500/20 border border-transparent rounded-3xl p-5 flex flex-col justify-between h-32 relative group">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <Receipt size={16} className="text-app-text dark:text-blue-400" />
          </div>
          <span className="font-medium text-app-text/90 dark:text-gray-200 text-sm">
            Total Transaksi
          </span>
        </div>
        <div>
          <h3 className="text-3xl font-bold text-app-text dark:text-white mb-1">
            {stats?.total_count || 0}
          </h3>
          <p className="text-xs text-app-text/70 dark:text-gray-400">
            Sesuai filter terpilih
          </p>
        </div>
      </div>

      {/* Pengadaan / Uang Keluar */}
      <div className="bg-[#FFB5A7] dark:bg-red-500/10 dark:border-red-500/20 border border-transparent rounded-3xl p-5 flex flex-col justify-between h-32 relative group">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <TrendingUp size={16} className="text-app-text dark:text-red-400" />
          </div>
          <span className="font-medium text-app-text/90 dark:text-gray-200 text-sm">
            Total Pengadaan
          </span>
        </div>
        <div>
          <h3 className="text-2xl font-bold text-app-text dark:text-white mb-1">
            {formatRupiah(stats?.total_amount_in || 0)}
          </h3>
          <p className="text-xs text-app-text/70 dark:text-gray-400">
            Uang keluar untuk belanja
          </p>
        </div>
      </div>

      {/* Penjualan / Uang Masuk */}
      <div className="bg-[#B9FBC0] dark:bg-green-500/10 dark:border-green-500/20 border border-transparent rounded-3xl p-5 flex flex-col justify-between h-32 relative group">
        <div className="flex items-center gap-2">
          <div className="bg-black/10 p-1.5 rounded-lg">
            <TrendingDown
              size={16}
              className="text-app-text dark:text-green-400"
            />
          </div>
          <span className="font-medium text-app-text/90 dark:text-gray-200 text-sm">
            Total Penjualan
          </span>
        </div>
        <div>
          <h3 className="text-2xl font-bold text-app-text dark:text-white mb-1">
            {formatRupiah(stats?.total_amount_out || 0)}
          </h3>
          <p className="text-xs text-app-text/70 dark:text-gray-400">
            Pendapatan kotor
          </p>
        </div>
      </div>
    </div>
  );
}
