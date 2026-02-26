export interface FinancialProfitLoss {
  revenue: number;
  cogs: number;
  gross_profit: number;
  operational_expenses: number;
  net_profit: number;
  date_from: string | null;
  date_to: string | null;
}

export interface FinancialFilters {
  date_from?: string;
  date_to?: string;
}
