# Custom MinIO Dockerfile
# Based on official MinIO with custom configurations

FROM minio/minio:latest

# Set environment variables
ENV MINIO_ROOT_USER=minioadmin
ENV MINIO_ROOT_PASSWORD=minioadmin123
ENV MINIO_BROWSER_REDIRECT_URL=http://localhost:9001

# Create data directory
RUN mkdir -p /data

# Expose ports
EXPOSE 9000
EXPOSE 9001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:9000/minio/health/live || exit 1

# Default command
CMD ["server", "/data", "--console-address", ":9001"] 