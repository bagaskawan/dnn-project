import { FileText, Edit2, Plus, User, Mail, Phone, Link2, Calendar } from "lucide-react";

export function DetailedInformation() {
    return (
        <div className="bg-app-surface border border-[#f3eee4] rounded-3xl p-6 flex flex-col gap-6 flex-1">
            {/* Header */}
            <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                    <div className="bg-app-text rounded-full p-2 text-white">
                        <FileText size={16} />
                    </div>
                    <h2 className="text-lg font-semibold text-app-text">Detailed Information</h2>
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

            <div className="flex flex-col gap-4">
                {/* First Name */}
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <User size={18} className="text-app-muted" />
                        <div className="flex flex-col">
                            <span className="text-[10px] text-app-muted">First Name</span>
                            <span className="text-sm font-semibold text-app-text">Mason</span>
                        </div>
                    </div>
                    <button className="text-app-muted hover:text-app-text"><Edit2 size={14} /></button>
                </div>

                {/* Last Name */}
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <User size={18} className="text-app-muted" />
                        <div className="flex flex-col">
                            <span className="text-[10px] text-app-muted">Last Name</span>
                            <span className="text-sm font-semibold text-app-text">Walker</span>
                        </div>
                    </div>
                    <button className="text-app-muted hover:text-app-text"><Edit2 size={14} /></button>
                </div>

                {/* Email */}
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <Mail size={18} className="text-app-muted" />
                        <div className="flex flex-col">
                            <span className="text-[10px] text-app-muted">Email</span>
                            <span className="text-sm font-semibold text-app-text">masonwalker@gmail.com</span>
                        </div>
                    </div>
                    <button className="text-app-muted hover:text-app-text"><Edit2 size={14} /></button>
                </div>

                {/* Phone Number */}
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <Phone size={18} className="text-app-muted" />
                        <div className="flex flex-col">
                            <span className="text-[10px] text-app-muted">Phone Number</span>
                            <span className="text-sm font-semibold text-app-text">+9446357359</span>
                        </div>
                    </div>
                    <button className="text-app-muted hover:text-app-text"><Edit2 size={14} /></button>
                </div>

                {/* Source */}
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <Link2 size={18} className="text-app-muted" />
                        <div className="flex flex-col">
                            <span className="text-[10px] text-app-muted">Source</span>
                            <div className="flex items-center gap-2 mt-1">
                                <div className="w-5 h-5 rounded-full bg-gray-200 flex items-center justify-center text-[8px] font-bold">X</div>
                                <div className="w-5 h-5 rounded-full bg-gray-200 flex items-center justify-center text-[8px] font-bold">In</div>
                                <div className="w-5 h-5 rounded-full bg-gray-200 flex items-center justify-center text-[8px] font-bold">FB</div>
                                <div className="w-5 h-5 rounded-full bg-gray-200 flex items-center justify-center text-[8px] font-bold">IG</div>
                            </div>
                        </div>
                    </div>
                    <button className="text-app-muted hover:text-app-text"><Edit2 size={14} /></button>
                </div>

                {/* Last Connected */}
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <Calendar size={18} className="text-app-muted" />
                        <div className="flex flex-col">
                            <span className="text-[10px] text-app-muted">Last Connected</span>
                            <span className="text-sm font-semibold text-app-text">05/15/2025 at 7:16 pm</span>
                        </div>
                    </div>
                    <button className="text-app-muted hover:text-app-text"><Edit2 size={14} /></button>
                </div>
            </div>
        </div>
    );
}
