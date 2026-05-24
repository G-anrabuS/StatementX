# StatementX Frontend 📊📱✨

The **StatementX Frontend** is a premium, cross-platform client application built using the **Flutter SDK (Dart)**. It targets both **high-fidelity responsive web browsers** and **native Android mobile environments**. 

The app features a custom futuristic **Space-Dark/Glassmorphism theme** with soft neon purple/violet highlights, dynamic cashflow visualizations via `fl_chart`, a secure authentication system integrated with Google OAuth, and an interactive RAG semantic chat assistant interface.

---

## 📂 Codebase & Module Structure

The Flutter application is structured in a highly modular, decoupled fashion:

```
flutter_frontend/
├── assets/                  # Decoupled JSON configs & custom assets (e.g. .env config)
├── lib/
│   ├── main.dart            # Application bootstrapper & global state / routing configurations
│   ├── theme/
│   │   └── app_theme.dart   # Premium Space-Dark visual system design & HSL neon colors
│   ├── models/
│   │   ├── statement_model.dart      # Typings for loaded statements and transactions
│   │   ├── insights_model.dart       # Structured budget coaching & anomaly typings
│   │   └── visualization_model.dart  # Data aggregations for interactive timelines & budgets
│   ├── services/
│   │   ├── auth_service.dart         # JWT token management, persistent sessions, and Google OAuth
│   │   └── statement_service.dart    # API client matching all FastAPI analytical endpoints
│   └── screens/
│       ├── login_screen.dart         # Dynamic, glassmorphic login gate with Google Identity Services
│       ├── home_screen.dart          # High-performance main dashboard showing all files
│       ├── upload_screen.dart        # Drag-and-drop secure statement parser with password unlocks
│       ├── extraction_loading_screen.dart # Interactive state-machine loader showing pipeline stages
│       ├── transaction_screen.dart   # Interactive searchable & paginated financial transaction ledger
│       ├── insights_screen.dart      # Audit logs (Subscriptions & Anomalies detector)
│       ├── ai_coach_screen.dart      # Premium personalized AI wealth advisor interface
│       ├── visualization_screen.dart # Interactive fl_charts (Cashflow, 50/30/20, Weekday trends)
│       └── chat_bot_screen.dart      # RAG-grounded conversational interface with source-link mapping
```

---

## 🎨 Premium Visual System & Design Aesthetics

The user interface follows advanced web design guidelines to deliver a premium, responsive layout:

* **Dark Mode Glassmorphism:** Deep space background (`#0A0A10`) layered with semi-transparent card panels (`rgba(255, 255, 255, 0.05)`) featuring elegant high-contrast borders and custom radial gradient backdrops.
* **Modern Typography:** Uses Google's sleek **Outfit** and **Inter** sans-serif font families for high readability and premium presentation.
* **Micro-Animations & Transitions:** Fluid hover responses, subtle scale elevations on interactive panels, animated state-change loaders, and custom typing indicators inside the chat interface.
* **Dynamic Visualization:** Interactive custom-styled graphs depicting cash inflows vs. outflows, budget gauges, and anomalies.

---

## 🔑 Google Client Single Sign-On (SSO) Configurations

StatementX uses secure Google OAuth authentication. You must configure client credentials on both platforms:

### 1. Web Configuration
* **Client ID Provisioning:** Configure an OAuth 2.0 Web Application in the Google Cloud Platform console.
* **Setup Asset Environment:** Create an environment config file `assets/.env`:
  ```ini
  GOOGLE_WEB_CLIENT_ID=your-web-id.apps.googleusercontent.com
  GOOGLE_ANDROID_CLIENT_ID=your-android-id.apps.googleusercontent.com
  ```
* **HTML Head Script Injection:** Double-check that your `web/index.html` file includes the Google Sign-in meta tag in the header block:
  ```html
  <meta name="google-signin-client_id" content="your-web-id.apps.googleusercontent.com">
  ```

### 2. Android Configuration
* **Developer Fingerprint:** Run the Gradle signing task to obtain your SHA-1 hash:
  ```bash
  cd android
  ./gradlew signingReport
  ```
* **Client ID Provisioning:** In the Google Cloud Console, register a new "Android" client credential utilizing your package name (e.g., `com.example.statementx`) and the SHA-1 fingerprint generated above.
* **XML AndroidManifest Configurations:** Add internet permissions and allow cleartext HTTP (strictly for local development) inside `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  <application android:usesCleartextTraffic="true" ...>
  ```

---

## 🚀 How to Install and Run Locally

Ensure you have the **Flutter SDK** installed and running on your system path.

### 1. Fetch Flutter Pub Dependencies
Navigate to the frontend folder and install packages:
```bash
cd flutter_frontend
flutter pub get
```

### 2. Launch Local Development Server
Boot up the development hot-reload server:

```bash
# Run on Google Chrome (Flutter Web)
flutter run -d chrome --web-port 8080

# Run on a connected Android phone or emulator
flutter run -d android
```

---

## 🐳 Docker Production Web Deployment

The frontend comes equipped with a optimized multi-stage `Dockerfile` to build and serve static assets securely.

### Containerization Strategy
1. **Compilation Phase:** Uses a lightweight `cirrusci/flutter:stable` builder to compile the Flutter Web release bundle (`flutter build web --release`).
2. **Serving Phase:** Mounts the compiled JS/HTML directory into a highly-performant, secure **Nginx** container (`nginx:stable-alpine`) to serve assets on port `80`.

To build the frontend image individually:
```bash
docker build -t statementx-frontend -f Dockerfile .
```
*(For global multi-container deployment, please refer to the root `docker-compose.yml` guidelines)*
