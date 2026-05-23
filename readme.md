# StatementX 🏦

A Bank Statement Analyzer application built using a high-performance **FastAPI backend** and a cross-platform **Flutter frontend**. The system utilizes semantic AI modeling layers to automatically ingest, isolate, map, and cleanly parse structural variations within multi-bank Indian transaction statement matrices.

---

## 🛠️ Technology Highlights

- **Backend:** FastAPI, Python (3.11+ recommended), SQLite (local) / PostgreSQL (production), Google GenAI SDK, Pydantic structural JSON schemas, and Hugging Face API integrations.
- **Frontend:** Flutter, Dart, Multi-platform rendering layout system.
- **Core Engine Features:**
    - **Strict Input Constraints:** Validates and restricts payload processing exclusively to PDF and CSV statement formats.
    - **Structured AI Ingestion:** Harnesses strict Pydantic JSON schemas with Gemini to cleanly extract multi-column statement rows.
    - **Automated Column Mapping:** Converts varying bank schema representations into a unified structure (`date`, `narration`, `debit`, `credit`, `balance`).
    - **Local Fuzzy Caching:** Leverages an SQLite-based `merchant_cache` table with a custom-compiled Python `similarity()` connection function, providing database-level similarity match optimizations.

---

## 📂 Project Layout

```text
StatementX/
├── fastapi_backend/
│   ├── app/
│   │   ├── api/          # Route handlers & multi-part gateway adapters
│   │   ├── core/         # Settings configuration, database engine, & environment resolution
│   │   ├── models/       # Database ORM model layers (SQLAlchemy)
│   │   ├── schemas/      # Unified Pydantic models for data validation
│   │   ├── services/     # AI Extraction engine & categorizers using Gemini Client & ONNX
│   │   └── main.py       # Application initialization and CORS configurations
│   ├── create_tables.py  # Script to initialize/migrate local database schemas
│   └── requirements.txt  # Python package dependencies
│
└── flutter_frontend/
    ├── lib/
    │   ├── models/       # Frontend transaction models mapping backend models
    │   ├── screens/      # Core interface layout and upload screens
    │   ├── services/     # Http clients hooking into backend services
    │   ├── widgets/      # Reusable visual UI components
    │   └── main.dart     # App boot and widget tree injection point
    └── pubspec.yaml      # Flutter dependency management configurations
```

---

## ⚙️ Environment Configuration

Before running the backend processing engine, configure your API credentials and database path inside the FastAPI backend. Create a `.env` configuration file in the `fastapi_backend` directory:

```env
# Google Gemini API Key from Google AI Studio
GEMINI_API_KEY=your_google_gemini_api_key_here

# Database connection URL (SQLite used by default for local setup)
DATABASE_URL=sqlite:///./statementx.db

# Hugging Face Token (if applicable for AI categorizer fallback modules)
HF_TOKEN=your_hugging_face_token_here
```

---

## 🚀 Quick Start (Local Setup)

### 1. Backend Setup

From the `fastapi_backend` folder, initialize your Python environment, install packages, prepare the database, and spin up the development server:

```bash
# Create a virtual environment using Python 3.11
py -3.11 -m venv .venv

# Activate the environment (Windows PowerShell)
.venv\Scripts\Activate.ps1

# Activate the environment (Linux / MacOS)
# source .venv/bin/activate

# Install required dependencies
pip install -r requirements.txt

# Create & initialize database tables
python create_tables.py

# Run live development server with hot-reload
uvicorn app.main:app --reload
```

- **API Live Endpoint:** `http://127.0.0.1:8000`
- **Interactive Documentation Portal:** `http://127.0.0.1:8000/docs` (Swagger UI) or `/redoc`

### 2. Frontend Setup

From the `flutter_frontend` folder, synchronize local platform engines and launch your cross-platform target:

```bash
# Fetch target platform dependencies
flutter pub get

# Launch interface compilation framework
flutter run
```

---

## 🗺️ Core API Architecture Contracts

### **Root Status Endpoint**

- **Route:** `GET /`
- **Utility:** Returns system runtime details, health status check, metadata routing endpoints, and version indicators.

### **Statement AI Extraction Engine**

- **Route:** `POST /api/statements/extract`
- **Payload Constraints:** Expects a multipart form body interface accepting a single `(.pdf)` or `(.csv)` document file stream parameter under the key name `file`.
- **Response Structure:** Hydrates validated JSON back cleanly into a structured payload matrix describing the inferred bank, mapped transaction rows, and calculated totals:

```json
{
  "bank_name": "HDFC Bank",
  "total_transactions": 3,
  "transactions": [
    {
      "date": "2026-05-15",
      "narration": "UPI-Barbeque Nation-12345",
      "debit": 1500.00,
      "credit": 0.00,
      "balance": 18500.00,
      "category": "Food & Dining",
      "sub_category": "Restaurants",
      "confidence": 1.00
    }
  ]
}
```
