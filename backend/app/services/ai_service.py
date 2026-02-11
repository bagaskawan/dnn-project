import os
import json
import base64
import re
import random
import tempfile
from groq import Groq
from dotenv import load_dotenv
from fuzzywuzzy import fuzz
from datetime import date
from app.config import GROQ_TEXT_MODEL, GROQ_VISION_MODEL


def normalize_phone(phone: str) -> str:
    """Normalize phone number to always start with '0'."""
    if not phone:
        return phone
    phone = phone.strip().replace(" ", "").replace("-", "")
    # Remove +62 prefix
    if phone.startswith("+62"):
        phone = "0" + phone[3:]
    elif phone.startswith("62") and len(phone) > 10:
        phone = "0" + phone[2:]
    # If starts with 8 (missing leading 0)
    elif phone and phone[0] == '8':
        phone = "0" + phone
    return phone

# EasyOCR for accurate text extraction (simpler than PaddleOCR, no conflicts)
import easyocr

# Lazy-loaded OCR instance
_ocr_reader = None

def get_ocr():
    """Get or create EasyOCR reader (lazy loading for performance)"""
    global _ocr_reader
    if _ocr_reader is None:
        print("[OCR] Initializing EasyOCR (first run may download models)...")
        # Support Indonesian (id) and English (en) text
        _ocr_reader = easyocr.Reader(['id', 'en'], gpu=False)
    return _ocr_reader

def extract_text_from_image(image_bytes) -> str:
    """
    Step 1: Extract raw text from image using EasyOCR.
    REVISED: Better row grouping logic for skewed receipts.
    """
    with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as f:
        f.write(image_bytes)
        temp_path = f.name
    
    try:
        reader = get_ocr()
        # width_ths=0.7 allows merging closer words
        result = reader.readtext(temp_path, paragraph=False, width_ths=0.7)
        
        if not result:
            return ""
        
        # Helper to get center Y and min X
        def get_box_center_y(box):
            return (box[0][1] + box[2][1]) / 2

        def get_box_min_x(box):
            return box[0][0]

        # 1. Sort all boxes by Y (top to bottom)
        boxes = sorted(result, key=lambda r: get_box_center_y(r[0]))
        
        # 2. Group into rows
        rows = []
        if boxes:
            current_row = [boxes[0]]
            last_y = get_box_center_y(boxes[0][0])
            
            # Increased threshold for better line merging (was 30)
            ROW_THRESHOLD = 50 
            
            for box in boxes[1:]:
                current_y = get_box_center_y(box[0])
                if abs(current_y - last_y) <= ROW_THRESHOLD:
                    current_row.append(box)
                else:
                    rows.append(current_row)
                    current_row = [box]
                    last_y = current_y
            rows.append(current_row)
        
        # 3. Sort each row by X (left to right) and join text
        lines = []
        for row in rows:
            # Sort row items by X coordinate
            row.sort(key=lambda r: get_box_min_x(r[0]))
            
            # Filter low confidence items aggressively
            # Lowered threshold to 0.1 to catch faint prices
            row_text = [r[1] for r in row if r[2] > 0.1] 
            
            if row_text:
                lines.append(" ".join(row_text))
        
        raw_text = '\n'.join(lines)
        print(f"[OCR] Extracted {len(lines)} lines. Raw Content:\n{raw_text}")
        return raw_text

    except Exception as e:
        print(f"[OCR] Error: {e}")
        return ""
    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path) # Cleanup temp file

load_dotenv()

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

STANDARD_UNITS = {
    'ton': 1000.0, 'kwintal': 100.0, 'ons': 0.1, 'pon': 0.5,
    'lusin': 12.0, 'kodi': 20.0, 'gross': 144.0, 'rim': 500.0
}

# --- FUZZY MATCHING FOR OCR CORRECTION ---

