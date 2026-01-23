from pydantic import BaseModel
from typing import List, Optional

# Model untuk Input Teks Chat dengan Context
class ChatInput(BaseModel):
    text: str
    current_draft: Optional[dict] = None  # Current draft context for follow-up responses

# Model untuk Output Item Barang (Hasil Ekstrak AI)
class ExtractedItem(BaseModel):
    product_name: str
    qty: float
    unit: str
    total_price: float
    notes: Optional[str] = None

# Model untuk Output Utama (Satu Transaksi Utuh)
class ProcurementDraft(BaseModel):
    action: Optional[str] = "new"  # "new", "append", "update", "delete", "chat"
    supplier_name: Optional[str] = None
    transaction_date: str
    items: List[ExtractedItem]
    follow_up_question: Optional[str] = None  # AI asks if data is missing
    suggested_actions: Optional[List[str]] = None  # Action buttons to show (e.g., ["Simpan", "Tidak"])
    confidence_score: float  # AI yakin berapa persen?