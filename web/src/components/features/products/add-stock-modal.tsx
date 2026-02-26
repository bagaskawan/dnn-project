import { useState, useEffect } from "react";
import { X, PlusCircle } from "lucide-react";
import { ProductListItem, ProductStockAddInput } from "../../../types/product";
import { ContactItem } from "../../../types/contact";
import { contactService } from "../../../services/contact.service";
import { formatRupiah } from "../../../lib/format";

interface AddStockModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (id: string, data: ProductStockAddInput) => Promise<void>;
  product: ProductListItem | null;
}

export function AddStockModal({
  isOpen,
  onClose,
  onSave,
  product,
}: AddStockModalProps) {
  const [formData, setFormData] = useState<ProductStockAddInput>({
    qty: 0,
    supplier_name: "",
    supplier_phone: "",
    total_buy_price: 0,
  });
  const [suppliers, setSuppliers] = useState<ContactItem[]>([]);
  const [loadingSuppliers, setLoadingSuppliers] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isOpen) {
      // Reset form
      setFormData({
        qty: 0,
        supplier_name: "",
        supplier_phone: "",
        total_buy_price: 0,
      });

      // Load suppliers
      const fetchSuppliers = async () => {
        setLoadingSuppliers(true);
        try {
          const data = await contactService.getContacts("SUPPLIER");
          setSuppliers(data);
        } catch (error) {
          console.error("Failed to fetch suppliers:", error);
        } finally {
          setLoadingSuppliers(false);
        }
      };
      fetchSuppliers();
    }
  }, [isOpen]);

  if (!isOpen || !product) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (formData.qty <= 0) {
      alert("Jumlah stok masuk harus lebih dari 0");
      return;
    }
    setLoading(true);
    try {
      await onSave(product.id, formData);
      onClose();
    } catch (error) {
      console.error("Failed to add stock:", error);
      alert("Gagal menambah stok.");
    } finally {
      setLoading(false);
    }
  };

  const handlePriceChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const rawValue = e.target.value.replace(/[^0-9]/g, "");
    setFormData({
      ...formData,
      total_buy_price: rawValue ? parseInt(rawValue, 10) : 0,
    });
  };

  const handleQtyChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const rawValue = e.target.value;
    setFormData({
      ...formData,
      qty: rawValue === "" ? 0 : parseFloat(rawValue) || 0,
    });
  };

  const handleSupplierSelect = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const supplierName = e.target.value;
    if (!supplierName) {
      setFormData({ ...formData, supplier_name: "", supplier_phone: "" });
      return;
    }

    if (supplierName === "NEW") {
      setFormData({ ...formData, supplier_name: "Baru", supplier_phone: "" });
      return;
    }

    const supplier = suppliers.find((s) => s.name === supplierName);
    setFormData({
      ...formData,
      supplier_name: supplierName,
      supplier_phone: supplier?.phone || "",
    });
  };

  // Calculate projected average cost
  const projectedAvgCostText =
    formData.qty > 0 && formData.total_buy_price > 0
      ? formatRupiah(formData.total_buy_price / formData.qty)
      : "Rp 0";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-3xl w-full max-w-lg overflow-hidden shadow-xl animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50/50">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 text-blue-600 rounded-xl">
              <PlusCircle size={20} />
            </div>
            <h2 className="text-lg font-bold text-app-text">
              Tambah Stok Barang
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
          <div className="bg-gray-50 rounded-xl p-4 mb-2">
            <div className="text-sm font-medium text-app-text mb-1">
              {product.name} {product.variant ? `(${product.variant})` : ""}
            </div>
            <div className="text-xs text-gray-500">
              Stok Saat Ini: {product.stock} {product.unit} | SKU:{" "}
              {product.sku || "-"}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-app-text mb-1.5">
                Jumlah Masuk <span className="text-red-500">*</span>
              </label>
              <div className="relative">
                <input
                  type="number"
                  step="0.01"
                  required
                  className="w-full px-4 py-2.5 pr-14 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all font-medium text-blue-700"
                  value={formData.qty || ""}
                  onChange={handleQtyChange}
                />
                <span className="absolute inset-y-0 right-0 pr-4 flex items-center text-gray-500 text-sm pointer-events-none">
                  {product.unit}
                </span>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-app-text mb-1.5">
                Total Harga Beli <span className="text-red-500">*</span>
              </label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 pl-4 flex items-center text-gray-500 font-medium text-sm">
                  Rp
                </span>
                <input
                  type="text"
                  inputMode="numeric"
                  required
                  className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-sm font-medium"
                  value={
                    formData.total_buy_price
                      ? formData.total_buy_price.toLocaleString("id-ID")
                      : ""
                  }
                  onChange={handlePriceChange}
                />
              </div>
            </div>
          </div>

          {formData.qty > 0 && formData.total_buy_price > 0 && (
            <div className="bg-blue-50/50 p-3 rounded-lg flex justify-between items-center text-sm border border-blue-100">
              <span className="text-blue-800">
                Estimasi Modal / {product.unit}:
              </span>
              <span className="font-semibold text-blue-900">
                {projectedAvgCostText}
              </span>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-app-text mb-1.5">
              Data Supplier <span className="text-red-500">*</span>
            </label>
            <select
              required
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all bg-white"
              value={
                formData.supplier_name === "Baru"
                  ? "NEW"
                  : formData.supplier_name
              }
              onChange={handleSupplierSelect}
              disabled={loadingSuppliers}
            >
              <option value="" disabled>
                {loadingSuppliers ? "Memuat..." : "Pilih Supplier"}
              </option>
              {suppliers.map((s) => (
                <option key={s.id} value={s.name}>
                  {s.name} {s.phone ? `(${s.phone})` : ""}
                </option>
              ))}
              <option value="NEW">+ Tambah Supplier Baru</option>
            </select>
          </div>

          {formData.supplier_name === "Baru" && (
            <div className="grid grid-cols-2 gap-4 mt-2 p-4 bg-gray-50 border border-gray-100 rounded-xl">
              <div>
                <label className="block text-xs font-medium text-app-text mb-1.5">
                  Nama Supplier Baru <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-sm"
                  placeholder="Nama supplier"
                  value={
                    formData.supplier_name === "Baru"
                      ? ""
                      : formData.supplier_name
                  }
                  onChange={(e) =>
                    setFormData({ ...formData, supplier_name: e.target.value })
                  }
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-app-text mb-1.5">
                  No. HP / WA
                </label>
                <input
                  type="text"
                  className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all text-sm"
                  placeholder="Opsional"
                  value={formData.supplier_phone || ""}
                  onChange={(e) =>
                    setFormData({ ...formData, supplier_phone: e.target.value })
                  }
                />
              </div>
            </div>
          )}

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
              disabled={
                loading ||
                formData.qty <= 0 ||
                !formData.supplier_name ||
                formData.total_buy_price <= 0
              }
              className="px-6 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 disabled:cursor-not-allowed rounded-xl transition-colors drop-shadow-sm flex items-center gap-2"
            >
              {loading && (
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              )}
              {loading ? "Menyimpan..." : "Simpan Stok Masuk"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
