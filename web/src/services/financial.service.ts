import { FinancialProfitLoss, FinancialFilters } from "../types/financial";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

export const financialService = {
  getProfitLoss: async (
    filters?: FinancialFilters,
  ): Promise<FinancialProfitLoss> => {
    const url = new URL(`${API_BASE}/financial/profit-loss`);

    if (filters) {
      if (filters.date_from)
        url.searchParams.append("date_from", filters.date_from);
      if (filters.date_to) url.searchParams.append("date_to", filters.date_to);
    }

    const res = await fetch(url.toString());
    if (!res.ok) throw new Error("Failed to fetch profit loss statement");
    return res.json();
  },
};
