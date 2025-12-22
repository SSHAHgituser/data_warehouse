# Airbyte Server Dockerfile
# This Dockerfile sets up the Airbyte server service for the data warehouse project
#
# Note: Airbyte is typically deployed using docker-compose with multiple services.
# This Dockerfile provides a custom build for the Airbyte server component.
# For production, consider using the official Airbyte images or abctl for deployment.

# Use OpenJDK as base image (Airbyte server is Java-based)
FROM eclipse-temurin:17-jre-alpine

# Set metadata
LABEL maintainer="data-warehouse-team"
LABEL description="Airbyte Server Service for Data Warehouse"
LABEL version="1.0"

# Set working directory
WORKDIR /app

# Install necessary dependencies
RUN apk add --no-cache \
    curl \
    bash \
    postgresql-client \
    tzdata \
    && rm -rf /var/cache/apk/*

# Set timezone (adjust as needed)
ENV TZ=UTC

# Set environment variables
ENV AIRBYTE_VERSION=0.50.0
ENV JAVA_OPTS="-Xms512m -Xmx2048m -XX:+UseG1GC"
ENV AIRBYTE_ROLE=server
ENV DATABASE_URL=""
ENV DATABASE_USER=""
ENV DATABASE_PASSWORD=""
ENV DATABASE_DB="airbyte"
ENV AIRBYTE_SERVER_HOST="0.0.0.0"
ENV AIRBYTE_SERVER_PORT="8001"

# Create directories for Airbyte
RUN mkdir -p /data /logs /tmp /app/bin

# Download and set up Airbyte server
# Note: You may need to adjust the download URL or provide the JAR file separately
# Alternative: Copy a pre-downloaded JAR file from your build context
# COPY airbyte-server.jar /app/bin/airbyte-server.jar
RUN curl -L -o /app/bin/airbyte-server.jar \
    https://github.com/airbytehq/airbyte/releases/download/v${AIRBYTE_VERSION}/airbyte-server-${AIRBYTE_VERSION}.jar \
    2>/dev/null || echo "Warning: Airbyte JAR download failed. Please provide airbyte-server.jar in build context."

# Copy configuration files (if any)
# Uncomment and adjust if you have custom config files
# COPY config/ ./config/

# Expose Airbyte server port (default is 8001)
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/api/v1/health || exit 1

# Create non-root user for security
RUN addgroup -S airbyte && adduser -S airbyte -G airbyte && \
    chown -R airbyte:airbyte /app /data /logs /tmp

# Switch to non-root user
USER airbyte

# Run Airbyte server
# The server will connect to the database specified in DATABASE_URL environment variable
CMD ["java", \
     "-XX:+UseG1GC", \
     "-Xms512m", \
     "-Xmx2048m", \
     "-jar", \
     "/app/bin/airbyte-server.jar", \
     "server"]

