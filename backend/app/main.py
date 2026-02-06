from contextlib import asynccontextmanager
import databases
import os
import json
import sys
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from app.schemas import ProcurementDraft, ChatInput, CommitTransactionInput, CommitTransactionResponse, TransactionListItem, TransactionDetailResponse, TransactionItemDetail, ContactItem, ContactCreateInput, ContactUpdateInput, ContactStats
from app.services.ai_service import parse_procurement_text, parse_procurement_image
from app.services.commit_service import commit_transaction_logic

# Load environment variables dari file .env
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("WARNING: DATABASE_URL not found in .env!")
else:
    print(f"[DB] Using DATABASE_URL (redacted): ...{DATABASE_URL[-30:]}")

# Create database with statement_cache_size=0 for pgbouncer compatibility
# The databases library passes these options directly to asyncpg
database = databases.Database(
    DATABASE_URL,
    min_size=1,
    max_size=5,
    statement_cache_size=0,  # Critical for pgbouncer
) if DATABASE_URL else None

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        await database.connect()
        print("✅ Database Connected Successfully!")
    except Exception as e:
        print(f"❌ Database Connection Failed: {e}")
    yield
    await database.disconnect()

app = FastAPI(
    title="DNN Project API",
    description="Backend API untuk DNN Project dengan integrasi Groq AI",
    version="1.0.0",
    lifespan=lifespan
)


# CORS Middleware - Agar Flutter bisa akses API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Ganti dengan domain spesifik di production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """Health check endpoint."""
    return {"message": "DNN Project API is running with RAG engine!", "status": "ok"}


@app.get("/health")
async def health_check():
    """Health check untuk monitoring."""
    return {"status": "healthy"}

@app.post("/api/v1/parse/text")
async def parse_text_endpoint(chat_data: ChatInput):
    print(f"[API_DEBUG] Received Text Input: {chat_data.new_message}")
    print(f"[API_DEBUG] Current Draft Context: {chat_data.current_draft}")
    known_products = []
    try:
        # Fetch products with variant for enhanced RAG
        query = "SELECT name, variant, base_unit, category, conversion_rules FROM products"
        rows = await database.fetch_all(query=query)
        known_products = [dict(row) for row in rows]
        for p in known_products:
            if isinstance(p.get('conversion_rules'), str):
                p['conversion_rules'] = json.loads(p['conversion_rules'])
                
    except Exception as e:
        print(f"⚠️ RAG Warning: Gagal ambil produk dari DB ({e}). AI akan jalan tanpa konteks produk.")
        known_products = []

    result = await parse_procurement_text(
        text_input=chat_data.new_message,
        current_draft=chat_data.current_draft,
        known_products=known_products
    )
    
    print(f"[API_DEBUG] Returning Result: {result}")
    
    return result

# --- ENDPOINT PRODUCT SEARCH (AUTOCOMPLETE) ---
@app.get("/api/v1/products/search")
async def search_products(q: str):
    """
    Search products by name for autocomplete.
    Now includes variant for Smart Separation Strategy.
    """
    try:
        query = """
            SELECT id, name, variant, base_unit, category 
            FROM products 
            WHERE name ILIKE :q OR variant ILIKE :q
            LIMIT 10
        """
        rows = await database.fetch_all(query=query, values={"q": f"%{q}%"})
        
        return [
            {
                "id": str(row["id"]),
                "name": row["name"], 
                "variant": row["variant"],
                "unit": row["base_unit"],
                "category": row["category"],
                # Display name for UI
                "display_name": f"{row['name']} ({row['variant']})" if row["variant"] else row["name"]
            } 
            for row in rows
        ]
    except Exception as e:
        print(f"Error Search Products: {e}")
        return []


