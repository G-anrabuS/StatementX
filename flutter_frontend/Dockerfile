# ==============================================================================
# Optimized Production Dockerfile for StatementX Flutter Web Frontend
# Pre-built copy approach: Saves 4.5GB of build disk space on EC2 servers!
# ==============================================================================

FROM nginx:stable-alpine AS runner

# Remove the default nginx homepage assets
RUN rm -rf /usr/share/nginx/html/*

# Copy pre-compiled Flutter web assets from local build context
COPY build/web /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Run nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]
