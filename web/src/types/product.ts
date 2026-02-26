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

export interface ProductDetail extends ProductListItem {
  average_cost: number;
  cost_per_pcs: number | null;
  needs_recalculation: boolean;
  created_at: string | null;
  updated_at: string | null;
}

export interface ProductCreateInput {
  name: string;
  sku?: string | null;
  base_unit?: string;
  category?: string | null;
  variant?: string | null;
  latest_selling_price?: number;
}

export interface ProductUpdateInput {
  name: string;
  latest_selling_price: number;
  current_stock: number;
  average_cost?: number | null;
}

export interface ProductStockAddInput {
  qty: number;
  supplier_name: string;
  supplier_phone?: string | null;
  total_buy_price: number;
}

export interface ProductHistoryItem {
  date: string;
  type: string;
  qty_change: number;
  invoice_number: string | null;
  contact_name: string | null;
  price_at_moment: number | null;
}

export interface ProductStats {
  total: number;
  low_stock: number;
  out_of_stock: number;
}
