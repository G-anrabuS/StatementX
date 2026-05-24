#!/bin/sh
# Exit immediately if a command exits with a non-zero status
set -e

echo "[STARTUP] Running database table checking and self-healing migrations..."
python create_tables.py

echo "[STARTUP] Database initialized. Launching FastAPI application..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