# --- ENDPOINT RAG PRODUCT MATCHING ---
@app.get("/api/v1/products/match")
async def match_product(name: str, variant: str = None):
    """
    RAG endpoint to find similar products in database.
    Used for deduplication confirmation flow.
    
    Returns candidates with similarity info.
    """
    from fuzzywuzzy import fuzz
    
    try:
        # Get all products for matching
        query = "SELECT id, name, variant, base_unit, category FROM products"
        rows = await database.fetch_all(query=query)
        
        candidates = []
        search_term = f"{name} {variant}".strip() if variant else name
        
        for row in rows:
            db_name = row["name"]
            db_variant = row["variant"] or ""
            db_full = f"{db_name} {db_variant}".strip()
            
            # Calculate similarity scores
            name_similarity = fuzz.ratio(name.lower(), db_name.lower())
            full_similarity = fuzz.ratio(search_term.lower(), db_full.lower())
            partial_similarity = fuzz.partial_ratio(search_term.lower(), db_full.lower())
            
            # Take best score
            best_score = max(name_similarity, full_similarity, partial_similarity)
            
            # Only include if similarity > 50%
            if best_score >= 50:
                candidates.append({
                    "id": str(row["id"]),
                    "name": db_name,
                    "variant": row["variant"],
                    "unit": row["base_unit"],
                    "category": row["category"],
                    "display_name": f"{db_name} ({row['variant']})" if row["variant"] else db_name,
                    "similarity": best_score,
                    "match_type": "exact" if best_score >= 90 else "similar" if best_score >= 70 else "possible"
                })
        
        # Sort by similarity descending
        candidates.sort(key=lambda x: x["similarity"], reverse=True)
        
        return {
            "query": {"name": name, "variant": variant},
            "candidates": candidates[:5],  # Top 5 matches
            "has_exact_match": any(c["match_type"] == "exact" for c in candidates),
            "needs_confirmation": len(candidates) > 0 and not any(c["similarity"] == 100 for c in candidates)
        }
        
    except Exception as e:
        print(f"Error Match Product: {e}")
        return {"query": {"name": name, "variant": variant}, "candidates": [], "has_exact_match": False, "needs_confirmation": False}

# --- ENDPOINT IMAGE UPLOAD ---
@app.post("/api/v1/parse/image")
async def parse_image_endpoint(file: UploadFile = File(...), current_draft_str: str = None):
    # Note: current_draft dikirim sebagai string JSON jika lewat Form Data (Multipart)
    current_draft = None
    if current_draft_str:
        try:
            current_draft = json.loads(current_draft_str)
        except:
            pass

    # A. Ambil Context Produk (Sama seperti Text)
    known_products = []
    try:
        query = "SELECT name, base_unit, conversion_rules FROM products"
        rows = await database.fetch_all(query=query)
        known_products = [dict(row) for row in rows]
    except Exception:
        pass

    # B. Baca File Gambar
    image_bytes = await file.read()
    
    # C. Panggil AI Service
    result = await parse_procurement_image(
        image_bytes=image_bytes,
        current_draft=current_draft,
        known_products=known_products
    )
    
    return result


# --- ENDPOINT COMMIT TRANSACTION ---
@app.post("/api/v1/transactions/commit", response_model=CommitTransactionResponse)
async def commit_transaction_endpoint(data: CommitTransactionInput):
    """
    Commit a procurement transaction to the database.
    This saves data to: contacts, transactions, products, transaction_items, stock_ledger.
    """
    print(f"[COMMIT API] Received commit request for supplier: {data.supplier_name}")
    print(f"[COMMIT API] Items count: {len(data.items)}")
    sys.stdout.flush()
    
    # Convert Pydantic items to dict for the service
    items_dict = [item.dict() for item in data.items]
    
    try:
        result = await commit_transaction_logic(database, data)
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"[COMMIT ERROR] {e}")
        sys.stdout.flush()
        return CommitTransactionResponse(
            success=False,
            message=f"Gagal menyimpan transaksi: {str(e)}"
        )
    
    print(f"[COMMIT API] Result: {result}")
    sys.stdout.flush()
    
    return CommitTransactionResponse(**result)


