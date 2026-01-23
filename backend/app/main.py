from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from app.schemas import ProcurementDraft, ChatInput
from app.services.ai_service import parse_procurement_text, parse_procurement_image

# Load environment variables dari file .env
load_dotenv()

app = FastAPI(
    title="DNN Project API",
    description="Backend API untuk DNN Project dengan integrasi Groq AI",
    version="1.0.0"
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
    return {"message": "DNN Project API is running!", "status": "ok"}


@app.get("/health")
async def health_check():
    """Health check untuk monitoring."""
    return {"status": "healthy"}

# 1. Endpoint untuk Chat Teks (dengan context)
@app.post("/api/v1/parse/text", response_model=ProcurementDraft)
async def parse_text_endpoint(chat: ChatInput):
    result = await parse_procurement_text(chat.text, chat.current_draft)
    if not result:
        raise HTTPException(status_code=500, detail="AI gagal memproses data")
    return result

# 2. Endpoint untuk Upload Gambar Struk
@app.post("/api/v1/parse/image", response_model=ProcurementDraft)
async def parse_image_endpoint(file: UploadFile = File(...)):
    # Baca file gambar
    image_bytes = await file.read()
    
    result = await parse_procurement_image(image_bytes)
    if not result:
        raise HTTPException(status_code=500, detail="AI gagal membaca gambar")
    return result