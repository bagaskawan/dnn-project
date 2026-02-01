from contextlib import asynccontextmanager
import databases
import os
import json
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from app.schemas import ProcurementDraft, ChatInput
from app.services.ai_service import parse_procurement_text, parse_procurement_image

# Load environment variables dari file .env
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("WARNING: DATABASE_URL not found in .env!")
else:
    if "prepared_statement_cache_size" not in DATABASE_URL:
        separator = "&" if "?" in DATABASE_URL else "?"
        DATABASE_URL += f"{separator}prepared_statement_cache_size=0"

database = databases.Database(DATABASE_URL)

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