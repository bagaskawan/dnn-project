"use client";

import { useState, useEffect } from "react";
import { TransactionTable } from "../../../components/features/transaction/transaction-table";
import { TransactionStatsCards } from "../../../components/features/transaction/transaction-stats-cards";
import { TransactionDetailModal } from "../../../components/features/transaction/transaction-detail-modal";
import { transactionService } from "../../../services/transaction.service";
import {
  TransactionListItem,
  TransactionStats,
  TransactionFilters,
} from "../../../types/transaction";

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<TransactionListItem[]>([]);
  const [stats, setStats] = useState<TransactionStats | null>(null);
  const [loading, setLoading] = useState(true);

  // Filter states
  const [filters, setFilters] = useState<TransactionFilters>({
    type: "ALL",
    date_from: "",
    date_to: "",
    search: "",
  });

  // Modal State
  const [selectedTransactionId, setSelectedTransactionId] = useState<
    string | null
  >(null);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [listData, statsData] = await Promise.all([
        transactionService.getTransactions(filters),
        transactionService.getStats(filters),
      ]);
      setTransactions(listData);
      setStats(statsData);
    } catch (error) {
      console.error("Failed to fetch transactions:", error);
    } finally {
      setLoading(false);
    }
  };

  // Debounce search effect
  useEffect(() => {
    const timer = setTimeout(() => {
      fetchData();
    }, 300);

    return () => clearTimeout(timer);
  }, [filters]);

  const handleFilterChange = (key: keyof TransactionFilters, value: any) => {
    setFilters((prev) => ({ ...prev, [key]: value }));
  };

  return (
    <div className="flex flex-col h-full gap-6">
      {/* Header & Stats Row */}
      <div className="flex flex-col xl:flex-row gap-6">
        <div className="xl:w-1/3 flex flex-col justify-end pb-2">
          <h1 className="text-2xl font-bold text-app-text mb-2">
            Riwayat Transaksi
          </h1>
          <p className="text-sm text-app-muted">
            Pantau semua aktivitas penjualan dan pengadaan stok Anda.
          </p>
        </div>
        <div className="xl:w-2/3">
          <TransactionStatsCards stats={stats} loading={loading} />
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex flex-col flex-1 bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 min-h-[500px]">
        {/* Toolbar: Filters */}
        <div className="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-4 mb-6">
          {/* Tabs / Type Filter */}
          <div className="flex p-1 bg-gray-100 rounded-xl overflow-x-auto w-full lg:w-auto">
            {(["ALL", "IN", "OUT"] as const).map((type) => (
              <button
                key={type}
                onClick={() => handleFilterChange("type", type)}
                className={`px-6 py-2 rounded-lg text-sm font-medium transition-all whitespace-nowrap ${
                  filters.type === type
                    ? "bg-white text-app-text shadow-sm"
                    : "text-gray-500 hover:text-app-text"
                }`}
              >
                {type === "ALL"
                  ? "Semua"
                  : type === "IN"
                    ? "Pengadaan (Masuk)"
                    : "Penjualan (Keluar)"}
              </button>
            ))}
          </div>

          {/* Date Range & Search */}
          <div className="flex flex-col sm:flex-row w-full lg:w-auto items-center gap-3">
            <div className="flex items-center gap-2 w-full sm:w-auto">
              <input
                type="date"
                value={filters.date_from || ""}
                onChange={(e) =>
                  handleFilterChange("date_from", e.target.value)
                }
                className="w-full sm:w-auto px-3 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-sm transition-all"
              />
              <span className="text-gray-400">-</span>
              <input
                type="date"
                value={filters.date_to || ""}
                onChange={(e) => handleFilterChange("date_to", e.target.value)}
                className="w-full sm:w-auto px-3 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-sm transition-all"
              />
            </div>

            <input
              type="text"
              placeholder="Cari Invoice atau Pihak Terkait..."
              value={filters.search || ""}
              onChange={(e) => handleFilterChange("search", e.target.value)}
              className="w-full sm:w-64 px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-sm transition-all"
            />
          </div>
        </div>

        {/* Table Area */}
        <TransactionTable
          transactions={transactions}
          loading={loading}
          onViewDetail={(id) => setSelectedTransactionId(id)}
        />
      </div>

      {/* Detail Modal */}
      <TransactionDetailModal
        isOpen={!!selectedTransactionId}
        transactionId={selectedTransactionId}
        onClose={() => setSelectedTransactionId(null)}
      />
    </div>
  );
}
