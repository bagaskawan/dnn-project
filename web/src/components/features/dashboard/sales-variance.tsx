import { TrendingUp, Plus } from "lucide-react";

export function SalesVariance() {
    return (
        <div className="bg-white/50 backdrop-blur-sm border border-[#f3eee4] rounded-3xl p-5 flex flex-col gap-4">
            <div className="flex items-center justify-between h-10">
                <div className="flex items-center gap-2">
                    <div className="bg-app-text rounded-full p-2 text-white">
                        <TrendingUp size={16} />
                    </div>
                    <h2 className="text-lg font-semibold text-app-text">Jewellery Sales Variance</h2>
                </div>
                <button className="w-8 h-8 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
                    <Plus size={16} />
                </button>
            </div>

            {/* Gold Jewellery */}
            <div className="bg-app-surface border border-white rounded-2xl p-4 flex flex-col gap-3">
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2 font-medium">
                        <div className="w-6 h-6 bg-yellow-100 flex items-center justify-center rounded-full">
                            <span className="text-yellow-600 text-xs text-center border-b-2 border-yellow-600">G</span>
                        </div>
                        <span className="text-sm">Gold Jewellery</span>
                    </div>
                    <div className="text-right">
                        <div className="text-[10px] text-app-muted">Error</div>
                        <div className="text-xs font-semibold">-4.2%</div>
                    </div>
                </div>

                {/* Progress Bar */}
                <div className="h-2.5 w-full bg-gray-100 rounded-full overflow-hidden flex">
                    <div className="h-full bg-app-purple w-[65%]" />
                    <div className="h-full bg-app-purple/30 w-[10%]" />
                </div>

                <div className="grid grid-cols-4 gap-2 text-xs mt-1">
                    <div>
                        <div className="text-app-muted text-[10px]">Forecasted</div>
                        <div className="font-semibold">$120,000</div>
                    </div>
                    <div>
                        <div className="text-app-muted text-[10px]">Actual</div>
                        <div className="font-semibold">$115,000</div>
                    </div>
                    <div>
                        <div className="text-app-muted text-[10px]">Confidence</div>
                        <div className="font-semibold text-[10px]">★★★★☆</div>
                    </div>
                    <div className="text-right">
                        <div className="text-app-muted text-[10px]">Variance</div>
                        <div className="font-semibold text-red-500">-$5,000</div>
                    </div>
                </div>
            </div>

            {/* Diamond Jewellery */}
            <div className="bg-app-surface border border-white rounded-2xl p-4 flex flex-col gap-3">
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2 font-medium">
                        <div className="w-6 h-6 bg-blue-50 flex items-center justify-center rounded-full">
                            <span className="text-blue-500 text-xs">💎</span>
                        </div>
                        <span className="text-sm">Diamond Jewellery</span>
                    </div>
                    <div className="text-right">
                        <div className="text-[10px] text-app-muted">Error</div>
                        <div className="text-xs font-semibold text-green-600">+3.8%</div>
                    </div>
                </div>

                {/* Progress Bar */}
                <div className="h-2.5 w-full bg-gray-100 rounded-full overflow-hidden flex">
                    <div className="h-full bg-app-rose w-[75%]" />
                    <div className="h-full bg-app-rose/30 w-[15%]" />
                </div>

                <div className="grid grid-cols-4 gap-2 text-xs mt-1">
                    <div>
                        <div className="text-app-muted text-[10px]">Forecasted</div>
                        <div className="font-semibold">$180,000</div>
                    </div>
                    <div>
                        <div className="text-app-muted text-[10px]">Actual</div>
                        <div className="font-semibold">$187,000</div>
                    </div>
                    <div>
                        <div className="text-app-muted text-[10px]">Confidence</div>
                        <div className="font-semibold text-[10px]">★★★★☆</div>
                    </div>
                    <div className="text-right">
                        <div className="text-app-muted text-[10px]">Variance</div>
                        <div className="font-semibold text-green-600">+$7,000</div>
                    </div>
                </div>
            </div>

        </div>
    );
}
