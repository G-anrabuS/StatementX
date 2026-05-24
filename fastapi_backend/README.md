# StatementX AI Core Engine 📊🚀

The **StatementX Backend** is a high-performance, robust, and intelligent bank statement parser and analytical engine built using **FastAPI** and **Python 3.10+**. It implements a dual-mode parser (PDF & CSV), a localized machine learning inference categorizer, dynamic cash-flow auditing, and a RAG (Retrieval-Augmented Generation) semantic chat interface.

---

## 🛠️ System Architecture & Technology Stack

The backend is engineered for high scalability, decoupling AI/ML inferences from storage layers:

* **Framework:** **FastAPI** + **Uvicorn** for real-time asynchronous HTTP operations.
* **ML Inference Engine:** Localized sequence classification models loaded through **ONNX Runtime** (`onnxruntime`, `optimum`, `transformers`, `torch`) for sub-millisecond transaction categorization.
* **Database Layer:** Platform-agnostic **SQLAlchemy ORM** supporting both **PostgreSQL** (production ready with native `pgvector`) and a self-healing **SQLite** fallback connection with a custom-injected similarity function.
* **Parser Layer:** Asynchronous **PyPDF** and high-speed **Polars** engines for parsing transaction statements.
* **Cognitive Services:** **Google GenAI** (Gemini) for high-fidelity insights extraction, emergency action plans, and semantic memory summaries.

---

## 📂 Feature Scope Matrix

- [x] **Cross-Format Upload Parser:** Processes both `.pdf` and `.csv` statement files asynchronously.
- [x] **Local ONNX Classification:** Automated sequence labeling of transaction narrations into structured category tokens.
- [x] **Smart Caching Layer:** Features a `merchant_cache` table to store verified rules and dramatically bypass redundant NLP inferences.
- [x] **Auditor & Anomaly Engine:** Auto-scans datasets for duplicates, midnight transfers, and monthly subscription tracks.
- [x] **Semantic RAG Chatbot:** Conversational engine featuring transaction context lookup, fallback keyword search, and memory history.

---

## 🏗️ Self-Healing Database Layer
To enable friction-free local development with SQLite while maintaining schema-level parity with production PostgreSQL/pgvector clusters, the database layer implements a **custom connection hook** (`app/core/database.py`):

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

This dynamically binds a two-parameter `similarity(col, term)` function inside SQLite execution environments, allowing the exact same vector-similarity raw SQL queries to execute successfully on local databases without alteration.

---

## 🛡️ Enterprise Security Infrastructure

StatementX implements an enterprise-grade security layer to guard sensitive financial databases against unauthorized access and malicious file ingestion.

### 1. Triple-Layer Ingestion Security Engine
All file uploads targeting the statement ingestion endpoint (`/api/statements/extract`) pass through a rigorous, multi-staged security validator:

```mermaid
graph TD
    File[Uploaded File] --> L1{Layer 1: Extension Check}
    L1 -- Not .pdf/.csv --> Reject[400 Bad Request: Reject Upload]
    L1 -- Pass --> L2{Layer 2: MIME-Type Alignment}
    L2 -- Mismatched MIME --> Reject
    L2 -- Pass --> L3{Layer 3: Forensic Binary Check}
    L3 -- Non-matching Magic Number / Binary Nulls --> Reject
    L3 -- Pass --> Parse[Successful Parsing & Extraction]
```

* **Layer 1: Extension Verification:** Enforces strict whitelist validation. Only files ending with a lowercase `.pdf` or `.csv` extension are allowed.
* **Layer 2: Client-Declared MIME-Type Alignment:** Cross-references the browser's declared HTTP `Content-Type` header (e.g. `application/pdf` or `text/csv`) with the target extension to catch basic header-spoofing attempts.
* **Layer 3: Forensic Magic-Number & Binary Null Inspection:** Read and scan the raw file header (first `1024` bytes) directly:
  * For **PDFs**, verifies the file starts with the official binary signature `%PDF` (Hex: `25 50 44 46`).
  * For **CSVs**, blocks potential executable file signatures (e.g., Windows PE `MZ` or Linux `ELF` headers) and scans for binary null control characters (`\x00`), which represent compiled payload injection.

### 2. Transparent Column-Level Cryptography (At-Rest)
To protect confidential personal financial data, StatementX employs **transparent, symmetric column-level encryption** using **AES-256 (Fernet)**.

