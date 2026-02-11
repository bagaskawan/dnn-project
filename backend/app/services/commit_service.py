import asyncpg
import re
import uuid
from typing import Optional, Dict, Any, List
from datetime import datetime, date

# --- HELPER FUNCTIONS ---

def extract_conversion_rate(variant: Optional[str]) -> float:
    if not variant:
        return 1.0
    match = re.search(r'(?:isi|x|@)\s*(\d+)', str(variant).lower())
    if match:
        return float(match.group(1))
    match = re.search(r'^(\d+)', str(variant))
    if match:
        return float(match.group(1))
    return 1.0

def calculate_new_average_cost(old_stock: float, old_avg_cost: float, new_qty: float, new_unit_price: float) -> float:
    total_qty = old_stock + new_qty
    if total_qty <= 0:
        return new_unit_price
    total_old_value = old_stock * old_avg_cost
    total_new_value = new_qty * new_unit_price
    return round((total_old_value + total_new_value) / total_qty, 2)

def generate_invoice_number() -> str:
    date_part = datetime.now().strftime("%Y%m%d")
    random_part = str(uuid.uuid4().int)[:5]
    return f"INV-{date_part}-{random_part}"

def parse_date(date_input) -> date:
    if isinstance(date_input, date): return date_input
    if isinstance(date_input, datetime): return date_input.date()
    if isinstance(date_input, str):
        for fmt in ["%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y", "%Y/%m/%d"]:
            try:
                return datetime.strptime(date_input, fmt).date()
            except ValueError:
                continue
    return datetime.now().date()

async def generate_sku(database, name: str, variant: Optional[str], unit: str, category: Optional[str] = None) -> str:
    """
    Generate SKU with format: [KATEGORI]-[MEREK]-[SATUAN]-[NUMBER]
    Example: FRZ-SING-BKS-001, FRZ-SING-BKS-002, etc.
    Checks database for existing SKUs and auto-increments to find unique number.
    """
    # Category mapping (3 letters)
    category_map = {
        "frozen": "FRZ", "beku": "FRZ",
        "snack": "SNK", "cemilan": "SNK", "kripik": "SNK",
        "beverage": "BEV", "minuman": "BEV",
        "fresh": "FSH", "segar": "FSH",
        "groceries": "GRC", "sembako": "GRC"
    }
    
    # Unit mapping (2-3 letters)
    unit_map = {
        "bungkus": "BKS", "pack": "PAK", "dus": "DUS", "box": "BOX",
        "pcs": "PCS", "pieces": "PCS", "buah": "PCS",
        "kg": "KG", "kilogram": "KG", "gram": "GRM", "liter": "LTR"
    }
    
    # Extract KATEGORI (3 letters)
    kategori = "GEN"  # Default
    if category:
        for key, code in category_map.items():
            if key in category.lower():
                kategori = code
                break
    else:
        # Try to infer from product name
        name_lower = name.lower()
        for key, code in category_map.items():
            if key in name_lower:
                kategori = code
                break
    
    # Extract MEREK (3-4 letters from product name)
    # Remove common words and take first word
    name_clean = re.sub(r'\b(original|pedas|manis|besar|kecil|level)\b', '', name, flags=re.IGNORECASE).strip()
    first_word = name_clean.split()[0] if name_clean.split() else name
    merek = first_word[:4].upper()  # Take first 3-4 characters
    
    # Extract SATUAN (2-3 letters)
    satuan = unit_map.get(unit.lower(), unit[:3].upper())
    
    # Base SKU without number
    base_sku = f"{kategori}-{merek}-{satuan}"
    
    # Query database for existing SKUs with same prefix
    query = "SELECT sku FROM products WHERE sku LIKE :pattern ORDER BY sku DESC LIMIT 1"
    existing = await database.fetch_one(query=query, values={"pattern": f"{base_sku}-%"})
    
    # Determine next number
    if existing:
        # Extract number from last SKU (e.g., "GEN-SING-BKS-003" -> 3)
        last_sku = existing["sku"]
        try:
            last_number = int(last_sku.split("-")[-1])
            next_number = last_number + 1
        except (ValueError, IndexError):
            next_number = 1
    else:
        next_number = 1
    
    # Format with 3-digit padding (001, 002, etc.)
    final_sku = f"{base_sku}-{next_number:03d}"
    
    return final_sku

