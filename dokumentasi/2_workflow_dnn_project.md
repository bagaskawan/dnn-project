# Workflow & Alur Kerja — DNN Project

## AI-Powered Inventory & POS System

---

## 1. Arsitektur Sistem (High-Level)

```
┌─────────────────────────────────────────────────────────────────────┐
│                          PENGGUNA (User)                            │
│           Pemilik Bisnis · Admin/Kasir · Staf Gudang                │
└─────────────┬───────────────────────────────────┬───────────────────┘
              │                                   │
      ┌───────▼──────────┐               ┌───────▼──────────┐
      │   Web Dashboard  │               │   Mobile App     │
      │   (Next.js 16)   │               │   (Flutter)      │
      │    React · TW4   │               │   Android/iOS    │
      └───────┬──────────┘               └───────┬──────────┘
              │            HTTP/REST              │
              └───────────────┬───────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │   Backend API     │
                    │   (FastAPI)       │
                    │   Python · Async  │
                    └───┬─────────┬─────┘
                        │         │
            ┌───────────▼──┐  ┌───▼──────────────┐
            │  PostgreSQL  │  │  Groq AI (LLM)   │
            │  (Database)  │  │  + EasyOCR        │
            └──────────────┘  └──────────────────-┘
```

---

## 2. Struktur Proyek (Project Structure)

```
dnn-project/
├── backend/                   # Backend API (FastAPI + Python)
│   ├── .env                   # Konfigurasi environment (DB, API keys)
│   ├── requirements.txt       # Dependensi Python
│   └── app/
│       ├── main.py            # Entry point, semua API endpoints (~30 endpoint)
│       ├── config.py          # Konfigurasi model AI (Groq)
│       ├── schemas.py         # Pydantic schemas (request/response models)
│       └── services/
│           ├── ai_service.py      # Logika AI: OCR, NLP parsing, fuzzy matching
│           └── commit_service.py  # Logika transaksi DB: upsert, stock ledger
│
├── web/                       # Web Dashboard (Next.js 16 + React)
│   ├── package.json           # Dependensi Node.js
│   └── src/
│       ├── app/               # App Router (pages & layouts)
│       │   ├── (auth)/login/  # Halaman Login
│       │   └── (dashboard)/   # Dashboard Layout + Halaman-halaman
│       │       ├── dashboard/         # 📊 Ringkasan bisnis
│       │       ├── products/          # 📦 Manajemen produk + detail
│       │       ├── inventory/         # 📋 Stock ledger + opname
│       │       ├── transaction/       # 💰 Riwayat transaksi
│       │       ├── contacts/          # 👥 Pelanggan & Supplier
│       │       ├── financial/         # 💵 Laporan keuangan
│       │       ├── reports/           # 📈 Laporan P&L, Stock Flow
│       │       └── settings/users/    # ⚙️ Manajemen user
│       ├── components/        # Komponen React (features/ + layout/ + ui/)
│       ├── services/          # Service layer (API calls ke backend)
│       ├── types/             # TypeScript type definitions
│       ├── hooks/             # Custom React hooks
│       └── lib/               # Utilities, formatters, constants
│
├── mobile/                    # Aplikasi Mobile (Flutter)
│   └── lib/
│       ├── main.dart          # Entry point Flutter
│       ├── core/              # Router, API Service, Theme, Constants
│       ├── features/          # Fitur-fitur: Home, Buy, Sale, Product, dll.
│       ├── models/            # Data models (ProcurementDraft, SaleDraft)
│       └── shared/widgets/    # Shared UI (Bottom Nav Bar, Main Shell)
│
├── dokumentasi/               # Dokumentasi proyek
└── structure-database.sql     # Skema database (referensi)
```

---

## 3. Skema Database (Entity-Relationship)