def fuzzy_correct_product_names(ai_response: dict, known_products: list, threshold: int = 70) -> dict:
    """
    Post-process AI response to correct product names using fuzzy matching.
    This catches OCR errors that the LLM might miss.
    
    Args:
        ai_response: Parsed OCR data from LLM
        known_products: List of products from database
        threshold: Minimum similarity score (0-100) to consider a match
    
    Returns:
        Updated ai_response with corrected product names
    """
    if not known_products or 'items' not in ai_response:
        return ai_response
    
    # Build searchable product name list
    product_name_map = {}
    for p in known_products:
        full_name = p.get('name', '')
        variant = p.get('variant', '')
        if variant:
            full_name = f"{full_name} {variant}"
        product_name_map[full_name.lower()] = full_name
    
    for item in ai_response.get('items', []):
        ocr_name = item.get('product_name', '')
        if not ocr_name:
            continue
            
        ocr_lower = ocr_name.lower()
        
        # Find best match
        best_match = None
        best_score = 0
        
        for db_name_lower, db_name_original in product_name_map.items():
            # Use token_set_ratio for better matching with word order variations
            score = fuzz.token_set_ratio(ocr_lower, db_name_lower)
            if score > best_score:
                best_score = score
                best_match = db_name_original
        
        # Apply correction if match is good enough
        if best_match and best_score >= threshold:
            if best_score < 100:  # Only log if there was a correction
                print(f"[FUZZY] Corrected '{ocr_name}' → '{best_match}' (score: {best_score})")
            item['product_name'] = best_match
    
    return ai_response

# --- 1. PERSONA & PROMPT ENGINE ---

BASE_SYSTEM_PROMPT = """
You are 'Asisten Kulakan', a friendly procurement assistant. Respond in casual Indonesian (pakai 'Kak').

## INTENT CLASSIFICATION
- **Greeting/Chat**: "Halo", "Pagi", "Catat dong", "Mulai" → action: "chat"
- **Supplier Name**: Store pattern (Toko X, UD X, Pak/Bu X, CV/PT X) → action: "update"
- **Product Input**: Has quantity+price → action: "append", extract items
- **Genuinely Ambiguous**: Single word without qty/price → action: "clarify"

## SMART SEPARATION STRATEGY (CRITICAL!)
For each product, separate into 3 components:
1. **product_name** = Core product (untuk database matching)
   - "Nangka", "Kripik Mamah Erok", "Beras"
2. **variant** = Size/Type yang membedakan SKU (BEDA PRODUK!)
   - "Besar", "Kecil", "Level 5", "Premium", "1L", "500ml", "Pedas"
3. **notes** = Atribut tambahan yang TIDAK membedakan SKU
   - "Manis", "Wangi", "Organik", "Diskon"

## JSON OUTPUT:
{
  "action": "chat|update|append|delete|clarify",
  "supplier_name": "string or null",
  "transaction_date": "YYYY-MM-DD",
  "items": [{"product_name":"", "variant":"string or null", "qty":0, "unit":"pcs", "total_price":0, "notes":"string or null"}],
  "follow_up_question": "string (WAJIB!)",
  "suggested_actions": ["string"] 
}
"""

# --- RECEIPT SCANNING PROMPT (OCR) ---
# --- RECEIPT SCANNING PROMPT (OCR) ---
RECEIPT_SCAN_PROMPT = """
Kamu adalah asisten OCR yang ahli membaca struk belanjaan grosir/reseller Indonesia.

## TUGAS UTAMA:
Ekstrak data transaksi dari teks struk.

## 1. ATURAN PARSING SUPPLIER (HEADER STRUK) - CRITICAL!

Fokus pisahkan **Nama Toko** dan **Alamat**. Jangan digabung!

### POLA IDENTIFIKASI:
1.  **supplier_name (Nama Toko):**
    * Biasanya HANYA ada di **Baris Pertama** teks.
    * Format umum: "Toko X", "UD X", "CV X", "Warung X", atau Nama Brand.
    * **PANTANGAN:** Jangan masukkan kata-kata alamat ke dalam nama toko.

2.  **supplier_address (Alamat):**
    * Biasanya mulai dari **Baris Kedua**.
    * Ciri khas kata kunci alamat: "Jl.", "Jalan", "Raya", "Kec.", "Kab.", "Kota", "Blok", "No.".

### CONTOH KASUS NYATA (PERHATIKAN BEDANYA):

**Kasus A (Jalan Raya):**
*Teks OCR:*
`Toko Yunden Jaya`
`Jl. Raya Nanjung no 8`

*Salah (JANGAN SEPERTI INI):*
`supplier_name`: "Toko Yunden Jaya Jl. Raya" ❌ (Salah ambil baris kedua)

*Benar:*
`supplier_name`: "Toko Yunden Jaya" ✅
`supplier_address`: "Jl. Raya Nanjung no 8" ✅

**Kasus B (Tanpa Label Jalan):**
*Teks OCR:*
`Berkah Abadi`
`Pasar Induk Blok C-12`

*Benar:*
`supplier_name`: "Berkah Abadi"
`supplier_address`: "Pasar Induk Blok C-12"

---

## 2. ATURAN PARSING PRODUK (GROSIR)

### QTY vs VARIANT:
- **qty**: Angka yang berdiri sendiri (jumlah barang).
- **variant**: Angka yang menempel satuan (kg/gr/L/isi/pcs dalam nama).
- **unit**: Satuan wadah (Karton/Dus/Bungkus/Bal).

### CONTOH PRODUK:
Teks: `Kara Santan Kartonan isi 36 | 1 | 175.000`
-> Product: "Kara Santan Kartonan", Variant: "Isi 36", Qty: 1, Unit: "Karton"

Teks: `Singkong jadul ORI 1kg | 5 | 85.000`
-> Product: "Singkong Jadul ORI", Variant: "1kg", Qty: 5, Unit: "Bungkus"

### HITUNG QTY DARI HARGA:
Jika OCR gagal baca Qty, hitung manual: `qty = total_price / unit_price`.
Contoh: `17.000 x ... = 85.000` -> Qty otomatis **5**.

---

## OUTPUT FORMAT (JSON):
{
  "action": "new",
  "supplier_name": "Nama Toko (Hanya Nama)",
  "supplier_phone": "Nomor HP/WA",
  "supplier_address": "Alamat Lengkap",
  "transaction_date": "YYYY-MM-DD",
  "receipt_number": "Nomor Invoice",
  "items": [
    {
      "product_name": "Nama Produk", 
      "variant": "Ukuran/Isi", 
      "qty": 0, 
      "unit": "Satuan", 
      "unit_price": 0, 
      "total_price": 0, 
      "notes": null
    }
  ],
  "subtotal": 0,
  "discount": 0,
  "total": 0,
  "payment_method": "Tunai/Transfer",
  "follow_up_question": "Struk terbaca! Cek nama toko dan produknya ya Kak?",
  "confidence_score": 0.9
}
"""

