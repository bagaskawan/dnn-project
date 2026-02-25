import Image from "next/image";

const TABS = [
    {
        name: "Sophia Bennett",
        role: "Luxury Jewelry Collector",
        tag: "+30% week",
        avatar: "https://i.pravatar.cc/150?u=a04258114e29026702d",
        active: false,
    },
    {
        name: "Boutique Owner",
        role: "In-store Registration, LinkedIn",
        tag: "",
        avatar: "https://i.pravatar.cc/150?u=a042581f4e29026024d",
        active: true,
    },
    {
        name: "Aria Thompson",
        role: "Bridal Consultant",
        tag: "+16% today",
        avatar: "https://i.pravatar.cc/150?u=a04258a2462d826712d",
        active: false,
        tagColor: "bg-app-purple"
    },
    {
        name: "Aria Thompson",
        role: "Bridal Consultant",
        tag: "+8% today",
        avatar: "https://i.pravatar.cc/150?u=a04258a2462d826713d",
        active: false,
        tagColor: "bg-blue-300"
    },
];

export function CustomerTabs() {
    return (
        <div className="flex items-center gap-6 overflow-x-auto pb-2 scrollbar-none w-full">
            {TABS.map((tab, idx) => (
                <div
                    key={idx}
                    className={`flex items-center gap-3 p-2 rounded-2xl cursor-pointer transition-all whitespace-nowrap ${tab.active ? "bg-white/60 shadow-sm" : "hover:bg-white/40"
                        }`}
                >
                    <div className="w-10 h-10 rounded-full bg-gray-200 overflow-hidden shrink-0 border border-white/50">
                        <img src={tab.avatar} alt={tab.name} className="w-full h-full object-cover" />
                    </div>
                    <div className="flex flex-col">
                        <div className="flex items-center gap-2">
                            <span className="font-semibold text-app-text text-sm">{tab.name}</span>
                            {tab.tag && (
                                <span className={`text-[10px] px-2 py-0.5 rounded-full font-medium ${tab.tagColor ? tab.tagColor : "bg-pink-300"
                                    }`}>
                                    {tab.tag}
                                </span>
                            )}
                        </div>
                        <span className="text-xs text-app-muted mt-0.5">{tab.role}</span>
                    </div>
                </div>
            ))}
        </div>
    );
}
