import { Star, Plus } from "lucide-react";

export function ValuableCustomer() {
    return (
        <div className="bg-white/50 backdrop-blur-sm border border-[#f3eee4] rounded-3xl p-5 flex flex-col gap-4 flex-1">
            <div className="flex items-center justify-between h-10">
                <div className="flex items-center gap-2">
                    <div className="bg-app-text rounded-full p-2 text-white">
                        <Star size={16} />
                    </div>
                    <h2 className="text-lg font-semibold text-app-text">Valuable Customer</h2>
                </div>
                <button className="w-8 h-8 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
                    <Plus size={16} />
                </button>
            </div>

            <div className="mt-2 flex flex-col gap-2">
                <div className="flex items-center justify-between text-xs text-app-text font-medium px-1">
                    <span>Milestones Progress</span>
                </div>
                <div className="h-3 w-full bg-app-purple/20 rounded-full overflow-hidden relative border border-app-purple/10">
                    <div className="absolute top-0 left-0 h-full bg-app-purple w-[55%] rounded-full opacity-80" />
                </div>
                <div className="flex items-center justify-between text-[10px] text-app-muted px-1 mt-1">
                    <span>0%</span>
                    <span>20%</span>
                    <span>55%</span>
                    <span>100%</span>
                </div>
            </div>

            <div className="flex flex-col gap-4 mt-2 h-full overflow-y-auto pr-1">
                {/* Task 1 */}
                <div className="flex flex-col gap-1.5 pb-3 border-b border-gray-100">
                    <div className="flex items-start justify-between">
                        <span className="text-sm font-medium text-app-text">Restock Emerald Necklace - Main Inventory</span>
                        <span className="bg-app-blue/40 text-blue-800 text-[10px] px-2.5 py-1 rounded-full font-medium whitespace-nowrap">● Inventory</span>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-app-muted">
                        <img src="https://i.pravatar.cc/150?u=a042581f4e29026024d" className="w-5 h-5 rounded-full" alt="assignee" />
                        <span>May 24 — 2 days from now</span>
                    </div>
                </div>

                {/* Task 2 */}
                <div className="flex flex-col gap-1.5 pb-3 border-b border-gray-100">
                    <div className="flex items-start justify-between">
                        <span className="text-sm font-medium text-app-text">Finalize Client Order - Isabella Reed</span>
                        <span className="bg-app-salmon text-orange-900 text-[10px] px-2.5 py-1 rounded-full font-medium whitespace-nowrap">● Custom Order</span>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-app-muted">
                        <img src="https://i.pravatar.cc/150?u=a042581f4e29026024d" className="w-5 h-5 rounded-full" alt="assignee" />
                        <span>May 24 — 2 days from now</span>
                    </div>
                </div>

                {/* Task 3 */}
                <div className="flex flex-col gap-1.5">
                    <div className="flex items-start justify-between">
                        <span className="text-sm font-medium text-app-text">Schedule Diamond Polishing</span>
                        <span className="bg-app-rose text-pink-900 text-[10px] px-2.5 py-1 rounded-full font-medium whitespace-nowrap">● Maintenance</span>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-app-muted">
                        <img src="https://i.pravatar.cc/150?u=a042581f4e29026024d" className="w-5 h-5 rounded-full" alt="assignee" />
                        <span>May 24 — 2 days from now</span>
                    </div>
                </div>
            </div>
        </div>
    );
}