# --- ENDPOINT GET TRANSACTIONS LIST ---
@app.get("/api/v1/transactions", response_model=list[TransactionListItem])
async def get_transactions(limit: int = 20, offset: int = 0, contact_id: str = None):
    """
    Get list of transactions for home page.
    Returns transactions with contact info, ordered by date DESC.
    Optionally filter by contact_id.
    """
    try:
        base_query = """
            SELECT 
                t.id, t.type, t.transaction_date, t.total_amount, 
                t.invoice_number, t.payment_method, t.created_at,
                c.name as contact_name, c.phone as contact_phone, c.address as contact_address
            FROM transactions t
            LEFT JOIN contacts c ON t.contact_id = c.id
        """
        
        conditions = []
        values = {"limit": limit, "offset": offset}
        
        if contact_id:
            conditions.append("t.contact_id = CAST(:contact_id AS uuid)")
            values["contact_id"] = contact_id
            
        where_clause = " WHERE " + " AND ".join(conditions) if conditions else ""
        
        query = f"{base_query}{where_clause} ORDER BY t.transaction_date DESC, t.created_at DESC LIMIT :limit OFFSET :offset"
        
        rows = await database.fetch_all(query=query, values=values)
        
        return [
            TransactionListItem(
                id=str(row["id"]),
                type=row["type"] or "IN",
                transaction_date=str(row["transaction_date"]),
                total_amount=float(row["total_amount"] or 0),
                invoice_number=row["invoice_number"],
                payment_method=row["payment_method"],
                contact_name=row["contact_name"] or "Unknown",
                contact_phone=row["contact_phone"],
                contact_address=row["contact_address"],
                created_at=str(row["created_at"])
            )
            for row in rows
        ]
    except Exception as e:
        print(f"[GET TRANSACTIONS] Error: {e}")
        import traceback
        traceback.print_exc()
        return []


