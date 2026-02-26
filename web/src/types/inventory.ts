export interface StockLedgerItem {
  id: string;
  date: string;
  type: "IN" | "OUT";
  qty_change: number;
  qty_balance: number;
  product_name: string;
  product_sku: string | null;
  product_unit: string;
  invoice_number: string | null;
  contact_name: string | null;
}

export interface InventoryStats {
  total_products: number;
  total_stock_value: number; // For future implementation
}