MISSING_SUPPLIER_INSTRUCTION = """
CONTEXT: Draft is new, Supplier is missing.
If input looks like a Store Name -> action="update", supplier_name=Input.
If input looks like a Product -> Treat as product.
"""

# --- 2. LOGIC GATEKEEPER & MATCHING ---

def resolve_ambiguity_preprocessing(text_input: str, current_draft: dict):
    text_clean = text_input.strip()
    text_lower = text_clean.lower()

    # A. Handle Command Tombol
    if text_lower.startswith("jadikan supplier:"):
        new_supplier = text_input.split(":", 1)[1].strip()
        return {
            "action": "update",
            "supplier_name": new_supplier,
            "items": [], 
            "follow_up_question": f"Sip, Supplier '{new_supplier}' dicatat. Lanjut input barangnya Kak!",
            "suggested_actions": ["Batal"]
        }

    if text_lower.startswith("jadikan produk:"):
        product_name = text_input.split(":", 1)[1].strip()
        return {
            "action": "chat",
            "supplier_name": current_draft.get('supplier_name') if current_draft else None,
            "items": [], 
            "follow_up_question": f"Oke, '{product_name}' dicatat. Qty dan harganya berapa? 📝",
            "suggested_actions": ["Batal"]
        }

    # B. Handle "Tambah ke Qty"
    if text_lower == "tambah ke qty":
        merge_candidate = current_draft.get('merge_candidate') if current_draft else None
        
        if merge_candidate and merge_candidate.get('source') == 'draft':
            existing_idx = merge_candidate.get('existing_index')
            new_input = merge_candidate.get('new_input', {})
            
            if existing_idx is not None and current_draft.get('items'):
                current_items = list(current_draft['items']) # Copy list
                
                if 0 <= existing_idx < len(current_items):
                    target_item = current_items[existing_idx]
                    
                    old_qty = float(target_item.get('qty', 0))
                    add_qty = float(new_input.get('qty', 0))
                    new_total_qty = old_qty + add_qty
                    
                    old_price = float(target_item.get('total_price', 0))
                    add_price = float(new_input.get('total_price', 0))
                    new_total_price = old_price + add_price
                    
                    target_item['qty'] = new_total_qty
                    target_item['total_price'] = new_total_price
                    
                    new_note = new_input.get('notes')
                    new_variant_txt = new_input.get('variant', '')
                    old_variant_txt = target_item.get('variant', '')
                    
                    notes_to_add = []
                    if new_note: notes_to_add.append(new_note)
                    if new_variant_txt and new_variant_txt != old_variant_txt:
                        notes_to_add.append(f"Varian input: {new_variant_txt}")

                    if notes_to_add:
                        existing_notes = target_item.get('notes') or ""
                        combined = ", ".join(notes_to_add)
                        if combined not in existing_notes:
                            target_item['notes'] = f"{existing_notes}, {combined}".strip(', ')

                    current_items[existing_idx] = target_item
                    
                    display_name = target_item.get('product_name')
                    if target_item.get('variant'):
                        display_name += f" ({target_item.get('variant')})"

                    return {
                        "action": "new", # Replace list
                        "supplier_name": current_draft.get('supplier_name'),
                        "items": current_items,
                        "follow_up_question": f"Sip! Stok '{display_name}' bertambah jadi {new_total_qty} {target_item.get('unit')}. 👌",
                        "suggested_actions": ["Simpan", "Edit"]
                    }

        return {
            "action": "chat",
            "follow_up_question": "Data kadaluarsa. Mohon input ulang barangnya ya Kak.",
            "items": []
        }

    # C. Handle "Tidak, Buat Baru"
    if text_lower == "tidak, buat baru":
        merge_candidate = current_draft.get('merge_candidate') if current_draft else None
        if merge_candidate:
            new_input = merge_candidate.get('new_input', {})
            item_to_add = {
                "product_name": new_input.get('name'),
                "variant": new_input.get('variant'),
                "qty": new_input.get('qty', 0),
                "unit": new_input.get('unit', 'pcs'),
                "total_price": new_input.get('total_price', 0),
                "notes": new_input.get('notes')
            }
            return {
                "action": "append",
                "supplier_name": current_draft.get('supplier_name'),
                "items": [item_to_add],
                "follow_up_question": f"Oke, '{item_to_add['product_name']}' dicatat sebagai barang baru. ✅",
                "suggested_actions": ["Edit", "Simpan"]
            }

    return None

