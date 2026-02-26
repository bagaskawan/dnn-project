import { useState, useEffect } from "react";
import { X, Edit2 } from "lucide-react";
import { ProductListItem, ProductUpdateInput } from "../../../types/product";

interface EditProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (id: string, data: ProductUpdateInput) => Promise<void>;
  product: ProductListItem | null;
}

export function EditProductModal({
  isOpen,
  onClose,
  onSave,
  product,
}: EditProductModalProps) {
  const [formData, setFormData] = useState<ProductUpdateInput>({
    name: "",
    latest_selling_price: 0,
    current_stock: 0,
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (product && isOpen) {
      setFormData({
        name: product.name,
        latest_selling_price: product.price,
        current_stock: product.stock,
      });
    }
  }, [product, isOpen]);

  if (!isOpen || !product) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await onSave(product.id, formData);
      onClose();
    } catch (error) {
      console.error("Failed to update product:", error);
      alert("Gagal mengupdate produk.");
    } finally {
      setLoading(false);
    }
  };

  const handlePriceChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const rawValue = e.target.value.replace(/[^0-9]/g, "");
    setFormData({
      ...formData,
      latest_selling_price: rawValue ? parseInt(rawValue, 10) : 0,
    });
  };

  const handleStockChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const rawValue = e.target.value;
    // Allow empty string for backspace, but otherwise parse as float
    setFormData({
      ...formData,
      current_stock: rawValue === "" ? 0 : parseFloat(rawValue) || 0,
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-3xl w-full max-w-lg overflow-hidden shadow-xl animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50/50">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-orange-100 text-orange-600 rounded-xl">
              <Edit2 size={20} />
            </div>
            <h2 className="text-lg font-bold text-app-text">
              Edit Detail Produk
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 flex flex-col gap-4">
          <div className="bg-gray-50 rounded-xl p-4 mb-2">
            <div className="text-sm font-medium text-app-text mb-1">
              {product.name} {product.variant ? `(${product.variant})` : ""}
            </div>
            <div className="text-xs text-gray-500">
              SKU: {product.sku || "-"} | Kategori: {product.category || "-"} |
              Satuan: {product.unit}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-app-text mb-1.5">
              Nama Produk <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all"
              placeholder="Masukkan nama produk"
              value={formData.name}
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-app-text mb-1.5">
                Stok Saat Ini
              </label>
              <div className="relative">
                <input
                  type="number"
                  step="0.01"
                  className="w-full px-4 py-2.5 pr-14 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all"
                  value={formData.current_stock || ""}
                  onChange={handleStockChange}
                />
                <span className="absolute inset-y-0 right-0 pr-4 flex items-center text-gray-500 text-sm pointer-events-none">
                  {product.unit}
                </span>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-app-text mb-1.5">
                Harga Jual
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 pl-4 flex items-center text-gray-500 font-medium text-sm">
                  Rp
                </span>
                <input
                  type="text"
                  inputMode="numeric"
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-orange-500/20 focus:border-orange-500 transition-all text-sm font-medium"
                  value={
                    formData.latest_selling_price
                      ? formData.latest_selling_price.toLocaleString("id-ID")
                      : ""
                  }
                  onChange={handlePriceChange}
                />
              </div>
            </div>
          </div>

          <div className="flex gap-3 justify-end mt-4 pt-4 border-t border-gray-100">
            <button
              type="button"
              onClick={onClose}
              className="px-6 py-2.5 text-sm font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-xl transition-colors"
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={loading || !formData.name}
              className="px-6 py-2.5 text-sm font-medium text-white bg-orange-600 hover:bg-orange-700 disabled:bg-orange-300 disabled:cursor-not-allowed rounded-xl transition-colors drop-shadow-sm flex items-center gap-2"
            >
              {loading && (
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              )}
              {loading ? "Menyimpan..." : "Simpan Perubahan"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
