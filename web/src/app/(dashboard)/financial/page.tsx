"use client";

import { useState, useEffect } from "react";
import { ProfitLossReport } from "../../../components/features/financial/profit-loss-report";
import { financialService } from "../../../services/financial.service";
import {
  FinancialProfitLoss,
  FinancialFilters,
} from "../../../types/financial";
import { Calendar, Download } from "lucide-react";

export default function FinancialPage() {
  const [data, setData] = useState<FinancialProfitLoss | null>(null);
  const [loading, setLoading] = useState(true);

  // Filter states
  const [filters, setFilters] = useState<FinancialFilters>({
    date_from: "",
    date_to: "",
  });

  const fetchData = async () => {
    setLoading(true);
    try {
      const result = await financialService.getProfitLoss(filters);
      setData(result);
    } catch (error) {
      console.error("Failed to fetch financial data:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [filters]);

  const handleFilterChange = (key: keyof FinancialFilters, value: any) => {
    setFilters((prev) => ({ ...prev, [key]: value }));
  };

  const handleQuickFilter = (days: number) => {
    const today = new Date();
    const past = new Date();
    past.setDate(today.getDate() - days);

    setFilters({
      date_from: past.toISOString().split("T")[0],
      date_to: today.toISOString().split("T")[0],
    });
  };

  return (
    <div className="flex flex-col h-full gap-6 max-w-5xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-app-text mb-1">Keuangan</h1>
          <p className="text-sm text-app-muted">
            Pantau arus kas, pendapatan, dan laba rugi bisnis Anda.
          </p>
        </div>

        <button className="px-4 py-2 bg-white text-app-text border border-gray-200 rounded-xl text-sm font-medium hover:bg-gray-50 transition-colors flex items-center justify-center gap-2 drop-shadow-sm">
          <Download size={16} />
          <span>Export Laporan</span>
        </button>
      </div>

      {/* Toolbar / Filters */}
      <div className="bg-white/50 rounded-2xl p-4 shadow-sm border border-gray-100 flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-2 w-full md:w-auto overflow-x-auto pb-2 md:pb-0">
          <span className="text-sm font-medium text-app-muted mr-2 flex items-center gap-1">
            <Calendar size={14} /> Cepat:
          </span>
          <button
            onClick={() => handleQuickFilter(7)}
            className="px-3 py-1.5 text-xs font-medium bg-gray-100 hover:bg-blue-100 hover:text-blue-700 rounded-lg whitespace-nowrap transition-colors"
          >
            7 Hari
          </button>
          <button
            onClick={() => handleQuickFilter(30)}
            className="px-3 py-1.5 text-xs font-medium bg-gray-100 hover:bg-blue-100 hover:text-blue-700 rounded-lg whitespace-nowrap transition-colors"
          >
            30 Hari
          </button>
          <button
            onClick={() => setFilters({ date_from: "", date_to: "" })}
            className="px-3 py-1.5 text-xs font-medium bg-gray-100 hover:bg-blue-100 hover:text-blue-700 rounded-lg whitespace-nowrap transition-colors"
          >
            Semua
          </button>
        </div>

        <div className="flex items-center gap-2 w-full md:w-auto">
          <input
            type="date"
            value={filters.date_from || ""}
            onChange={(e) => handleFilterChange("date_from", e.target.value)}
            className="flex-1 md:w-36 px-3 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-sm transition-all"
          />
          <span className="text-gray-400">-</span>
          <input
            type="date"
            value={filters.date_to || ""}
            onChange={(e) => handleFilterChange("date_to", e.target.value)}
            className="flex-1 md:w-36 px-3 py-2 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-sm transition-all"
          />
        </div>
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 pb-6">
        <div className="lg:col-span-1">
          <ProfitLossReport
            data={data}
            loading={loading}
            dateFrom={filters.date_from}
            dateTo={filters.date_to}
          />
        </div>

        {/* Placeholder for future charts / cash flow */}
        <div className="lg:col-span-1 flex flex-col gap-6">
          <div className="bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 flex-1 flex flex-col items-center justify-center text-center opacity-70">
            <h3 className="text-lg font-bold text-app-text mb-2">
              Arus Kas (Cash Flow)
            </h3>
            <p className="text-sm text-app-muted max-w-xs">
              Fitur grafik arus kas masuk/keluar harian sedang dalam
              pengembangan.
            </p>
          </div>
          <div className="bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 h-48 flex flex-col items-center justify-center text-center opacity-70">
            <h3 className="text-lg font-bold text-app-text mb-2">
              Hutang / Piutang
            </h3>
            <p className="text-sm text-app-muted max-w-xs">
              Ringkasan tempo pembayaran belum tersedia.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
