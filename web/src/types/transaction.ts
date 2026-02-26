export interface TransactionListItem {
  id: string;
  type: "IN" | "OUT";
  transaction_date: string;
  total_amount: number;
  invoice_number: string | null;
  payment_method: string | null;
  contact_name: string;
  contact_phone: string | null;
  contact_address: string | null;
  created_at: string;
}

export interface TransactionItemDetail {
  id: string;
  product_name: string;
  variant: string | null;
  qty: number;
  unit: string;
  unit_price: number;
  subtotal: number;
  notes: string | null;
}

export interface TransactionDetail {
  id: string;
  type: "IN" | "OUT";
  transaction_date: string;
  total_amount: number;
  invoice_number: string | null;
  payment_method: string | null;
  contact_name: string;
  contact_phone: string | null;
  contact_address: string | null;
  created_at: string;
  items: TransactionItemDetail[];
}

export interface TransactionFilters {
  limit?: number;
  offset?: number;
  contact_id?: string;
  type?: "IN" | "OUT" | "ALL";
  date_from?: string;
  date_to?: string;
  search?: string;
}

export interface TransactionStats {
  total_count: number;
  total_amount_in: number;
  total_amount_out: number;
}
