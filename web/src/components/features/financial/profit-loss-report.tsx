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
      <div className="bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 animate-pulse">
        <div className="h-8 bg-gray-200 rounded w-1/3 mb-6"></div>
        <div className="space-y-4">
          <div className="h-12 bg-gray-100 rounded-xl"></div>
          <div className="h-12 bg-gray-100 rounded-xl"></div>
          <div className="h-12 bg-gray-100 rounded-xl"></div>
          <div className="h-16 bg-gray-200 rounded-xl mt-4"></div>
        </div>
      </div>
    );
  }

  if (!data) {
    return (
      <div className="bg-white/50 rounded-3xl p-12 shadow-sm border border-gray-100 flex flex-col items-center justify-center text-center">
        <AlertCircle size={48} className="text-gray-300 mb-4" />
        <h3 className="text-lg font-bold text-app-text mb-2">
          Data Tidak Tersedia
        </h3>
        <p className="text-app-muted text-sm max-w-sm">
          Gagal memuat laporan laba rugi. Silakan coba atur ulang filter
          tanggal.
        </p>
      </div>
    );
  }

  const isProfit = data.net_profit >= 0;

  return (
    <div className="bg-white/50 rounded-3xl overflow-hidden shadow-sm border border-gray-100 flex flex-col h-full">
      {/* Header */}
      <div className="px-6 py-5 border-b border-gray-100 bg-gray-50/50 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-indigo-100 text-indigo-600 rounded-xl">
            <Calculator size={24} />
          </div>
          <div>
            <h2 className="text-lg font-bold text-app-text">
              Laporan Laba Rugi
            </h2>
            <p className="text-xs text-app-muted mt-0.5">
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
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center p-4 rounded-2xl bg-white border border-gray-100 hover:border-blue-100 transition-colors">
            <div className="flex items-center gap-3 mb-2 sm:mb-0">
              <div className="w-8 h-8 rounded-full bg-blue-50 flex items-center justify-center text-blue-600">
                <TrendingUp size={16} />
              </div>
              <div>
                <p className="font-semibold text-app-text text-sm">
                  Pendapatan Kotor
                </p>
                <p className="text-xs text-app-muted">Total penjualan</p>
              </div>
            </div>
            <span className="text-lg font-bold text-app-text ml-11 sm:ml-0">
              {formatRupiah(data.revenue)}
            </span>
          </div>

          {/* HPP (COGS) */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center p-4 rounded-2xl bg-white border border-gray-100 hover:border-orange-100 transition-colors">
            <div className="flex items-center gap-3 mb-2 sm:mb-0">
              <div className="w-8 h-8 rounded-full bg-orange-50 flex items-center justify-center text-orange-600">
                <TrendingDown size={16} />
              </div>
              <div>
                <p className="font-semibold text-app-text text-sm">
                  Harga Pokok Penjualan (HPP)
                </p>
                <p className="text-xs text-app-muted">Modal barang terjual</p>
              </div>
            </div>
            <span className="text-lg font-bold text-app-text ml-11 sm:ml-0 text-orange-600">
              - {formatRupiah(data.cogs)}
            </span>
          </div>

          {/* Laba Kotor */}
          <div className="flex justify-between items-center p-4 rounded-2xl bg-gray-50 border border-gray-100">
            <span className="font-semibold text-app-text ml-11">
              Laba Kotor
            </span>
            <span className="text-lg font-bold text-app-text">
              {formatRupiah(data.gross_profit)}
            </span>
          </div>

          {/* Beban Operasional (Placeholder for future) */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center p-4 rounded-2xl bg-white border border-gray-100 hover:border-orange-100 transition-colors opacity-70">
            <div className="flex items-center gap-3 mb-2 sm:mb-0">
              <div className="w-8 h-8 rounded-full bg-orange-50 flex items-center justify-center text-orange-600">
                <DollarSign size={16} />
              </div>
              <div>
                <p className="font-semibold text-app-text text-sm">
                  Biaya Operasional
                </p>
                <p className="text-xs text-app-muted">
                  Gaji, sewa, dll (Segera Hadir)
                </p>
              </div>
            </div>
            <span className="text-lg font-bold text-app-text ml-11 sm:ml-0 text-orange-600">
              - {formatRupiah(data.operational_expenses)}
            </span>
          </div>
        </div>

        {/* Laba Bersih (Net Profit) - Bottom Result */}
        <div
          className={`mt-auto p-5 rounded-2xl flex flex-col sm:flex-row items-start sm:items-center justify-between border ${
            isProfit
              ? "bg-green-50 border-green-200"
              : "bg-red-50 border-red-200"
          }`}
        >
          <div>
            <h3
              className={`text-lg font-bold ${isProfit ? "text-green-800" : "text-red-800"}`}
            >
              Laba Bersih
            </h3>
            <p
              className={`text-sm mt-0.5 ${isProfit ? "text-green-700/80" : "text-red-700/80"}`}
            >
              Berdasarkan HPP rata-rata berjalan
            </p>
          </div>
          <div className="mt-3 sm:mt-0 flex items-center gap-2">
            <span
              className={`text-3xl font-bold tracking-tight ${isProfit ? "text-green-600" : "text-red-600"}`}
            >
              {formatRupiah(data.net_profit)}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
