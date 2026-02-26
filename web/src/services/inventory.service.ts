import { StockLedgerItem } from "../types/inventory";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

export const inventoryService = {
  getLedger: async (
    limit: number = 50,
    offset: number = 0,
  ): Promise<StockLedgerItem[]> => {
    const res = await fetch(
      `${API_BASE}/inventory/ledger?limit=${limit}&offset=${offset}`,
    );
    if (!res.ok) throw new Error("Failed to fetch inventory ledger");
    return res.json();
  },
};
