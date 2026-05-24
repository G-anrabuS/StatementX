# StatementX 📊🚀

StatementX is an end-to-end, AI-powered Bank Statement Analyser built as a cross-platform application (**Flutter Web & Android**) supported by a high-performance **FastAPI backend**. It securely extracts transactions from raw files, categorizes financial rows dynamically using a trained machine learning model, detects recurring subscription lines, and identifies unusual financial anomalies.

Now featuring **Multi-tenant User Ownership** via Google OAuth integration.

---

## 🛠 Project Architecture Overview

The system architecture decoupling analytical processing from presentation to allow seamless cross-platform performance:

- **Frontend:** Flutter (Dart) using a unified memory buffer strategy to handle files (`file_picker`). Uses **Google Identity Services (GIS)** for secure Web & Android authentication.
- **Backend:** Python 3.10+ powered by FastAPI. Implements **JWT-based session management** and enforces strict user-data isolation (multi-tenancy).
- **Database:** Relational engine managed via SQLAlchemy ORM. Supports **PostgreSQL** (Production) and **SQLite** (Development).
- **Security:** Triple-layer file ingestion sanitization and **Transparent Column-Level Cryptography (AES-256)** for transaction data at rest.

---

## 🚀 How to Run the Project Locally

### Prerequisites

1. **Flutter SDK** installed and added to your environmental path variables.
2. **Python 3.10 or higher** installed.
3. **PostgreSQL** installed and running (or use fallback SQLite).
4. A **Google Cloud Project** with OAuth 2.0 Client IDs configured.

---

### Phase 0: Google Cloud Configuration

To enable Google Sign-In, you must configure your credentials in the [Google Cloud Console](https://console.cloud.google.com/):

1.  **Web Client ID:** Create an OAuth 2.0 Client ID for "Web Application".
2.  **Android Client ID:** 
    *   Find your SHA-1 fingerprint:
        ```bash
        cd flutter_frontend/android
        ./gradlew signingReport
        ```
    *   Create an OAuth 2.0 Client ID for "Android" using your package name and SHA-1.
3.  **Enable People API:** Search for "People API" in the Google Cloud Library and click **ENABLE**.

---

### Phase 1: Launch the FastAPI Backend

1. Navigate to the backend directory:
    ```bash
    cd fastapi_backend
    ```

2. Generate a local Python virtual environment and activate it:
    ```bash
    # Windows
    python -m venv venv
    .\venv\Scripts\activate

    # macOS / Linux
    python3 -m venv venv
    source venv/bin/activate
    ```

3. Install all dependencies:
    ```bash
    pip install -r requirements.txt
    ```

4. **Environment Setup:** Create a `.env` file in `fastapi_backend/` (use `.env.example` as a template):
    ```ini
    GEMINI_API_KEY=your_key
    DATABASE_URL=postgresql://user:pass@localhost:5432/statementx
    SECRET_KEY=any_long_random_string
    GOOGLE_WEB_CLIENT_ID=your-web-id.apps.googleusercontent.com
    GOOGLE_ANDROID_CLIENT_ID=your-android-id.apps.googleusercontent.com
    ```

5. Initialize the database schemas:
    ```bash
    python create_tables.py
    ```

6. Boot the server:
    ```bash
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
    ```

---

### Phase 2: Spin Up the Flutter Frontend

1. Navigate to the frontend directory:
    ```bash
    cd flutter_frontend
    ```

2. **Environment Setup:** Create a `.env` file inside `flutter_frontend/assets/`:
    ```ini
    GOOGLE_WEB_CLIENT_ID=your-web-id.apps.googleusercontent.com
    GOOGLE_ANDROID_CLIENT_ID=your-android-id.apps.googleusercontent.com
    ```

3. Fetch dependencies:
    ```bash
    flutter pub get
    ```

4. **Web Configuration:** Open `web/index.html` and ensure the Google meta tag matches your Web Client ID:
    ```html
    <meta name="google-signin-client_id" content="your-web-id.apps.googleusercontent.com">
    ```

5. Run the application:
    ```bash
    # For Web
    flutter run -d chrome

    # For Android
    flutter run -d your_device_id
    ```

---

## 🔒 Crucial Mobile Production Configuration

If deploying to Android, verify these properties in `android/app/src/main/AndroidManifest.xml`:

1.  **Cleartext Traffic:** Allow `http` for local development:
    ```xml
    <application android:usesCleartextTraffic="true" ...>
    ```
2.  **Internet Permission:**
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    ```

---

## 📂 Feature Scope Matrix

- [x] **Multi-tenant Authentication:** Secure Google OAuth login for Web & Android.
- [x] **Cross-Format Upload Parser:** Support for `.pdf` and `.csv` statement parsing.
- [x] **User Ownership:** Private data isolation; users only see their own statements.
- [x] **Automated ML Classification:** Local transaction categorization using ONNX.
- [x] **AI Financial Coach:** Narrative health summaries and prioritized actions.
- [x] **Semantic RAG Chat:** Chat with your bank statements using vector search.
- [x] **At-Rest Encryption:** Industry-standard AES-256 encryption for financial data.
