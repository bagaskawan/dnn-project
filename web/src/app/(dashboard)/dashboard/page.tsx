import { BusinessSummary } from "../../../components/features/dashboard/business-summary";
import { RevenueChart } from "../../../components/features/dashboard/revenue-chart";
import { LowStockTable } from "../../../components/features/dashboard/low-stock-table";
import { TransactionListTable } from "../../../components/features/dashboard/transaction-list-table";
import { ProductStockTable } from "../../../components/features/dashboard/product-stock-table";

export default function DashboardPage() {
  return (
    <div className="flex flex-col gap-6 h-full">
      {/* Row 1: Summary Cards (full width) */}
      <BusinessSummary />

      {/* Row 2: Chart (2/3) + Low Stock Alert (1/3) */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
        <div className="xl:col-span-2">
          <RevenueChart />
        </div>
        <div>
          <LowStockTable />
        </div>
      </div>

      {/* Row 3: Recent Transactions (1/2) + Product Stock (1/2) */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <TransactionListTable />
        <ProductStockTable />
      </div>
    </div>
  );
}