def normalize_item_data(item, product_context=None):
    try:
        qty_val = float(item.get('qty', 0))
        if qty_val <= 0: qty_val = 0 
    except:
        qty_val = 0
    item['qty'] = qty_val
    
    raw_unit = str(item.get('unit', 'pcs')).lower().strip()
    if raw_unit in ["none", ""]: raw_unit = "pcs"
    item['unit'] = raw_unit
    
    if raw_unit in STANDARD_UNITS:
        converted_qty = qty_val * STANDARD_UNITS[raw_unit]
        item['notes'] = f"Konversi: {qty_val} {raw_unit} = {converted_qty} (Base)"
        item['qty'] = converted_qty
    return item

def validate_extracted_items(ai_response: dict):
    if ai_response.get('action') in ['chat', 'clarify', 'merge_confirm']:
        return ai_response
    if ai_response.get('action') not in ['new', 'append', 'update']:
        return ai_response

    valid_items = []
    incomplete_items = []

    for item in ai_response.get('items', []):
        qty = float(item.get('qty', 0))
        if qty > 0: 
            valid_items.append(item)
        else:
            incomplete_items.append(item.get('product_name', 'Barang'))

    if incomplete_items:
        names = ", ".join(incomplete_items)
        return {
            "action": "chat", 
            "supplier_name": ai_response.get('supplier_name'),
            "items": [], 
            "follow_up_question": f"Waduh, '{names}' belum ada jumlahnya nih. Berapa banyak?",
            "suggested_actions": ["Input Manual"]
        }
    
    ai_response['items'] = valid_items
    return ai_response

def add_supplier_reminder(response: dict, current_draft: dict = None):
    has_supplier = response.get('supplier_name') or (current_draft and current_draft.get('supplier_name'))
    has_items = len(response.get('items', [])) > 0 or (current_draft and len(current_draft.get('items', [])) > 0)
    
    if has_items and not has_supplier:
        q = response.get('follow_up_question', '')
        if 'supplier' not in q.lower():
            response['follow_up_question'] = f"{q}\n\n📝 Jangan lupa masukkan nama supplier-nya ya Kak!"
            
    if has_items and 'Edit' not in (response.get('suggested_actions') or []):
        actions = response.get('suggested_actions', []) or []
        if 'Edit' not in actions: actions.append('Edit')
        response['suggested_actions'] = actions
    
    return response

# --- CHECK DUPLICATION LOGIC (FIXED) ---

