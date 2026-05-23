# ==============================================================================
# Production Dockerfile for StatementX Flutter Web Frontend
# Tech Stack: Multi-stage Docker, Flutter compilation, nginx static server
# ==============================================================================

# --- Stage 1: Build compilation stage ---
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Switch to root to ensure proper package upgrades
USER root

# Copy package management files to fetch dependencies
COPY pubspec.yaml ./

# Run flutter pub get to fetch all package requirements
RUN flutter pub get

# Copy the rest of the application files
COPY . .

# Compile Flutter Web application in release mode
# --web-renderer canvaskit provides high performance canvas rendering on modern web browsers.
RUN flutter build web --release --web-renderer canvaskit

# --- Stage 2: Final lightweight web serving stage ---
FROM nginx:stable-alpine AS runner

# Remove the default nginx homepage assets
RUN rm -rf /usr/share/nginx/html/*

# Copy compiled Flutter web assets from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Run nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]
