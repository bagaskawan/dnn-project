"use client";

import { useEffect, useState } from "react";
import { MoreHorizontal } from "lucide-react";
import { dashboardService } from "../../../services/dashboard.service";
import { TransactionListItem } from "../../../types/dashboard";

function formatRupiah(value: number): string {
  return "Rp " + value.toLocaleString("id-ID", { minimumFractionDigits: 0 });
}

function formatDate(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    return date.toLocaleDateString("id-ID", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return dateStr;
  }
}

function SkeletonRow() {
  return (
    <tr className="border-b border-gray-50 dark:border-neutral-800">
      <td className="px-4 py-3">
        <div className="h-4 bg-gray-100 dark:bg-neutral-800 rounded w-28 animate-pulse mb-1"></div>
        <div className="h-3 bg-gray-100 dark:bg-neutral-800 rounded w-20 animate-pulse"></div>
      </td>
      <td className="px-4 py-3">
        <div className="h-4 bg-gray-100 dark:bg-neutral-800 rounded w-14 animate-pulse"></div>
      </td>
      <td className="px-4 py-3">
        <div className="h-4 bg-gray-100 dark:bg-neutral-800 rounded w-20 animate-pulse"></div>
      </td>
    </tr>
  );
}

export function TransactionListTable() {
  const [transactions, setTransactions] = useState<TransactionListItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    dashboardService
      .getRecentTransactions(5)
      .then(setTransactions)
      .catch((err) => console.error("Failed to fetch transactions:", err))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="bg-white/50 dark:bg-app-surface rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-neutral-800 flex flex-col gap-4 h-full">
      <div className="flex items-center justify-between">
        <h2 className="font-bold text-app-text px-4">Transaksi Terbaru</h2>
        <button className="text-app-muted hover:text-app-text transition-colors">
          <MoreHorizontal size={20} />
        </button>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left text-app-text">
          <thead className="text-xs text-app-muted uppercase bg-gray-50/50 dark:bg-neutral-800/50 rounded-lg">
            <tr>
              <th scope="col" className="px-4 py-3 rounded-l-lg">
                Invoice
              </th>
              <th scope="col" className="px-4 py-3">
                Tipe
              </th>
              <th scope="col" className="px-4 py-3 rounded-r-lg">
                Total
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              [1, 2, 3, 4, 5].map((i) => <SkeletonRow key={i} />)
            ) : transactions.length === 0 ? (
              <tr>
                <td
                  colSpan={3}
                  className="px-4 py-8 text-center text-app-muted"
                >
                  Belum ada transaksi
                </td>
              </tr>
            ) : (
              transactions.map((tx) => (
                <tr
                  key={tx.id}
                  className="border-b border-gray-50 dark:border-neutral-800 last:border-0 hover:bg-gray-50/30 dark:hover:bg-neutral-800/30 transition-colors"
                >
                  <td className="px-4 py-3">
                    <div className="font-medium">
                      {tx.invoice_number || "-"}
                    </div>
                    <div className="text-xs text-app-muted">
                      {formatDate(tx.transaction_date)}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium ${
                        tx.type === "SALE" || tx.type === "OUT"
                          ? "bg-green-100 text-green-800 dark:bg-green-500/10 dark:text-green-400"
                          : "bg-blue-100 text-blue-800 dark:bg-blue-500/10 dark:text-blue-400"
                      }`}
                    >
                      {tx.type === "IN" || tx.type === "PROCUREMENT"
                        ? "BELI"
                        : "JUAL"}
                    </span>
                    <div className="text-[10px] text-app-muted mt-1">
                      {tx.contact_name}
                    </div>
                  </td>
                  <td className="px-4 py-3 font-medium">
                    {formatRupiah(tx.total_amount)}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
      <div className="mt-auto pt-4 border-t border-gray-100 dark:border-neutral-800">
        <button className="w-full py-2 text-sm font-medium text-app-text border border-gray-200 dark:border-neutral-800 rounded-xl hover:bg-gray-50 dark:hover:bg-neutral-800/50 transition-colors">
          Lihat Semua Transaksi
        </button>
      </div>
    </div>
  );
}