* **Encrypted Columns:** All highly sensitive text fields (like transaction descriptions, annotations) and numeric fields (amounts, balances) are seamlessly encrypted using Python's `cryptography.fernet` package before committing to the SQLite/PostgreSQL storage layer, and decrypted on-the-fly when retrieved.
* **Database Theft Mitigation:** Even if the underlying database file (`statementx.db` or PostgreSQL storage clusters) is compromised or leaked, the transaction data remains mathematically scrambled and unreadable without the symmetric `ENCRYPTION_KEY`.

---

## 🚀 Local Installation & Setup

Ensure you have **Python 3.10+** installed before proceeding.

### 1. Initialize Virtual Environment
Navigate to the backend directory and spin up a local isolation sandbox:

```powershell
# Windows
cd fastapi_backend
python -m venv venv
.\venv\Scripts\activate

# macOS / Linux
cd fastapi_backend
python3 -m venv venv
source venv/bin/activate
```

### 2. Install Engine Dependencies
Install the required analytical and deep-learning runtimes:
```bash
pip install -r requirements.txt
```

### 3. Environment Configuration
Create a `.env` file in the root of the `fastapi_backend` directory (matching the structure of `.env.example`):
```ini
GEMINI_API_KEY=your_gemini_api_key_here
DATABASE_URL=sqlite:///./statementx.db
ENCRYPTION_KEY=your_32_byte_urlsafe_base64_fernet_key
```
> **Note:** If you wish to migrate to production PostgreSQL, verify the `postgresql-x64` service is running locally on your target machine and adjust the `DATABASE_URL` string: `postgresql://username:password@localhost:5432/statementx`. For local testing, if `ENCRYPTION_KEY` is omitted, the engine falls back to a stable cryptographic master seed.

### 4. Create Database Tables
Initialize database tracking schemas:
```bash
python create_tables.py
```

### 5. Boot Up the Server
Start the Uvicorn live reload development server:
```bash
uvicorn app.main:app --reload
```
Once the startup cycle is complete, access the interactive OpenAPI/Swagger docs at: **`http://127.0.0.1:8000/docs`**

---

## 🧪 Running Integration & Security Tests
The backend is packaged with two simulation scripts to verify functional health and security boundaries.

### 1. Functional E2E Integration Test
Verifies the database lifecycle, classification accuracy, insights engine, and RAG chatbot services:
```bash
python run_api_test.py
```

### 2. Security Exploit & Validation Test
Verifies the ingestion validation engine, blocking of extension-spoofed scripts, and malicious binary rejection:
```bash
python test_security_exploit.py
```

---

## 🔌 API Reference & Schema Specification

### Endpoints Overview

| Method | Path | Auth | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/statements/extract` | None | Uploads a `.pdf` or `.csv` bank statement, parses transaction arrays, performs ML classification, caches merchants, and persists the record. |
| `GET` | `/api/statements` | None | Lists all saved bank statements with their metadata and database IDs. |
| `GET` | `/api/statements/{statement_id}/insights` | None | Computes transaction counts, income/expense splits, top categories, recurring subscriptions, and transaction anomalies. |
| `GET` | `/api/statements/{statement_id}/ai-coach` | None | Generates narrative AI summaries and prioritized action items for savings health. |
| `POST` | `/api/statements/{statement_id}/chat` | None | Asks context-aware questions to a statement's history using semantic search and RAG. |

---

### Request & Response Examples

#### 1. Statement Extraction
* **URL:** `/api/statements/extract`
* **Request (Multipart Form-Data):**
  * `file`: (binary payload of `.csv` or `.pdf` ledger)
* **Response (Status `200`):**
```json
{
  "statement_id": "a7bfb96a-43ff-4d0d-96eb-b9b4b4c8dd37",
  "bank_name": "Imported CSV Statement",
  "total_transactions": 7,
  "transactions": [
    {
      "date": "2026-05-01",
      "narration": "UPI/SALARY/PAYROLL/CR",
      "debit": 0.0,
      "credit": 50000.0,
      "balance": 50000.0,
      "category": "Salary & Income",
      "sub_category": "Salary",
      "confidence": 1.0
    }
  ]
}
```

#### 2. Chatbot Semantic Query
* **URL:** `/api/statements/{statement_id}/chat`
* **Request Body (JSON):**
```json
{
  "message": "Do I have any Netflix streaming commitments?",
  "chat_history": []
}
```
* **Response (Status `200`):**
```json
{
  "response": "Based on your bank statements, you have a recurring Netflix streaming commitment of INR 199.00 debited monthly...",
  "sources": [
    {
      "date": "2026-05-10",
      "description": "UPI/NETFLIX/STREAMING",
      "similarity": 0.425
    }
  ]
}
```
