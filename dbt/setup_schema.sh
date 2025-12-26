#!/bin/bash

# Script to create the dbt schema in PostgreSQL

set -e

echo "🔧 Setting up dbt schema in PostgreSQL..."

# Check if PostgreSQL container is running
if ! docker ps | grep -q data_warehouse_postgres; then
    echo "❌ PostgreSQL container is not running. Starting it..."
    docker-compose up -d postgres
    echo "⏳ Waiting for PostgreSQL to be ready..."
    sleep 5
fi

# Create dbt schema
echo "Creating dbt schema..."
docker exec -i data_warehouse_postgres psql -U postgres -d data_warehouse <<EOF
CREATE SCHEMA IF NOT EXISTS dbt;
GRANT ALL PRIVILEGES ON SCHEMA dbt TO postgres;
EOF

echo "✅ dbt schema created successfully!"
echo ""
echo "You can now run dbt commands:"
echo "  cd dbt"
echo "  dbt --profiles-dir . debug"
echo "  dbt --profiles-dir . run"

