# StatementX 📊🚀

StatementX is an end-to-end, AI-powered Bank Statement Analyser built as a cross-platform application (**Flutter Web & Android**) supported by a high-performance **FastAPI backend**. It securely extracts transactions from raw files, categorizes financial rows dynamically using a trained machine learning model, detects recurring subscription lines, and identifies unusual financial anomalies.

---

## 🛠 Project Architecture Overview

The system architecture decouples analytical processing from presentation to allow seamless cross-platform performance across different device environments:

- **Frontend:** Flutter (Dart) using a unified memory buffer strategy to handle files (`file_picker`) across Web sandboxes and Android storage frameworks seamlessly.
- **Backend:** Python 3.10+ powered by FastAPI, Uvicorn, and an ONNX runtime engine to execute transaction classification models instantly.
- **Database:** SQLite relational engine (`statementx.db`) managed via SQLAlchemy Object Relational Mapping (ORM).

---

## 🚀 How to Run the Project Locally

Follow these operational steps sequentially to stand up the service infrastructure on your local workspace.

### Prerequisites

1. **Flutter SDK** installed and added to your environmental path variables (`flutter doctor` must pass successfully).
2. **Python 3.10 or higher** installed.
3. Both testing hosts (e.g., your development machine and your physical Android phone) **must reside on the exact same local Wi-Fi connection network** to communicate.

---

### Phase 1: Launch the FastAPI Backend

1. Open your terminal workspace and navigate to the backend directory:
    ```bash
    cd fastapi_backend
    ```

````

2. Generate a local Python isolation sandbox environment and activate it:
```bash
# Windows Command Prompt
python -m venv venv
.\venv\Scripts\activate

# macOS / Linux Terminal
python3 -m venv venv
source venv/bin/activate

````

3. Install all listed engine dependency modules:

```bash
pip install -r requirements.txt

```

4. Initialize your local database configuration and populate SQLite tracking schemas:

```bash
python create_tables.py

```

5. Find your computer's explicit local network IP address:

- **Windows:** Execute `ipconfig` and look for your active Wireless LAN adapter's `IPv4 Address` (e.g., `10.149.147.205`).
- **macOS/Linux:** Execute `ifconfig` or `ip a`.

6. Boot your live API server binding to `0.0.0.0` so it actively accepts inward device requests from your local network route:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

```

_Verify your backend is alive by visiting `http://127.0.0.1:8000/docs` in your web browser._

---

### Phase 2: Spin Up the Flutter Frontend

1. Open a new separate terminal instance and enter the frontend directory:

```bash
cd flutter_frontend

```

2. Open `lib/services/statement_service.dart` and update the local network loopback fallback IP matching your laptop's actual IP address discovered in Phase 1, Step 5:

```dart
static String get baseUrl {
  if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
    // Replace this string with your exact Laptop Local IP address
    return '[http://10.149.147.205:8000/api/statements](http://10.149.147.205:8000/api/statements)';
  }
  return '[http://127.0.0.1:8000/api/statements](http://127.0.0.1:8000/api/statements)';
}

```

3. Fetch the application asset dependencies:

```bash
flutter pub get

```

4. Execute compilation targets depending on your target preview device:

#### To compile and run on a Web Browser:

```bash
flutter run -d chrome

```

#### To compile and run on your connected Android Device:

Make sure you have enabled USB debugging inside your phone's Android developer settings panel, then execute:

```bash
# Replace RMX2002 with your exact target device name ID listed via `flutter devices`
flutter run -d RMX2002

```

---

## 🎨 UI & UX Specifications

The frontend implements a clean, premium **Financial Analytics Light Theme** engine designed to prevent platform-specific rendering anomalies:

- **Upload Screen:** Employs a bounded single-page layout using a structural `LayoutBuilder` matrix instead of fluid vertical scrolling zones. This completely eliminates nested scrolling conflicts on Android, guaranteeing zero text layout overlaps while adapting components fluidly across both mobile phone form factors and desktop web layouts.
- **Transactions Page:** Uses an internal `Wrap` algorithm on category subtitles rather than a standard stretching row element. This ensures category descriptors, bullet dividers, and transaction timestamps remain tightly grouped from left to right without float alignment drift on desktop web browser screens. To prioritize user reading space on smaller mobile viewports, bulky category icons are swapped out for elegant 4px vertical accent lines.
- **Insights Screen:** Dynamically modifies `childAspectRatio` configurations ($1.35$ on mobile, $1.1$ on desktop screens) to provide breathing room for financial metric fields, eliminating vertical box layout clipping warnings.

---

## 🔒 Crucial Mobile Production Configuration

If you configure or clone this workspace onto a new Android container layout, verify these properties to prevent local network connection drops:

### 1. Cleartext Network Traffic

Because local development APIs host over unencrypted `http://` configurations instead of remote secure tunnels (`https://`), you must explicitly authorize cleartext queries inside `android/app/src/main/AndroidManifest.xml` under the main `<application>` bracket:

```xml
<application
    android:label="StatementX"
    android:usesCleartextTraffic="true"
    ...

```

### 2. Networking Permissions

Verify that explicit network access rules are active directly above the opening application block in your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />

```

---

## 📂 Feature Scope Matrix

- [x] **Cross-Format Upload Parser:** Support for both `.pdf` and `.csv` statement parsing over web and android pipelines.
- [x] **Automated ML Classification:** Local token categorization using a high-performance machine learning inference engine.
- [x] **Financial Health Auditing:** Auto-scans file datasets to map spending breakdowns, hidden subscriptions, and double duplicate anomalies.

```

```
