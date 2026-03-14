import { ProductDetail } from "../../../types/product";
import { formatRupiah, formatNumber, formatDate } from "../../../lib/format";
import { Package, TrendingUp, Clock, Tag, AlertTriangle } from "lucide-react";

interface ProductDetailViewProps {
  product: ProductDetail | null;
  loading: boolean;
}

export function ProductDetailView({
  product,
  loading,
}: ProductDetailViewProps) {
  if (loading || !product) {
    return (
      <div className="bg-white/50 dark:bg-app-surface/50 rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-white/5 animate-pulse">
        <div className="flex gap-6 items-start">
          <div className="w-24 h-24 rounded-2xl bg-gray-200 dark:bg-white/10" />
          <div className="flex-1 space-y-3">
            <div className="h-8 bg-gray-200 dark:bg-white/10 rounded w-1/3" />
            <div className="h-4 bg-gray-200 dark:bg-white/10 rounded w-1/4" />
            <div className="grid grid-cols-3 gap-4 mt-6">
              <div className="h-20 bg-gray-200 dark:bg-white/10 rounded-xl" />
              <div className="h-20 bg-gray-200 dark:bg-white/10 rounded-xl" />
              <div className="h-20 bg-gray-200 dark:bg-white/10 rounded-xl" />
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Calculate margin
  const marginPercentage =
    product.price > 0 && product.average_cost > 0
      ? ((product.price - product.average_cost) / product.price) * 100
      : 0;

  return (
    <div className="bg-white/50 dark:bg-app-surface rounded-3xl p-6 md:p-8 shadow-sm border border-gray-100 dark:border-white/5">
      <div className="flex flex-col md:flex-row gap-6 items-start">
        {/* Product Icon/Image Placeholder */}
        <div className="w-24 h-24 md:w-32 md:h-32 rounded-2xl bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-500/10 dark:to-indigo-500/10 flex flex-col items-center justify-center text-blue-600 dark:text-blue-400 border border-blue-100 dark:border-blue-500/20 shrink-0">
          <span className="text-4xl md:text-5xl font-bold">
            {product.initial}
          </span>
        </div>

        {/* Product Info */}
        <div className="flex-1 w-full">
          <div className="flex flex-col md:flex-row md:items-start justify-between gap-4 mb-2">
            <div>
              <h2 className="text-2xl md:text-3xl font-bold text-app-text dark:text-white flex items-center gap-3">
                {product.name}
                {product.stock <= 0 ? (
                  <span className="text-xs font-semibold px-2.5 py-1 bg-red-100 dark:bg-red-500/10 text-red-700 dark:text-red-400 rounded-lg">
                    Habis
                  </span>
                ) : product.stock <= 5 ? (
                  <span className="text-xs font-semibold px-2.5 py-1 bg-yellow-100 dark:bg-yellow-500/10 text-yellow-700 dark:text-yellow-400 rounded-lg">
                    Menipis
                  </span>
                ) : (
                  <span className="text-xs font-semibold px-2.5 py-1 bg-green-100 dark:bg-green-500/10 text-green-700 dark:text-green-400 rounded-lg">
                    Tersedia
                  </span>
                )}
              </h2>
              {product.variant && (
                <p className="text-app-muted dark:text-gray-400 mt-1 text-lg">
                  {product.variant}
                </p>
              )}
            </div>
            <div className="text-left md:text-right">
              <p className="text-sm text-app-muted dark:text-gray-400 mb-1">
                Harga Jual Default
              </p>
              <p className="text-2xl md:text-3xl font-bold text-app-text dark:text-white">
                {formatRupiah(product.price)}
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-4 text-sm text-app-muted dark:text-gray-400 mb-6">
            {product.sku && (
              <span className="flex items-center gap-1.5 bg-gray-50 dark:bg-white/5 px-3 py-1.5 rounded-lg border border-gray-100 dark:border-white/5">
                <Tag size={14} className="text-gray-400" /> SKU: {product.sku}
              </span>
            )}
            <span className="flex items-center gap-1.5 bg-gray-50 dark:bg-white/5 px-3 py-1.5 rounded-lg border border-gray-100 dark:border-white/5">
              <Package size={14} className="text-gray-400" /> Satuan:{" "}
              {product.unit}
            </span>
            {product.category && (
              <span className="flex items-center gap-1.5 bg-gray-50 dark:bg-white/5 px-3 py-1.5 rounded-lg border border-gray-100 dark:border-white/5">
                Kategori: {product.category}
              </span>
            )}
            <span className="flex items-center gap-1.5 bg-gray-50 dark:bg-white/5 px-3 py-1.5 rounded-lg border border-gray-100 dark:border-white/5">
              <Clock size={14} className="text-gray-400" /> Diupdate:{" "}
              {formatDate(product.updated_at || product.created_at)}
            </span>
          </div>

          {/* Metrics Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="bg-gray-50 dark:bg-white/5 rounded-2xl p-4 border border-gray-100 dark:border-white/5">
              <p className="text-sm font-medium text-app-muted dark:text-gray-400 mb-1">
                Sisa Stok
              </p>
              <div className="flex items-end gap-2">
                <span className="text-2xl font-bold text-app-text dark:text-white">
                  {formatNumber(product.stock)}
                </span>
                <span className="text-sm text-app-muted dark:text-gray-400 font-medium mb-1">
                  {product.unit}
                </span>
              </div>
            </div>

            <div className="bg-gray-50 dark:bg-white/5 rounded-2xl p-4 border border-gray-100 dark:border-white/5">
              <p className="text-sm font-medium text-app-muted dark:text-gray-400 mb-1">
                Rata-rata Harga Modal
              </p>
              <div className="flex items-end gap-2">
                <span className="text-2xl font-bold text-app-text dark:text-white">
                  {formatRupiah(product.average_cost)}
                </span>
                <span className="text-sm text-app-muted dark:text-gray-400 font-medium mb-1">
                  /{product.unit}
                </span>
              </div>
              {product.needs_recalculation && (
                <p className="text-xs text-orange-500 mt-1 flex items-center gap-1">
                  <AlertTriangle size={12} /> Data butuh kalkulasi ulang
                </p>
              )}
            </div>

            <div
              className={`rounded-2xl p-4 border ${marginPercentage > 0 ? "bg-green-50 dark:bg-green-500/10 border-green-100 dark:border-green-500/20" : "bg-gray-50 dark:bg-white/5 border-gray-100 dark:border-white/5"}`}
            >
              <p
                className={`text-sm font-medium mb-1 ${marginPercentage > 0 ? "text-green-800 dark:text-green-400" : "text-app-muted dark:text-gray-400"}`}
              >
                Estimasi Margin
              </p>
              <div className="flex items-end gap-2">
                <span
                  className={`text-2xl font-bold ${marginPercentage > 0 ? "text-green-700 dark:text-green-400" : "text-app-text dark:text-white"}`}
                >
                  {marginPercentage.toFixed(1)}%
                </span>
                {marginPercentage > 0 && (
                  <TrendingUp
                    size={20}
                    className="text-green-600 dark:text-green-400 mb-1"
                  />
                )}
              </div>
              <p
                className={`text-xs mt-1 ${marginPercentage > 0 ? "text-green-600/80 dark:text-green-500/80" : "text-app-muted dark:text-gray-400"}`}
              >
                Potensi laba{" "}
                {formatRupiah(product.price - product.average_cost)}/
                {product.unit}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
