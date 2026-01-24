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
    # A. Ambil Known Products dari DB (RAG Context)
    known_products = []
    try:
        # Kita ambil nama, satuan dasar, dan rules konversinya
        query = "SELECT name, base_unit, conversion_rules FROM products"
        rows = await database.fetch_all(query=query)
        # Convert ke format dictionary
        known_products = [dict(row) for row in rows]
        # Decode JSONB conversion_rules jika perlu (tergantung driver, biasanya otomatis)
        for p in known_products:
            if isinstance(p['conversion_rules'], str):
                p['conversion_rules'] = json.loads(p['conversion_rules'])
                
    except Exception as e:
        print(f"⚠️ RAG Warning: Gagal ambil produk dari DB ({e}). AI akan jalan tanpa konteks produk.")
        # Jangan crash, lanjut saja dengan list kosong
        known_products = []

    # B. Panggil AI Service
    result = await parse_procurement_text(
        text_input=chat_data.new_message,
        current_draft=chat_data.current_draft,
        known_products=known_products
    )
    
    return result

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