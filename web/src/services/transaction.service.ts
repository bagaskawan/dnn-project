import {
  TransactionListItem,
  TransactionDetail,
  TransactionFilters,
  TransactionStats,
} from "../types/transaction";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

export const transactionService = {
  getTransactions: async (
    filters?: TransactionFilters,
  ): Promise<TransactionListItem[]> => {
    const url = new URL(`${API_BASE}/transactions`);

    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== "") {
          url.searchParams.append(key, String(value));
        }
      });
    }

    const res = await fetch(url.toString());
    if (!res.ok) throw new Error("Failed to fetch transactions");
    return res.json();
  },

  getDetail: async (id: string): Promise<TransactionDetail> => {
    const res = await fetch(`${API_BASE}/transactions/${id}`);
    if (!res.ok) throw new Error("Failed to fetch transaction detail");
    return res.json();
  },

  getStats: async (
    filters?: Omit<TransactionFilters, "limit" | "offset">,
  ): Promise<TransactionStats> => {
    const url = new URL(`${API_BASE}/transactions/stats`);

    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== "") {
          url.searchParams.append(key, String(value));
        }
      });
    }

    const res = await fetch(url.toString());
    if (!res.ok) throw new Error("Failed to fetch transaction stats");
    return res.json();
  },
};
