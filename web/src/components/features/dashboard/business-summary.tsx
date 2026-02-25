import { Edit2, Plus, ArrowUpRight, BarChart2, Briefcase, Calendar, FileText, AlertCircle, PauseCircle } from "lucide-react";

const SUMMARY_DATA = [
    {
        title: "Total Sales",
        value: "$1,284",
        subtitle: "+30% compared to last month",
        icon: BarChart2,
        color: "bg-[#FFED66]", // Light Yellow
    },
    {
        title: "Total Making",
        value: "$42,215",
        subtitle: "+30% includes labor + materials",
        icon: Briefcase,
        color: "bg-[#A9E5BB]", // Light Orange/Peach
    },
    {
        title: "Today's Sales",
        value: "$124",
        subtitle: "+30% since yesterday",
        icon: Calendar,
        color: "bg-[#A4BFEB]", // Light Pink
    },

];

export function BusinessSummary() {
    return (
        <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                </div>
                <div className="flex gap-2">
                    <button className="w-8 h-8 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
                        <Edit2 size={14} />
                    </button>
                    <button className="w-8 h-8 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
                        <Plus size={16} />
                    </button>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {SUMMARY_DATA.map((item, idx) => (
                    <div
                        key={idx}
                        className={`${item.color} rounded-3xl p-5 flex flex-col justify-between h-40 relative group transition-transform hover:scale-[1.02]`}
                    >
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                <div className="bg-black/10 p-1.5 rounded-lg">
                                    <item.icon size={16} className="text-app-text" />
                                </div>
                                <span className="font-medium text-app-text/90 text-sm">{item.title}</span>
                            </div>
                            <button className="text-app-text/60 hover:text-app-text bg-white/20 p-1.5 rounded-full opacity-0 group-hover:opacity-100 transition-opacity">
                                <ArrowUpRight size={14} />
                            </button>
                        </div>
                        <div>
                            <h3 className="text-3xl font-bold text-app-text mb-1">{item.value}</h3>
                            <p className="text-xs text-app-text/70">{item.subtitle}</p>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
