import { useState, useEffect } from "react";
import { X } from "lucide-react";
import { ContactItem, ContactUpdateInput } from "../../../types/contact";

interface EditContactModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: (id: string, data: ContactUpdateInput) => Promise<void>;
  contact: ContactItem | null;
}

export function EditContactModal({
  isOpen,
  onClose,
  onSave,
  contact,
}: EditContactModalProps) {
  const [formData, setFormData] = useState<ContactUpdateInput>({
    name: "",
    phone: "",
    address: "",
    notes: "",
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (contact && isOpen) {
      setFormData({
        name: contact.name,
        phone: contact.phone || "",
        address: contact.address || "",
        notes: contact.notes || "",
      });
    }
  }, [contact, isOpen]);

  if (!isOpen || !contact) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await onSave(contact.id, formData);
      onClose();
    } catch (error) {
      console.error("Failed to update contact:", error);
      alert("Gagal mengupdate kontak");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
      <div className="bg-white rounded-3xl w-full max-w-md overflow-hidden shadow-xl animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50/50">
          <h2 className="text-lg font-bold text-app-text">Edit Kontak</h2>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 transition-colors"
          >
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 flex flex-col gap-4">
          <div>
            <label className="block text-sm font-medium text-app-text mb-1.5">
              Nama Lengkap <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
              placeholder="Masukkan nama kontak"
              value={formData.name}
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-app-text mb-1.5">
              Tipe Kontak
            </label>
            <div className="w-full px-4 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-gray-500 cursor-not-allowed flex items-center">
              {contact.type === "CUSTOMER" ? "Customer" : "Supplier"}
            </div>
            <p className="text-[10px] text-gray-400 mt-1">
              Tipe kontak tidak dapat diubah setelah dibuat.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-app-text mb-1.5">
              No. Telepon / WhatsApp
            </label>
            <input
              type="text"
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
              placeholder="Contoh: 08123456789"
              value={formData.phone || ""}
              onChange={(e) =>
                setFormData({ ...formData, phone: e.target.value })
              }
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-app-text mb-1.5">
              Alamat
            </label>
            <textarea
              className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all resize-none"
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
              className="flex-1 px-4 py-2.5 text-sm font-medium text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-xl transition-colors"
            >
              Batal
            </button>
            <button
              type="submit"
              disabled={loading || !formData.name}
              className="flex-1 px-4 py-2.5 text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 disabled:cursor-not-allowed rounded-xl transition-colors drop-shadow-sm"
            >
              {loading ? "Menyimpan..." : "Simpan Perubahan"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
