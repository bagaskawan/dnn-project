"use client";

import { useEffect, useState } from "react";
import {
  ArrowUpRight,
  BarChart2,
  ShoppingCart,
  Activity,
  TrendingUp,
} from "lucide-react";
import { dashboardService } from "../../../services/dashboard.service";
import { DashboardSummary } from "../../../types/dashboard";

function formatRupiah(value: number): string {
  return "Rp " + value.toLocaleString("id-ID", { minimumFractionDigits: 0 });
}

const CARD_CONFIG = [
  {
    key: "total_sales_month" as keyof DashboardSummary,
    title: "Penjualan Bulan Ini",
    icon: BarChart2,
    color: "bg-[#FFED66]",
    subtitleKey: "sales_count_month" as keyof DashboardSummary,
    subtitleSuffix: " transaksi penjualan",
    isRupiah: true,
  },
  {
    key: "total_purchase_month" as keyof DashboardSummary,
    title: "Pembelian Bulan Ini",
    icon: ShoppingCart,
    color: "bg-[#A9E5BB]",
    subtitleKey: "purchase_count_month" as keyof DashboardSummary,
    subtitleSuffix: " transaksi pembelian",
    isRupiah: true,
  },
  {
    key: "transaction_count_today" as keyof DashboardSummary,
    title: "Transaksi Hari Ini",
    icon: Activity,
    color: "bg-[#A4BFEB]",
    subtitleKey: null,
    subtitleSuffix: "Total transaksi hari ini",
    isRupiah: false,
  },
  {
    key: "estimated_profit_today" as keyof DashboardSummary,
    title: "Est. Laba Hari Ini",
    icon: TrendingUp,
    color: "bg-[#E8DAEF]",
    subtitleKey: null,
    subtitleSuffix: "Estimasi berdasarkan HPP",
    isRupiah: true,
  },
];

function SkeletonCard() {
  return (
    <div className="bg-gray-100 dark:bg-app-surface border border-transparent dark:border-neutral-800 rounded-3xl p-5 flex flex-col justify-between h-40 animate-pulse">
      <div>
        <div className="h-4 bg-gray-200 dark:bg-neutral-800 rounded w-1/2 mb-4"></div>
      </div>
      <div>
        <div className="h-8 bg-gray-200 dark:bg-neutral-800 rounded w-3/4 mb-2"></div>
        <div className="h-3 bg-gray-200 dark:bg-neutral-800 rounded w-2/3"></div>
      </div>
    </div>
  );
}

export function BusinessSummary() {
  const [data, setData] = useState<DashboardSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    dashboardService
      .getSummary()
      .then(setData)
      .catch((err) => console.error("Failed to fetch summary:", err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {[1, 2, 3, 4].map((i) => (
          <SkeletonCard key={i} />
        ))}
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      {CARD_CONFIG.map((card) => {
        const value = data ? data[card.key] : 0;
        const subtitle =
          card.subtitleKey && data
            ? `${data[card.subtitleKey]}${card.subtitleSuffix}`
            : card.subtitleSuffix;

        return (
          <div
            key={card.key}
            className={`${card.color} dark:bg-app-surface dark:border dark:border-neutral-800 rounded-3xl p-5 flex flex-col justify-between h-40 relative group transition-transform hover:scale-[1.02] shadow-sm`}
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="bg-black/10 dark:bg-white/10 p-1.5 rounded-lg">
                  <card.icon size={16} className="text-app-text" />
                </div>
                <span className="font-medium text-app-text/90 text-sm">
                  {card.title}
                </span>
              </div>
              <button className="text-app-text/60 hover:text-app-text bg-white/20 dark:bg-white/5 p-1.5 rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                <ArrowUpRight size={14} />
              </button>
            </div>
            <div>
              <h3 className="text-3xl font-bold text-app-text mb-1">
                {card.isRupiah ? formatRupiah(value) : value}
              </h3>
              <p className="text-xs text-app-text/70">{subtitle}</p>
            </div>
          </div>
        );
      })}
    </div>
  );
}
