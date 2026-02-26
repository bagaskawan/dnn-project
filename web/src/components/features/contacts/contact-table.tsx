import { ContactItem } from "../../../types/contact";
import { formatRupiah, formatDate } from "../../../lib/format";
import { MoreVertical, Edit2, Truck, User } from "lucide-react";

interface ContactTableProps {
  contacts: ContactItem[];
  loading: boolean;
  onEdit: (contact: ContactItem) => void;
}

function SkeletonRow() {
  return (
    <tr className="border-b border-gray-50">
      <td className="px-4 py-4">
        <div className="h-5 bg-gray-100 rounded w-32 animate-pulse mb-1"></div>
        <div className="h-3 bg-gray-100 rounded w-20 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-5 bg-gray-100 rounded w-20 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 rounded w-28 animate-pulse mb-1"></div>
        <div className="h-3 bg-gray-100 rounded w-40 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-8 w-8 bg-gray-100 rounded-lg animate-pulse"></div>
      </td>
    </tr>
  );
}

export function ContactTable({ contacts, loading, onEdit }: ContactTableProps) {
  return (
    <div className="bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 flex flex-col gap-4 h-full flex-1">
      <div className="overflow-x-auto flex-1">
        <table className="w-full text-sm text-left text-app-text">
          <thead className="text-xs text-app-muted uppercase bg-gray-50/50 rounded-lg">
            <tr>
              <th scope="col" className="px-4 py-3 rounded-l-lg">
                Nama Kontak
              </th>
              <th scope="col" className="px-4 py-3">
                Tipe
              </th>
              <th scope="col" className="px-4 py-3">
                Info Kontak
              </th>
              <th scope="col" className="px-4 py-3 text-right rounded-r-lg">
                Aksi
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              [1, 2, 3, 4, 5].map((i) => <SkeletonRow key={i} />)
            ) : contacts.length === 0 ? (
              <tr>
                <td
                  colSpan={4}
                  className="px-4 py-12 text-center text-app-muted"
                >
                  <div className="flex flex-col items-center justify-center gap-2">
                    <User size={32} className="text-gray-300" />
                    <p>Belum ada daftar kontak</p>
                  </div>
                </td>
              </tr>
            ) : (
              contacts.map((contact) => (
                <tr
                  key={contact.id}
                  className="border-b border-gray-50 last:border-0 hover:bg-gray-50/30 transition-colors group"
                >
                  <td className="px-4 py-4">
                    <div className="font-semibold text-app-text">
                      {contact.name || "-"}
                    </div>
                    <div className="text-xs text-app-muted">
                      Ditambahkan: {formatDate(contact.created_at)}
                    </div>
                  </td>
                  <td className="px-4 py-4">
                    <span
                      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${
                        contact.type === "SUPPLIER"
                          ? "bg-purple-100 text-purple-800"
                          : "bg-blue-100 text-blue-800"
                      }`}
                    >
                      {contact.type === "SUPPLIER" ? (
                        <Truck size={12} />
                      ) : (
                        <User size={12} />
                      )}
                      {contact.type}
                    </span>
                  </td>
                  <td className="px-4 py-4">
                    <div className="font-medium">{contact.phone || "-"}</div>
                    <div className="text-xs text-app-muted line-clamp-1 max-w-xs">
                      {contact.address || "-"}
                    </div>
                  </td>
                  <td className="px-4 py-4 text-right">
                    <button
                      onClick={() => onEdit(contact)}
                      className="p-2 text-app-muted hover:text-app-text hover:bg-white rounded-lg transition-colors border border-transparent hover:border-gray-200"
                      title="Edit Kontak"
                    >
                      <Edit2 size={16} />
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
