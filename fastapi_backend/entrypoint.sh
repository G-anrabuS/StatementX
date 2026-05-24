#!/bin/sh
set -e

# ==============================================================================
# StatementX FastAPI Production Entrypoint Script
# - Waits for PostgreSQL database readiness
# - Generates local ONNX sequence classifier model
# - Performs database schema creation/migration
# - Starts FastAPI via Gunicorn with Uvicorn workers
# ==============================================================================

echo "=========================================================="
echo "🚀 Starting StatementX Production Boot sequence..."
echo "=========================================================="

# 1. Wait for database readiness using Python socket probe
python -c "
import socket
import time
import os
from urllib.parse import urlparse

db_url = os.getenv('DATABASE_URL', '')
if not db_url:
    print('[ERROR] DATABASE_URL is not set inside the environment variables!')
    exit(1)

# Handle schema replacements if sqlite or postgres
if db_url.startswith('sqlite:///'):
    print('[DATABASE] Using local SQLite. Socket checks skipped.')
    exit(0)

try:
    parsed = urlparse(db_url)
    host = parsed.hostname
    port = parsed.port or 5432
except Exception as e:
    print(f'[ERROR] Failed to parse DATABASE_URL: {e}')
    exit(1)

print(f'[DATABASE] Connection probe starting for {host}:{port}...')
retries = 30
for i in range(retries):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1.5)
        s.connect((host, port))
        s.close()
        print('[DATABASE] Connected! Database is online and accepting connections.')
        exit(0)
    except (socket.error, socket.timeout):
        print(f'[DATABASE] DB not ready yet... ({i+1}/{retries})')
        time.sleep(2)

print('[ERROR] Timeout reached waiting for database startup!')
exit(1)
"

# 2. Export transformer models to ONNX (Must happen before FastAPI startup to prevent import crashes)
if [ ! -d "/app/onnx_model" ] || [ ! -f "/app/onnx_model/model.onnx" ]; then
    echo "[ONNX ENGINE] ONNX classification model files not found in /app/onnx_model."
    echo "[ONNX ENGINE] Exporting DistilBERT sequence classifier to local ONNX format..."
    python export_to_onnx.py
    echo "[ONNX ENGINE] Model successfully exported and compiled."
else
    echo "[ONNX ENGINE] Existing ONNX model files detected in /app/onnx_model. Skipping export."
fi

# 3. Create database tables
echo "[DATABASE MIGRATOR] Initializing operational database schemas..."
python create_tables.py
echo "[DATABASE MIGRATOR] Schema creation completed."

# 4. Launch FastAPI through Gunicorn (Uvicorn Workers)
# Configure worker counts based on CPU count dynamically or default to 4 workers
CPU_CORES=$(python -c "import os; print(os.cpu_count() or 2)")
WORKERS=$((CPU_CORES * 2 + 1))
echo "[WEB SERVER] Launching Gunicorn with ${WORKERS} Uvicorn worker processes..."

exec gunicorn app.main:app \
    --bind 0.0.0.0:8000 \
    --workers "$WORKERS" \
    --worker-class uvicorn.workers.UvicornWorker \
    --timeout 120 \
    --keep-alive 5 \
    --access-logfile - \
    --error-logfile - \
    --log-level info
