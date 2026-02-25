from contextlib import asynccontextmanager
import databases
import os
import io
import json
import uuid
import sys
import uuid
from app.services.commit_service import commit_transaction_logic, generate_invoice_number
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from app.schemas import ProcurementDraft, ChatInput, CommitTransactionInput, CommitTransactionResponse, TransactionListItem, TransactionDetailResponse, TransactionItemDetail, ContactItem, ContactCreateInput, ContactUpdateInput, ContactStats, ProductHistoryItem, ProductListItem, ProductDetailResponse, ProductUpdateInput, ProductStockAddInput, SaleDraft, CommitSaleInput
from typing import List, Optional
from app.services.ai_service import parse_procurement_text, parse_procurement_image, parse_sale_text
from app.services.commit_service import commit_transaction_logic, commit_sale_logic, generate_invoice_number

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
    known_suppliers = []
    try:
        # Fetch products with variant for enhanced RAG
        query = "SELECT name, variant, base_unit, category, conversion_rules FROM products"
        rows = await database.fetch_all(query=query)
        known_products = [dict(row) for row in rows]
        for p in known_products:
            if isinstance(p.get('conversion_rules'), str):
                p['conversion_rules'] = json.loads(p['conversion_rules'])
        
        # Fetch suppliers for deduplication
        supplier_query = "SELECT name, phone FROM contacts WHERE type = 'SUPPLIER'"
        supplier_rows = await database.fetch_all(query=supplier_query)
        known_suppliers = [dict(row) for row in supplier_rows]
                
    except Exception as e:
        print(f"⚠️ RAG Warning: Gagal ambil data dari DB ({e}). AI akan jalan tanpa konteks.")
        known_products = []
        known_suppliers = []

    result = await parse_procurement_text(
        text_input=chat_data.new_message,
        current_draft=chat_data.current_draft,
        known_products=known_products,
        known_suppliers=known_suppliers
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
    return result

# --- ENDPOINT PARSE SALE TEXT ---
@app.post("/api/v1/parse/sale")
async def parse_sale_endpoint(chat_data: ChatInput):
    """
    Endpoint for parsing SALE chat.
    """
    print(f"[API_SALE] Received Input: {chat_data.new_message}")
    
    known_products = []
    try:
        query = "SELECT name, variant, base_unit, category, latest_selling_price FROM products"
        rows = await database.fetch_all(query=query)
        known_products = [dict(row) for row in rows]
    except Exception as e:
        print(f"⚠️ DB Error: {e}")

    result = await parse_sale_text(
        text_input=chat_data.new_message,
        current_draft=chat_data.current_draft,
        known_products=known_products
    )
    return result


# --- ENDPOINT PARSE IMAGE (PROCUREMENT) ---
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


    return CommitTransactionResponse(**result)


# --- ENDPOINT COMMIT SALE ---
@app.post("/api/v1/sales/commit")
async def commit_sale_endpoint(data: CommitSaleInput):
    print(f"[COMMIT SALE] Customer: {data.customer_name}, Items: {len(data.items)}")
    try:
        result = await commit_sale_logic(database, data)
        return result
    except Exception as e:
        print(f"[COMMIT SALE ERROR] {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


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


# --- ENDPOINT GET PRODUCT HISTORY ---
@app.get("/api/v1/products/{product_id}/history", response_model=List[ProductHistoryItem])
async def get_product_history(product_id: str):
    """
    Get stock history for a product.
    Joins stock_ledger with transactions and contacts.
    """
    try:
        query = """
            SELECT 
                sl.date,
                sl.type,
                sl.qty_change,
                t.invoice_number,
                c.name as contact_name,
                ti.cost_price_at_moment as price_at_moment
            FROM stock_ledger sl
            LEFT JOIN transactions t ON sl.transaction_id = t.id
            LEFT JOIN contacts c ON t.contact_id = c.id
            LEFT JOIN transaction_items ti ON ti.transaction_id = t.id AND ti.product_id = sl.product_id
            WHERE sl.product_id = CAST(:product_id AS uuid)
            ORDER BY sl.date DESC
        """
        rows = await database.fetch_all(query=query, values={"product_id": product_id})
        
        return [
            ProductHistoryItem(
                date=str(row["date"]),
                type=row["type"],
                qty_change=float(row["qty_change"]),
                invoice_number=row["invoice_number"],
                contact_name=row["contact_name"],
                price_at_moment=float(row["price_at_moment"]) if row["price_at_moment"] is not None else None
            )
            for row in rows
        ]
    except Exception as e:
        print(f"[GET PRODUCT HISTORY] Error: {e}")
        import traceback
        traceback.print_exc()
        return []


# --- ENDPOINT GET PRODUCTS LIST ---
@app.get("/api/v1/products", response_model=List[ProductListItem])
async def get_products(status: str = "all"):
    """
    Get list of products with optional status filter.
    status: 'low_stock' (1-5), 'out_of_stock' (0), 'all' (default)
    """
    try:
        base_query = """
            SELECT id, name, sku, current_stock, base_unit, latest_selling_price, variant, category 
            FROM products
        """
        
        conditions = []
        
        if status == "low_stock":
            conditions.append("current_stock > 0 AND current_stock <= 5")
        elif status == "out_of_stock":
            conditions.append("current_stock <= 0")
            
        where_clause = " WHERE " + " AND ".join(conditions) if conditions else ""
        
        # Order by name ASC
        query = f"{base_query}{where_clause} ORDER BY name ASC"
        
        rows = await database.fetch_all(query=query)
        
        return [
            ProductListItem(
                id=str(row["id"]),
                name=row["name"],
                sku=row["sku"],
                stock=float(row["current_stock"] or 0),
                unit=row["base_unit"],
                price=float(row["latest_selling_price"] or 0),
                initial=row["name"][:2].upper() if len(row["name"]) >= 2 else row["name"][:1].upper(),
                category=row["category"],
                variant=row["variant"]
            )
            for row in rows
        ]
    except Exception as e:
        print(f"[GET PRODUCTS] Error: {e}")
        import traceback
        traceback.print_exc()
        return []

# --- ENDPOINT GET PRODUCT DETAIL ---
@app.get("/api/v1/products/{product_id}", response_model=ProductDetailResponse)
async def get_product_detail(product_id: str):
    """
    Get full product details including average cost.
    Includes needs_recalculation flag for stale pricing data.
    """
    try:
        query = """
            SELECT id, name, sku, current_stock, base_unit, latest_selling_price, variant, category, average_cost, created_at, updated_at
            FROM products
            WHERE id = CAST(:product_id AS uuid)
        """
        row = await database.fetch_one(query=query, values={"product_id": product_id})
        
        if not row:
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Check if any transaction_items have cost_price_at_moment=0 with conversion_rate>1
        # This indicates old data that wasn't normalized
        stale_query = """
            SELECT COUNT(*) as stale_count
            FROM transaction_items
            WHERE product_id = CAST(:pid AS uuid)
              AND (cost_price_at_moment IS NULL OR cost_price_at_moment = 0)
              AND conversion_rate > 1
        """
        stale_row = await database.fetch_one(query=stale_query, values={"pid": product_id})
        needs_recalc = (stale_row["stale_count"] or 0) > 0 if stale_row else False
        
        avg_cost = float(row["average_cost"] or 0)
        
        return ProductDetailResponse(
            id=str(row["id"]),
            name=row["name"],
            sku=row["sku"],
            stock=float(row["current_stock"] or 0),
            unit=row["base_unit"],
            price=float(row["latest_selling_price"] or 0),
            initial=row["name"][:2].upper() if len(row["name"]) >= 2 else row["name"][:1].upper(),
            category=row["category"],
            variant=row["variant"],
            average_cost=avg_cost,
            cost_per_pcs=round(avg_cost, 2) if avg_cost > 0 else None,
            needs_recalculation=needs_recalc,
            created_at=str(row["created_at"]) if row["created_at"] else None,
            updated_at=str(row["updated_at"]) if row["updated_at"] else None
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"[GET PRODUCT DETAIL] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# --- ENDPOINT UPDATE PRODUCT ---
@app.put("/api/v1/products/{product_id}", response_model=ProductDetailResponse)
async def update_product(product_id: str, data: ProductUpdateInput):
    """
    Update product details (name, selling price, stock).
    """
    try:
        # Check if product exists
        check_query = "SELECT id FROM products WHERE id = CAST(:id AS uuid)"
        existing = await database.fetch_one(query=check_query, values={"id": product_id})
        if not existing:
            raise HTTPException(status_code=404, detail="Product not found")

        query = """
            UPDATE products
            SET name = :name,
                latest_selling_price = :latest_selling_price,
                current_stock = :current_stock,
                updated_at = NOW()
            WHERE id = CAST(:id AS uuid)
            RETURNING id, name, sku, current_stock, base_unit, latest_selling_price, variant, category, average_cost, created_at, updated_at
        """
        values = {
            "id": product_id,
            "name": data.name,
            "latest_selling_price": data.latest_selling_price,
            "current_stock": data.current_stock
        }

        if data.average_cost is not None:
            query = """
                UPDATE products
                SET name = :name,
                    latest_selling_price = :latest_selling_price,
                    current_stock = :current_stock,
                    average_cost = :average_cost,
                    updated_at = NOW()
                WHERE id = CAST(:id AS uuid)
                RETURNING id, name, sku, current_stock, base_unit, latest_selling_price, variant, category, average_cost, created_at, updated_at
            """
            values["average_cost"] = data.average_cost
        
        row = await database.fetch_one(query=query, values=values)
        
        return ProductDetailResponse(
            id=str(row["id"]),
            name=row["name"],
            sku=row["sku"],
            stock=float(row["current_stock"] or 0),
            unit=row["base_unit"],
            price=float(row["latest_selling_price"] or 0),
            initial=row["name"][:2].upper() if len(row["name"]) >= 2 else row["name"][:1].upper(),
            category=row["category"],
            variant=row["variant"],
            average_cost=float(row["average_cost"] or 0),
            cost_per_pcs=round(float(row["average_cost"] or 0), 2) if float(row["average_cost"] or 0) > 0 else None,
            created_at=str(row["created_at"]) if row["created_at"] else None,
            updated_at=str(row["updated_at"]) if row["updated_at"] else None
        )
    except HTTPException:
        raise
    except Exception as e:
        print(f"[UPDATE PRODUCT] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# --- ENDPOINT ADD STOCK ---
@app.post("/api/v1/products/{product_id}/stock")
async def add_product_stock(product_id: str, data: ProductStockAddInput):
    """
    Add stock to a product with supplier details.
    Creates an 'IN' transaction and updates stock/average_cost.
    """
    try:
        # Check product exists
        check_query = "SELECT id, name, current_stock, average_cost, base_unit FROM products WHERE id = CAST(:id AS uuid)"
        product = await database.fetch_one(query=check_query, values={"id": product_id})
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")

        async with database.transaction():
            # 1. Find or Create Supplier Contact
            supplier_id = None
            if data.supplier_name:
                # Check existing
                find_supplier = "SELECT id FROM contacts WHERE LOWER(name) = :name AND type = 'SUPPLIER'"
                supplier = await database.fetch_one(query=find_supplier, values={"name": data.supplier_name.lower().strip()})
                
                if supplier:
                    supplier_id = str(supplier["id"])
                    # Optional: Update phone if provided and not set? 
                    # For simplicity, we just use existing ID.
                else:
                    # Create new supplier
                    new_supplier_id = str(uuid.uuid4())
                    insert_supplier = """
                        INSERT INTO contacts (id, name, type, phone, created_at, updated_at)
                        VALUES (CAST(:id AS uuid), :name, 'SUPPLIER', :phone, NOW(), NOW())
                        RETURNING id
                    """
                    await database.execute(query=insert_supplier, values={
                        "id": new_supplier_id,
                        "name": data.supplier_name.strip(),
                        "phone": data.supplier_phone
                    })
                    supplier_id = new_supplier_id

            # 2. Create Transaction (IN)
            transaction_id = str(uuid.uuid4())
            invoice_number = generate_invoice_number()
            
            # Calculate total amount
            # total_buy_price is mandatory now
            total_amount = data.total_buy_price
            unit_price = total_amount / data.qty if data.qty > 0 else 0
            
            insert_transaction = """
                INSERT INTO transactions (id, type, transaction_date, total_amount, invoice_number, contact_id, created_at, updated_at)
                VALUES (CAST(:id AS uuid), 'IN', NOW(), :total, :inv, CAST(:cid AS uuid), NOW(), NOW())
            """
            await database.execute(query=insert_transaction, values={
                "id": transaction_id,
                "total": total_amount,
                "inv": invoice_number,
                "cid": supplier_id
            })

            # 3. Create Transaction Item
            item_id = str(uuid.uuid4())
            # For direct stock add, conversion rate is 1 (base unit)
            # input_price in transaction_items is UNIT PRICE because subtotal is generated (qty * price)
            insert_item = """
                INSERT INTO transaction_items (id, transaction_id, product_id, input_qty, input_unit, conversion_rate, input_price, cost_price_at_moment)
                VALUES (CAST(:id AS uuid), CAST(:tid AS uuid), CAST(:pid AS uuid), :qty, :unit, 1.0, :unit_price, :cost_at_moment)
            """
            await database.execute(query=insert_item, values={
                "id": item_id,
                "tid": transaction_id,
                "pid": product_id,
                "qty": data.qty,
                "unit": product["base_unit"],
                "unit_price": unit_price,
                "cost_at_moment": unit_price,
            })

            # 4. Update Product Stock & Average Cost
            new_stock = float(product["current_stock"] or 0) + data.qty
            
            # Calculate new average cost
            old_stock = float(product["current_stock"] or 0)
            old_avg = float(product["average_cost"] or 0)
            
            new_avg = old_avg # Default
            if new_stock > 0:
                total_old_val = old_stock * old_avg
                total_new_val = total_amount # (qty * unit_price)
                # If old stock < 0, handle gracefully? 
                # If old_stock < 0, we treat it as 0 value for avg cost calc? 
                # Basic weighted average:
                effective_old_stock = max(0, old_stock)
                new_avg = ( (effective_old_stock * old_avg) + total_new_val ) / (effective_old_stock + data.qty)
            
            update_product_query = """
                UPDATE products
                SET current_stock = :stock,
                    average_cost = :avg,
                    updated_at = NOW()
                WHERE id = CAST(:id AS uuid)
            """
            await database.execute(query=update_product_query, values={
                "stock": new_stock,
                "avg": round(new_avg, 2),
                "id": product_id
            })

            # 5. Insert into Stock Ledger
            insert_ledger = """
                INSERT INTO stock_ledger (product_id, transaction_id, date, type, qty_change, stock_after, notes)
                VALUES (CAST(:pid AS uuid), CAST(:tid AS uuid), NOW(), 'IN', :qty, :stock_after, 'Restock via App')
            """
            await database.execute(query=insert_ledger, values={
                "pid": product_id,
                "tid": transaction_id,
                "qty": data.qty,
                "stock_after": new_stock
            })

        return {"success": True, "message": "Stok berhasil ditambahkan", "new_stock": new_stock, "new_avg_cost": round(new_avg, 2)}

    except HTTPException:
        raise
    except Exception as e:
        print(f"[ADD STOCK] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# --- ENDPOINT RECALCULATE PRODUCT AVERAGE COST ---
@app.post("/api/v1/products/{product_id}/recalculate")
async def recalculate_product_cost(product_id: str):
    """
    Recalculate average_cost from all transaction_items for this product.
    Also updates cost_price_at_moment for old items that have it as 0.
    """
    try:
        # Check product exists
        check_query = "SELECT id, current_stock FROM products WHERE id = CAST(:id AS uuid)"
        product = await database.fetch_one(query=check_query, values={"id": product_id})
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Get all IN transaction items for this product
        items_query = """
            SELECT ti.id, ti.input_qty, ti.input_price, ti.conversion_rate, ti.cost_price_at_moment
            FROM transaction_items ti
            JOIN transactions t ON ti.transaction_id = t.id
            WHERE ti.product_id = CAST(:pid AS uuid)
              AND t.type = 'IN'
            ORDER BY t.transaction_date ASC
        """
        items = await database.fetch_all(query=items_query, values={"pid": product_id})
        
        if not items:
            return {"success": True, "message": "Tidak ada riwayat transaksi", "new_average_cost": 0}
        
        # Recalculate weighted average cost per base unit
        total_cost_value = 0.0
        total_base_qty = 0.0
        
        for item in items:
            qty = float(item["input_qty"] or 0)
            price = float(item["input_price"] or 0)
            conv_rate = float(item["conversion_rate"] or 1)
            
            safe_qty = qty if qty > 0 else 1
            base_qty = qty * conv_rate
            # price = harga total untuk semua qty, bukan per-unit
            cost_per_pcs = price / safe_qty / conv_rate if conv_rate > 0 else price / safe_qty
            
            total_base_qty += base_qty
            total_cost_value += base_qty * cost_per_pcs
            
            # Update cost_price_at_moment if it was 0 (old data)
            old_cost = float(item["cost_price_at_moment"] or 0)
            if old_cost == 0 and conv_rate > 0:
                await database.execute(
                    query="UPDATE transaction_items SET cost_price_at_moment = :cost WHERE id = CAST(:id AS uuid)",
                    values={"cost": round(cost_per_pcs, 2), "id": str(item["id"])}
                )
        
        new_avg = round(total_cost_value / total_base_qty, 2) if total_base_qty > 0 else 0
        
        # Update product average_cost
        await database.execute(
            query="UPDATE products SET average_cost = :avg, updated_at = NOW() WHERE id = CAST(:id AS uuid)",
            values={"avg": new_avg, "id": product_id}
        )
        
        print(f"[RECALCULATE] Product {product_id}: new average_cost = {new_avg}")
        
        return {
            "success": True, 
            "new_average_cost": new_avg,
            "items_updated": len(items),
            "message": f"Harga modal berhasil diperbarui: Rp {new_avg:,.0f}/pcs"
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"[RECALCULATE] Error: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
