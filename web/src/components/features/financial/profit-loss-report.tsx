import { FinancialProfitLoss } from "../../../types/financial";
import { formatRupiah, formatDate } from "../../../lib/format";
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  Calculator,
  AlertCircle,
} from "lucide-react";

interface ProfitLossReportProps {
  data: FinancialProfitLoss | null;
  loading: boolean;
  dateFrom?: string;
  dateTo?: string;
}

export function ProfitLossReport({
  data,
  loading,
  dateFrom,
  dateTo,
}: ProfitLossReportProps) {
  if (loading) {
    return (
      <div className="bg-white/50 dark:bg-app-surface/50 rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-white/5 animate-pulse">
        <div className="h-8 bg-gray-200 dark:bg-white/10 rounded w-1/3 mb-6"></div>
        <div className="space-y-4">
          <div className="h-12 bg-gray-100 dark:bg-white/5 rounded-xl"></div>
          <div className="h-12 bg-gray-100 dark:bg-white/5 rounded-xl"></div>
          <div className="h-12 bg-gray-100 dark:bg-white/5 rounded-xl"></div>
          <div className="h-16 bg-gray-200 dark:bg-white/10 rounded-xl mt-4"></div>
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="bg-white/50 dark:bg-app-surface/50 rounded-3xl p-12 shadow-sm border border-gray-100 dark:border-white/5 flex flex-col items-center justify-center text-center">
        <AlertCircle
          size={48}
          className="text-gray-300 dark:text-gray-600 mb-4"
        />
        <h3 className="text-lg font-bold text-app-text dark:text-white mb-2">
          Data Tidak Tersedia
        </h3>
        <p className="text-app-muted dark:text-gray-400 text-sm max-w-sm">
          Gagal memuat laporan laba rugi. Silakan coba atur ulang filter
          tanggal.
        </p>
      </div>
    );
  }

  const isProfit = data.net_profit >= 0;

  return (
    <div className="bg-white/50 dark:bg-app-surface/50 rounded-3xl overflow-hidden shadow-sm border border-gray-100 dark:border-white/5 flex flex-col h-full">
      {/* Header */}
      <div className="px-6 py-5 border-b border-gray-100 dark:border-white/5 bg-gray-50/50 dark:bg-black/20 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-indigo-100 dark:bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 rounded-xl">
            <Calculator size={24} />
          </div>
          <div>
            <h2 className="text-lg font-bold text-app-text dark:text-white">
              Laporan Laba Rugi
            </h2>
            <p className="text-xs text-app-muted dark:text-gray-400 mt-0.5">
              {dateFrom && dateTo
                ? `Periode: ${formatDate(dateFrom)} - ${formatDate(dateTo)}`
                : dateFrom
                  ? `Mulai dari ${formatDate(dateFrom)}`
                  : dateTo
                    ? `Hingga ${formatDate(dateTo)}`
                    : "Semua Waktu"}
            </p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="p-6 flex-1 flex flex-col gap-6">
        {/* Detail Rows */}
        <div className="space-y-3">
          {/* Pendapatan (Revenue) */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center p-4 rounded-2xl bg-white dark:bg-app-surface/50 border border-gray-100 dark:border-white/5 hover:border-blue-100 dark:hover:border-blue-500/30 transition-colors">
            <div className="flex items-center gap-3 mb-2 sm:mb-0">
              <div className="w-8 h-8 rounded-full bg-blue-50 dark:bg-blue-500/10 flex items-center justify-center text-blue-600 dark:text-blue-400">
                <TrendingUp size={16} />
              </div>
              <div>
                <p className="font-semibold text-app-text dark:text-white text-sm">
                  Pendapatan Kotor
                </p>
                <p className="text-xs text-app-muted dark:text-gray-400">
                  Total penjualan
                </p>
              </div>
            </div>
            <span className="text-lg font-bold text-app-text dark:text-white ml-11 sm:ml-0">
              {formatRupiah(data.revenue)}
            </span>
          </div>

          {/* HPP (COGS) */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center p-4 rounded-2xl bg-white dark:bg-app-surface/50 border border-gray-100 dark:border-white/5 hover:border-orange-100 dark:hover:border-orange-500/30 transition-colors">
            <div className="flex items-center gap-3 mb-2 sm:mb-0">
              <div className="w-8 h-8 rounded-full bg-orange-50 dark:bg-orange-500/10 flex items-center justify-center text-orange-600 dark:text-orange-400">
                <TrendingDown size={16} />
              </div>
              <div>
                <p className="font-semibold text-app-text dark:text-white text-sm">
                  Harga Pokok Penjualan (HPP)
                </p>
                <p className="text-xs text-app-muted dark:text-gray-400">
                  Modal barang terjual
                </p>
              </div>
            </div>
            <span className="text-lg font-bold text-app-text dark:text-white ml-11 sm:ml-0 text-orange-600 dark:text-orange-400">
              - {formatRupiah(data.cogs)}
            </span>
          </div>

          {/* Laba Kotor */}
          <div className="flex justify-between items-center p-4 rounded-2xl bg-gray-50 dark:bg-black/20 border border-gray-100 dark:border-white/5">
            <span className="font-semibold text-app-text dark:text-white ml-11">
              Laba Kotor
            </span>
            <span className="text-lg font-bold text-app-text dark:text-white">
              {formatRupiah(data.gross_profit)}
            </span>
          </div>

          {/* Beban Operasional (Placeholder for future) */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center p-4 rounded-2xl bg-white dark:bg-app-surface/50 border border-gray-100 dark:border-white/5 hover:border-orange-100 dark:hover:border-orange-500/30 transition-colors opacity-70">
            <div className="flex items-center gap-3 mb-2 sm:mb-0">
              <div className="w-8 h-8 rounded-full bg-orange-50 dark:bg-orange-500/10 flex items-center justify-center text-orange-600 dark:text-orange-400">
                <DollarSign size={16} />
              </div>
              <div>
                <p className="font-semibold text-app-text dark:text-white text-sm">
                  Biaya Operasional
                </p>
                <p className="text-xs text-app-muted dark:text-gray-400">
                  Gaji, sewa, dll (Segera Hadir)
                </p>
              </div>
            </div>
            <span className="text-lg font-bold text-app-text dark:text-white ml-11 sm:ml-0 text-orange-600 dark:text-orange-400">
              - {formatRupiah(data.operational_expenses)}
            </span>
          </div>
        </div>

        {/* Laba Bersih (Net Profit) - Bottom Result */}
        <div
          className={`mt-auto p-5 rounded-2xl flex flex-col sm:flex-row items-start sm:items-center justify-between border ${
            isProfit
              ? "bg-green-50 dark:bg-green-500/10 border-green-200 dark:border-green-500/20"
              : "bg-red-50 dark:bg-red-500/10 border-red-200 dark:border-red-500/20"
          }`}
        >
          <div>
            <h3
              className={`text-lg font-bold ${isProfit ? "text-green-800 dark:text-green-400" : "text-red-800 dark:text-red-400"}`}
            >
              Laba Bersih
            </h3>
            <p
              className={`text-sm mt-0.5 ${isProfit ? "text-green-700/80 dark:text-green-500/80" : "text-red-700/80 dark:text-red-500/80"}`}
            >
              Berdasarkan HPP rata-rata berjalan
            </p>
          </div>
          <div className="mt-3 sm:mt-0 flex items-center gap-2">
            <span
              className={`text-3xl font-bold tracking-tight ${isProfit ? "text-green-600 dark:text-green-400" : "text-red-600 dark:text-red-400"}`}
            >
              {formatRupiah(data.net_profit)}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
