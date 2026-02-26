"use client";

import { useState, useEffect } from "react";
import { Plus, Search, Filter } from "lucide-react";
import { ContactTable } from "../../../components/features/contacts/contact-table";
import { ContactStatsCards } from "../../../components/features/contacts/contact-stats-cards";
import { AddContactModal } from "../../../components/features/contacts/add-contact-modal";
import { EditContactModal } from "../../../components/features/contacts/edit-contact-modal";
import { contactService } from "../../../services/contact.service";
import {
  ContactItem,
  ContactSummary,
  ContactCreateInput,
  ContactUpdateInput,
} from "../../../types/contact";

export default function ContactsPage() {
  const [contacts, setContacts] = useState<ContactItem[]>([]);
  const [summary, setSummary] = useState<ContactSummary | null>(null);
  const [loading, setLoading] = useState(true);

  // Filter states
  const [activeTab, setActiveTab] = useState<"ALL" | "CUSTOMER" | "SUPPLIER">(
    "ALL",
  );
  const [searchQuery, setSearchQuery] = useState("");

  // Modal states
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingContact, setEditingContact] = useState<ContactItem | null>(
    null,
  );

  const fetchData = async () => {
    setLoading(true);
    try {
      const typeParam = activeTab === "ALL" ? undefined : activeTab;
      const [contactsData, summaryData] = await Promise.all([
        contactService.getContacts(typeParam),
        contactService.getSummary(),
      ]);
      setContacts(contactsData);
      setSummary(summaryData);
    } catch (error) {
      console.error("Failed to fetch contacts data:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  const handleAddContact = async (data: ContactCreateInput) => {
    await contactService.createContact(data);
    fetchData();
  };

  const handleEditContact = async (id: string, data: ContactUpdateInput) => {
    await contactService.updateContact(id, data);
    fetchData();
  };

  // Filter contacts by search query on the client side
  const filteredContacts = contacts.filter((contact) => {
    if (!searchQuery) return true;
    const lowerQuery = searchQuery.toLowerCase();
    return (
      contact.name.toLowerCase().includes(lowerQuery) ||
      (contact.phone && contact.phone.toLowerCase().includes(lowerQuery))
    );
  });

  return (
    <div className="flex flex-col h-full gap-6">
      {/* Header & Stats Row */}
      <div className="flex flex-col xl:flex-row gap-6">
        <div className="xl:w-1/3 flex flex-col justify-end pb-2">
          <h1 className="text-2xl font-bold text-app-text mb-2">
            Manajemen Kontak
          </h1>
          <p className="text-sm text-app-muted">
            Kelola daftar pelanggan dan supplier Anda di sini.
          </p>
        </div>
        <div className="xl:w-2/3">
          <ContactStatsCards summary={summary} loading={loading} />
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex flex-col flex-1 bg-white/50 rounded-3xl p-6 shadow-sm border border-gray-100 min-h-[500px]">
        {/* Toolbar: Tabs & Search */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-6">
          {/* Tabs */}
          <div className="flex p-1 bg-gray-100 rounded-xl">
            {(["ALL", "CUSTOMER", "SUPPLIER"] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-6 py-2 rounded-lg text-sm font-medium transition-all ${
                  activeTab === tab
                    ? "bg-white text-app-text shadow-sm"
                    : "text-gray-500 hover:text-app-text"
                }`}
              >
                {tab === "ALL"
                  ? "Semua Kontak"
                  : tab === "CUSTOMER"
                    ? "Pelanggan"
                    : "Supplier"}
              </button>
            ))}
          </div>

          {/* Right Actions */}
          <div className="flex w-full md:w-auto items-center gap-3">
            <div className="relative flex-1 md:w-64">
              <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-gray-400">
                <Search size={16} />
              </span>
              <input
                type="text"
                placeholder="Cari nama atau no. telepon..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 text-sm transition-all"
              />
            </div>

            <button
              onClick={() => setIsAddModalOpen(true)}
              className="px-4 py-2.5 bg-app-text text-white rounded-xl text-sm font-medium hover:bg-black transition-colors flex items-center gap-2 drop-shadow-sm whitespace-nowrap"
            >
              <Plus size={16} />
              <span className="hidden sm:inline">Tambah Kontak</span>
            </button>
          </div>
        </div>

        {/* Table Area (Flex-1 allows it to take remaining height) */}
        <ContactTable
          contacts={filteredContacts}
          loading={loading}
          onEdit={(contact) => setEditingContact(contact)}
        />
      </div>

      {/* Modals */}
      <AddContactModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onSave={handleAddContact}
      />

      <EditContactModal
        isOpen={!!editingContact}
        contact={editingContact}
        onClose={() => setEditingContact(null)}
        onSave={handleEditContact}
      />
    </div>
  );
}