```mermaid
erDiagram
    users ||--o{ transactions : "created_by"
    users ||--o{ stock_ledger : "created_by"
    contacts ||--o{ transactions : "contact_id"
    transactions ||--|{ transaction_items : "transaction_id"
    transactions ||--o{ stock_ledger : "transaction_id"
    products ||--|{ transaction_items : "product_id"
    products ||--o{ stock_ledger : "product_id"

    users {
        uuid id PK
        varchar username UK
        varchar full_name
        enum role "ADMIN / STAFF"
        text password_hash
        text biometric_token
        boolean is_active
    }

    contacts {
        uuid id PK
        varchar name
        enum type "CUSTOMER / SUPPLIER"
        varchar phone
        text address
        text notes
    }

    products {
        uuid id PK
        varchar sku UK
        varchar name
        varchar variant
        varchar category
        varchar base_unit "default: pcs"
        numeric current_stock
        numeric average_cost
        numeric latest_selling_price
        jsonb conversion_rules
    }

    transactions {
        uuid id PK
        enum type "IN (Pengadaan) / OUT (Penjualan)"
        uuid contact_id FK
        timestamp transaction_date
        varchar invoice_number UK
        numeric total_amount
        varchar payment_method
        varchar input_source "MANUAL / OCR / CHAT"
        text evidence_url
        uuid created_by FK
    }

    transaction_items {
        uuid id PK
        uuid transaction_id FK
        uuid product_id FK
        numeric input_qty
        varchar input_unit
        numeric input_price
        numeric conversion_rate
        numeric base_qty "calculated"
        numeric cost_price_at_moment
        numeric subtotal "calculated"
        text notes
    }

    stock_ledger {
        bigint id PK
        uuid product_id FK
        uuid transaction_id FK
        enum type "IN / OUT"
        numeric qty_change
        numeric stock_after
        text notes
        uuid created_by FK
    }
```

---

## 4. Alur Kerja Utama (Core Workflows)

### 4.1. Workflow: AI Smart Entry — Pengadaan via Chat

Alur input transaksi pengadaan (barang masuk) menggunakan teks natural language.

```mermaid
sequenceDiagram
    actor User as 👤 User
    participant FE as 📱 Frontend (Web/Mobile)
    participant API as ⚙️ FastAPI Backend
    participant AI as 🤖 Groq AI (LLM)
    participant DB as 🗄️ PostgreSQL

    User->>FE: Ketik pesan, misal:<br/>"Beli 10 kardus Indomie 100rb dari Toko A"
    FE->>API: POST /api/v1/parse-text<br/>{new_message, current_draft}
    API->>DB: Query known_products & known_suppliers
    API->>AI: Kirim prompt + konteks produk DB (RAG)
    AI-->>API: JSON ProcurementDraft<br/>{supplier, items[], total, confidence}

    Note over API: Post-processing:<br/>1. Fuzzy match nama produk<br/>2. Validasi items<br/>3. Cek duplikasi supplier<br/>4. Cek duplikasi draft items

    API-->>FE: ProcurementDraft response
    FE-->>User: Tampilkan draft preview

    alt User setuju
        User->>FE: Klik "Simpan"
        FE->>API: POST /api/v1/commit-transaction
        API->>DB: BEGIN TRANSACTION
        Note over API,DB: 1. Upsert Contact (Supplier)<br/>2. Create Transaction header (type=IN)<br/>3. Loop items:<br/>   a. Upsert Product<br/>   b. Hitung Average Cost baru<br/>   c. Create Transaction Item<br/>   d. Update current_stock<br/>   e. Record Stock Ledger
        API->>DB: COMMIT
        API-->>FE: CommitTransactionResponse ✅
    else User koreksi
        User->>FE: Kirim pesan koreksi<br/>"Ubah qty Indomie jadi 15"
        FE->>API: POST /api/v1/parse-text<br/>{new_message, current_draft: draft_sebelumnya}
        Note over API: AI menerima konteks draft lama,<br/>melakukan action: "update"
        API-->>FE: Updated ProcurementDraft
    end
```

---

### 4.2. Workflow: AI Smart Entry — Pengadaan via Scan Struk (OCR)

Alur input transaksi dengan scan gambar struk/nota fisik.

```mermaid
sequenceDiagram
    actor User as 👤 User
    participant FE as 📱 Frontend
    participant API as ⚙️ Backend
    participant OCR as 👁️ EasyOCR
    participant AI as 🤖 Groq Vision LLM
    participant DB as 🗄️ PostgreSQL

    User->>FE: Upload foto struk belanja
    FE->>API: POST /api/v1/parse-image<br/>(multipart/form-data: file)

    API->>OCR: Step 1: Ekstrak teks dari gambar
    OCR-->>API: Raw text (grouped by baris)

    API->>DB: Query known_products (untuk RAG)
    API->>AI: Step 2: Kirim raw text + daftar produk DB
    Note over AI: LLM mem-parsing teks struk:<br/>- Nama toko/supplier<br/>- Nomor struk<br/>- Daftar produk + qty + harga<br/>- Diskon, total, metode bayar

    AI-->>API: JSON ProcurementDraft

    Note over API: Post-processing:<br/>1. Fuzzy match koreksi nama produk<br/>2. Validasi items (harga, qty, unit)<br/>3. Cek duplikasi supplier

    API-->>FE: ProcurementDraft response
    FE-->>User: Tampilkan draft preview untuk review

    User->>FE: Konfirmasi / koreksi via chat
    Note over FE,API: Selanjutnya sama seperti<br/>Workflow 4.1 (commit/koreksi)
```

