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
    # Supplier confirmation field
    supplier_candidate: Optional[dict] = None  # Info about similar supplier: {name, phone, similarity}

class SaleDraft(BaseModel):
    action: Optional[str] = "new"
    customer_name: Optional[str] = "Pelanggan Umum"
    items: List[ExtractedItem]
    total: Optional[float] = None
    follow_up_question: Optional[str] = None
    suggested_actions: Optional[List[str]] = None


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

class CommitSaleInput(BaseModel):
    """Input schema for committing a sale transaction."""
    customer_name: str
    items: List[ExtractedItem]
    total: float
    payment_method: Optional[str] = "TUNAI"
    transaction_date: str = "NOW"


class CommitTransactionResponse(BaseModel):
    """Response schema after committing a transaction."""
    success: bool
    transaction_id: Optional[str] = None
    invoice_number: Optional[str] = None
    items_processed: Optional[int] = None
    new_products_created: Optional[int] = None
    message: str


# --- TRANSACTION LIST/DETAIL SCHEMAS ---

class TransactionListItem(BaseModel):
    """Schema for transaction list item (home page)."""
    id: str
    type: str  # "IN" for pengadaan, "OUT" for penjualan
    transaction_date: str
    total_amount: float
    invoice_number: Optional[str] = None
    payment_method: Optional[str] = None
    contact_name: str
    contact_phone: Optional[str] = None
    contact_address: Optional[str] = None
    created_at: str

class TransactionStats(BaseModel):
    total_count: int
    total_amount_in: float
    total_amount_out: float

class FinancialProfitLoss(BaseModel):
    """Schema for Profit & Loss (Laba Rugi) response."""
    revenue: float
    cogs: float  # Cost of Goods Sold / HPP
    gross_profit: float
    operational_expenses: float
    net_profit: float
    date_from: Optional[str] = None
    date_to: Optional[str] = None

class TransactionItemDetail(BaseModel):
    """Schema for transaction item detail."""
    id: str
    product_name: str
    variant: Optional[str] = None
    qty: float
    unit: str
    unit_price: float
    subtotal: float
    notes: Optional[str] = None


class TransactionDetailResponse(BaseModel):
    """Full transaction detail including items."""
    id: str
    type: str
    transaction_date: str
    total_amount: float
    invoice_number: Optional[str] = None
    payment_method: Optional[str] = None
    contact_name: str
    contact_phone: Optional[str] = None
    contact_address: Optional[str] = None
    created_at: str
    items: List[TransactionItemDetail]


# --- CONTACT SCHEMAS ---

class ContactItem(BaseModel):
    """Schema for contact list item."""
    id: str
    name: str
    type: str  # "CUSTOMER" atau "SUPPLIER"
    phone: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None
    created_at: str


class ContactCreateInput(BaseModel):
    """Schema for creating a new contact."""
    name: str
    type: str  # "CUSTOMER" or "SUPPLIER"
    phone: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None


class ContactUpdateInput(BaseModel):
    """Schema for updating contact."""
    name: str
    phone: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None

class ContactStats(BaseModel):
    """Schema for contact transaction statistics."""
    count: int
    total_amount: float

class ContactSummary(BaseModel):
    """Schema for total customers and suppliers."""
    total_customers: int
    total_suppliers: int


class ProductHistoryItem(BaseModel):
    """Schema for product history/stock ledger item."""
    date: str
    type: str  # IN / OUT
    qty_change: float
    invoice_number: Optional[str] = None
    contact_name: Optional[str] = None
    price_at_moment: Optional[float] = None


class ProductListItem(BaseModel):
    """Schema for product list item."""
    id: str
    name: str
    sku: Optional[str] = None
    stock: float
    unit: str
    price: float
    initial: str
    category: Optional[str] = None
    variant: Optional[str] = None



class ProductDetailResponse(ProductListItem):
    """
    Schema for full product detail.
    Inherits from ProductListItem and adds more fields.
    """
    average_cost: float
    cost_per_pcs: Optional[float] = None
    needs_recalculation: bool = False
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class ProductCreateInput(BaseModel):
    name: str
    sku: Optional[str] = None
    base_unit: Optional[str] = "pcs"
    category: Optional[str] = None
    variant: Optional[str] = None
    latest_selling_price: Optional[float] = 0

class ProductStats(BaseModel):
    total: int
    low_stock: int
    out_of_stock: int


class ProductUpdateInput(BaseModel):
    """Schema for updating product."""
    name: str
    latest_selling_price: float
    current_stock: float
    average_cost: Optional[float] = None


class ProductStockAddInput(BaseModel):
    """Schema for adding stock to a product."""
    qty: float
    supplier_name: str
    supplier_phone: Optional[str] = None
    total_buy_price: float  # Total buy price is now required
