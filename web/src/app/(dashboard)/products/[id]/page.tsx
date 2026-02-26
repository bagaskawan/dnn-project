"use client";

import { useState, useEffect } from "react";
import { useParams, useRouter } from "next/navigation";
import { ArrowLeft, Edit2, PlusCircle } from "lucide-react";
import Link from "next/link";
import { productService } from "../../../../services/product.service";
import { ProductDetailView } from "../../../../components/features/products/product-detail-view";
import { ProductStockHistory } from "../../../../components/features/products/product-stock-history";
import { EditProductModal } from "../../../../components/features/products/edit-product-modal";
import { AddStockModal } from "../../../../components/features/products/add-stock-modal";
import {
  ProductDetail,
  ProductHistoryItem,
  ProductUpdateInput,
  ProductStockAddInput,
} from "../../../../types/product";

export default function ProductDetailPage() {
  const params = useParams();
  const router = useRouter();
  const productId = params.id as string;

  const [product, setProduct] = useState<ProductDetail | null>(null);
  const [history, setHistory] = useState<ProductHistoryItem[]>([]);
  const [loading, setLoading] = useState(true);

  // Modals
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isAddStockModalOpen, setIsAddStockModalOpen] = useState(false);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [detailData, historyData] = await Promise.all([
        productService.getDetail(productId),
        productService.getHistory(productId),
      ]);
      setProduct(detailData);
      setHistory(historyData);
    } catch (error) {
      console.error("Failed to fetch product detail:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (productId) {
      fetchData();
    }
  }, [productId]);

  const handleEditProduct = async (id: string, data: ProductUpdateInput) => {
    await productService.updateProduct(id, data);
    fetchData();
  };

  const handleAddStock = async (id: string, data: ProductStockAddInput) => {
    await productService.addStock(id, data);
    fetchData();
  };

  return (
    <div className="flex flex-col h-full gap-6 max-w-5xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div className="flex items-center gap-4">
          <Link
            href="/products"
            className="p-2 text-app-muted hover:text-app-text hover:bg-white rounded-xl transition-colors shrink-0 border border-transparent hover:border-gray-200"
          >
            <ArrowLeft size={20} />
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-app-text mb-1">
              Detail Produk
            </h1>
            <p className="text-sm text-app-muted">
              Informasi lengkap dan riwayat pergerakan stok
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3 w-full sm:w-auto">
          <button
            onClick={() => setIsEditModalOpen(true)}
            disabled={!product}
            className="flex-1 sm:flex-none px-4 py-2.5 bg-white text-app-text border border-gray-200 rounded-xl text-sm font-medium hover:bg-gray-50 transition-colors flex items-center justify-center gap-2 drop-shadow-sm disabled:opacity-50"
          >
            <Edit2 size={16} />
            <span>Edit Info</span>
          </button>
          <button
            onClick={() => setIsAddStockModalOpen(true)}
            disabled={!product}
            className="flex-1 sm:flex-none px-4 py-2.5 bg-blue-600 text-white rounded-xl text-sm font-medium hover:bg-blue-700 transition-colors flex items-center justify-center gap-2 drop-shadow-sm disabled:opacity-50 disabled:bg-blue-300"
          >
            <PlusCircle size={16} />
            <span>Tambah Stok</span>
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="flex flex-col gap-6">
        <ProductDetailView product={product} loading={loading} />
        <ProductStockHistory
          history={history}
          loading={loading}
          unit={product?.unit || "pcs"}
        />
      </div>

      {/* Modals */}
      <EditProductModal
        isOpen={isEditModalOpen}
        product={product}
        onClose={() => setIsEditModalOpen(false)}
        onSave={handleEditProduct}
      />

      <AddStockModal
        isOpen={isAddStockModalOpen}
        product={product}
        onClose={() => setIsAddStockModalOpen(false)}
        onSave={handleAddStock}
      />
    </div>
  );
}
