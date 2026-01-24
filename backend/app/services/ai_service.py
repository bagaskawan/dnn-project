import os
import json
import base64
from groq import Groq
from dotenv import load_dotenv
from fuzzywuzzy import fuzz  # Pastikan install: pip install fuzzywuzzy python-Levenshtein
from datetime import date
from app.config import GROQ_TEXT_MODEL, GROQ_VISION_MODEL

# Load API Key
load_dotenv()

# Initialize Groq Client
client = Groq(
    api_key=os.getenv("GROQ_API_KEY"),
)

# ==========================================
# 📐 STANDARD UNITS LIBRARY (Static Math)
# ==========================================
# Hanya satuan yang SIFATNYA MUTLAK yang boleh ditaruh di sini.
# Satuan seperti 'Karung', 'Bal', 'Dus' ditangani via Database Product Rules.
STANDARD_UNITS = {
    # Berat
    'ton': 1000.0,
    'kwintal': 100.0,
    'ons': 0.1,
    'pon': 0.5,
    # Jumlah
    'lusin': 12.0,
    'kodi': 20.0,
    'gross': 144.0,
    'rim': 500.0
}

# ==========================================
# 🧠 RAG & PROMPT ENGINE
# ==========================================

BASE_SYSTEM_PROMPT = """
You are an expert Procurement Data Analyst AI.
Task: Extract structured data from chat/receipts into JSON.

CORE RULES:
1. Output ONLY valid JSON.
2. EXTRACT data exactly as stated. Do NOT perform math conversions yourself (e.g. if user says '1.5 ton', keep unit 'ton').
3. USE CONTEXT: If provided with 'Known Products', try to match user input to those exact product names and units.

JSON SCHEMA:
{
  "action": "new/append/update/delete/chat",
  "supplier_name": "string or null", 
  "transaction_date": "YYYY-MM-DD",
  "items": [
    {
      "product_name": "string",
      "qty": float,
      "unit": "string", 
      "total_price": float,
      "notes": "string"
    }
  ],
  "follow_up_question": "string (If ambiguous)",
  "suggested_actions": ["array of strings"]
}

DUPLICATE & AMBIGUITY HANDLING:
- If user input matches a 'Known Product' but the unit is different (e.g. User: 'Kg', DB: 'Bal'), extract the RAW unit. Let backend handle conversion.
- If multiple products match (e.g. 'Alpukat'), ask: "Alpukat yang mana? Mentega atau Biasa?".
"""

def normalize_item_data(item, product_context=None):
    """
    Fungsi 'Otak Kiri' (Logika Python) untuk menangani Matematika & Konversi.
    AI (Otak Kanan) hanya ekstrak teks, Python yang menghitung.
    """
    raw_unit = item['unit'].lower().strip()
    qty = float(item['qty'])
    
    # 1. Cek Satuan Standar (Global)
    if raw_unit in STANDARD_UNITS:
        # Konversi ke Base Unit (biasanya Kg atau Pcs)
        converted_qty = qty * STANDARD_UNITS[raw_unit]
        item['notes'] = f"Konversi Otomatis: {qty} {raw_unit} = {converted_qty} (Base Unit)"
        item['qty'] = converted_qty
        # Kita asumsikan output standar adalah 'kg' utk berat, 'pcs' utk jumlah
        # Tapi idealnya ini dicek lagi tipe produknya. Untuk aman, kita biarkan unit asli
        # atau ubah jika kamu punya standar baku 'kg' di DB.
        # item['unit'] = 'kg' if raw_unit in ['ton','kwintal','ons'] else 'pcs'
    
    # 2. Cek Satuan Dinamis Berdasarkan Produk (RAG)
    elif product_context:
        # Cari produk yang cocok di context
        best_match = None
        highest_score = 0
        
        for prod in product_context:
            score = fuzz.ratio(item['product_name'].lower(), prod['name'].lower())
            if score > 80 and score > highest_score:
                highest_score = score
                best_match = prod
        
        # Jika ketemu produknya, cek conversion_rules-nya
        if best_match and 'conversion_rules' in best_match:
            rules = best_match['conversion_rules'] # Contoh: {"karung": 30, "bal": 20}
            # Cek apakah unit user (misal "karung") ada di rules
            if raw_unit in rules:
                conversion_factor = float(rules[raw_unit])
                converted_qty = qty * conversion_factor
                item['notes'] = f"Konversi Produk: {qty} {raw_unit} @ {conversion_factor} = {converted_qty} {best_match.get('base_unit', 'unit')}"
                item['qty'] = converted_qty
                item['unit'] = best_match.get('base_unit', 'pcs') # Ubah ke base unit DB

    return item

