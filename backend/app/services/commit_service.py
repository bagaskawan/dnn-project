"""
Commit Transaction Service
Handles the database operations for committing procurement drafts.
"""
import re
import uuid
from typing import Optional, Dict, Any, List
from datetime import datetime, date


def extract_conversion_rate(variant: Optional[str]) -> int:
    """
    Extract numeric value from variant string for conversion rate.
    Examples:
        "Isi 36" -> 36
        "1kg" -> 1
        "Besar" -> 1 (no number found)
        "Level 5 Pedas" -> 5
    """
    if not variant:
        return 1
    
    # Find all numbers in the variant
    numbers = re.findall(r'\d+', variant)
    
    if numbers:
        # Return the first number found
        return int(numbers[0])
    
    return 1


def calculate_new_average_cost(
    old_stock: float,
    old_avg_cost: float,
    new_qty: float,
    new_unit_price: float
) -> float:
    """
    Calculate new weighted average cost (HPP) after adding new stock.
    Formula: ((old_stock * old_avg) + (new_qty * new_price)) / (old_stock + new_qty)
    """
    if old_stock + new_qty == 0:
        return new_unit_price
    
    total_old_value = old_stock * old_avg_cost
    total_new_value = new_qty * new_unit_price
    new_avg = (total_old_value + total_new_value) / (old_stock + new_qty)
    
    return round(new_avg, 2)


def generate_invoice_number() -> str:
    """
    Generate unique invoice number with format: INV-YYYYMMDD-XXXXX
    where XXXXX is a random 5-digit number.
    """
    date_part = datetime.now().strftime("%Y%m%d")
    random_part = str(uuid.uuid4().int)[:5]
    return f"INV-{date_part}-{random_part}"


def parse_date(date_input) -> date:
    """
    Parse various date formats to datetime.date object.
    Accepts: date object, datetime object, or string (YYYY-MM-DD format).
    """
    if isinstance(date_input, date):
        return date_input
    if isinstance(date_input, datetime):
        return date_input.date()
    if isinstance(date_input, str):
        # Try common formats
        for fmt in ["%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y", "%Y/%m/%d"]:
            try:
                return datetime.strptime(date_input, fmt).date()
            except ValueError:
                continue
        # Fallback: try to parse as ISO format
        try:
            return datetime.fromisoformat(date_input).date()
        except:
            pass
    # If all else fails, return today's date
    return datetime.now().date()


async def upsert_contact(
    database,
    name: str,
    phone: Optional[str] = None,
    address: Optional[str] = None,
    contact_type: str = "SUPPLIER"
) -> str:
    """
    Check if contact exists by name, insert if not, return contact ID.
    """
    # Check if contact exists
    query = "SELECT id FROM contacts WHERE LOWER(name) = LOWER(:name) AND type = :type"
    result = await database.fetch_one(query=query, values={"name": name, "type": contact_type})
    
    if result:
        contact_id = str(result["id"])
        
        # Update phone/address if provided and different
        if phone or address:
            update_parts = []
            values = {"contact_id": contact_id}
            
            if phone:
                update_parts.append("phone = :phone")
                values["phone"] = phone
            if address:
                update_parts.append("address = :address")
                values["address"] = address
            
            if update_parts:
                update_query = f"UPDATE contacts SET {', '.join(update_parts)} WHERE id = CAST(:contact_id AS uuid)"
                await database.execute(query=update_query, values=values)
        
        return contact_id
    
    # Insert new contact
    new_id = str(uuid.uuid4())
    insert_query = """
        INSERT INTO contacts (id, name, type, phone, address)
        VALUES (CAST(:new_id AS uuid), :name, :type, :phone, :address)
        RETURNING id
    """
    await database.execute(
        query=insert_query,
        values={
            "new_id": new_id,
            "name": name,
            "type": contact_type,
            "phone": phone,
            "address": address
        }
    )
    
    return new_id


