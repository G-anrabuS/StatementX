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
```
> **Note:** If you wish to migrate to production PostgreSQL, verify the `postgresql-x64` service is running locally on your target machine and adjust the `DATABASE_URL` string: `postgresql://username:password@localhost:5432/statementx`

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

## 🧪 Running Integration Tests
The backend is packaged with an End-to-End client simulation script that verifies the full database lifecycle, classification accuracy, insights aggregator, and chatbot services.

To execute the test:
```bash
python run_api_test.py
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
