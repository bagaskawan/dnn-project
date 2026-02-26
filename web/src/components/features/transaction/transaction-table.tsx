import { TransactionListItem } from "../../../types/transaction";
import { formatRupiah, formatDate } from "../../../lib/format";
import {
  ArrowDownLeft,
  ArrowUpRight,
  FileText,
  AlertCircle,
  Eye,
} from "lucide-react";
import Link from "next/link";

interface TransactionTableProps {
  transactions: TransactionListItem[];
  loading: boolean;
  onViewDetail: (id: string) => void;
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
          <div className="h-3 bg-gray-100 rounded w-24 animate-pulse"></div>
        </div>
      </td>
      <td className="px-4 py-4">
        <div className="h-6 bg-gray-100 rounded-full w-20 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="flex flex-col gap-1">
          <div className="h-4 bg-gray-100 rounded w-28 animate-pulse"></div>
          <div className="h-3 bg-gray-100 rounded w-20 animate-pulse"></div>
        </div>
      </td>
      <td className="px-4 py-4 text-right">
        <div className="h-8 w-8 bg-gray-100 rounded-lg animate-pulse ml-auto"></div>
      </td>
    </tr>
  );
}

export function TransactionTable({
  transactions,
  loading,
  onViewDetail,
}: TransactionTableProps) {
  return (
    <div className="bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 flex flex-col gap-4 h-full flex-1">
      <div className="overflow-x-auto flex-1">
        <table className="w-full text-sm text-left text-app-text">
          <thead className="text-xs text-app-muted uppercase bg-gray-50/50 rounded-lg">
            <tr>
              <th scope="col" className="px-4 py-3 rounded-l-lg">
                Tgl Transaksi
              </th>
              <th scope="col" className="px-4 py-3">
                Pihak Terkait
              </th>
              <th scope="col" className="px-4 py-3">
                Tipe
              </th>
              <th scope="col" className="px-4 py-3">
                Total / Pembayaran
              </th>
              <th scope="col" className="px-4 py-3 text-right rounded-r-lg">
                Aksi
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              [1, 2, 3, 4, 5].map((i) => <SkeletonRow key={i} />)
            ) : transactions.length === 0 ? (
              <tr>
                <td
                  colSpan={5}
                  className="px-4 py-12 text-center text-app-muted"
                >
                  <div className="flex flex-col items-center justify-center gap-2">
                    <AlertCircle size={32} className="text-gray-300" />
                    <p>Tidak ada transaksi yang ditemukan</p>
                  </div>
                </td>
              </tr>
            ) : (
              transactions.map((trx) => (
                <tr
                  key={trx.id}
                  className="border-b border-gray-50 last:border-0 hover:bg-gray-50/30 transition-colors group"
                >
                  <td className="px-4 py-4 whitespace-nowrap text-app-muted font-medium">
                    {formatDate(trx.transaction_date)}
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex flex-col">
                      <span className="font-semibold text-app-text">
                        {trx.contact_name}
                      </span>
                      {trx.invoice_number && (
                        <span className="text-xs text-app-muted flex items-center gap-1 mt-0.5">
                          <FileText size={10} /> {trx.invoice_number}
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-4">
                    {trx.type === "IN" ? (
                      <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-orange-50 text-orange-700 border border-orange-100/50">
                        <ArrowUpRight size={14} /> Pengadaan
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-100/50">
                        <ArrowDownLeft size={14} /> Penjualan
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex flex-col">
                      <span
                        className={`font-bold ${trx.type === "IN" ? "text-orange-600" : "text-blue-600"}`}
                      >
                        {formatRupiah(trx.total_amount)}
                      </span>
                      {trx.payment_method && (
                        <span className="text-xs text-app-muted uppercase mt-0.5">
                          Metode: {trx.payment_method}
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-4 text-right">
                    <button
                      onClick={() => onViewDetail(trx.id)}
                      className="p-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-colors border border-transparent hover:border-blue-100 inline-flex"
                      title="Lihat Detail"
                    >
                      <Eye size={18} />
                    </button>
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