# --- ENDPOINT GET TRANSACTION DETAIL ---
@app.get("/api/v1/transactions/{transaction_id}", response_model=TransactionDetailResponse)
async def get_transaction_detail(transaction_id: str):
    """
    Get full transaction detail including items.
    Used for transaction detail page.
    """
    try:
        # 1. Fetch transaction header with contact
        header_query = """
            SELECT 
                t.id, t.type, t.transaction_date, t.total_amount, 
                t.invoice_number, t.payment_method, t.created_at,
                c.name as contact_name, c.phone as contact_phone, c.address as contact_address
            FROM transactions t
            LEFT JOIN contacts c ON t.contact_id = c.id
            WHERE t.id = CAST(:id AS uuid)
        """
        header = await database.fetch_one(query=header_query, values={"id": transaction_id})
        
        if not header:
            raise HTTPException(status_code=404, detail="Transaction not found")
        
        # 2. Fetch transaction items with product info
        items_query = """
            SELECT 
                ti.id, ti.input_qty, ti.input_unit, ti.input_price, ti.subtotal, ti.notes,
                p.name as product_name, p.variant
            FROM transaction_items ti
            LEFT JOIN products p ON ti.product_id = p.id
            WHERE ti.transaction_id = CAST(:trans_id AS uuid)
        """
        items_rows = await database.fetch_all(query=items_query, values={"trans_id": transaction_id})
        
        items = [
            TransactionItemDetail(
                id=str(row["id"]),
                product_name=row["product_name"] or "Unknown Product",
                variant=row["variant"],
                qty=float(row["input_qty"] or 0),
                unit=row["input_unit"] or "pcs",
                unit_price=float(row["input_price"] or 0),
                subtotal=float(row["subtotal"] or 0),
                notes=row["notes"]
            )
            for row in items_rows
        ]
        
        return TransactionDetailResponse(
            id=str(header["id"]),
            type=header["type"] or "IN",
            transaction_date=str(header["transaction_date"]),
            total_amount=float(header["total_amount"] or 0),
            invoice_number=header["invoice_number"],
            payment_method=header["payment_method"],
            contact_name=header["contact_name"] or "Unknown",
            contact_phone=header["contact_phone"],
            contact_address=header["contact_address"],
            created_at=str(header["created_at"]),
            items=items
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"[GET TRANSACTION DETAIL] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# --- ENDPOINT GET CONTACTS LIST ---
@app.get("/api/v1/contacts", response_model=list[ContactItem])
async def get_contacts(type: str = None, limit: int = 50, offset: int = 0):
    """
    Get list of contacts with optional type filter.
    type: "CUSTOMER", "SUPPLIER", or None for all
    """
    try:
        if type:
            query = """
                SELECT id, name, type, phone, address, notes, created_at
                FROM contacts
                WHERE type = :type
                ORDER BY name ASC
                LIMIT :limit OFFSET :offset
            """
            rows = await database.fetch_all(query=query, values={"type": type.upper(), "limit": limit, "offset": offset})
        else:
            query = """
                SELECT id, name, type, phone, address, notes, created_at
                FROM contacts
                ORDER BY name ASC
                LIMIT :limit OFFSET :offset
            """
            rows = await database.fetch_all(query=query, values={"limit": limit, "offset": offset})
        
        return [
            ContactItem(
                id=str(row["id"]),
                name=row["name"] or "Unknown",
                type=row["type"] or "CUSTOMER",
                phone=row["phone"],
                address=row["address"],
                notes=row["notes"],
                created_at=str(row["created_at"]) if row["created_at"] else ""
            )
            for row in rows
        ]
    except Exception as e:
        print(f"[GET CONTACTS] Error: {e}")
        import traceback
        traceback.print_exc()
        return []


# --- ENDPOINT CREATE CONTACT ---
@app.post("/api/v1/contacts", response_model=ContactItem)
async def create_contact(data: ContactCreateInput):
    """
    Create a new contact.
    """
    try:
        query = """
            INSERT INTO contacts (name, type, phone, address, notes)
            VALUES (:name, :type, :phone, :address, :notes)
            RETURNING id, name, type, phone, address, notes, created_at
        """
        values = {
            "name": data.name,
            "type": data.type,
            "phone": data.phone,
            "address": data.address,
            "notes": data.notes
        }
        
        row = await database.fetch_one(query=query, values=values)
        
        return ContactItem(
            id=str(row["id"]),
            name=row["name"],
            type=row["type"],
            phone=row["phone"],
            address=row["address"],
            notes=row["notes"],
            created_at=str(row["created_at"])
        )
    except Exception as e:
        print(f"[CREATE CONTACT] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# --- ENDPOINT UPDATE CONTACT ---
@app.put("/api/v1/contacts/{contact_id}", response_model=ContactItem)
async def update_contact(contact_id: str, data: ContactUpdateInput):
    """
    Update contact details.
    """
    try:
        # Check if contact exists
        check_query = "SELECT id FROM contacts WHERE id = CAST(:id AS uuid)"
        existing = await database.fetch_one(query=check_query, values={"id": contact_id})
        if not existing:
             raise HTTPException(status_code=404, detail="Contact not found")

        query = """
            UPDATE contacts
            SET name = :name,
                phone = :phone,
                address = :address,
                notes = :notes
            WHERE id = CAST(:id AS uuid)
            RETURNING id, name, type, phone, address, notes, created_at
        """
        values = {
            "id": contact_id,
            "name": data.name,
            "phone": data.phone,
            "address": data.address,
            "notes": data.notes
        }
        
        row = await database.fetch_one(query=query, values=values)
        
        return ContactItem(
            id=str(row["id"]),
            name=row["name"],
            type=row["type"],
            phone=row["phone"],
            address=row["address"],
            notes=row["notes"],
            created_at=str(row["created_at"])
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"[UPDATE CONTACT] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# --- ENDPOINT GET CONTACT STATS ---
@app.get("/api/v1/contacts/{contact_id}/stats", response_model=ContactStats)
async def get_contact_stats(contact_id: str):
    """
    Get transaction statistics for a contact.
    """
    try:
        query = """
            SELECT 
                COUNT(*) as count,
                COALESCE(SUM(total_amount), 0) as total_amount
            FROM transactions
            WHERE contact_id = CAST(:contact_id AS uuid)
        """
        row = await database.fetch_one(query=query, values={"contact_id": contact_id})
        
        return ContactStats(
            count=row["count"],
            total_amount=float(row["total_amount"])
        )
    except Exception as e:
        print(f"[GET CONTACT STATS] Error: {e}")
        return ContactStats(count=0, total_amount=0)