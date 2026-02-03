from pydantic import BaseModel
from typing import List, Optional

# Model untuk Input Teks Chat dengan Context
class ChatInput(BaseModel):
    new_message: str
    current_draft: Optional[dict] = None  # Current draft context for follow-up responses

# Model untuk Output Item Barang (Hasil Ekstrak AI)
class ExtractedItem(BaseModel):
    product_name: str           # Core product: "Nangka", "Kripik"
    variant: Optional[str] = None  # Size/Type variant: "Besar", "Kecil", "Level 5"
    qty: float
    unit: str
    unit_price: Optional[float] = None  # Price per unit (from receipt)
    total_price: float
    notes: Optional[str] = None    # Attributes: "Manis", "Pedas Sedang"

# Model untuk Output Utama (Satu Transaksi Utuh)
class ProcurementDraft(BaseModel):
    action: Optional[str] = "new"  # "new", "append", "update", "delete", "chat", "clarify", "merge_confirm"
    supplier_name: Optional[str] = None
    supplier_phone: Optional[str] = None  # Phone/WA number from receipt
    supplier_address: Optional[str] = None  # Address from receipt
    transaction_date: str
    receipt_number: Optional[str] = None  # Invoice/receipt number
    items: List[ExtractedItem]
    subtotal: Optional[float] = None  # Sum of items before discount
    discount: Optional[float] = None  # Discount amount
    total: Optional[float] = None  # Final total after discount
    payment_method: Optional[str] = None  # Tunai/Transfer/etc
    follow_up_question: Optional[str] = None  # AI asks if data is missing
    suggested_actions: Optional[List[str]] = None  # Action buttons to show (e.g., ["Simpan", "Tidak"])
    confidence_score: float  # AI yakin berapa persen?
    # Merge confirmation fields
    merge_candidate: Optional[dict] = None  # Info about existing product match
    pending_items: Optional[List[dict]] = None  # Items waiting for merge confirmation


# --- COMMIT TRANSACTION SCHEMAS ---
class CommitTransactionInput(BaseModel):
    """Input schema for committing a procurement transaction to database."""
    supplier_name: str
    supplier_phone: Optional[str] = None
    supplier_address: Optional[str] = None
    transaction_date: str
    receipt_number: Optional[str] = None
    items: List[ExtractedItem]
    discount: Optional[float] = None
    total: float
    payment_method: Optional[str] = None
    input_source: str = "OCR"  # OCR atau MANUAL
    evidence_url: Optional[str] = None  # Path gambar struk


class CommitTransactionResponse(BaseModel):
    """Response schema after committing a transaction."""
    success: bool
    transaction_id: Optional[str] = None
    invoice_number: Optional[str] = None
    items_processed: Optional[int] = None
    new_products_created: Optional[int] = None
    message: str
