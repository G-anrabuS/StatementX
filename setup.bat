@echo off
rem ==============================================================================
rem StatementX Production One-Click Docker Setup Script (Windows Command Prompt)
rem ==============================================================================

echo ======================================================================
echo       StatementX Production Docker Containerization System Setup
echo ======================================================================

rem 1. Directory Checks and Creation
echo.
echo [1/3] Ensuring required directory structure exists...
if not exist "nginx" mkdir "nginx"
if not exist "certbot\www" mkdir "certbot\www"
if not exist "certbot\conf" mkdir "certbot\conf"
echo       - certbot\www (validation directory) -^> Created / Verified
echo       - certbot\conf (SSL certificates)     -^> Created / Verified
echo       - nginx (configuration mount)         -^> Created / Verified

rem 2. Environment Verification
echo.
echo [2/3] Checking environment file configurations...
if not exist ".env" (
    echo       WARNING: No '.env' file found at root directory.
    if exist "fastapi_backend\.env" (
        echo       Found existing backend '.env'. Copying to root configuration...
        copy "fastapi_backend\.env" ".env" >nul
    ) else (
        echo       Copying '.env.example' to '.env'...
        copy ".env.example" ".env" >nul
    )
    echo       IMPORTANT: Please open the '.env' file at root and fill in your details (like GEMINI_API_KEY) before launching!
) else (
    echo       - Root '.env' file found -^> Verified
)

rem 3. Launch Instructions
echo.
echo [3/3] Docker Compose initialization ready!
echo       To build and spin up the entire cluster in the background, run:
echo       docker compose up -d --build
echo.
echo       To watch the boot logs (including self-healing database tables):
echo       docker compose logs -f backend
echo ======================================================================
pause
