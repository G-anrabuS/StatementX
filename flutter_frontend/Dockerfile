# ==============================================================================
# Multi-Stage Flutter Web Build and Serve Production Configuration
# ==============================================================================

# Stage 1: Compile Flutter Web Static Assets
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy dependency specifications
COPY pubspec.yaml pubspec.lock ./

# Pre-fetch flutter web packages
RUN flutter pub get

# Copy frontend source files
COPY . .

# Build Flutter Web in Release Mode
RUN flutter build web --release

# Stage 2: Serve compiled assets using lightweight Nginx
FROM nginx:stable-alpine

# Copy built artifacts from the compiler stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose HTTP port 80 inside the network
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
