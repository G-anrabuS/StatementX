# StatementX 🏦

A Bank Statement Analyzer application built using a FastAPI backend and a Flutter frontend.

---

## 📂 Current Project Layout

```text
StatementX/
├── fastapi_backend/
│   ├── app/
│   │   ├── api/
│   │   ├── core/
│   │   ├── models/
│   │   ├── services/
│   │   └── main.py
│   └── requirements.txt
│
└── flutter_frontend/
    ├── lib/
    │   ├── src/
    │   │   ├── models/
    │   │   ├── screens/
    │   │   ├── services/
    │   │   └── widgets/
    │   └── main.py
```

---

---

🚀 Quick Start (Local Setup)

1. Backend Setup
   From the fastapi_backend folder, set up your Python environment and launch the development server:

```
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## API will run live at: http://127.0.0.1:8000

---

2. Frontend Setup
   From the flutter_frontend folder, fetch dependencies and boot up the UI engine:

```
flutter pub get
flutter run
```

---
