# ==============================================================================
# Production Dockerfile for StatementX FastAPI Backend Engine
# ==============================================================================
FROM python:3.11-slim

# Prevent Python from writing .pyc files to disk and enable unbuffered logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install system dependencies (curl is used for Docker service health checks)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency specifications
COPY requirements.txt .

# Install pip packages with cache optimizations
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend codebase
COPY . .

# Grant execution rights to startup entrypoint script
RUN chmod +x docker-entrypoint.sh

# Expose FastAPI backend standard port
EXPOSE 8000

# Bind startup sequence to the entrypoint manager
ENTRYPOINT ["/app/docker-entrypoint.sh"]
