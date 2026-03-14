import { StockLedgerItem } from "../../../types/inventory";
import { formatDate } from "../../../lib/format";
import {
  ArrowDownLeft,
  ArrowUpRight,
  FileText,
  AlertCircle,
  Package,
} from "lucide-react";

interface InventoryTableProps {
  ledger: StockLedgerItem[];
  loading: boolean;
}

function SkeletonRow() {
  return (
    <tr className="border-b border-gray-50 dark:border-white/5">
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 dark:bg-white/10 rounded w-24 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="flex flex-col gap-1">
          <div className="h-4 bg-gray-100 dark:bg-white/10 rounded w-32 animate-pulse"></div>
          <div className="h-3 bg-gray-100 dark:bg-white/10 rounded w-20 animate-pulse"></div>
        </div>
      </td>
      <td className="px-4 py-4">
        <div className="h-6 bg-gray-100 dark:bg-white/10 rounded-full w-20 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 dark:bg-white/10 rounded w-24 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 dark:bg-white/10 rounded w-16 animate-pulse"></div>
      </td>
    </tr>
  );
}

export function InventoryTable({ ledger, loading }: InventoryTableProps) {
  return (
    <div className="bg-white/50 dark:bg-app-surface/50 rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-white/5 flex flex-col gap-4 h-full flex-1">
      <div className="overflow-x-auto flex-1">
        <table className="w-full text-sm text-left text-app-text dark:text-gray-300">
          <thead className="text-xs text-app-muted dark:text-gray-400 uppercase bg-gray-50/50 dark:bg-black/20 rounded-lg">
            <tr>
              <th scope="col" className="px-4 py-3 rounded-l-lg">
                Tanggal
              </th>
              <th scope="col" className="px-4 py-3">
                Produk
              </th>
              <th scope="col" className="px-4 py-3">
                Tipe Mutasi
              </th>
              <th scope="col" className="px-4 py-3">
                Keterangan
              </th>
              <th scope="col" className="px-4 py-3 text-right">
                Perubahan
              </th>
              <th scope="col" className="px-4 py-3 text-right rounded-r-lg">
                Sisa Stok
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              [1, 2, 3, 4, 5, 6].map((i) => <SkeletonRow key={i} />)
            ) : ledger.length === 0 ? (
              <tr>
                <td
                  colSpan={6}
                  className="px-4 py-12 text-center text-app-muted"
                >
                  <div className="flex flex-col items-center justify-center gap-2">
                    <AlertCircle size={32} className="text-gray-300" />
                    <p>Tidak ada riwayat pergerakan stok</p>
                  </div>
                </td>
              </tr>
            ) : (
              ledger.map((item) => (
                <tr
                  key={item.id}
                  className="border-b border-gray-50 dark:border-white/5 last:border-0 hover:bg-gray-50/30 dark:hover:bg-white/5 transition-colors group"
                >
                  <td className="px-4 py-4 whitespace-nowrap text-app-muted font-medium">
                    {formatDate(item.date)}
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex items-center gap-2">
                      <div className="bg-gray-50 dark:bg-black/20 p-1.5 rounded-lg text-gray-400 dark:text-gray-500">
                        <Package size={16} />
                      </div>
                      <div className="flex flex-col">
                        <span className="font-semibold text-app-text dark:text-white">
                          {item.product_name}
                        </span>
                        {item.product_sku && (
                          <span className="text-xs text-app-muted mt-0.5">
                            SKU: {item.product_sku}
                          </span>
                        )}
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-4">
                    {item.type === "IN" ? (
                      <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-blue-50 dark:bg-blue-500/10 text-blue-700 dark:text-blue-400 border border-blue-100/50 dark:border-blue-500/20">
                        <ArrowDownLeft size={14} /> Stok Masuk
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-orange-50 dark:bg-orange-500/10 text-orange-700 dark:text-orange-400 border border-orange-100/50 dark:border-orange-500/20">
                        <ArrowUpRight size={14} /> Stok Keluar
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex flex-col gap-0.5">
                      {item.contact_name ? (
                        <span className="font-medium text-app-text dark:text-gray-200">
                          {item.contact_name}
                        </span>
                      ) : (
                        <span className="text-app-muted">-</span>
                      )}
                      {item.invoice_number && (
                        <span className="text-xs text-app-muted flex items-center gap-1">
                          <FileText size={10} /> {item.invoice_number}
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-4 text-right">
                    <span
                      className={`font-bold ${item.type === "IN" ? "text-blue-600 dark:text-blue-400" : "text-orange-600 dark:text-orange-400"}`}
                    >
                      {item.type === "IN" ? "+" : "-"}
                      {Math.abs(item.qty_change)}{" "}
                      <span className="text-xs font-medium opacity-80">
                        {item.product_unit}
                      </span>
                    </span>
                  </td>
                  <td className="px-4 py-4 text-right font-medium text-app-text dark:text-white">
                    {item.qty_balance}{" "}
                    <span className="text-xs text-app-muted dark:text-gray-400">
                      {item.product_unit}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
