"use client";

import { useState, useEffect } from "react";
import { InventoryTable } from "../../../components/features/inventory/inventory-table";
import { inventoryService } from "../../../services/inventory.service";
import { StockLedgerItem } from "../../../types/inventory";
import { Search } from "lucide-react";

export default function InventoryPage() {
  const [ledger, setLedger] = useState<StockLedgerItem[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchData = async () => {
    setLoading(true);
    try {
      // Just pulling the latest 50 records for the MVP ledger view
      const data = await inventoryService.getLedger(50, 0);
      setLedger(data);
    } catch (error) {
      console.error("Failed to fetch inventory ledger:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  return (
    <div className="flex flex-col h-full gap-6">
      {/* Header Row */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-app-text mb-1">
            Inventaris & Stok
          </h1>
          <p className="text-sm text-app-muted">
            Pantau pergerakan stok, barang masuk, dan barang keluar secara
            real-time.
          </p>
        </div>

        <div className="flex gap-3 w-full sm:w-auto">
          <button className="flex-1 sm:flex-none px-5 py-2.5 bg-white text-app-text border border-gray-200 rounded-xl text-sm font-semibold shadow-sm hover:bg-gray-50 transition-colors">
            Cetak Laporan
          </button>
          <button className="flex-1 sm:flex-none px-5 py-2.5 bg-app-accent text-white rounded-xl text-sm font-semibold shadow-sm shadow-orange-500/20 hover:bg-orange-600 transition-colors">
            Stok Opname
          </button>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex flex-col flex-1 bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 min-h-[500px]">
        {/* Toolbar */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
          <div className="flex p-1 bg-gray-100 rounded-xl w-full md:w-auto">
            <button className="flex-1 md:flex-none px-6 py-2 rounded-lg text-sm font-medium transition-all bg-white text-app-text shadow-sm">
              Semua Mutasi
            </button>
            <button className="flex-1 md:flex-none px-6 py-2 rounded-lg text-sm font-medium transition-all text-gray-500 hover:text-app-text">
              Stok Masuk
            </button>
            <button className="flex-1 md:flex-none px-6 py-2 rounded-lg text-sm font-medium transition-all text-gray-500 hover:text-app-text">
              Stok Keluar
            </button>
          </div>

          <div className="relative w-full md:w-64">
            <Search
              className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
              size={18}
            />
            <input
              type="text"
              placeholder="Cari produk atau SKU..."
              className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-sm transition-all"
            />
          </div>
        </div>

        {/* Ledger Table */}
        <InventoryTable ledger={ledger} loading={loading} />
      </div>
    </div>
  );
}