**Pipeline OCR 2 Langkah:**

1. **EasyOCR** → Ekstraksi teks mentah dengan pengelompokan baris (row grouping berdasarkan Y-coordinate)
2. **Text LLM + RAG** → Parsing teks mentah menjadi data terstruktur, dengan pencocokan cerdas terhadap database produk

---

### 4.3. Workflow: Penjualan (Sales)

Alur pencatatan penjualan (barang keluar).

```mermaid
sequenceDiagram
    actor User as 👤 User
    participant FE as 📱 Frontend
    participant API as ⚙️ Backend
    participant AI as 🤖 Groq AI
    participant DB as 🗄️ PostgreSQL

    User->>FE: Ketik pesan penjualan, misal:<br/>"Jual 3 Indomie ke Pak Budi"
    FE->>API: POST /api/v1/parse-sale<br/>{new_message, current_draft}
    API->>DB: Query known_products (harga jual terbaru)
    API->>AI: Kirim prompt penjualan + konteks produk
    AI-->>API: JSON SaleDraft<br/>{customer, items[], total}
    API-->>FE: SaleDraft response
    FE-->>User: Tampilkan draft penjualan

    User->>FE: Klik "Simpan Penjualan"
    FE->>API: POST /api/v1/commit-sale
    API->>DB: BEGIN TRANSACTION
    Note over API,DB: 1. Upsert Contact (Customer)<br/>2. Create Transaction header (type=OUT)<br/>3. Loop items:<br/>   a. Find Product (by name+variant)<br/>   b. Hitung subtotal (qty × selling_price)<br/>   c. Record cost_price_at_moment (HPP snapshot)<br/>   d. Create Transaction Item<br/>   e. Kurangi current_stock<br/>   f. Record Stock Ledger (OUT)
    API->>DB: COMMIT
    API-->>FE: CommitTransactionResponse ✅
```

**Perbedaan kunci antara Pengadaan vs Penjualan:**

| Aspek          | Pengadaan (IN)             | Penjualan (OUT)                 |
| -------------- | -------------------------- | ------------------------------- |
| Tipe Transaksi | `IN`                       | `OUT`                           |
| Kontak         | Supplier                   | Customer                        |
| Harga Acuan    | `input_price` (harga beli) | `latest_selling_price`          |
| Efek Stok      | `+qty` (stok bertambah)    | `-qty` (stok berkurang)         |
| Average Cost   | Di-recalculate             | Snapshot `cost_price_at_moment` |

---

### 4.4. Workflow: Manajemen Produk

```mermaid
flowchart TD
    A[Halaman Daftar Produk] --> B{Aksi?}
    B -->|Tambah| C[Add Product Modal]
    B -->|Lihat Detail| D[Product Detail Page]
    B -->|Filter| E[Filter: All / Low Stock / Out of Stock]

    C -->|POST /products| F[(Database)]

    D --> G[Info Produk: Nama, SKU, Stok, Harga, Average Cost]
    D --> H[Stock History / Ledger]
    D --> I{Aksi Detail?}

    I -->|Edit| J[Edit Product Modal]
    I -->|Tambah Stok| K[Add Stock Modal]
    I -->|Recalculate| L[Recalculate Average Cost]

    J -->|PUT /products/:id| F
    K -->|POST /products/:id/stock| F
    L -->|POST /products/:id/recalculate| F

    K --> M[Auto: Create Transaction IN +<br/>Update current_stock +<br/>Recalculate average_cost +<br/>Record Stock Ledger]
```

**Detail Alur Tambah Stok Manual:**

1. User mengisi form: Qty, Supplier, Total Harga Beli
2. Backend melakukan:
   - Upsert kontak supplier
   - Buat transaksi header (`type=IN`)
   - Hitung `average_cost` baru: `(old_stock × old_avg + new_qty × new_price) / (old_stock + new_qty)`
   - Update `current_stock` produk
   - Catat di `stock_ledger`
