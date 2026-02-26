import {
  ContactItem,
  ContactCreateInput,
  ContactUpdateInput,
  ContactStats,
  ContactSummary,
} from "../types/contact";

const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

export const contactService = {
  getContacts: async (
    type?: "CUSTOMER" | "SUPPLIER",
  ): Promise<ContactItem[]> => {
    const url = new URL(`${API_BASE}/contacts`);
    if (type) {
      url.searchParams.append("type", type);
    }
    const res = await fetch(url.toString());
    if (!res.ok) throw new Error("Failed to fetch contacts");
    return res.json();
  },

  createContact: async (data: ContactCreateInput): Promise<ContactItem> => {
    const res = await fetch(`${API_BASE}/contacts`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error("Failed to create contact");
    return res.json();
  },

  updateContact: async (
    id: string,
    data: ContactUpdateInput,
  ): Promise<ContactItem> => {
    const res = await fetch(`${API_BASE}/contacts/${id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error("Failed to update contact");
    return res.json();
  },

  getStats: async (id: string): Promise<ContactStats> => {
    const res = await fetch(`${API_BASE}/contacts/${id}/stats`);
    if (!res.ok) throw new Error("Failed to fetch contact stats");
    return res.json();
  },

  getSummary: async (): Promise<ContactSummary> => {
    const res = await fetch(`${API_BASE}/contacts/summary`);
    if (!res.ok) throw new Error("Failed to fetch contact summary");
    return res.json();
  },
};
