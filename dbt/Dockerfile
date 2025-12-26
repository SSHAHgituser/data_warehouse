# Dockerfile for dbt docs generation and hosting
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    nginx \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy dbt project files
COPY dbt_project.yml .
COPY profiles.yml .
COPY models/ ./models/
COPY macros/ ./macros/
COPY seeds/ ./seeds/
COPY tests/ ./tests/
COPY analyses/ ./analyses/

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set DBT_PROFILES_DIR
ENV DBT_PROFILES_DIR=/app

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Use entrypoint to generate docs and serve
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