3. Semua dalam satu database transaction (atomik)

---

### 4.5. Workflow: RAG & Fuzzy Matching (Deduplikasi Produk)

Sistem mencegah duplikasi produk dengan mekanisme pencocokan cerdas.

```mermaid
flowchart TD
    A[Input AI: Nama produk dari struk/chat] --> B[Query database produk]
    B --> C[Fuzzy Matching<br/>fuzzywuzzy library]

    C --> D{Similarity Score}
    D -->|≥ 85%| E[✅ Auto-match:<br/>Gunakan produk yang ada]
    D -->|70-84%| F[⚠️ Konfirmasi user:<br/>Apakah ini produk yang sama?]
    D -->|< 70%| G[🆕 Buat produk baru]

    F -->|Ya| E
    F -->|Tidak| G

    E --> H[Gunakan product_id yang ada]
    G --> I[Generate SKU baru + insert produk]

    H --> J[Lanjut ke commit transaksi]
    I --> J
```

**Mekanisme Pencocokan:**

- **Exact Match**: Nama + Varian sama persis → langsung gunakan
- **Fuzzy Match**: Menggunakan `fuzzywuzzy` (Token Sort Ratio) → threshold 70%
- **RAG Context**: Daftar produk DB dikirim sebagai konteks ke LLM agar AI bisa mengenali produk yang sudah ada
- **Supplier Matching**: Logika serupa diterapkan untuk nama supplier (cek duplikasi kontak)

---

### 4.6. Workflow: Dashboard & Reporting

```mermaid
flowchart LR
    subgraph Dashboard
        A[Summary Cards] --> A1[Total Pendapatan Bulan Ini]
        A --> A2[Total Pembelian Bulan Ini]
        A --> A3[Estimasi Profit Hari Ini]
        A --> A4[Jumlah Transaksi Hari Ini]
        B[Revenue Chart] --> B1[Grafik 7 Hari: Sales vs Purchase]
        C[Low Stock Alert] --> C1[Tabel produk stok ≤ 5]
        D[Recent Transactions] --> D1[Tabel transaksi terakhir]
    end

    subgraph Reports
        E[Profit & Loss] --> E1[Revenue - COGS = Gross Profit]
        F[Stock Flow] --> F1[Mutasi stok per produk per periode]
    end

    subgraph Financial
        G[Laporan Laba Rugi] --> G1[Filter berdasarkan periode]
        G1 --> G2[Revenue: Sum OUT transactions]
        G1 --> G3[COGS: Sum cost_price_at_moment × qty]
        G1 --> G4[Gross Profit = Revenue - COGS]
    end
```

**Kalkulasi Keuangan:**

- **Revenue** = Total semua transaksi `OUT` (penjualan)
- **COGS (HPP)** = Σ(`cost_price_at_moment` × `base_qty`) dari semua item terjual
- **Gross Profit** = Revenue - COGS
- **Average Cost** = `(Stok Lama × HPP Lama + Qty Baru × Harga Beli Baru) / Total Stok`

---

## 5. API Endpoints Reference

### 5.1. AI & Parsing

| Method | Endpoint                      | Deskripsi                                      |
| ------ | ----------------------------- | ---------------------------------------------- |
| `POST` | `/api/v1/parse-text`          | Parse teks natural language → ProcurementDraft |
| `POST` | `/api/v1/parse-sale`          | Parse teks penjualan → SaleDraft               |
| `POST` | `/api/v1/parse-image`         | OCR scan struk → ProcurementDraft              |
| `GET`  | `/api/v1/search-products?q=`  | Autocomplete pencarian produk                  |
| `GET`  | `/api/v1/match-product?name=` | RAG: Cari produk mirip (fuzzy)                 |

### 5.2. Transaksi

| Method | Endpoint                     | Deskripsi                                     |
| ------ | ---------------------------- | --------------------------------------------- |
| `POST` | `/api/v1/commit-transaction` | Commit transaksi pengadaan (IN)               |
| `POST` | `/api/v1/commit-sale`        | Commit transaksi penjualan (OUT)              |
| `GET`  | `/api/v1/transactions`       | Daftar transaksi (filter: type, date, search) |
| `GET`  | `/api/v1/transactions/stats` | Statistik transaksi (count, sum IN/OUT)       |
| `GET`  | `/api/v1/transactions/{id}`  | Detail transaksi + items                      |

