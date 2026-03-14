# Business and Product Requirement Document (BPRD)

## Project Name: DNN Project (AI-Powered Inventory & POS System)

---

## 1. Executive Summary

DNN Project adalah sistem Enterprise Resource Planning (ERP) dan Point of Sales (POS) berskala ringan yang dirancang khusus untuk mempermudah operasional bisnis jual-beli. Keunggulan utama (Unique Selling Proposition) dari sistem ini adalah penggunaan kecerdasan buatan (AI) terintegrasi menggunakan LLM/Groq AI untuk melakukan _data entry_ secara otomatis, baik melalui ekstraksi gambar struk nota fisik (OCR) maupun _natural language chat_. Sistem ini mencakup manajemen inventaris, pencatatan transaksi masuk (pengadaan) dan keluar (penjualan), manajemen kontak (pelanggan & supplier), serta pelaporan keuangan (Laba/Rugi).

## 2. Project Objectives

- **Automasi Data Entry**: Mempercepat proses pencatatan pengadaan dan penjualan dengan meminimalisir input manual menggunakan pemrosesan bahasa alami (NLP) dan AI Vision.
- **Manajemen Stok Real-Time**: Memberikan visibilitas langsung terhadap ketersediaan barang, riwayat mutasi stok, serta memberikan peringatan dini untuk stok menipis (Low Stock) dan stok habis (Out of Stock).
- **Rekonsiliasi Keuangan Akurat**: Memungkinkan pemilik bisnis untuk langsung melihat kalkulasi Laba/Rugi (Profit & Loss) berdasarkan Harga Pokok Penjualan (HPP/Average Cost) secara real-time.
- **Manajemen Hubungan Pelanggan & Pemasok**: Mengelola data pelanggan dan _supplier_ secara terpusat untuk analisis transaksi.

## 3. User Personas

1. **Pemilik Bisnis (Business Owner)**: Membutuhkan ringkasan dashboard, laporan laba/rugi, dan kesehatan stok untuk mengambil keputusan strategis.
2. **Admin / Kasir**: Pengguna sehari-hari yang melakukan input transaksi penjualan dan pengadaaan stok. Menginginkan proses input yang cepat (menggunakan fitur _scan struk_ atau _chat bot_).
3. **Staf Gudang (Inventory Manager)**: Bertanggung jawab atas ketersediaan barang, memantau _stock ledger_, dan melakukan _stock opname_.

## 4. Scope of Work (Ruang Lingkup)

### In-Scope

- Web-based Dashboard (Next.js, React, Tailwind CSS).
- Backend Rest API (FastAPI, Python, PostgreSQL).
- Modul AI Smart Entry (Image to Text OCR & Natural Language to Transaction Draft).
- Modul Manajemen Produk & Stok.
- Modul Manajemen Transaksi (Pengadaan dan Penjualan).
- Modul Manajemen Kontak (Customer & Supplier).
- Laporan Keuangan Dasar (Laba Rugi).

### Out-of-Scope

- Integrasi _Payment Gateway_ untuk pembayaran online pelanggan.
- Aplikasi Mobile Native (iOS/Android).
- Modul HR / Penggajian Karyawan.

---

## 5. Functional Requirements (Kebutuhan Fungsional)

### 5.1. Dashboard & Analytics

- **FR.DASH.01**: Sistem harus menampilkan ringkasan performa bisnis (Total Pendapatan, Transaksi, dll).
- **FR.DASH.02**: Sistem harus menampilkan grafik (_charts_) penjualan dan tren keuangan.
- **FR.DASH.03**: Sistem harus memberikan indikator peringatan untuk barang-barang yang stoknya menipis atau habis.

### 5.2. AI Smart Entry (Core Feature)

