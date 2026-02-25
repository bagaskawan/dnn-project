import { CustomerTabs } from "../../../components/features/dashboard/customer-tabs";
import { BusinessSummary } from "../../../components/features/dashboard/business-summary";
import { TransactionListTable } from "../../../components/features/dashboard/transaction-list-table";
import { ProductStockTable } from "../../../components/features/dashboard/product-stock-table";

export default function DashboardPage() {
    return (
        <div className="flex flex-col gap-8 h-full">

            {/* Main Grid */}
            <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">

                {/* Left Column (2/3) */}
                <div className="xl:col-span-2 flex flex-col gap-6">
                    {/* Business Summary Cards */}
                    <BusinessSummary />

                    {/* Bottom Left Row: Transactions and Product Stock */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <TransactionListTable />
                        <ProductStockTable />
                    </div>
                </div>

                {/* Right Column (1/3) */}
                <div className="flex flex-col gap-6">
                    <ProductStockTable />
                </div>

            </div>
        </div>
    );
}
