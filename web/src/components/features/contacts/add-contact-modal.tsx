import { useState } from "react";
import { X } from "lucide-react";
import { ContactCreateInput } from "../../../types/contact";

interface AddContactModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (data: ContactCreateInput) => Promise<void>;
}

export function AddContactModal({
  isOpen,
  onClose,
  onSave,
}: AddContactModalProps) {
  const [formData, setFormData] = useState<ContactCreateInput>({
    name: "",
    type: "CUSTOMER",
    phone: "",
    address: "",
    notes: "",
  });
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await onSave(formData);
      onClose();
      // Reset form on success
      setFormData({
        name: "",
        type: "CUSTOMER",
        phone: "",
        address: "",
        notes: "",
      });
    } catch (error) {
      console.error("Failed to save contact:", error);
      alert("Gagal menyimpan kontak");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white dark:bg-app-surface rounded-3xl dark:border dark:border-white/5 w-full max-w-md overflow-hidden shadow-xl animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 dark:border-white/5 bg-gray-50/50 dark:bg-black/20">
          <h2 className="text-lg font-bold text-app-text dark:text-white">
            Tambah Kontak Baru
          </h2>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 dark:hover:bg-white/10 transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 flex flex-col gap-4">
          <div>
            <label className="block text-sm font-medium text-app-text dark:text-white dark:text-gray-200 mb-1.5">
              Nama Lengkap <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 dark:border-white/10 dark:bg-black/20 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
              placeholder="Masukkan nama kontak"
              value={formData.name}
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-app-text dark:text-white dark:text-gray-200 mb-1.5">
              Tipe Kontak <span className="text-red-500">*</span>
            </label>
            <div className="grid grid-cols-2 gap-3">
              <label
                className={`flex items-center justify-center py-2.5 rounded-xl border cursor-pointer transition-all ${
                  formData.type === "CUSTOMER"
                    ? "bg-blue-50 dark:bg-blue-500/10 border-blue-200 dark:border-blue-500/20 text-blue-700 dark:text-blue-400"
                    : "border-gray-200 dark:border-white/10 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-white/5"
                }`}
              >
                <input
                  type="radio"
                  className="sr-only"
                  checked={formData.type === "CUSTOMER"}
                  onChange={() =>
                    setFormData({ ...formData, type: "CUSTOMER" })
                  }
                />
                <span className="text-sm font-medium">Customer</span>
              </label>
              <label
                className={`flex items-center justify-center py-2.5 rounded-xl border cursor-pointer transition-all ${
                  formData.type === "SUPPLIER"
                    ? "bg-purple-50 dark:bg-purple-500/10 border-purple-200 dark:border-purple-500/20 text-purple-700 dark:text-purple-400"
                    : "border-gray-200 dark:border-white/10 text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-white/5"
                }`}
              >
                <input
                  type="radio"
                  className="sr-only"
                  checked={formData.type === "SUPPLIER"}
                  onChange={() =>
                    setFormData({ ...formData, type: "SUPPLIER" })
                  }
                />
                <span className="text-sm font-medium">Supplier</span>
              </label>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-app-text dark:text-white dark:text-gray-200 mb-1.5">
              No. Telepon / WhatsApp
            </label>
            <input
              type="tel"
              inputMode="numeric"
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 dark:border-white/10 dark:bg-black/20 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
              placeholder="Contoh: 0812-3456-7890-12"
              value={formData.phone || ""}
              onChange={(e) => {
                let numericValue = e.target.value.replace(/[^0-9]/g, "");
                if (numericValue.length > 14) {
                  numericValue = numericValue.slice(0, 14);
                }
                const formattedValue =
                  numericValue.match(/.{1,4}/g)?.join("-") || "";
                setFormData({ ...formData, phone: formattedValue });
              }}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-app-text dark:text-white dark:text-gray-200 mb-1.5">
              Alamat
            </label>
            <textarea
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 dark:border-white/10 dark:bg-black/20 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all resize-none"
              placeholder="Masukkan alamat lengkap"
              rows={3}
              value={formData.address || ""}
              onChange={(e) =>
                setFormData({ ...formData, address: e.target.value })
              }
            />
          </div>

          <div className="flex gap-3 mt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 text-sm font-medium text-gray-600 dark:text-gray-300 bg-gray-100 dark:bg-white/5 hover:bg-gray-200 dark:hover:bg-white/10 rounded-xl transition-colors"
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={loading || !formData.name}
              className="flex-1 px-4 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 disabled:cursor-not-allowed rounded-xl transition-colors drop-shadow-sm"
            >
              {loading ? "Menyimpan..." : "Simpan Kontak"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