def check_draft_duplication(response: dict, current_draft: dict):
    """
    LOGIKA FILTER DUPLIKASI (FIXED & STRICT):
    Membandingkan Input Baru (new_items) vs Draft Lama (draft_items).
    """
    # Validasi Dasar
    if not current_draft or not current_draft.get('items'):
        return response
    if response.get('action') not in ['append', 'new']:
        return response
        
    new_items = response.get('items', [])
    if not new_items: return response
    
    draft_items = current_draft.get('items', [])
    
    # Helper: Normalisasi & Ekstraksi Angka
    def normalize(text): return str(text or '').lower().strip()
    def extract_numbers(text): return set(re.findall(r'\d+', text))
    
    def build_display_name(item):
        name = item.get('product_name', '')
        variant = item.get('variant')
        return f"{name} ({variant})" if variant else name

    # --- MAIN LOOP (Item Baru vs Draft Lama) ---
    duplicate_matches = [] # Menyimpan yang EXACT match / Angka Sama
    ambiguous_matches = [] # Menyimpan yang butuh KONFIRMASI (Teks beda)
    non_duplicate_items = [] # Barang baru
    
    for item_idx, new_item in enumerate(new_items):
        match_found = False
        
        # Ambil data item baru
        new_name = normalize(new_item.get('product_name'))
        new_variant = normalize(new_item.get('variant'))
        new_nums = extract_numbers(new_variant)
        
        for draft_idx, draft_item in enumerate(draft_items):
            # Ambil data item draft
            d_name = normalize(draft_item.get('product_name'))
            d_variant = normalize(draft_item.get('variant'))
            d_nums = extract_numbers(d_variant)
            
            # 1. Cek Nama Produk (Wajib Mirip > 85%)
            if fuzz.token_sort_ratio(new_name, d_name) < 85:
                continue # Lanjut ke item draft berikutnya
            
            # Jika nama mirip, baru cek Varian
            match_type = "NONE"

            # 2. Cek Angka Varian (CRITICAL)
            if new_nums and d_nums:
                if new_nums == d_nums:
                    # Angka SAMA (Level 2 vs Level 2 Pedas) -> Ini Kuncinya!
                    # Anggap MATCH (Duplikat), nanti user pilih tambah qty
                    match_type = "EXACT" 
                else:
                    # Angka BEDA (Level 2 vs Level 5) -> BEDA BARANG
                    match_type = "NONE"
            
            # 3. Jika Tidak Ada Angka, Cek Teks
            elif not new_nums and not d_nums:
                if new_variant == d_variant:
                    match_type = "EXACT"
                elif fuzz.token_set_ratio(new_variant, d_variant) > 85:
                    match_type = "EXACT"
                else:
                    match_type = "NONE" # Varian teks beda jauh (Pedas vs Manis)
            
            # 4. Satu ada angka, satu tidak -> Beda
            else:
                match_type = "NONE"

            # Jika MATCH, simpan dan stop loop draft (karena sudah ketemu pasangannya)
            if match_type == "EXACT":
                match_data = {
                    'draft_idx': draft_idx,
                    'new_display': build_display_name(new_item),
                    'existing_display': build_display_name(draft_item),
                    'item': new_item,
                    'existing_item': draft_item
                }
                duplicate_matches.append(match_data)
                match_found = True
                break # Stop loop draft
        
        if not match_found:
            non_duplicate_items.append(new_item)

    # --- DECISION MAKING ---

    duplicate_count = len(duplicate_matches)

    # KASUS A: Ada Item Baru (Non-Duplikat) -> PRIORITAS
    # Masukkan item baru, abaikan duplikat (user harus edit manual duplikatnya nanti)
    if len(non_duplicate_items) > 0:
        response['items'] = non_duplicate_items
        added_str = ", ".join([build_display_name(i) for i in non_duplicate_items])
        
        msg = f"✅ Produk baru ditambahkan: {added_str}."
        
        # Beri notifikasi santai kalau ada yang mirip
        if duplicate_count > 0:
            dup_str = ", ".join([d['existing_display'] for d in duplicate_matches])
            msg += f"\n\n⚠️ {duplicate_count} produk lainnya ({dup_str}) sudah ada di draft. Saya skip ya biar nggak dobel."
        
        response['follow_up_question'] = msg
        response['suggested_actions'] = ["Edit", "Simpan"]
        return response

    # KASUS B: SEMUA DUPLIKAT (Match ditemukan)
    if duplicate_count > 0:
        
        # Jika cuma 1 item duplikat (Skenario Paling Umum & Target Anda)
        if duplicate_count == 1:
            match = duplicate_matches[0]
            response['items'] = [] # Tahan dulu
            response['action'] = 'merge_confirm'
            
            # KALIMAT SESUAI REQUEST KAMU:
            response['follow_up_question'] = f"'{match['new_display']}' sudah ada dalam draft list ({match['existing_display']}).\n\nApakah kamu mau menambahkan jumlah qty dan harganya?"
            
            response['suggested_actions'] = ["Tambah ke Qty", "Tidak, Buat Baru"]
            
            # Simpan data untuk merge
            response['merge_candidate'] = {
                'source': 'draft',
                'existing_index': match['draft_idx'],
                'new_input': {
                    'qty': match['item'].get('qty', 0),
                    'total_price': match['item'].get('total_price', 0),
                    'notes': match['item'].get('notes'),
                    'variant': match['item'].get('variant'),
                    'name': match['item'].get('product_name')
                }
            }
            return response
            
        else:
            # Batch Duplicates (> 1 item sama) -> Info saja
            dup_list = "\n".join([f"• {d['existing_display']}" for d in duplicate_matches])
            return {
                "action": "chat",
                "supplier_name": current_draft.get('supplier_name'),
                "items": [],
                "follow_up_question": f"Ada {duplicate_count} produk yang sama persis di draft:\n{dup_list}\n\nMohon update manual satu per satu lewat tombol Edit ya Kak, biar datanya aman! 🙏",
                "suggested_actions": ["Edit"]
            }

    # Default: Loloskan semua (harusnya tidak sampai sini jika logika benar)
    return response