async def upsert_product(
    database,
    name: str,
    variant: Optional[str],
    unit: str,
    qty: float,
    unit_price: float
) -> Dict[str, Any]:
    """
    Check if product exists by name+variant, insert if not.
    Update stock and average cost.
    Returns dict with product_id, conversion_rate, base_qty, stock_after.
    """
    # Calculate conversion rate from variant
    conversion_rate = extract_conversion_rate(variant)
    base_qty = qty * conversion_rate
    
    # Check if product exists
    if variant:
        query = """
            SELECT id, current_stock, average_cost 
            FROM products 
            WHERE LOWER(name) = LOWER(:name) AND LOWER(variant) = LOWER(:variant)
        """
        result = await database.fetch_one(query=query, values={"name": name, "variant": variant})
    else:
        query = """
            SELECT id, current_stock, average_cost 
            FROM products 
            WHERE LOWER(name) = LOWER(:name) AND (variant IS NULL OR variant = '')
        """
        result = await database.fetch_one(query=query, values={"name": name})
    
    if result:
        product_id = str(result["id"])
        old_stock = float(result["current_stock"] or 0)
        old_avg_cost = float(result["average_cost"] or 0)
        
        # Calculate new average cost
        new_avg_cost = calculate_new_average_cost(old_stock, old_avg_cost, base_qty, unit_price)
        new_stock = old_stock + base_qty
        
        # Update product stock and average cost
        update_query = """
            UPDATE products 
            SET current_stock = :stock, average_cost = :avg_cost
            WHERE id = CAST(:product_id AS uuid)
        """
        await database.execute(
            query=update_query,
            values={
                "product_id": product_id,
                "stock": new_stock,
                "avg_cost": new_avg_cost
            }
        )
        
        print(f"[UPSERT] Updated existing product: id={product_id}, base_qty={base_qty}, stock_after={new_stock}")
        return {
            "product_id": product_id,
            "conversion_rate": conversion_rate,
            "base_qty": base_qty,
            "stock_after": new_stock,
            "is_new": False
        }
    
    # Insert new product
    new_id = str(uuid.uuid4())
    insert_query = """
        INSERT INTO products (id, name, variant, base_unit, current_stock, average_cost)
        VALUES (CAST(:new_id AS uuid), :name, :variant, :unit, :stock, :avg_cost)
    """
    await database.execute(
        query=insert_query,
        values={
            "new_id": new_id,
            "name": name,
            "variant": variant,
            "unit": unit,
            "stock": base_qty,
            "avg_cost": unit_price
        }
    )
    
    print(f"[UPSERT] Created new product: id={new_id}, base_qty={base_qty}, stock_after={base_qty}")
    return {
        "product_id": new_id,
        "conversion_rate": conversion_rate,
        "base_qty": base_qty,
        "stock_after": base_qty,
        "is_new": True
    }


async def create_transaction(
    database,
    contact_id: str,
    transaction_date: str,
    invoice_number: Optional[str],
    total_amount: float,
    payment_method: Optional[str],
    input_source: str = "OCR",
    evidence_url: Optional[str] = None
) -> str:
    """
    Create transaction header record.
    Returns transaction_id.
    """
    transaction_id = str(uuid.uuid4())
    
    # Auto-generate invoice number if not provided
    if not invoice_number:
        invoice_number = generate_invoice_number()
    
    insert_query = """
        INSERT INTO transactions (
            id, type, contact_id, transaction_date, invoice_number,
            total_amount, payment_method, input_source, evidence_url
        )
        VALUES (
            CAST(:trans_id AS uuid), 'IN', CAST(:contact_id AS uuid), :trans_date, :invoice,
            :total, :payment, :source, :evidence
        )
    """
    await database.execute(
        query=insert_query,
        values={
            "trans_id": transaction_id,
            "contact_id": contact_id,
            "trans_date": parse_date(transaction_date),
            "invoice": invoice_number,
            "total": total_amount,
            "payment": payment_method,
            "source": input_source,
            "evidence": evidence_url
        }
    )
    
    return transaction_id


async def create_transaction_item(
    database,
    transaction_id: str,
    product_id: str,
    input_qty: float,
    input_unit: str,
    input_price: float,
    conversion_rate: int,
    notes: Optional[str] = None
) -> str:
    """
    Create transaction item record.
    Note: base_qty and subtotal are generated columns, so we don't insert them.
    Returns item_id.
    """
    item_id = str(uuid.uuid4())
    
    # Note: base_qty = input_qty * conversion_rate (generated)
    # Note: subtotal = input_qty * input_price (generated)
    insert_query = """
        INSERT INTO transaction_items (
            id, transaction_id, product_id, input_qty, input_unit,
            input_price, conversion_rate, notes
        )
        VALUES (
            CAST(:item_id AS uuid), CAST(:trans_id AS uuid), CAST(:prod_id AS uuid), 
            :qty, :unit, :price, :conv_rate, :notes
        )
    """
    await database.execute(
        query=insert_query,
        values={
            "item_id": item_id,
            "trans_id": transaction_id,
            "prod_id": product_id,
            "qty": input_qty,
            "unit": input_unit,
            "price": input_price,
            "conv_rate": conversion_rate,
            "notes": notes
        }
    )
    
    return item_id