### 5.3. Produk

| Method | Endpoint                            | Deskripsi                                            |
| ------ | ----------------------------------- | ---------------------------------------------------- |
| `GET`  | `/api/v1/products`                  | Daftar produk (filter: all, low_stock, out_of_stock) |
| `GET`  | `/api/v1/products/stats`            | Statistik produk (total, low, out)                   |
| `POST` | `/api/v1/products`                  | Buat produk baru                                     |
| `GET`  | `/api/v1/products/{id}`             | Detail produk                                        |
| `PUT`  | `/api/v1/products/{id}`             | Update produk                                        |
| `POST` | `/api/v1/products/{id}/stock`       | Tambah stok manual                                   |
| `GET`  | `/api/v1/products/{id}/history`     | Riwayat stok (stock ledger)                          |
| `POST` | `/api/v1/products/{id}/recalculate` | Recalculate average cost                             |

### 5.4. Kontak

| Method | Endpoint                      | Deskripsi                            |
| ------ | ----------------------------- | ------------------------------------ |
| `GET`  | `/api/v1/contacts/summary`    | Ringkasan jumlah customer & supplier |
| `GET`  | `/api/v1/contacts`            | Daftar kontak (filter: type)         |
| `POST` | `/api/v1/contacts`            | Buat kontak baru                     |
| `PUT`  | `/api/v1/contacts/{id}`       | Update kontak                        |
| `GET`  | `/api/v1/contacts/{id}/stats` | Statistik transaksi per kontak       |

### 5.5. Inventaris & Keuangan

| Method | Endpoint                        | Deskripsi                       |
| ------ | ------------------------------- | ------------------------------- |
| `GET`  | `/api/v1/inventory/ledger`      | Stock ledger global (paginated) |
| `GET`  | `/api/v1/financial/profit-loss` | Laporan Laba Rugi per periode   |

### 5.6. Dashboard

| Method | Endpoint                    | Deskripsi                                    |
| ------ | --------------------------- | -------------------------------------------- |
| `GET`  | `/api/v1/dashboard/summary` | Ringkasan bisnis (pendapatan, profit, count) |
| `GET`  | `/api/v1/dashboard/chart`   | Data grafik 7 hari (sales vs purchase)       |

---

## 6. Alur Data (Data Flow) — Commit Transaksi

Flowchart detail yang terjadi saat transaksi di-commit ke database:

```mermaid
flowchart TD
    START([Endpoint: commit-transaction / commit-sale]) --> A

    A[1. Parse & Validasi Input] --> B[2. Upsert Contact]
    B --> B1{Contact sudah ada?}
    B1 -->|Ya, by name| B2[Update phone/address jika lebih lengkap]
    B1 -->|Tidak| B3[Insert contact baru]
    B2 --> C
    B3 --> C

    C[3. Generate Invoice Number<br/>Format: INV-YYYYMMDD-XXXX] --> D
    D[4. Create Transaction Header] --> E

    E[5. Loop setiap Item] --> F{Tipe?}
    F -->|Pengadaan IN| G[Upsert Product]
    F -->|Penjualan OUT| H[Find Product by name+variant]

    G --> G1[Hitung Average Cost Baru:<br/>old_stock × old_avg + new_qty × new_price<br/>÷ old_stock + new_qty]
    G1 --> G2[Update current_stock += qty]

    H --> H1[Snapshot cost_price_at_moment<br/>= average_cost saat ini]
    H1 --> H2[Update current_stock -= qty]

    G2 --> I
    H2 --> I

    I[6. Create Transaction Item] --> J
    J[7. Record Stock Ledger Entry] --> K{Item berikutnya?}
    K -->|Ya| E
    K -->|Tidak| L([Return Success ✅])
```

---

## 7. Tech Stack Detail

