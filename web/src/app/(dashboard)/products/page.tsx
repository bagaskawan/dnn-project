"use client";

import { useState, useEffect } from "react";
import { Plus, Search } from "lucide-react";
import { ProductTable } from "../../../components/features/products/product-table";
import { ProductStatsCards } from "../../../components/features/products/product-stats-cards";
import { AddProductModal } from "../../../components/features/products/add-product-modal";
import { EditProductModal } from "../../../components/features/products/edit-product-modal";
import { AddStockModal } from "../../../components/features/products/add-stock-modal";
import { productService } from "../../../services/product.service";
import {
  ProductListItem,
  ProductStats,
  ProductCreateInput,
  ProductUpdateInput,
  ProductStockAddInput,
} from "../../../types/product";

export default function ProductsPage() {
  const [products, setProducts] = useState<ProductListItem[]>([]);
  const [stats, setStats] = useState<ProductStats | null>(null);
  const [loading, setLoading] = useState(true);

  // Filter states
  const [activeTab, setActiveTab] = useState<
    "all" | "low_stock" | "out_of_stock"
  >("all");
  const [searchQuery, setSearchQuery] = useState("");

  // Modal states
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<ProductListItem | null>(
    null,
  );
  const [addingStockProduct, setAddingStockProduct] =
    useState<ProductListItem | null>(null);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [productsData, statsData] = await Promise.all([
        productService.getProducts(activeTab),
        productService.getStats(),
      ]);
      setProducts(productsData);
      setStats(statsData);
    } catch (error) {
      console.error("Failed to fetch products data:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const handleAddProduct = async (data: ProductCreateInput) => {
    await productService.createProduct(data);
    fetchData();
  };

  const handleEditProduct = async (id: string, data: ProductUpdateInput) => {
    await productService.updateProduct(id, data);
    fetchData();
  };

  const handleAddStock = async (id: string, data: ProductStockAddInput) => {
    await productService.addStock(id, data);
    fetchData();
  };

  // Filter products by search query on the client side
  const filteredProducts = products.filter((product) => {
    if (!searchQuery) return true;
    const lowerQuery = searchQuery.toLowerCase();
    return (
      product.name.toLowerCase().includes(lowerQuery) ||
      (product.sku && product.sku.toLowerCase().includes(lowerQuery)) ||
      (product.variant && product.variant.toLowerCase().includes(lowerQuery))
    );
  });

  return (
    <div className="flex flex-col h-full gap-6">
      {/* Header & Stats Row */}
      <div className="flex flex-col xl:flex-row gap-6">
        <div className="xl:w-1/3 flex flex-col justify-end pb-2">
          <h1 className="text-2xl font-bold text-app-text mb-2">
            Manajemen Produk
          </h1>
          <p className="text-sm text-app-muted">
            Kelola daftar produk, harga, dan pantau ketersediaan stok.
          </p>
        </div>
        <div className="xl:w-2/3">
          <ProductStatsCards stats={stats} loading={loading} />
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex flex-col flex-1 bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 min-h-[500px]">
        {/* Toolbar: Tabs & Search */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
          {/* Tabs */}
          <div className="flex p-1 bg-gray-100 rounded-xl overflow-x-auto w-full md:w-auto">
            {(["all", "low_stock", "out_of_stock"] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-6 py-2 rounded-lg text-sm font-medium transition-all whitespace-nowrap ${
                  activeTab === tab
                    ? "bg-white text-app-text shadow-sm"
                    : "text-gray-500 hover:text-app-text"
                }`}
              >
                {tab === "all"
                  ? "Semua Produk"
                  : tab === "low_stock"
                    ? "Stok Menipis"
                    : "Stok Habis"}
              </button>
            ))}
          </div>

          {/* Right Actions */}
          <div className="flex w-full md:w-auto items-center gap-3">
            <div className="relative flex-1 md:w-64">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-400">
                <Search size={16} />
              </span>
              <input
                type="text"
                placeholder="Cari nama atau SKU..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-sm transition-all"
              />
            </div>

            <button
              onClick={() => setIsAddModalOpen(true)}
              className="px-4 py-2.5 bg-app-text text-white rounded-xl text-sm font-medium hover:bg-black transition-colors flex items-center gap-2 drop-shadow-sm whitespace-nowrap"
            >
              <Plus size={16} />
              <span className="hidden sm:inline">Tambah Produk</span>
            </button>
          </div>
        </div>

        {/* Table Area (Flex-1 allows it to take remaining height) */}
        <ProductTable
          products={filteredProducts}
          loading={loading}
          onEdit={(product) => setEditingProduct(product)}
          onAddStock={(product) => setAddingStockProduct(product)}
        />
      </div>

      {/* Modals */}
      <AddProductModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onSave={handleAddProduct}
      />

      <EditProductModal
        isOpen={!!editingProduct}
        product={editingProduct}
        onClose={() => setEditingProduct(null)}
        onSave={handleEditProduct}
      />

      <AddStockModal
        isOpen={!!addingStockProduct}
        product={addingStockProduct}
        onClose={() => setAddingStockProduct(null)}
        onSave={handleAddStock}
      />
    </div>
  );
}
