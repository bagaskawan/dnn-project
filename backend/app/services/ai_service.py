import os
import json
import base64
import re
import random 
from groq import Groq
from dotenv import load_dotenv
from fuzzywuzzy import fuzz
from datetime import date
from app.config import GROQ_TEXT_MODEL, GROQ_VISION_MODEL

load_dotenv()

client = Groq(api_key=os.getenv("GROQ_API_KEY"))

STANDARD_UNITS = {
    'ton': 1000.0, 'kwintal': 100.0, 'ons': 0.1, 'pon': 0.5,
    'lusin': 12.0, 'kodi': 20.0, 'gross': 144.0, 'rim': 500.0
}

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
RECEIPT_SCAN_PROMPT = """
Kamu adalah asisten OCR yang ahli membaca struk belanjaan Indonesia.

## TUGAS: Ekstrak SEMUA informasi dari gambar struk

### INFORMASI TOKO
- supplier_name: Nama toko (Toko X, UD X, CV X, dll.)
- supplier_address: Alamat lengkap jika ada
- supplier_phone: Nomor HP/WA (format: 08xxx atau +62xxx)

### DETAIL TRANSAKSI
- transaction_date: Tanggal dan waktu dari struk (format: YYYY-MM-DD)
- receipt_number: Nomor nota/invoice jika ada

### DAFTAR PRODUK
Untuk setiap item, ekstrak:
- product_name: Nama produk inti
- variant: Varian ukuran/tipe jika ada
- qty: Jumlah (angka)
- unit: Satuan (pcs, kg, dll)
- unit_price: Harga per satuan
- total_price: Total = qty × unit_price

### TOTAL BELANJAAN
- subtotal: Jumlah sebelum diskon
- discount: Potongan harga jika ada
- total: Jumlah akhir yang dibayar
- payment_method: Tunai/Transfer/dll

## FORMAT OUTPUT (JSON):
{
  "action": "new",
  "supplier_name": "Nama Toko",
  "supplier_phone": "08xxxxxxxxx",
  "supplier_address": "Alamat lengkap",
  "transaction_date": "YYYY-MM-DD",
  "receipt_number": "No. Invoice",
  "items": [
    {"product_name":"", "variant":null, "qty":1, "unit":"pcs", "unit_price":0, "total_price":0, "notes":null}
  ],
  "subtotal": 0,
  "discount": 0,
  "total": 0,
  "payment_method": "Tunai",
  "follow_up_question": "Struk berhasil dibaca! Ada yang perlu dikoreksi Kak?",
  "suggested_actions": ["Edit", "Simpan"],
  "confidence_score": 0.85
}

PENTING:
- Baca SEMUA produk yang tercantum di struk
- Jika ada harga satuan di struk, isi unit_price
- Jika tidak yakin, set confidence_score lebih rendah
- Jangan skip produk apapun!
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

# --- MAIN EXPORT FUNCTION ---

async def parse_procurement_text(text_input: str, current_draft: dict = None, known_products: list = None):
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
        
        for item in ai_response.get('items', []):
            normalize_item_data(item, product_context=known_products)
            
        final = validate_extracted_items(ai_response)
        final = check_draft_duplication(final, current_draft) # LOGIKA BARU
        final = add_supplier_reminder(final, current_draft)
        
        return final

    except Exception as e:
        print(f"Error: {e}")
        return {"action": "chat", "follow_up_question": "Sistem sedang sibuk, coba lagi ya Kak!", "items": []}

async def parse_procurement_image(image_bytes, current_draft: dict = None, known_products: list = None):
    try:
        base64_image = base64.b64encode(image_bytes).decode('utf-8')
        
        # Use specialized receipt scanning prompt
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": RECEIPT_SCAN_PROMPT},
                {"role": "user", "content": [
                    {"type": "text", "text": "Baca struk belanjaan ini dengan teliti. Ekstrak semua informasi toko, produk, dan total belanjaan."},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}},
                ]}
            ],
            model=GROQ_VISION_MODEL,
            temperature=0,
            response_format={"type": "json_object"}
        )
        ai_response = json.loads(chat_completion.choices[0].message.content)
        
        print(f"[RECEIPT_OCR] Raw AI Response: {ai_response}")
        
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
        return {"action": "chat", "follow_up_question": "Gagal membaca struk. Pastikan gambar jelas dan coba lagi ya Kak! 📸", "items": []}