# --- DATABASE OPERATIONS ---

async def upsert_contact(database, name: str, phone: Optional[str], address: Optional[str]) -> str:
    # Normalize phone number: ensure it starts with '0'
    if phone:
        phone = phone.strip().replace(" ", "").replace("-", "")
        # Remove +62 prefix
        if phone.startswith("+62"):
            phone = "0" + phone[3:]
        elif phone.startswith("62") and len(phone) > 10:
            phone = "0" + phone[2:]
        # If starts with 8 (missing leading 0)
        elif phone and phone[0] == '8':
            phone = '0' + phone
    
    query = "SELECT id FROM contacts WHERE LOWER(name) = LOWER(:name) AND type = 'SUPPLIER'"
    row = await database.fetch_one(query=query, values={"name": name})
    if row:
        return str(row["id"])
    
    new_id = str(uuid.uuid4())
    query = """
        INSERT INTO contacts (id, name, type, phone, address)
        VALUES (CAST(:id AS uuid), :name, 'SUPPLIER', :phone, :address)
    """
    await database.execute(query=query, values={"id": new_id, "name": name, "phone": phone, "address": address})
    return new_id

async def upsert_product(database, name: str, variant: Optional[str], unit: str, qty: float, unit_price: float) -> Dict[str, Any]:
    """
    Update/Insert produk dan mengembalikan data stok terupdate.
    """
    qty = float(qty or 0)
    unit_price = float(unit_price or 0)
    conversion_rate = extract_conversion_rate(variant)
    base_qty_change = qty * conversion_rate
    # Normalisasi harga ke per-base-unit (per pcs)
    # unit_price dari OCR = harga total untuk semua qty, bukan per-unit
    # Contoh: 17.000 total untuk 5 bungkus → 17.000/5 = 3.400/bungkus
    # Lalu dibagi conversion_rate untuk per-pcs
    # Contoh: 175.000/karton isi 36pcs → 175.000/1/36 = 4.861/pcs
    safe_qty = qty if qty > 0 else 1
    base_unit_price = unit_price / safe_qty / conversion_rate if conversion_rate > 0 else unit_price / safe_qty

    # Cek Existing
    if variant:
        query = "SELECT id, current_stock, average_cost FROM products WHERE LOWER(name) = LOWER(:name) AND LOWER(variant) = LOWER(:variant)"
        params = {"name": name, "variant": variant}
    else:
        query = "SELECT id, current_stock, average_cost FROM products WHERE LOWER(name) = LOWER(:name) AND (variant IS NULL OR variant = '')"
        params = {"name": name}
        
    product = await database.fetch_one(query=query, values=params)

    if product:
        product_id = str(product["id"])
        old_stock = float(product["current_stock"] or 0)
        old_avg = float(product["average_cost"] or 0)
        new_avg = calculate_new_average_cost(old_stock, old_avg, base_qty_change, base_unit_price)
        stock_after = old_stock + base_qty_change
        
        await database.execute(
            query="UPDATE products SET current_stock = :stock, average_cost = :avg, updated_at = NOW() WHERE id = CAST(:id AS uuid)",
            values={"stock": stock_after, "avg": new_avg, "id": product_id}
        )
    else:
        product_id = str(uuid.uuid4())
        stock_after = base_qty_change
        # Generate SKU for new product (with database check for uniqueness)
        sku = await generate_sku(database, name, variant, unit)
        await database.execute(
            query="""
            INSERT INTO products (id, sku, name, variant, base_unit, current_stock, average_cost, created_at, updated_at)
            VALUES (CAST(:id AS uuid), :sku, :name, :variant, :unit, :stock, :avg, NOW(), NOW())
            """,
            values={"id": product_id, "sku": sku, "name": name, "variant": variant, "unit": unit, "stock": stock_after, "avg": base_unit_price}
        )

    return {
        "product_id": product_id,
        "base_qty_change": float(base_qty_change), 
        "stock_after": float(stock_after),
        "conversion_rate": conversion_rate,
        "base_unit_price": round(float(base_unit_price), 2)
    }

