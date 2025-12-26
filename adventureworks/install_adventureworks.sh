#!/bin/bash

# Adventure Works Installation Script for PostgreSQL
# This script downloads and installs the Adventure Works sample database

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the project root directory (parent of adventureworks)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Starting Adventure Works installation..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if PostgreSQL container is running
echo -e "${YELLOW}Checking if PostgreSQL container is running...${NC}"
if ! docker ps | grep -q data_warehouse_postgres; then
    echo "❌ PostgreSQL container is not running. Starting it..."
    cd "$PROJECT_ROOT"
    docker-compose up -d postgres
    echo "⏳ Waiting for PostgreSQL to be ready..."
    sleep 5
else
    echo -e "${GREEN}✓ PostgreSQL container is running${NC}"
fi

# Create a temporary directory for the installation
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo -e "${YELLOW}Step 1: Cloning AdventureWorks-for-Postgres repository...${NC}"
git clone https://github.com/lorint/AdventureWorks-for-Postgres.git
cd AdventureWorks-for-Postgres

echo -e "${YELLOW}Step 2: Downloading AdventureWorks data files...${NC}"
if command -v wget &> /dev/null; then
    wget --no-verbose --continue 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip'
elif command -v curl &> /dev/null; then
    curl -L -o AdventureWorks-oltp-install-script.zip 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip'
else
    echo "❌ Error: Neither wget nor curl is available. Please install one of them."
    exit 1
fi

echo -e "${YELLOW}Step 3: Extracting data files...${NC}"
unzip -q AdventureWorks-oltp-install-script.zip

echo -e "${YELLOW}Step 4: Preparing CSV files for PostgreSQL...${NC}"
if command -v ruby &> /dev/null; then
    ruby update_csvs.rb
    echo -e "${GREEN}✓ CSV files prepared${NC}"
else
    echo -e "${YELLOW}⚠ Ruby not found. Skipping CSV update (may work without it)${NC}"
fi

echo -e "${YELLOW}Step 5: Creating AdventureWorks database...${NC}"
docker exec -i data_warehouse_postgres psql -U postgres -c "CREATE DATABASE \"Adventureworks\";" || {
    echo -e "${YELLOW}⚠ Database may already exist, continuing...${NC}"
}

echo -e "${YELLOW}Step 6: Copying CSV files and install script into PostgreSQL container...${NC}"
# Create a directory in the container for AdventureWorks files
docker exec data_warehouse_postgres mkdir -p /tmp/adventureworks_data
# Copy all files (including CSV and install.sql) into the container
docker cp . data_warehouse_postgres:/tmp/adventureworks_data/
echo -e "${GREEN}✓ Files copied${NC}"

echo -e "${YELLOW}Step 7: Installing database schema and loading data...${NC}"
echo "This may take several minutes..."
# Run install.sql from inside the container where CSV files are accessible
# The \copy commands in install.sql use relative paths, so we need to run from that directory
docker exec -w /tmp/adventureworks_data data_warehouse_postgres psql -U postgres -d Adventureworks -f install.sql

echo -e "${YELLOW}Step 8: Cleaning up empty schemas...${NC}"
docker exec -i data_warehouse_postgres psql -U postgres -d Adventureworks < "${SCRIPT_DIR}/cleanup_empty_schemas.sql"
echo -e "${GREEN}✓ Empty schemas cleaned up${NC}"

echo -e "${GREEN}✓ Adventure Works database installed successfully!${NC}"
echo ""
echo "You can now connect to the database using:"
echo "  docker exec -it data_warehouse_postgres psql -U postgres -d Adventureworks"
echo ""
echo "Or from your host machine:"
echo "  psql -h localhost -p 5432 -U postgres -d Adventureworks"

# Cleanup
cd /
rm -rf "$TEMP_DIR"
# Clean up files from container
docker exec data_warehouse_postgres rm -rf /tmp/adventureworks_data 2>/dev/null || true

echo -e "${GREEN}🎉 Installation complete!${NC}"

