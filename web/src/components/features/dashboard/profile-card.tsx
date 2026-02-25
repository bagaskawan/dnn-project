import { FileText, Share2, Edit2, Maximize2, Mail, Phone, Plus, Contact, Trash2 } from "lucide-react";

export function ProfileCard() {
    return (
        <div className="bg-app-surface border border-[#f3eee4] rounded-3xl p-6 flex flex-col items-center relative text-center">
            {/* Top Actions */}
            <div className="absolute top-6 left-6 flex gap-2">
                <button className="w-8 h-8 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
                    <FileText size={14} />
                </button>
                <button className="w-8 h-8 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
                    <Share2 size={14} />
                </button>
            </div>
            <div className="absolute top-6 right-6 flex gap-2">
                <button className="w-8 h-8 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
                    <Edit2 size={14} />
                </button>
                <button className="w-8 h-8 rounded-full border border-gray-200 flex items-center justify-center bg-white text-app-text hover:bg-gray-50 transition-colors">
                    <Maximize2 size={14} />
                </button>
            </div>

            {/* Avatar */}
            <div className="w-24 h-24 rounded-full border-4 border-white shadow-sm overflow-hidden mt-8 mb-4">
                <img src="https://i.pravatar.cc/150?u=a042581f4e29026024d" alt="Mason Walker" className="w-full h-full object-cover" />
            </div>

            {/* Info */}
            <h2 className="text-xl font-bold text-app-text mb-1">Mason Walker</h2>
            <p className="text-sm text-app-muted max-w-[200px]">High-End Client Coordinator in Jewelry Enthusiast</p>

            {/* Action Buttons */}
            <div className="flex items-center gap-2 mt-6">
                <button className="w-9 h-9 rounded-full bg-gray-100 flex items-center justify-center text-app-text hover:bg-gray-200 transition-colors">
                    <Edit2 size={14} />
                </button>
                <button className="w-9 h-9 rounded-full bg-gray-100 flex items-center justify-center text-app-text hover:bg-gray-200 transition-colors">
                    <Mail size={14} />
                </button>
                <button className="w-9 h-9 rounded-full bg-gray-100 flex items-center justify-center text-app-text hover:bg-gray-200 transition-colors">
                    <Phone size={14} />
                </button>
                <button className="w-9 h-9 rounded-full bg-gray-100 flex items-center justify-center text-app-text hover:bg-gray-200 transition-colors">
                    <Plus size={16} />
                </button>
                <button className="w-9 h-9 rounded-full bg-gray-100 flex items-center justify-center text-app-text hover:bg-gray-200 transition-colors">
                    <Contact size={14} />
                </button>
                <button className="w-9 h-9 rounded-full bg-gray-100 flex items-center justify-center text-app-text hover:bg-gray-200 transition-colors">
                    <Trash2 size={14} />
                </button>
            </div>
        </div>
    );
}
