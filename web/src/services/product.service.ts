import {
  ProductListItem,
  ProductDetail,
  ProductCreateInput,
  ProductUpdateInput,
  ProductStockAddInput,
  ProductHistoryItem,
  ProductStats,
} from "../types/product";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

export const productService = {
  getProducts: async (
    status: "all" | "low_stock" | "out_of_stock" = "all",
  ): Promise<ProductListItem[]> => {
    const res = await fetch(`${API_BASE}/products?status=${status}`);
    if (!res.ok) throw new Error("Failed to fetch products");
    return res.json();
  },

  getDetail: async (id: string): Promise<ProductDetail> => {
    const res = await fetch(`${API_BASE}/products/${id}`);
    if (!res.ok) throw new Error("Failed to fetch product detail");
    return res.json();
  },

  createProduct: async (data: ProductCreateInput): Promise<ProductDetail> => {
    const res = await fetch(`${API_BASE}/products`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error("Failed to create product");
    return res.json();
  },

  updateProduct: async (
    id: string,
    data: ProductUpdateInput,
  ): Promise<ProductDetail> => {
    const res = await fetch(`${API_BASE}/products/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error("Failed to update product");
    return res.json();
  },

  addStock: async (id: string, data: ProductStockAddInput): Promise<any> => {
    const res = await fetch(`${API_BASE}/products/${id}/stock`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error("Failed to add stock");
    return res.json();
  },

  getHistory: async (id: string): Promise<ProductHistoryItem[]> => {
    const res = await fetch(`${API_BASE}/products/${id}/history`);
    if (!res.ok) throw new Error("Failed to fetch product history");
    return res.json();
  },

  getStats: async (): Promise<ProductStats> => {
    const res = await fetch(`${API_BASE}/products/stats`);
    if (!res.ok) throw new Error("Failed to fetch product stats");
    return res.json();
  },
};
