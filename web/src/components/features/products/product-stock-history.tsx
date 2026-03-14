import { ProductHistoryItem } from "../../../types/product";
import { formatRupiah, formatNumber, formatDate } from "../../../lib/format";
import { History, ArrowDownLeft, ArrowUpRight, FileText } from "lucide-react";

interface ProductStockHistoryProps {
  history: ProductHistoryItem[];
  loading: boolean;
  unit: string;
}

function SkeletonRow() {
  return (
    <tr className="border-b border-gray-50 dark:border-white/5">
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 dark:bg-white/10 rounded w-24 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-6 bg-gray-100 dark:bg-white/10 rounded-full w-16 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 dark:bg-white/10 rounded w-16 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 dark:bg-white/10 rounded w-28 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 dark:bg-white/10 rounded w-32 animate-pulse"></div>
      </td>
    </tr>
  );
}

export function ProductStockHistory({
  history,
  loading,
  unit,
}: ProductStockHistoryProps) {
  return (
    <div className="bg-white/50 dark:bg-app-surface rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-white/5 flex flex-col gap-4">
      <div className="flex items-center gap-2 mb-2">
        <div className="p-2 text-app-text dark:text-white rounded-xl bg-gray-100 dark:bg-white/10">
          <History size={20} />
        </div>
        <h3 className="text-lg font-bold text-app-text dark:text-white">
          Riwayat Mutasi Stok
        </h3>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left text-app-text dark:text-gray-300">
          <thead className="text-xs text-app-muted dark:text-gray-400 uppercase bg-gray-50/50 dark:bg-black/20 rounded-lg">
            <tr>
              <th scope="col" className="px-4 py-3 rounded-l-lg">
                Tanggal
              </th>
              <th scope="col" className="px-4 py-3">
                Tipe
              </th>
              <th scope="col" className="px-4 py-3">
                Qty
              </th>
              <th scope="col" className="px-4 py-3">
                Harga @
              </th>
              <th scope="col" className="px-4 py-3 rounded-r-lg">
                Keterangan
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              [1, 2, 3].map((i) => <SkeletonRow key={i} />)
            ) : history.length === 0 ? (
              <tr>
                <td
                  colSpan={5}
                  className="px-4 py-8 text-center text-app-muted dark:text-gray-400"
                >
                  Belum ada riwayat pergerakan stok
                </td>
              </tr>
            ) : (
              history.map((item, index) => (
                <tr
                  key={index}
                  className="border-b border-gray-50 dark:border-white/5 last:border-0 hover:bg-gray-50/30 dark:hover:bg-white/5 transition-colors"
                >
                  <td className="px-4 py-4 whitespace-nowrap">
                    {formatDate(item.date)}
                  </td>
                  <td className="px-4 py-4">
                    {item.type === "IN" ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-50 dark:bg-blue-500/10 text-blue-700 dark:text-blue-400">
                        <ArrowDownLeft size={12} /> Masuk
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-orange-50 dark:bg-orange-500/10 text-orange-700 dark:text-orange-400">
                        <ArrowUpRight size={12} /> Keluar
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-4 font-semibold">
                    <span
                      className={
                        item.type === "IN"
                          ? "text-blue-600 dark:text-blue-400"
                          : "text-orange-600 dark:text-orange-400"
                      }
                    >
                      {item.type === "IN" ? "+" : "-"}
                      {formatNumber(Math.abs(item.qty_change))}
                    </span>{" "}
                    <span className="text-xs font-medium text-app-muted dark:text-gray-400">
                      {unit}
                    </span>
                  </td>
                  <td className="px-4 py-4">
                    {item.price_at_moment
                      ? formatRupiah(item.price_at_moment)
                      : "-"}
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex flex-col gap-0.5">
                      {item.contact_name && (
                        <span className="font-medium text-app-text dark:text-gray-200">
                          {item.contact_name}
                        </span>
                      )}
                      {item.invoice_number && (
                        <span className="text-xs text-app-muted dark:text-gray-400 flex items-center gap-1">
                          <FileText size={10} /> {item.invoice_number}
                        </span>
                      )}
                      {!item.contact_name && !item.invoice_number && (
                        <span className="text-app-muted dark:text-gray-500">
                          -
                        </span>
                      )}
                    </div>
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
