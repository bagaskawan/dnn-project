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
    <tr className="border-b border-gray-50">
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 rounded w-24 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="flex flex-col gap-1">
          <div className="h-4 bg-gray-100 rounded w-32 animate-pulse"></div>
          <div className="h-3 bg-gray-100 rounded w-20 animate-pulse"></div>
        </div>
      </td>
      <td className="px-4 py-4">
        <div className="h-6 bg-gray-100 rounded-full w-20 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 rounded w-24 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 rounded w-16 animate-pulse"></div>
      </td>
    </tr>
  );
}

export function InventoryTable({ ledger, loading }: InventoryTableProps) {
  return (
    <div className="bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 flex flex-col gap-4 h-full flex-1">
      <div className="overflow-x-auto flex-1">
        <table className="w-full text-sm text-left text-app-text">
          <thead className="text-xs text-app-muted uppercase bg-gray-50/50 rounded-lg">
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
                  className="border-b border-gray-50 last:border-0 hover:bg-gray-50/30 transition-colors group"
                >
                  <td className="px-4 py-4 whitespace-nowrap text-app-muted font-medium">
                    {formatDate(item.date)}
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex items-center gap-2">
                      <div className="bg-gray-50 p-1.5 rounded-lg text-gray-400">
                        <Package size={16} />
                      </div>
                      <div className="flex flex-col">
                        <span className="font-semibold text-app-text">
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
                      <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-100/50">
                        <ArrowDownLeft size={14} /> Stok Masuk
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-orange-50 text-orange-700 border border-orange-100/50">
                        <ArrowUpRight size={14} /> Stok Keluar
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex flex-col gap-0.5">
                      {item.contact_name ? (
                        <span className="font-medium text-app-text">
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
                      className={`font-bold ${item.type === "IN" ? "text-blue-600" : "text-orange-600"}`}
                    >
                      {item.type === "IN" ? "+" : "-"}
                      {Math.abs(item.qty_change)}{" "}
                      <span className="text-xs font-medium opacity-80">
                        {item.product_unit}
                      </span>
                    </span>
                  </td>
                  <td className="px-4 py-4 text-right font-medium text-app-text">
                    {item.qty_balance}{" "}
                    <span className="text-xs text-app-muted">
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
