import { MoreHorizontal } from "lucide-react";

const DUMMY_TRANSACTIONS = [
    {
        id: "1",
        invoice_number: "INV-2023-1001",
        type: "SALE",
        contact_name: "Walk-in Customer",
        transaction_date: "24 Oct 2023, 10:30",
        total_amount: 1250.00,
        payment_method: "CASH"
    },
    {
        id: "2",
        invoice_number: "INV-2023-1002",
        type: "SALE",
        contact_name: "John Doe",
        transaction_date: "24 Oct 2023, 11:15",
        total_amount: 850.00,
        payment_method: "CREDIT CARD"
    },
    {
        id: "3",
        invoice_number: "PO-2023-0050",
        type: "PURCHASE",
        contact_name: "Gold Supplier Inc.",
        transaction_date: "23 Oct 2023, 15:45",
        total_amount: 5500.00,
        payment_method: "BANK TRANSFER"
    },
    {
        id: "4",
        invoice_number: "INV-2023-1003",
        type: "SALE",
        contact_name: "Jane Smith",
        transaction_date: "23 Oct 2023, 16:20",
        total_amount: 120.00,
        payment_method: "CASH"
    },
    {
        id: "5",
        invoice_number: "INV-2023-1004",
        type: "SALE",
        contact_name: "Walk-in Customer",
        transaction_date: "23 Oct 2023, 17:00",
        total_amount: 3500.00,
        payment_method: "DEBIT CARD"
    }
];

export function TransactionListTable() {
    return (
        <div className="bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 flex flex-col gap-4 h-full">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                    <h2 className="font-bold text-app-text px-4">Transaksi Terbaru</h2>
                </div>
                <button className="text-app-muted hover:text-app-text transition-colors">
                    <MoreHorizontal size={20} />
                </button>
            </div>

            <div className="overflow-x-auto">
                <table className="w-full text-sm text-left text-app-text">
                    <thead className="text-xs text-app-muted uppercase bg-gray-50/50 rounded-lg">
                        <tr>
                            <th scope="col" className="px-4 py-3 rounded-l-lg">Invoice</th>
                            <th scope="col" className="px-4 py-3">Type</th>
                            <th scope="col" className="px-4 py-3 rounded-r-lg">Total</th>
                        </tr>
                    </thead>
                    <tbody>
                        {DUMMY_TRANSACTIONS.map((transaction) => (
                            <tr key={transaction.id} className="border-b border-gray-50 last:border-0 hover:bg-gray-50/30 transition-colors">
                                <td className="px-4 py-3">
                                    <div className="font-medium">{transaction.invoice_number}</div>
                                    <div className="text-xs text-app-muted">{transaction.transaction_date}</div>
                                </td>
                                <td className="px-4 py-3">
                                    <span className={`inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium ${transaction.type === 'SALE' ? 'bg-green-100 text-green-800' : 'bg-blue-100 text-blue-800'}`}>
                                        {transaction.type}
                                    </span>
                                    <div className="text-[10px] text-app-muted mt-1">{transaction.payment_method}</div>
                                </td>
                                <td className="px-4 py-3 font-medium">
                                    ${transaction.total_amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
            <div className="mt-auto pt-4 border-t border-gray-100">
                <button className="w-full py-2 text-sm font-medium text-app-text border border-gray-200 rounded-xl hover:bg-gray-50 transition-colors">
                    Lihat Semua Transaksi
                </button>
            </div>
        </div>
    );
}
