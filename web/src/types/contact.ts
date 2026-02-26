export interface ContactItem {
  id: string;
  name: string;
  type: "CUSTOMER" | "SUPPLIER";
  phone: string | null;
  address: string | null;
  notes: string | null;
  created_at: string;
}

export interface ContactCreateInput {
  name: string;
  type: "CUSTOMER" | "SUPPLIER";
  phone?: string | null;
  address?: string | null;
  notes?: string | null;
}

export interface ContactUpdateInput {
  name: string;
  phone?: string | null;
  address?: string | null;
  notes?: string | null;
}

export interface ContactStats {
  count: number;
  total_amount: number;
}

export interface ContactSummary {
  total_customers: number;
  total_suppliers: number;
}