| Layer               | Teknologi           | Versi   | Kegunaan                            |
| ------------------- | ------------------- | ------- | ----------------------------------- |
| **Frontend Web**    | Next.js             | 16.1.6  | Framework React (App Router, SSR)   |
|                     | React               | 19.2.3  | UI Library                          |
|                     | Tailwind CSS        | 4       | Styling (utility-first)             |
|                     | Recharts            | 3.7.0   | Visualisasi grafik dashboard        |
|                     | Lucide React        | 0.575.0 | Icon library                        |
|                     | next-themes         | 0.4.6   | Dark/Light mode toggle              |
| **Frontend Mobile** | Flutter             | Latest  | Cross-platform mobile framework     |
|                     | Dio                 | -       | HTTP client untuk REST API          |
| **Backend**         | FastAPI             | Latest  | Python web framework (async)        |
|                     | Uvicorn             | Latest  | ASGI server                         |
|                     | Pydantic            | Latest  | Validasi data & schema              |
| **AI / NLP**        | Groq API            | Latest  | LLM inference (text & vision)       |
|                     | EasyOCR             | Latest  | Ekstraksi teks dari gambar          |
|                     | FuzzyWuzzy          | Latest  | Pencocokan teks fuzzy (deduplikasi) |
|                     | python-Levenshtein  | Latest  | Akselerasi algoritma fuzzy          |
| **Database**        | PostgreSQL          | Latest  | Database utama (relational)         |
|                     | databases (asyncpg) | Latest  | Async database driver               |

---

## 8. Cara Menjalankan Proyek (Development)

### 8.1. Backend

```bash
cd backend
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

**Environment Variables** (`.env`):

```
DATABASE_URL=postgresql://user:pass@host:port/dbname
GROQ_API_KEY=gsk_xxxxx
```

### 8.2. Web Dashboard

```bash
cd web
npm install
npm run dev
```

Akses di: `http://localhost:3000`

### 8.3. Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

---

## 9. Mapping Halaman Web ↔ API Endpoint

| Halaman Web        | Route                 | Service Layer            | API Endpoint                                     |
| ------------------ | --------------------- | ------------------------ | ------------------------------------------------ |
| Dashboard          | `/dashboard`          | `dashboard.service.ts`   | `GET /dashboard/summary`, `GET /dashboard/chart` |
| Products           | `/products`           | `product.service.ts`     | `GET /products`, `GET /products/stats`           |
| Product Detail     | `/products/[id]`      | `product.service.ts`     | `GET /products/:id`, `GET /products/:id/history` |
| Create Product     | `/products/create`    | `product.service.ts`     | `POST /products`                                 |
| Transactions       | `/transaction`        | `transaction.service.ts` | `GET /transactions`, `GET /transactions/stats`   |
| Contacts           | `/contacts`           | `contact.service.ts`     | `GET /contacts`, `GET /contacts/summary`         |
| Inventory          | `/inventory`          | `inventory.service.ts`   | `GET /inventory/ledger`                          |
| Inventory Ledger   | `/inventory/ledger`   | `inventory.service.ts`   | `GET /inventory/ledger`                          |
| Financial          | `/financial`          | `financial.service.ts`   | `GET /financial/profit-loss`                     |
| Reports P&L        | `/reports/pnl`        | `financial.service.ts`   | `GET /financial/profit-loss`                     |
| Reports Stock Flow | `/reports/stock-flow` | `inventory.service.ts`   | `GET /inventory/ledger`                          |
| Settings Users     | `/settings/users`     | —                        | —                                                |
| Login              | `/login`              | —                        | —                                                |

---

## 10. Pola Arsitektur Frontend

### Web (Next.js)

```
Page (app/(dashboard)/xxx/page.tsx)
  └── Memanggil Service Layer (services/xxx.service.ts)
        └── HTTP fetch ke Backend API (localhost:8000/api/v1/...)
              └── Return typed data (types/xxx.ts)
                    └── Render ke Feature Components (components/features/xxx/...)
```

**Layer:**

1. **Pages** → Route handler (data fetching, state management)
2. **Services** → API calls (fetch, error handling)
3. **Types** → TypeScript interfaces untuk API response/request
4. **Components** → UI rendering (tabel, form, modal, kartu)
5. **Hooks** → Reusable stateful logic
6. **Lib** → Utility functions (formatting Rupiah, tanggal, dll)

### Mobile (Flutter)

```
Page (features/xxx/xxx_page.dart)
  └── Memanggil ApiService (core/services/api_service.dart)
        └── HTTP (Dio) ke Backend API
              └── Return parsed Model (models/xxx.dart)
                    └── Render ke Widget
```

---

_Dokumen ini di-generate otomatis berdasarkan analisis menyeluruh terhadap kode sumber proyek DNN Project._
_Terakhir diperbarui: 28 Februari 2026._
