"use client";

import { useEffect, useState } from "react";
import { MoreHorizontal } from "lucide-react";
import { dashboardService } from "../../../services/dashboard.service";
import { ProductListItem } from "../../../types/dashboard";

function formatRupiah(value: number): string {
  return "Rp " + value.toLocaleString("id-ID", { minimumFractionDigits: 0 });
}

function SkeletonRow() {
  return (
    <tr className="border-b border-gray-50 dark:border-neutral-800">
      <td className="px-4 py-3">
        <div className="h-4 bg-gray-100 dark:bg-neutral-800 rounded w-32 animate-pulse mb-1"></div>
        <div className="h-3 bg-gray-100 dark:bg-neutral-800 rounded w-16 animate-pulse"></div>
      </td>
      <td className="px-4 py-3">
        <div className="h-4 bg-gray-100 dark:bg-neutral-800 rounded w-10 animate-pulse"></div>
      </td>
      <td className="px-4 py-3">
        <div className="h-4 bg-gray-100 dark:bg-neutral-800 rounded w-20 animate-pulse"></div>
      </td>
    </tr>
  );
}

export function ProductStockTable() {
  const [products, setProducts] = useState<ProductListItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    dashboardService
      .getProducts("all")
      .then((data) => setProducts(data.slice(0, 5)))
      .catch((err) => console.error("Failed to fetch products:", err))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="bg-white/50 dark:bg-app-surface rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-neutral-800 flex flex-col gap-4 h-full">
      <div className="flex items-center justify-between">
        <h2 className="font-bold text-app-text px-4">Stok Produk</h2>
        <button className="text-app-muted hover:text-app-text transition-colors">
          <MoreHorizontal size={20} />
        </button>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left text-app-text">
          <thead className="text-xs text-app-muted uppercase bg-gray-50/50 dark:bg-neutral-800/50 rounded-lg">
            <tr>
              <th scope="col" className="px-4 py-3 rounded-l-lg">
                Produk
              </th>
              <th scope="col" className="px-4 py-3">
                Stok
              </th>
              <th scope="col" className="px-4 py-3 rounded-r-lg">
                Harga
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              [1, 2, 3, 4, 5].map((i) => <SkeletonRow key={i} />)
            ) : products.length === 0 ? (
              <tr>
                <td
                  colSpan={3}
                  className="px-4 py-8 text-center text-app-muted"
                >
                  Belum ada produk
                </td>
              </tr>
            ) : (
              products.map((product) => (
                <tr
                  key={product.id}
                  className="border-b border-gray-50 dark:border-neutral-800 last:border-0 hover:bg-gray-50/30 dark:hover:bg-neutral-800/30 transition-colors"
                >
                  <td className="px-4 py-3">
                    <div className="font-medium">{product.name}</div>
                    <div className="text-xs text-app-muted">
                      {product.variant || product.sku || "-"}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`font-medium ${
                        product.stock <= 0
                          ? "text-red-600"
                          : product.stock <= 5
                            ? "text-red-500"
                            : product.stock <= 10
                              ? "text-orange-500"
                              : "text-app-text"
                      }`}
                    >
                      {product.stock}
                    </span>
                    <span className="text-xs text-app-muted ml-1">
                      {product.unit}
                    </span>
                  </td>
                  <td className="px-4 py-3 font-medium">
                    {formatRupiah(product.price)}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      <div className="mt-auto pt-4 border-t border-gray-100 dark:border-neutral-800">
        <button className="w-full py-2 text-sm font-medium text-app-text border border-gray-200 dark:border-neutral-800 rounded-xl hover:bg-gray-50 dark:hover:bg-neutral-800/50 transition-colors">
          Lihat Semua Produk
        </button>
      </div>
    </div>
  );
}
