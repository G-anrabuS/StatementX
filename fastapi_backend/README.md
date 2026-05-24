# StatementX AI Core Engine (Backend) 📊🐍⚙️

The **StatementX Backend** is an asynchronous, high-performance financial analytics and parsing service built with **FastAPI** and **Python 3.10+**. 

It handles cross-format bank statement parsing (PDF and CSV), runs a local machine learning categorizer via **ONNX**, detects recurring subscriptions and transaction anomalies, and provides a RAG (Retrieval-Augmented Generation) chatbot grounded in statement context.

---

## 🛠️ System Architecture & Service Layers

The backend is organized as a decoupled, modular service system:

* **FastAPI Framework (`app/main.py`):** Drives asynchronous, high-throughput routing. Supports auto-generated OpenAPI/Swagger documentation.
* **Database & ORM (`app/core/database.py`):** Uses SQLAlchemy for multi-tenant database designs (supporting SQLite in local development and PostgreSQL in production).
* **ONNX ML Categorizer (`app/services/onnx_categorizer.py`):** Executes localized NLP sequence classification models using **ONNX Runtime**, categorizing transactions in sub-milliseconds without third-party API dependencies. Includes a **Merchant Rule Cache** bypass layer.
* **RAG Chatbot Service (`app/services/chatbot_service.py`):** Integrates Gemini API (`text-embedding-004`) to compute dense vector coordinates for transaction narrations. It merges dense vector search with a custom TF-IDF/SequenceMatcher sparse search via a **Hybrid Fusion Layer** (40% Vector + 60% Keyword overlap).
* **Insights & Anomalies Service (`app/services/insights_service.py`):** Scans statement ledgers to detect recurring subscriptions, duplicate/midnight transactions (anomalies), and formats personalized saving plans.
* **Visualization Service (`app/services/visualization_service.py`):** Calculates indicators like Cash Flow timelines, 50/30/20 budget framework distribution, and weekday spending patterns.
* **Security Sanitizers:** Enforces a Triple-Layer file inspection shield and AES-256 transparent column-level encryption for data at rest.

---

## 🏗️ SQLite Custom-Similarity Connection Hook
To enable parity between SQLite and production PostgreSQL vector indices (`pgvector`), the connection module (`app/core/database.py`) injects a custom hook:

```python
def sqlite_similarity(a, b):
    if a is None or b is None:
        return 0.0
    return difflib.SequenceMatcher(None, str(a), str(b)).ratio()

@event.listens_for(engine, "connect")
def setup_sqlite_connection(dbapi_connection, connection_record):
    if settings.DATABASE_URL.startswith("sqlite"):
        dbapi_connection.create_function("similarity", 2, sqlite_similarity)
```
This dynamically maps a raw SQL similarity function into SQLite, enabling the exact same similarity searches to run in local environments.

---

## 🛡️ Ingestion Security & Cryptography

### 1. Triple-Layer Ingestion Security Engine
Every statement upload goes through a strict validation chain before parsing:
* **Layer 1 (Extension Whitelist):** Enforces a strict extension check (rejecting anything other than lowercase `.pdf` or `.csv`).
* **Layer 2 (MIME-Type Check):** Cross-references client-declared content headers (`application/pdf` or `text/csv`) with extensions to catch spoofing.
* **Layer 3 (Forensic Magic Signature):** Scans the first 1024 binary bytes:
  * Verifies PDFs start with `%PDF` (Hex: `25 50 44 46`).
  * Scans CSVs to block execution codes (e.g. Windows PE headers `MZ` or Linux `ELF`) and rejects files containing control characters (`\x00`).

### 2. Transparent Column-Level Encryption
Sensitive financial fields (e.g. descriptions, debits, credits, balances) are seamlessly encrypted using **AES-256 (Fernet)** before insertion, securing the system at rest even if the database file (`statementx.db`) is leaked.

---

## 🚀 Local Installation & Setup

### 1. Initialize Python Environment
```bash
cd fastapi_backend
python -m venv venv

# Windows Activation
.\venv\Scripts\activate

# macOS / Linux Activation
source venv/bin/activate
```

### 2. Install Engine Packages
```bash
pip install -r requirements.txt
```

### 3. Setup Configuration
Create a `.env` file matching `.env.example`:
```ini
GEMINI_API_KEY=your_gemini_api_key
DATABASE_URL=sqlite:///./statementx.db
SECRET_KEY=your_jwt_signing_secret
GOOGLE_WEB_CLIENT_ID=your-google-web-id
GOOGLE_ANDROID_CLIENT_ID=your-google-android-id
```

### 4. Create Tables & Boot API
```bash
# Initialize DB tables
python create_tables.py

# Launch development server
uvicorn app.main:app --reload
```
Open **`http://127.0.0.1:8000/docs`** to test endpoints.

---

## 🧪 Security Validation Suite
To verify the forensic magic-signature security validators and malicious payload blocks, run:
```bash
python test_security_exploit.py
```
This script tests:
1. Legitimate PDF bypass confirmation.
2. Extension-spoofed text scripts blocks.
3. Windows binary executable masquerades blocks.
