"use client";

import { useEffect, useState } from "react";
import { AlertTriangle, CheckCircle } from "lucide-react";
import { dashboardService } from "../../../services/dashboard.service";
import { ProductListItem } from "../../../types/dashboard";

export function LowStockTable() {
  const [products, setProducts] = useState<ProductListItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    dashboardService
      .getProducts("low_stock")
      .then(setProducts)
      .catch((err) => console.error("Failed to fetch low stock:", err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="bg-white/50 dark:bg-app-surface rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-neutral-800 h-full">
        <div className="h-5 bg-gray-100 dark:bg-neutral-800 rounded w-32 animate-pulse mb-4"></div>
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="h-12 bg-gray-100 dark:bg-neutral-800 rounded-xl animate-pulse"
            ></div>
          ))}
        </div>
      </div>
    );
  }

  if (products.length === 0) {
    return (
      <div className="bg-white/50 dark:bg-app-surface rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-neutral-800 flex flex-col items-center justify-center gap-3 h-full">
        <div className="bg-green-100 dark:bg-green-500/10 p-3 rounded-full">
          <CheckCircle
            size={24}
            className="text-green-600 dark:text-green-500"
          />
        </div>
        <p className="text-sm font-medium text-green-700 dark:text-green-500">
          Semua stok aman ✅
        </p>
        <p className="text-xs text-app-muted">
          Tidak ada produk dengan stok rendah
        </p>
      </div>
    );
  }

  return (
    <div className="bg-white/50 dark:bg-app-surface rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-neutral-800 flex flex-col gap-4 h-full">
      <div className="flex items-center gap-2">
        <div className="bg-red-100 dark:bg-red-500/10 p-1.5 rounded-lg">
          <AlertTriangle size={16} className="text-red-600 dark:text-red-500" />
        </div>
        <h2 className="font-bold text-app-text">Stok Rendah</h2>
        <span className="bg-red-100 dark:bg-red-500/10 text-red-700 dark:text-red-400 text-xs font-semibold px-2 py-0.5 rounded-full ml-auto">
          {products.length} produk
        </span>
      </div>

      <div className="flex flex-col gap-2 overflow-y-auto">
        {products.map((product) => (
          <div
            key={product.id}
            className="flex items-center justify-between p-3 rounded-xl bg-red-50/50 dark:bg-red-950/20 border border-red-100 dark:border-red-900/50 hover:bg-red-50 dark:hover:bg-red-900/30 transition-colors"
          >
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-app-text truncate">
                {product.name}
              </p>
              <p className="text-xs text-app-muted">{product.variant || "-"}</p>
            </div>
            <div className="text-right ml-3">
              <p
                className={`text-sm font-bold ${product.stock <= 2 ? "text-red-600" : "text-orange-500"}`}
              >
                {product.stock} {product.unit}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
