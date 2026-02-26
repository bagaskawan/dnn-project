"use client";

import { useEffect, useState } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import { dashboardService } from "../../../services/dashboard.service";
import { ChartDataPoint } from "../../../types/dashboard";

function formatRupiahShort(value: number): string {
  if (value >= 1_000_000) return `${(value / 1_000_000).toFixed(1)}jt`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(0)}rb`;
  return value.toString();
}

function formatRupiahFull(value: number): string {
  return "Rp " + value.toLocaleString("id-ID", { minimumFractionDigits: 0 });
}

function formatDateShort(dateStr: string): string {
  try {
    const date = new Date(dateStr);
    return date.toLocaleDateString("id-ID", { day: "2-digit", month: "short" });
  } catch {
    return dateStr;
  }
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: Array<{ color: string; name: string; value: number }>;
  label?: string;
}

function CustomTooltip({ active, payload, label }: CustomTooltipProps) {
  if (!active || !payload) return null;
  return (
    <div className="bg-white dark:bg-app-surface border border-gray-200 dark:border-neutral-800 rounded-xl shadow-lg p-3">
      <p className="text-xs font-medium text-app-text mb-2">{label}</p>
      {payload.map((entry, idx) => (
        <p key={idx} className="text-xs" style={{ color: entry.color }}>
          {entry.name}: {formatRupiahFull(entry.value)}
        </p>
      ))}
    </div>
  );
}

export function RevenueChart() {
  const [data, setData] = useState<ChartDataPoint[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    dashboardService
      .getChartData()
      .then(setData)
      .catch((err) => console.error("Failed to fetch chart:", err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="bg-white/50 dark:bg-app-surface rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-neutral-800 h-80">
        <div className="h-5 bg-gray-100 dark:bg-neutral-800 rounded w-40 animate-pulse mb-6"></div>
        <div className="h-52 bg-gray-100 dark:bg-neutral-800 rounded-xl animate-pulse"></div>
      </div>
    );
  }

  const chartData = data.map((d) => ({
    ...d,
    date: formatDateShort(d.date),
  }));

  return (
    <div className="bg-white/50 dark:bg-app-surface rounded-3xl p-6 shadow-sm border border-gray-100 dark:border-neutral-800 flex flex-col gap-4">
      <h2 className="font-bold text-app-text px-2">
        Aktivitas 7 Hari Terakhir
      </h2>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={chartData}
            margin={{ top: 5, right: 10, left: -10, bottom: 5 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis
              dataKey="date"
              tick={{ fontSize: 11, fill: "#888" }}
              axisLine={false}
              tickLine={false}
            />
            <YAxis
              tick={{ fontSize: 11, fill: "#888" }}
              tickFormatter={formatRupiahShort}
              axisLine={false}
              tickLine={false}
            />
            <Tooltip content={<CustomTooltip />} />
            <Legend wrapperStyle={{ fontSize: 12, paddingTop: 8 }} />
            <Bar
              dataKey="sales"
              name="Penjualan"
              fill="#6E0E0A"
              radius={[6, 6, 0, 0]}
              barSize={20}
            />
            <Bar
              dataKey="purchase"
              name="Pembelian"
              fill="#478978"
              radius={[6, 6, 0, 0]}
              barSize={20}
            />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
