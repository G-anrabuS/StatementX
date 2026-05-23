# ==============================================================================
# Production Dockerfile for StatementX FastAPI Backend
# Tech Stack: Python 3.11 slim, non-root user, Gunicorn + Uvicorn workers
# ==============================================================================

# --- Stage 1: Build & Dependency Gathering ---
FROM python:3.11-slim AS builder

WORKDIR /app

# Install system dependencies required for building Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first to leverage Docker cache layers
COPY requirements.txt .

# Install dependencies into a wheels directory to copy to final stage
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt gunicorn

# --- Stage 2: Final Runtime Stage ---
FROM python:3.11-slim AS runner

WORKDIR /app

# Install runtime dependencies (like libpq for PostgreSQL connection)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from the builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Create a system group and user 'appuser' for enhanced security
RUN groupadd -r appgroup && useradd -r -g appgroup -d /home/appuser -m -s /sbin/nologin appuser

# Copy application source files
COPY --chown=appuser:appgroup . .

# Set up environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HOME=/home/appuser \
    PATH="/home/appuser/.local/bin:${PATH}"

# Ensure startup scripts are executable and directory permissions are correct
RUN chmod +x /app/entrypoint.sh \
    && mkdir -p /app/onnx_model /home/appuser/.cache/huggingface \
    && chown -R appuser:appgroup /app /home/appuser

# Switch to the non-root user
USER appuser

# Expose FastAPI internal application port
EXPOSE 8000

# Container health check to verify endpoint readiness
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD curl -f http://localhost:8000/ || exit 1

# Define script execution gateway
ENTRYPOINT ["/bin/sh", "/app/entrypoint.sh"]
