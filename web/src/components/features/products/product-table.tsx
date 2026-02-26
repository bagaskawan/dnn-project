import { ProductListItem } from "../../../types/product";
import { formatRupiah, formatNumber } from "../../../lib/format";
import { Edit2, PlusCircle, AlertCircle } from "lucide-react";
import Link from "next/link";

interface ProductTableProps {
  products: ProductListItem[];
  loading: boolean;
  onEdit: (product: ProductListItem) => void;
  onAddStock: (product: ProductListItem) => void;
}

function SkeletonRow() {
  return (
    <tr className="border-b border-gray-50">
      <td className="px-4 py-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gray-100 animate-pulse"></div>
          <div>
            <div className="h-5 bg-gray-100 rounded w-32 animate-pulse mb-1"></div>
            <div className="h-3 bg-gray-100 rounded w-20 animate-pulse"></div>
          </div>
        </div>
      </td>
      <td className="px-4 py-4">
        <div className="h-4 bg-gray-100 rounded w-16 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="h-5 bg-gray-100 rounded w-24 animate-pulse"></div>
      </td>
      <td className="px-4 py-4">
        <div className="flex gap-2 justify-end">
          <div className="h-8 w-8 bg-gray-100 rounded-lg animate-pulse"></div>
          <div className="h-8 w-8 bg-gray-100 rounded-lg animate-pulse"></div>
        </div>
      </td>
    </tr>
  );
}

export function ProductTable({
  products,
  loading,
  onEdit,
  onAddStock,
}: ProductTableProps) {
  return (
    <div className="bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 flex flex-col gap-4 h-full flex-1">
      <div className="overflow-x-auto flex-1">
        <table className="w-full text-sm text-left text-app-text">
          <thead className="text-xs text-app-muted uppercase bg-gray-50/50 rounded-lg">
            <tr>
              <th scope="col" className="px-4 py-3 rounded-l-lg">
                Info Produk
              </th>
              <th scope="col" className="px-4 py-3">
                Stok
              </th>
              <th scope="col" className="px-4 py-3">
                Harga Jual
              </th>
              <th scope="col" className="px-4 py-3 text-right rounded-r-lg">
                Aksi
              </th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              [1, 2, 3, 4, 5].map((i) => <SkeletonRow key={i} />)
            ) : products.length === 0 ? (
              <tr>
                <td
                  colSpan={4}
                  className="px-4 py-12 text-center text-app-muted"
                >
                  <div className="flex flex-col items-center justify-center gap-2">
                    <AlertCircle size={32} className="text-gray-300" />
                    <p>Tidak ada produk yang ditemukan</p>
                  </div>
                </td>
              </tr>
            ) : (
              products.map((product) => (
                <tr
                  key={product.id}
                  className="border-b border-gray-50 last:border-0 hover:bg-gray-50/30 transition-colors group"
                >
                  <td className="px-4 py-4">
                    <div className="flex items-center gap-3 w-full max-w-[300px]">
                      <div className="w-10 h-10 rounded-xl bg-[#F0F4FF] text-blue-600 flex items-center justify-center font-bold text-sm shrink-0">
                        {product.initial}
                      </div>
                      <div className="min-w-0 flex-1">
                        <Link
                          href={`/products/${product.id}`}
                          className="font-semibold text-app-text hover:text-blue-600 transition-colors block truncate"
                        >
                          {product.name}{" "}
                          {product.variant ? `(${product.variant})` : ""}
                        </Link>
                        <div className="text-xs text-app-muted flex items-center gap-2 mt-0.5">
                          {product.sku && (
                            <span className="truncate">SKU: {product.sku}</span>
                          )}
                          {product.category && (
                            <span className="px-2 py-0.5 bg-gray-100 rounded-md text-[10px] uppercase tracking-wider shrink-0">
                              {product.category}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-4">
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-app-text">
                        {formatNumber(product.stock)} {product.unit}
                      </span>
                      {product.stock <= 0 ? (
                        <span
                          className="w-2 h-2 rounded-full bg-red-500"
                          title="Stok Habis"
                        />
                      ) : product.stock <= 5 ? (
                        <span
                          className="w-2 h-2 rounded-full bg-yellow-400"
                          title="Stok Menipis"
                        />
                      ) : (
                        <span
                          className="w-2 h-2 rounded-full bg-green-500"
                          title="Stok Aman"
                        />
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-4">
                    <div className="font-semibold text-app-text">
                      {formatRupiah(product.price)}
                    </div>
                  </td>
                  <td className="px-4 py-4 text-right">
                    <div className="flex items-center justify-end gap-1">
                      <button
                        onClick={() => onAddStock(product)}
                        className="p-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-colors border border-transparent hover:border-blue-100"
                        title="Tambah Stok"
                      >
                        <PlusCircle size={16} />
                      </button>
                      <button
                        onClick={() => onEdit(product)}
                        className="p-2 text-app-muted hover:text-app-text hover:bg-white rounded-lg transition-colors border border-transparent hover:border-gray-200"
                        title="Edit Produk"
                      >
                        <Edit2 size={16} />
                      </button>
                    </div>
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
