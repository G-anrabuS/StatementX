````markdown
# StatementX 🏦

A Bank Statement Analyzer application built using a high-performance **FastAPI backend** and a cross-platform **Flutter frontend**. The system utilizes semantic AI modeling layers to automatically ingest, isolate, map, and cleanly parse structural variations within multi-bank Indian transaction statement matrices.

---

## 🛠️ Technology Highlights

- **Backend:** FastAPI, Python, Google GenAI SDK, Pydantic structural JSON schemas.
- **Frontend:** Flutter, Dart, Multi-platform rendering layout system.
- **Core Engine Features:**
    - Strict network-rim verification blocking non-PDF payload files.
    - Native JSON-Schema constraints ensuring highly structured transaction extraction.
    - Automated column mapping logic converting diverse bank templates into standard data structures (`narration`, `debit`, `credit`, `balance`).

---

## 📂 Project Layout

```text
StatementX/
├── fastapi_backend/
│   ├── app/
│   │   ├── api/          # Route handlers & multi-part gateway adapters
│   │   ├── core/         # Settings configuration and API environments
│   │   ├── models/       # Operational model layers
│   │   ├── schemas/      # Unified Pydantic models for data validation
│   │   ├── services/     # AI Extraction engine using Gemini Client
│   │   └── main.py       # Application initialization and CORS configurations
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
````

---

## ⚙️ Environment Configuration

Before running the backend processing engine, configure your API credentials inside the FastAPI backend. Create a `.env` configuration file or manage your execution environment variables to expose your Gemini key:

```env
GEMINI_API_KEY=your_google_gemini_api_key_here

```

---

## 🚀 Quick Start (Local Setup)

### 1. Backend Setup

From the `fastapi_backend` folder, initialize your Python environment, install packages, and spin up the ASGI development server:

```bash
# Create a virtual environment
python -m venv venv

# Activate the environment (Windows PowerShell)
.\venv\Scripts\Activate.ps1

# Activate the environment (Linux / MacOS)
# source venv/bin/activate

# Install required dependencies
pip install -r requirements.txt

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

- **Route:** `POST /api/v1/statements/extract`
- **Payload Constraints:** Expects a multipart form body interface strictly accepting a single `(.pdf)` document structure file stream parameter under the key name `file`.
- **Response Structure:** Hydrates validated JSON back cleanly into a structured payload matrix describing the inferred Indian banking commercial identity, mapped items row collection, and absolute indexed operational totals.

```

```
