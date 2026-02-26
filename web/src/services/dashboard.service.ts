import {
  DashboardSummary,
  ChartDataPoint,
  TransactionListItem,
  ProductListItem,
} from "../types/dashboard";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

export const dashboardService = {
  getSummary: async (): Promise<DashboardSummary> => {
    const res = await fetch(`${API_BASE}/dashboard/summary`);
    if (!res.ok) throw new Error("Failed to fetch summary");
    return res.json();
  },

  getChartData: async (): Promise<ChartDataPoint[]> => {
    const res = await fetch(`${API_BASE}/dashboard/chart`);
    if (!res.ok) throw new Error("Failed to fetch chart data");
    return res.json();
  },

  getRecentTransactions: async (
    limit: number = 5,
  ): Promise<TransactionListItem[]> => {
    const res = await fetch(`${API_BASE}/transactions?limit=${limit}`);
    if (!res.ok) throw new Error("Failed to fetch transactions");
    return res.json();
  },

  getProducts: async (status: string = "all"): Promise<ProductListItem[]> => {
    const res = await fetch(`${API_BASE}/products?status=${status}`);
    if (!res.ok) throw new Error("Failed to fetch products");
    return res.json();
  },
};