async def record_stock_movement(
    database,
    product_id: str,
    transaction_id: str,
    qty_change: float,
    stock_after: float,
    movement_type: str = "IN",
    notes: Optional[str] = None
) -> None:
    """
    Record stock movement in stock_ledger for audit trail.
    """
    # Validate and convert all values explicitly
    if qty_change is None:
        print(f"[STOCK_LEDGER ERROR] qty_change is None! Setting to 0.0")
        qty_change = 0.0
    if stock_after is None:
        print(f"[STOCK_LEDGER ERROR] stock_after is None! Setting to 0.0")
        stock_after = 0.0
    
    # Force to Python float
    qty_change_val = float(qty_change)
    stock_after_val = float(stock_after)
    
    print(f"[STOCK_LEDGER] INSERT params: product_id={product_id}, qty_change={qty_change_val}, stock_after={stock_after_val}, type={movement_type}, notes={notes}")
    
    # Use explicit SQL with proper parameter binding
    insert_query = """
        INSERT INTO stock_ledger (product_id, transaction_id, date, type, qty_change, stock_after, notes)
        VALUES (CAST(:prod_id AS uuid), CAST(:trans_id AS uuid), NOW(), CAST(:movement_type AS stock_movement_type), :qty_change, :stock_after, :notes_text)
    """
    
    values = {
        "prod_id": str(product_id),
        "trans_id": str(transaction_id),
        "movement_type": str(movement_type),
        "qty_change": qty_change_val,
        "stock_after": stock_after_val,
        "notes_text": notes
    }
    
    print(f"[STOCK_LEDGER] Executing with values: {values}")
    
    await database.execute(query=insert_query, values=values)


async def commit_procurement_transaction(
    database,
    supplier_name: str,
    supplier_phone: Optional[str],
    supplier_address: Optional[str],
    transaction_date: str,
    receipt_number: Optional[str],
    items: List[Dict[str, Any]],
    discount: Optional[float],
    total: float,
    payment_method: Optional[str],
    input_source: str = "OCR",
    evidence_url: Optional[str] = None
) -> Dict[str, Any]:
    """
    Main function to commit entire procurement transaction.
    Uses database transaction for atomicity.
    """
    try:
        # Note: databases library handles transactions differently
        # We'll execute operations sequentially, relying on the database's transactional behavior
        
        # 1. Upsert Contact (Supplier)
        contact_id = await upsert_contact(
            database=database,
            name=supplier_name,
            phone=supplier_phone,
            address=supplier_address,
            contact_type="SUPPLIER"
        )
        print(f"[COMMIT] Contact upserted: {contact_id}")
        
        # 2. Create Transaction Header
        transaction_id = await create_transaction(
            database=database,
            contact_id=contact_id,
            transaction_date=transaction_date,
            invoice_number=receipt_number,
            total_amount=total,
            payment_method=payment_method,
            input_source=input_source,
            evidence_url=evidence_url
        )
        print(f"[COMMIT] Transaction created: {transaction_id}")
        
        # 3. Process each item
        items_processed = 0
        new_products_created = 0
        
        for item in items:
            product_name = item.get("product_name", "")
            variant = item.get("variant")
            qty = float(item.get("qty", 0) or 0)  # Ensure qty is never None
            unit = item.get("unit", "pcs")
            
            # Skip items with 0 quantity
            if qty <= 0:
                print(f"[COMMIT] Skipping item with zero qty: {product_name}")
                continue
            
            unit_price = float(item.get("unit_price") or (item.get("total_price", 0) / qty))
            total_price = float(item.get("total_price", 0) or 0)
            notes = item.get("notes")
            
            print(f"[COMMIT] Processing item: {product_name}, qty={qty}, unit_price={unit_price}")
            
            # 3a. Upsert Product
            product_result = await upsert_product(
                database=database,
                name=product_name,
                variant=variant,
                unit=unit,
                qty=qty,
                unit_price=unit_price
            )
            
            if product_result["is_new"]:
                new_products_created += 1
            
            # 3b. Create Transaction Item (base_qty and subtotal are generated by DB)
            await create_transaction_item(
                database=database,
                transaction_id=transaction_id,
                product_id=product_result["product_id"],
                input_qty=qty,
                input_unit=unit,
                input_price=unit_price,
                conversion_rate=product_result["conversion_rate"],
                notes=notes
            )
            
            # 3c. Record Stock Movement
            await record_stock_movement(
                database=database,
                product_id=product_result["product_id"],
                transaction_id=transaction_id,
                qty_change=product_result["base_qty"],
                stock_after=product_result["stock_after"],
                movement_type="IN",
                notes=f"Pembelian dari {supplier_name}"
            )
            
            items_processed += 1
            print(f"[COMMIT] Item processed: {product_name} ({variant})")
        
        # Get the invoice number used
        invoice_query = "SELECT invoice_number FROM transactions WHERE id = CAST(:trans_id AS uuid)"
        invoice_result = await database.fetch_one(query=invoice_query, values={"trans_id": transaction_id})
        invoice_number = invoice_result["invoice_number"] if invoice_result else receipt_number
        
        return {
            "success": True,
            "transaction_id": transaction_id,
            "invoice_number": invoice_number,
            "items_processed": items_processed,
            "new_products_created": new_products_created,
            "message": f"Transaksi berhasil disimpan! {items_processed} item diproses."
        }
        
    except Exception as e:
        print(f"[COMMIT ERROR] {str(e)}")
        return {
            "success": False,
            "transaction_id": None,
            "invoice_number": None,
            "message": f"Gagal menyimpan transaksi: {str(e)}"
        }