def check_supplier_duplication(ai_response: dict, known_suppliers: list) -> dict:
    """
    Check if extracted supplier name is similar to existing suppliers.
    If similarity > 70%, return supplier_confirm action.
    """
    from fuzzywuzzy import fuzz
    
    supplier_name = ai_response.get('supplier_name')
    if not supplier_name or not known_suppliers:
        return ai_response
    
    # Check for fuzzy matches
    best_match = None
    best_score = 0
    
    for supplier in known_suppliers:
        existing_name = supplier.get('name', '')
        score = fuzz.ratio(supplier_name.lower(), existing_name.lower())
        
        if score > best_score:
            best_score = score
            best_match = supplier
    
    # If match > 70%, ask for confirmation
    if best_score > 70 and best_score < 100:  # Not exact match
        return {
            "action": "supplier_confirm",
            "supplier_name": supplier_name,  # New supplier name from input
            "supplier_candidate": {
                "name": best_match['name'],
                "phone": best_match.get('phone'),
                "similarity": best_score
            },
            "items": ai_response.get('items', []),
            "transaction_date": ai_response.get('transaction_date'),
            "follow_up_question": f"🤔 Apakah supplier '{supplier_name}' ini sama dengan '{best_match['name']}' yang sudah ada?",
            "suggested_actions": ["Ya, supplier yang sama", "Beda supplier"],
            "confidence_score": ai_response.get('confidence_score', 0.9)
        }
    
    return ai_response

# --- MAIN EXPORT FUNCTION ---

async def parse_procurement_text(text_input: str, current_draft: dict = None, known_products: list = None, known_suppliers: list = None):
    try:
        pre = resolve_ambiguity_preprocessing(text_input, current_draft)
        if pre: return pre 

        rag_context = ""
        if known_products:
            lines = [f"- {p['name']} ({p.get('variant','')})" for p in known_products[:50]]
            rag_context = "KNOWN PRODUCTS:\n" + "\n".join(lines)

        draft_context = ""
        is_missing_supp = True
        if current_draft:
            draft_context = f"CURRENT_DRAFT:\n{json.dumps(current_draft, ensure_ascii=False)}\n"
            if current_draft.get('supplier_name'): is_missing_supp = False

        instruction = MISSING_SUPPLIER_INSTRUCTION if is_missing_supp else ""
        prompt = BASE_SYSTEM_PROMPT + f"\n{rag_context}\n{instruction}"

        completion = client.chat.completions.create(
            model=GROQ_TEXT_MODEL,
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": f"{draft_context}USER INPUT:\n{text_input}"}
            ],
            temperature=0.3,
            response_format={"type": "json_object"}
        )
        
        ai_response = json.loads(completion.choices[0].message.content)
        
        # Normalize phone number
        if ai_response.get('supplier_phone'):
            ai_response['supplier_phone'] = normalize_phone(ai_response['supplier_phone'])
        
        for item in ai_response.get('items', []):
            normalize_item_data(item, product_context=known_products)
            
        final = validate_extracted_items(ai_response)
        final = check_draft_duplication(final, current_draft) # LOGIKA BARU
        final = add_supplier_reminder(final, current_draft)
        final = check_supplier_duplication(final, known_suppliers) # SUPPLIER DEDUP
        
        return final

    except Exception as e:
        print(f"Error: {e}")
        return {"action": "chat", "follow_up_question": "Sistem sedang sibuk, coba lagi ya Kak!", "items": []}

