#!/usr/bin/env bash
# ==============================================================================
# StatementX Production One-Click Docker Setup Script (Linux/macOS)
# ==============================================================================

set -eo pipefail

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================================================${NC}"
echo -e "${GREEN}      StatementX Production Docker Containerization System Setup       ${NC}"
echo -e "${GREEN}======================================================================${NC}"

# 1. Directory Checks and Creation
echo -e "\n[1/3] Ensuring required directory structure exists..."
mkdir -p nginx certbot/www certbot/conf
echo -e "      - certbot/www (validation directory) -> Created / Verified"
echo -e "      - certbot/conf (SSL certificates)     -> Created / Verified"
echo -e "      - nginx (configuration mount)         -> Created / Verified"

# 2. Environment Verification
echo -e "\n[2/3] Checking environment file configurations..."
if [ ! -f .env ]; then
    echo -e "      ${YELLOW}WARNING: No '.env' file found at root directory.${NC}"
    if [ -f fastapi_backend/.env ]; then
        echo -e "      Found existing backend '.env'. Copying to root configuration..."
        cp fastapi_backend/.env .env
    else
        echo -e "      Copying '.env.example' to '.env'..."
        cp .env.example .env
    fi
    echo -e "      ${RED}IMPORTANT: Please open the '.env' file at root and fill in your details (like GEMINI_API_KEY) before launching!${NC}"
else
    echo -e "      - Root '.env' file found -> Verified"
fi

# 3. Running Docker Build
echo -e "\n[3/3] Docker Compose initialization ready!"
echo -e "      To build and spin up the entire cluster in the background, run:"
echo -e "      ${GREEN}docker compose up -d --build${NC}"
echo -e ""
echo -e "      To watch the boot logs (including self-healing database tables):"
echo -e "      ${GREEN}docker compose logs -f backend${NC}"
echo -e "======================================================================"
