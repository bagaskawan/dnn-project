export interface DashboardSummary {
  total_sales_month: number;
  total_purchase_month: number;
  estimated_profit_today: number;
  transaction_count_today: number;
  sales_count_month: number;
  purchase_count_month: number;
}

export interface ChartDataPoint {
  date: string;
  sales: number;
  purchase: number;
}

export interface TransactionListItem {
  id: string;
  type: string;
  transaction_date: string;
  total_amount: number;
  invoice_number: string;
  payment_method: string;
  contact_name: string;
  contact_phone: string | null;
  contact_address: string | null;
  created_at: string;
}

export interface ProductListItem {
  id: string;
  name: string;
  sku: string | null;
  stock: number;
  unit: string;
  price: number;
  initial: string;
  category: string | null;
  variant: string | null;
}