- **FR.AI.01 (Image OCR)**: Sistem dapat menerima unggahan gambar struk belanja/nota pengadaan dan mengekstrak data item, kuantitas, harga, dan total menggunakan AI.
- **FR.AI.02 (Text Chat)**: Sistem dapat menerima input teks alami (contoh: _"Saya baru beli 10 kardus Indomie seharga 100rb dari Toko A"_) dan mengubahnya menjadi draf transaksi terstruktur.
- **FR.AI.03 (RAG & Deduplication)**: AI dapat mengenali dan mencocokkan produk yang disebutkan di struk/chat dengan _database_ produk yang sudah ada (menggunakan algoritma _Fuzzy matching_ / RAG) untuk mencegah duplikasi.
- **FR.AI.04**: Sistem menyediakan _UI preview/draft_ sebelum transaksi di-commit ke dalam database.

### 5.3. Manajemen Inventaris (Products)

- **FR.INV.01**: Pengguna dapat menambahkan, mengubah, dan melihat daftar produk (Nama, SKU, Varian, Kategori, Harga Jual, Harga Modal Rata-rata/Average Cost).
- **FR.INV.02**: Sistem akan menghitung dan memperbarui _current stock_ secara otomatis berdasarkan transaksi (In/Out).
- **FR.INV.03**: Sistem harus menyimpan _Stock Ledger_ (Buku Besar Stok) untuk melacak setiap mutasi barang per tanggal dan waktu.

### 5.4. Manajemen Transaksi

- **FR.TRX.01 (Pengadaan / Procurement)**: Mencatat barang masuk, memperbarui Harga Pokok Rata-Rata (HPP), dan menautkan penerimaan barang ke profil _Supplier_.
- **FR.TRX.02 (Penjualan / Sales)**: Mencatat barang keluar, mengkalkulasi total belanja dengan pajak/diskon, dan menautkan ke profil _Customer_.
- **FR.TRX.03**: Pengguna dapat memfilter dan mencari riwayat transaksi berdasarkan tanggal, tipe, dan nomor _invoice_.

### 5.5. Manajemen Kontak

- **FR.CNT.01**: Pengguna dapat mendata Relasi Bisnis yang dibedakan menjadi tipe `CUSTOMER` dan `SUPPLIER`.
- **FR.CNT.02**: Sistem dapat menampilkan profil kontak dan metrik ringkasan (contoh: Total jumlah rupiah transaksi dengan _supplier_ tertentu).

### 5.6. Laporan Keuangan (Financials)

- **FR.FIN.01**: Sistem dapat menghasilkan _Profit & Loss Statement_ (Laporan Laba Rugi).
- **FR.FIN.02**: Kalkulasi Gross Profit didapat dari **Total Revenue (Total Penjualan) - Total COGS (HPP barang terjual)** yang dihitung secara dinamis.

---

## 6. Non-Functional Requirements (Kebutuhan Non-Fungsional)

- **NFR.01 (Performance)**: API endpoint standar harus merespons dalam waktu kurang dari 300ms. Untuk endpoint pemrosesan AI (OCR/Chat), toleransi respons adalah 3-10 detik.
- **NFR.02 (Usability)**: UI mendukung _Dark Mode_ dan _Light Mode_ secara mulus, serta responsif di layar desktop maupun tablet. UI dirancang senyaman mungkin (_app-surface_, _glassmorphism_, status _skeleton loading_ yang halus).
- **NFR.03 (Reliability)**: Database terhubung menggunakan sistem _connection pooling_ (PgBouncer compatibility) untuk mencegah _connection leak_ pada trafik tinggi.
- **NFR.04 (Security)**: Endpoint harus mendukung middleware CORS yang aman.

---

## 7. System Architecture & Tech Stack

- **Frontend**: Next.js (App Router), React, Tailwind CSS, Lucide Icons.
- **Backend**: Python, FastAPI.
- **Database**: PostgreSQL (Via `databases` async driver).
- **AI Integration**: Groq API (menggunakan model LLM mutakhir untuk pemrosesan NLP dan vision OCR).
- **Algoritma Tambahan**: _Fuzzy Wuzzy_ (untuk pencocokan teks nama produk/varian cerdas).

---

_Dokumen ini dibuat otomatis sebagai panduan dasar pengembangan sistem DNN Project._
