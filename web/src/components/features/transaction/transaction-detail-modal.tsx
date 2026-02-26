import { useState, useEffect } from "react";
import { X, Receipt, Printer, ArrowDownLeft, ArrowUpRight } from "lucide-react";
import { TransactionDetail } from "../../../types/transaction";
import { transactionService } from "../../../services/transaction.service";
import { formatRupiah, formatDate } from "../../../lib/format";

interface TransactionDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  transactionId: string | null;
}

export function TransactionDetailModal({
  isOpen,
  onClose,
  transactionId,
}: TransactionDetailModalProps) {
  const [detail, setDetail] = useState<TransactionDetail | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isOpen && transactionId) {
      const fetchDetail = async () => {
        setLoading(true);
        try {
          const data = await transactionService.getDetail(transactionId);
          setDetail(data);
        } catch (error) {
          console.error("Failed to fetch transaction detail:", error);
        } finally {
          setLoading(false);
        }
      };
      fetchDetail();
    } else {
      setDetail(null);
    }
  }, [isOpen, transactionId]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-3xl w-full max-w-2xl overflow-hidden shadow-xl animate-in fade-in zoom-in-95 duration-200 flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50/50 shrink-0">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 text-blue-600 rounded-xl">
              <Receipt size={20} />
            </div>
            <div>
              <h2 className="text-lg font-bold text-app-text leading-tight">
                Detail Transaksi
              </h2>
              {detail && (
                <p className="text-xs text-app-muted">
                  ID: {detail.id.slice(0, 8)}...
                </p>
              )}
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              className="p-2 text-gray-500 hover:text-blue-600 rounded-xl hover:bg-blue-50 transition-colors hidden sm:flex"
              title="Cetak Struk"
            >
              <Printer size={20} />
            </button>
            <button
              onClick={onClose}
              className="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors"
            >
              <X size={20} />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {loading ? (
            <div className="flex flex-col gap-6 animate-pulse">
              <div className="h-24 bg-gray-100 rounded-2xl w-full"></div>
              <div className="h-40 bg-gray-100 rounded-2xl w-full"></div>
              <div className="h-10 bg-gray-100 rounded-xl w-full"></div>
            </div>
          ) : detail ? (
            <div className="flex flex-col gap-6">
              {/* Summary Card */}
              <div className="bg-gray-50 rounded-2xl p-5 border border-gray-100">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-lg font-bold text-app-text mb-1">
                      {detail.contact_name}
                    </h3>
                    <p className="text-sm text-app-muted">
                      {detail.contact_phone || "Tanpa No. HP"} •{" "}
                      {formatDate(detail.transaction_date)}
                    </p>
                  </div>
                  {detail.type === "IN" ? (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-orange-100 text-orange-700">
                      <ArrowUpRight size={14} /> Beli Dasar (Pengadaan)
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-blue-100 text-blue-700">
                      <ArrowDownLeft size={14} /> Jual Dagang (Penjualan)
                    </span>
                  )}
                </div>

                <div className="grid grid-cols-2 gap-4 pt-4 border-t border-gray-200/60">
                  <div>
                    <p className="text-xs text-app-muted mb-1 uppercase tracking-wider font-semibold">
                      No. Invoice
                    </p>
                    <p className="text-sm font-medium text-app-text">
                      {detail.invoice_number || "-"}
                    </p>
                  </div>
                  <div>
                    <p className="text-xs text-app-muted mb-1 uppercase tracking-wider font-semibold">
                      Metode Pembayaran
                    </p>
                    <p className="text-sm font-medium text-app-text">
                      {detail.payment_method || "-"}
                    </p>
                  </div>
                </div>
              </div>

              {/* Items Table */}
              <div>
                <h4 className="font-semibold text-app-text mb-3 px-1">
                  Daftar Item ({detail.items.length})
                </h4>
                <div className="border border-gray-100 rounded-2xl overflow-hidden">
                  <table className="w-full text-sm text-left">
                    <thead className="bg-gray-50/80 text-xs uppercase text-app-muted">
                      <tr>
                        <th className="px-4 py-3 font-semibold">Item</th>
                        <th className="px-4 py-3 font-semibold text-right">
                          Harga @
                        </th>
                        <th className="px-4 py-3 font-semibold text-center">
                          Qty
                        </th>
                        <th className="px-4 py-3 font-semibold text-right">
                          Subtotal
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {detail.items.map((item) => (
                        <tr
                          key={item.id}
                          className="hover:bg-gray-50/50 transition-colors"
                        >
                          <td className="px-4 py-3">
                            <p className="font-medium text-app-text">
                              {item.product_name}
                            </p>
                            {(item.variant || item.notes) && (
                              <p className="text-xs text-app-muted mt-0.5">
                                {item.variant}{" "}
                                {item.variant && item.notes ? "•" : ""}{" "}
                                {item.notes}
                              </p>
                            )}
                          </td>
                          <td className="px-4 py-3 text-right tabular-nums">
                            {formatRupiah(item.unit_price)}
                          </td>
                          <td className="px-4 py-3 text-center">
                            {item.qty}{" "}
                            <span className="text-xs text-app-muted">
                              {item.unit}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-right font-medium tabular-nums text-app-text">
                            {formatRupiah(item.subtotal)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot className="bg-gray-50 font-bold border-t border-gray-100">
                      <tr>
                        <td colSpan={3} className="px-4 py-4 text-right">
                          Total Transaksi
                        </td>
                        <td className="px-4 py-4 text-right text-lg text-blue-600">
                          {formatRupiah(detail.total_amount)}
                        </td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              </div>
            </div>
          ) : (
            <div className="py-12 text-center text-app-muted">
              Gagal memuat detail transaksi.
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-100 bg-gray-50/50 shrink-0 flex justify-end">
          <button
            onClick={onClose}
            className="px-6 py-2.5 bg-white border border-gray-200 text-gray-700 rounded-xl text-sm font-medium hover:bg-gray-50 transition-colors drop-shadow-sm"
          >
            Tutup
          </button>
        </div>
      </div>
    </div>
  );
}