async def parse_procurement_image(image_bytes, current_draft: dict = None, known_products: list = None):
    """
    TWO-STEP OCR PIPELINE:
    Step 1: PaddleOCR - Accurate text extraction from image
    Step 2: Text LLM + RAG - Parse text and correct typos using product database
    """
    try:
        # ============================================
        # STEP 1: Extract text using PaddleOCR (accurate)
        # ============================================
        raw_text = extract_text_from_image(image_bytes)
        print(f"[RECEIPT_OCR] Step 1 - Raw OCR Text:\n{raw_text}\n")
        
        if not raw_text or len(raw_text.strip()) < 10:
            return {
                "action": "chat", 
                "follow_up_question": "Tidak bisa membaca teks dari gambar. Pastikan foto struk jelas ya Kak! 📸", 
                "items": []
            }
        
        # ============================================
        # STEP 2: Parse with Text LLM + Product Database (RAG)
        # ============================================
        # This uses the smarter text model + fuzzy matching to correct typos
        
        # Build product context for RAG-based correction
        rag_context = ""
        if known_products:
            product_names = [f"- {p.get('name', '')} ({p.get('variant', '')})" for p in known_products[:100]]
            rag_context = f"KNOWN PRODUCTS IN DATABASE (gunakan untuk koreksi typo):\n" + "\n".join(product_names)
        
        ocr_parse_prompt = f"""
Kamu adalah asisten yang mengolah hasil OCR struk belanjaan grosir/reseller Indonesia.

## TEKS OCR:
{raw_text}

{rag_context}

## ATURAN PARSING SUPPLIER - SANGAT PENTING!

### 0. PISAHKAN NAMA SUPPLIER DAN ALAMAT (CRITICAL!):
- **supplier_name**: HANYA nama toko/usaha (Toko X, UD X, CV X, PT X, Pak/Bu X)
- **supplier_address**: Alamat lengkap yang biasanya diawali dengan:
  - "Jl.", "Jln.", "Jalan" (nama jalan)
  - "Kec.", "Kecamatan" (kecamatan)
  - "Kab.", "Kabupaten", "Kota" (kota/kabupaten)
  - "No.", "Blok", "RT", "RW" (nomor rumah/blok)

CONTOH BENAR:
Struk Header:
```
Toko Yunden Jaya
Jl. Raya Nanjung no.8
kec. Margaasih Kab. Bandung
```
→ supplier_name: "Toko Yunden Jaya" (HANYA ini!)
→ supplier_address: "Jl. Raya Nanjung no.8, kec. Margaasih Kab. Bandung"

CONTOH SALAH:
→ supplier_name: "Toko Yunden Jaya Raya" ❌ (kata "Raya" adalah bagian dari alamat!)

### TIPS IDENTIFIKASI:
- Nama supplier biasanya di BARIS PERTAMA dan berformat "Toko/UD/CV + Nama"
- Alamat biasanya di baris KEDUA dan KETIGA
- JANGAN gabungkan baris alamat ke nama supplier!

---

## ATURAN PARSING GROSIR - SANGAT PENTING!

### 1. PERBEDAAN QTY vs VARIANT:
- **qty**: JUMLAH YANG DIBELI (angka berdiri sendiri, biasanya di kolom qty struk)
- **variant**: UKURAN/ISI KEMASAN (angka yang menempel dengan kg/gr/L/isi)
- **unit**: SATUAN PEMBELIAN (Karton/Dus/Bungkus/Pcs, BUKAN kg jika kg adalah variant!)

### 2. CONTOH PARSING BENAR:

KASUS KARTONAN:
Struk: "Kara Santan Kartonan isi 36 | 1 | Rp 175.000"
→ product_name: "Kara Santan Kartonan"
→ variant: "Isi 36"
→ qty: 1
→ unit: "Karton"
→ total_price: 175000

KASUS UKURAN BERAT:
Struk: "Singkong jadul ORI 1kg | 5 | Rp 17.000 | Rp 85.000"  
→ product_name: "Singkong Jadul ORI"
→ variant: "1kg"
→ qty: 5 (BUKAN 1! Angka berdiri sendiri = qty)
→ unit: "Bungkus" (BUKAN kg! kg adalah variant)
→ unit_price: 17000
→ total_price: 85000

Struk: "Singkong jadul balado 1kg | 2 | Rp 20.000 | Rp 40.000"
→ product_name: "Singkong Jadul Balado"
→ variant: "1kg"
→ qty: 2 (BUKAN 1!)
→ unit: "Bungkus"
→ total_price: 40000

### 3. KOREKSI TYPO OCR:
- "Jongkong" → "Singkong"
- "Baladu" → "Balado"
- "tomyurn" → "tomyum"
- "Karuan" → "Kartonan"

### 4. HITUNG QTY DARI HARGA (CRITICAL!):
- Jika OCR tidak menangkap qty tapi ada harga satuan dan total:
- **qty = total_price / unit_price**
- Contoh: unit_price=17.000, total=85.000 → qty = 5
- Contoh: unit_price=20.000, total=40.000 → qty = 2
- JANGAN default ke qty=1 jika bisa dihitung!

## OUTPUT FORMAT (JSON):
{{
  "action": "new",
  "supplier_name": "Nama Toko",
  "supplier_phone": "Nomor HP",
  "supplier_address": "Alamat",
  "transaction_date": "YYYY-MM-DD",
  "receipt_number": "Nomor nota",
  "items": [
    {{"product_name":"Nama Produk", "variant":"ukuran/isi", "qty":1, "unit":"Karton/Bungkus/Pcs", "unit_price":0, "total_price":0, "notes":null}}
  ],
  "subtotal": 0,
  "total": 0,
  "payment_method": "Tunai/Transfer",
  "follow_up_question": "Struk terbaca! Cek qty dan variannya ya Kak?",
  "confidence_score": 0.85
}}

## PENTING - JANGAN SKIP PRODUK!
- Ekstrak SEMUA produk yang ada di teks OCR
- Jika ada produk yang tidak jelas, tetap masukkan dengan confidence rendah
"""
        
        completion = client.chat.completions.create(
            model=GROQ_TEXT_MODEL,
            messages=[
                {"role": "system", "content": ocr_parse_prompt},
                {"role": "user", "content": "Parse teks OCR di atas menjadi JSON. Koreksi semua typo OCR!"}
            ],
            temperature=0.1,
            response_format={"type": "json_object"}
        )
        
        ai_response = json.loads(completion.choices[0].message.content)
        print(f"[RECEIPT_OCR] Step 2 - Parsed Result: {ai_response}")
        
        # Normalize phone number
        if ai_response.get('supplier_phone'):
            ai_response['supplier_phone'] = normalize_phone(ai_response['supplier_phone'])
        
        # ============================================
        # STEP 3: Post-process with Fuzzy Matching (fallback)
        # ============================================
        if known_products:
            ai_response = fuzzy_correct_product_names(ai_response, known_products)
        
        # Normalize items
        for item in ai_response.get('items', []):
            normalize_item_data(item, product_context=known_products)
        
        # Calculate subtotal/total if not provided
        if not ai_response.get('subtotal') and ai_response.get('items'):
            calculated_subtotal = sum(item.get('total_price', 0) for item in ai_response['items'])
            ai_response['subtotal'] = calculated_subtotal
            if not ai_response.get('total'):
                ai_response['total'] = calculated_subtotal
        
        # Add default follow-up if not present
        if not ai_response.get('follow_up_question'):
            item_count = len(ai_response.get('items', []))
            total = ai_response.get('total', 0)
            ai_response['follow_up_question'] = f"✅ Struk berhasil dibaca! {item_count} produk dengan total Rp {total:,.0f}. Ada yang perlu dikoreksi?"
            ai_response['suggested_actions'] = ["Edit", "Simpan"]
            
        final = validate_extracted_items(ai_response)
        final = check_draft_duplication(final, current_draft)
        final = add_supplier_reminder(final, current_draft)
        return final
        
    except Exception as e:
        print(f"[RECEIPT_OCR] Error: {e}")
        import traceback
        traceback.print_exc()
        return {"action": "chat", "follow_up_question": "Gagal membaca struk. Pastikan gambar jelas dan coba lagi ya Kak! 📸", "items": []}