async def check_duplicates_logic(ai_json, current_draft):
    """
    Logic Python untuk cek duplikat. Lebih akurat daripada menyuruh AI.
    """
    if ai_json['action'] not in ['new', 'append']:
        return ai_json

    new_items_processed = []
    
    for new_item in ai_json['items']:
        is_duplicate = False
        if current_draft and 'items' in current_draft:
            for idx, existing in enumerate(current_draft['items']):
                # Fuzzy match nama produk
                similarity = fuzz.ratio(new_item['product_name'].lower(), existing['product_name'].lower())
                
                if similarity > 85: # Ambang batas kemiripan
                    is_duplicate = True
                    # Kita INTERUPSI respon AI
                    return {
                        "action": "chat",
                        "supplier_name": ai_json.get('supplier_name'),
                        "transaction_date": ai_json.get('transaction_date'),
                        "items": [], # Jangan masukkan item dulu
                        "follow_up_question": f"Sudah ada '{existing['product_name']}' ({existing['qty']} {existing['unit']}) di draft. Mau ditambahkan ke qty yang ada, atau buat baris baru?",
                        "suggested_actions": ["Tambah ke Qty", "Buat Baris Baru"],
                        # Simpan data sementara di memory/frontend (hidden field) bisa ditangani nanti
                        "confidence_score": 1.0
                    }
        
        if not is_duplicate:
            new_items_processed.append(new_item)
            
    ai_json['items'] = new_items_processed
    return ai_json

# ==========================================
# 🚀 MAIN SERVICE FUNCTIONS
# ==========================================

async def parse_procurement_text(text_input: str, current_draft: dict = None, known_products: list = None):
    """
    known_products: List of dict dari DB [{'name': 'Alpukat', 'base_unit': 'kg', 'conversion_rules': {'karung': 30}}]
    """
    try:
        # 1. RAG: Bangun Context String dari Known Products
        rag_context = ""
        if known_products:
            product_list_str = "\n".join([f"- {p['name']} (Base: {p['base_unit']}, Rules: {json.dumps(p.get('conversion_rules', {}))})" for p in known_products])
            rag_context = f"\nKNOWN PRODUCTS IN DATABASE (Use these details if matching):\n{product_list_str}\n"

        # 2. Draft Context
        draft_context = ""
        if current_draft:
            draft_context = f"\nCURRENT_DRAFT:\n{json.dumps(current_draft, ensure_ascii=False)}\n"
        
        # 3. Call AI
        completion = client.chat.completions.create(
            model=GROQ_TEXT_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": BASE_SYSTEM_PROMPT + rag_context
                },
                {
                    "role": "user",
                    "content": f"{draft_context}USER INPUT:\n{text_input}"
                }
            ],
            temperature=0,
            response_format={"type": "json_object"}
        )
        
        result_content = completion.choices[0].message.content
        ai_response = json.loads(result_content)
        
        # 4. Post-Processing (Python Logic)
        # a. Normalisasi Matematika & Satuan Dinamis
        for item in ai_response.get('items', []):
            normalize_item_data(item, product_context=known_products)
            
        # b. Cek Duplikat (Hanya jika action new/append)
        final_response = await check_duplicates_logic(ai_response, current_draft)
        
        return final_response
        
    except Exception as e:
        print(f"Error Groq Text Parsing: {e}")
        return {
            "action": "chat",
            "follow_up_question": "Maaf, ada kesalahan sistem saat memproses pesan. Bisa ulangi?",
            "items": [],
            "confidence_score": 0.0
        }

async def parse_procurement_image(image_bytes, current_draft: dict = None, known_products: list = None):
    try:
        base64_image = base64.b64encode(image_bytes).decode('utf-8')
        
        # RAG Context untuk Image juga
        rag_context = ""
        if known_products:
            # Batasi context untuk gambar agar tidak token limit (ambil nama saja)
            names_only = ", ".join([p['name'] for p in known_products[:50]]) 
            rag_context = f"\nPossible Product Matches: {names_only}\n"

        draft_context = ""
        if current_draft:
            draft_context = f"CURRENT_DRAFT:\n{json.dumps(current_draft, ensure_ascii=False)}\n\n"
        
        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "system", 
                    "content": BASE_SYSTEM_PROMPT + rag_context
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": f"{draft_context}ANALYZE THIS RECEIPT IMAGE:"},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}",
                            },
                        },
                    ],
                }
            ],
            model=GROQ_VISION_MODEL,
            temperature=0,
            response_format={"type": "json_object"}
        )

        result_content = chat_completion.choices[0].message.content
        ai_response = json.loads(result_content)
        
        # Post-Processing yang sama
        for item in ai_response.get('items', []):
            normalize_item_data(item, product_context=known_products)
            
        final_response = await check_duplicates_logic(ai_response, current_draft)
        
        return final_response
        
    except Exception as e:
        print(f"Error Groq Image Parsing: {e}")
        return {
            "action": "chat",
            "follow_up_question": "Gagal membaca gambar. Pastikan gambar jelas.",
            "items": [], 
            "confidence_score": 0.0
        }