import { useState } from "react";
import { X, PackagePlus } from "lucide-react";
import { ProductCreateInput } from "../../../types/product";

interface AddProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: ProductCreateInput) => Promise<void>;
}

export function AddProductModal({
  isOpen,
  onClose,
  onSave,
}: AddProductModalProps) {
  const [formData, setFormData] = useState<ProductCreateInput>({
    name: "",
    sku: "",
    base_unit: "pcs",
    category: "",
    variant: "",
    latest_selling_price: 0,
  });
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await onSave(formData);
      onClose();
      // Reset form
      setFormData({
        name: "",
        sku: "",
        base_unit: "pcs",
        category: "",
        variant: "",
        latest_selling_price: 0,
      });
    } catch (error) {
      console.error("Failed to save product:", error);
      alert("Gagal menyimpan produk. Cek console untuk info lebih lanjut.");
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

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-3xl w-full max-w-lg overflow-hidden shadow-xl animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50/50">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 text-blue-600 rounded-xl">
              <PackagePlus size={20} />
            </div>
            <h2 className="text-lg font-bold text-app-text">
              Tambah Produk Baru
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        <form
          onSubmit={handleSubmit}
          className="p-6 flex flex-col gap-4 max-h-[70vh] overflow-y-auto"
        >
          <div>
            <label className="block text-sm font-medium text-app-text mb-1.5">
              Nama Produk <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
              placeholder="Contoh: Indomie Goreng"
              value={formData.name}
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-app-text mb-1.5">
                SKU / Kode Produk
              </label>
              <input
                type="text"
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all uppercase"
                placeholder="Contoh: IDM-GRG-01"
                value={formData.sku || ""}
                onChange={(e) =>
                  setFormData({
                    ...formData,
                    sku: e.target.value.toUpperCase(),
                  })
                }
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-app-text mb-1.5">
                Varian
              </label>
              <input
                type="text"
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
                placeholder="Contoh: Pedas, Ori"
                value={formData.variant || ""}
                onChange={(e) =>
                  setFormData({ ...formData, variant: e.target.value })
                }
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-app-text mb-1.5">
                Kategori
              </label>
              <input
                type="text"
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all uppercase"
                placeholder="Contoh: MAKANAN"
                value={formData.category || ""}
                onChange={(e) =>
                  setFormData({
                    ...formData,
                    category: e.target.value.toUpperCase(),
                  })
                }
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-app-text mb-1.5">
                Satuan Dasar <span className="text-red-500">*</span>
              </label>
              <select
                required
                className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all bg-white"
                value={formData.base_unit || "pcs"}
                onChange={(e) =>
                  setFormData({ ...formData, base_unit: e.target.value })
                }
              >
                <option value="pcs">Pcs (Pieces)</option>
                <option value="kg">Kg (Kilogram)</option>
                <option value="liter">Liter (L)</option>
                <option value="box">Box</option>
                <option value="pack">Pack / Bungkus</option>
                <option value="dus">Dus</option>
                <option value="gram">Gram (gr)</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-app-text mb-1.5">
              Harga Jual Default <span className="text-red-500">*</span>
            </label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 pl-4 flex items-center text-gray-500 font-medium">
                Rp
              </span>
              <input
                type="text"
                inputMode="numeric"
                required
                className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium"
                placeholder="0"
                value={
                  formData.latest_selling_price
                    ? formData.latest_selling_price.toLocaleString("id-ID")
                    : ""
                }
                onChange={handlePriceChange}
              />
            </div>
            <p className="text-xs text-gray-500 mt-1">
              Dapat diubah nanti saat transaksi. Harga modal dihitung otomatis
              dari riwayat pembelian (stok).
            </p>
          </div>

          <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 mt-2">
            <h4 className="text-sm font-semibold text-blue-800 mb-1">
              Catatan Stok Awal
            </h4>
            <p className="text-xs text-blue-600/80 leading-relaxed">
              Produk baru yang dibuat akan memiliki stok 0. Untuk menambahkan
              stok awal, silakan gunakan fitur "Tambah Stok" setelah produk
              berhasil dibuat.
            </p>
          </div>

          <div className="flex gap-3 justify-end mt-2 pt-4 border-t border-gray-100">
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
              className="px-6 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 disabled:cursor-not-allowed rounded-xl transition-colors drop-shadow-sm flex items-center gap-2"
            >
              {loading && (
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              )}
              {loading ? "Menyimpan..." : "Simpan Produk Baru"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