async def create_transaction_header(database, contact_id, date_str, invoice, total, payment, source, evidence):
    trans_id = str(uuid.uuid4())
    invoice = invoice or generate_invoice_number()
    query = """
        INSERT INTO transactions (id, type, contact_id, transaction_date, invoice_number, total_amount, payment_method, input_source, evidence_url, created_at, updated_at)
        VALUES (CAST(:id AS uuid), 'IN', CAST(:contact_id AS uuid), :date, :invoice, :total, :payment, :source, :evidence, NOW(), NOW())
    """
    await database.execute(query=query, values={
        "id": trans_id, "contact_id": contact_id, "date": parse_date(date_str),
        "invoice": invoice, "total": float(total or 0), "payment": payment,
        "source": source, "evidence": evidence
    })
    return trans_id, invoice

async def create_transaction_item(database, trans_id, prod_id, qty, unit, price, conv_rate, subtotal, notes):
    # Hitung harga per-pcs untuk disimpan di cost_price_at_moment
    # price = harga total untuk semua qty, bukan per-unit
    safe_qty = float(qty or 1)
    safe_conv = float(conv_rate or 1)
    cost_per_unit = float(price or 0) / safe_qty / safe_conv if safe_qty > 0 and safe_conv > 0 else float(price or 0)
    
    query = """
        INSERT INTO transaction_items (id, transaction_id, product_id, input_qty, input_unit, input_price, conversion_rate, cost_price_at_moment, notes, created_at, updated_at)
        VALUES (CAST(:id AS uuid), CAST(:trans_id AS uuid), CAST(:prod_id AS uuid), :qty, :unit, :price, :conv, :cost_per_unit, :notes, NOW(), NOW())
    """
    await database.execute(query=query, values={
        "id": str(uuid.uuid4()), "trans_id": trans_id, "prod_id": prod_id,
        "qty": float(qty or 0), "unit": unit, "price": float(price or 0),
        "conv": safe_conv, "cost_per_unit": round(cost_per_unit, 2), "notes": notes
    })

async def record_stock_ledger(database, product_id, trans_id, qty_change, stock_after, notes):
    # SAFETY: Pastikan nilai float, bukan None
    qty_safe = float(qty_change) if qty_change is not None else 0.0
    stock_safe = float(stock_after) if stock_after is not None else 0.0
    
    query = """
        INSERT INTO stock_ledger (product_id, transaction_id, date, type, qty_change, stock_after, notes)
        VALUES (CAST(:prod_id AS uuid), CAST(:trans_id AS uuid), NOW(), 'IN', :qty, :stock, :notes)
    """
    await database.execute(query=query, values={
        "prod_id": product_id, "trans_id": trans_id,
        "qty": qty_safe, "stock": stock_safe, "notes": notes or "Pembelian"
    })

# --- MAIN SERVICE FUNCTION ---

async def commit_transaction_logic(database, data):
    async with database.transaction():
        # 1. Supplier
        contact_id = await upsert_contact(database, data.supplier_name, data.supplier_phone, data.supplier_address)
        
        # 2. Header
        trans_id, invoice_num = await create_transaction_header(
            database, contact_id, data.transaction_date, data.receipt_number, 
            data.total, data.payment_method, data.input_source, data.evidence_url
        )
        
        # 3. Items
        items_processed = 0
        for item in data.items:
            p_qty = float(item.qty or 0)
            if p_qty <= 0: continue

            # A. Upsert Product
            prod_result = await upsert_product(
                database, item.product_name, item.variant, item.unit, p_qty, float(item.unit_price or 0)
            )
            
            # B. Transaction Item
            await create_transaction_item(
                database, trans_id, prod_result["product_id"],
                p_qty, item.unit, float(item.unit_price or 0), prod_result["conversion_rate"], 
                float(item.total_price or 0), item.notes
            )
            
            # C. Stock Ledger - Gunakan key yang BENAR: 'base_qty_change'
            await record_stock_ledger(
                database, 
                prod_result["product_id"], 
                trans_id, 
                prod_result["base_qty_change"], # KEY DIPERBAIKI DISINI
                prod_result["stock_after"], 
                "Pembelian Masuk"
            )
            items_processed += 1
            
        return {
            "success": True,
            "transaction_id": trans_id,
            "invoice_number": invoice_num,
            "items_processed": items_processed,
            "message": "Transaksi berhasil disimpan!"
        }