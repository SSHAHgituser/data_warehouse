#!/bin/bash

# Data Warehouse Stack Startup Script
# This script starts all services in the correct order:
# 1. PostgreSQL
# 2. Streamlit
# 3. dbt Documentation Server
# 4. AdventureWorks Database (if not exists)
# 5. Airbyte (if abctl is installed)

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Data Warehouse Stack...${NC}"
echo ""

# Step 1: Start PostgreSQL
echo -e "${YELLOW}Step 1: Starting PostgreSQL...${NC}"
docker-compose up -d postgres
echo -e "${GREEN}✓ PostgreSQL started${NC}"
echo "   Waiting for PostgreSQL to be ready..."
sleep 3

# Wait for PostgreSQL to be healthy
until docker exec data_warehouse_postgres pg_isready -U postgres > /dev/null 2>&1; do
    echo "   Waiting for PostgreSQL..."
    sleep 2
done
echo -e "${GREEN}✓ PostgreSQL is ready${NC}"
echo ""

# Step 2: Start Streamlit
echo -e "${YELLOW}Step 2: Starting Streamlit...${NC}"
docker-compose up -d streamlit
echo -e "${GREEN}✓ Streamlit started${NC}"
echo ""

# Step 3: Start dbt Documentation Server
echo -e "${YELLOW}Step 3: Starting dbt Documentation Server...${NC}"
docker-compose up -d dbt-docs
echo -e "${GREEN}✓ dbt Documentation Server started${NC}"
echo ""

# Step 4: Check and Install AdventureWorks Database (if needed)
echo -e "${YELLOW}Step 4: Checking AdventureWorks database...${NC}"
# Wait a bit more to ensure PostgreSQL is fully ready for queries
sleep 2
ADVENTUREWORKS_EXISTS=$(docker exec data_warehouse_postgres psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='Adventureworks'" 2>/dev/null || echo "")
if [ -z "$ADVENTUREWORKS_EXISTS" ]; then
    echo -e "${YELLOW}   AdventureWorks database not found. Installing...${NC}"
    echo -e "${YELLOW}   This may take several minutes...${NC}"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/adventureworks/install_adventureworks.sh" ]; then
        # Temporarily disable exit on error for this step (it's optional)
        set +e
        "$SCRIPT_DIR/adventureworks/install_adventureworks.sh"
        INSTALL_RESULT=$?
        set -e
        if [ $INSTALL_RESULT -eq 0 ]; then
            echo -e "${GREEN}✓ AdventureWorks database installed${NC}"
        else
            echo -e "${YELLOW}⚠ AdventureWorks installation failed. You can install it manually later.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ AdventureWorks install script not found. Skipping installation.${NC}"
    fi
else
    echo -e "${GREEN}✓ AdventureWorks database already exists${NC}"
fi
echo ""

# Step 5: Start Airbyte (if abctl is available)
echo -e "${YELLOW}Step 5: Checking Airbyte status...${NC}"
if command -v abctl &> /dev/null; then
    # Check if Airbyte is installed and running
    AIRBYTE_STATUS=$(abctl local status 2>&1 || echo "not_installed")
    if echo "$AIRBYTE_STATUS" | grep -qi "running\|installed"; then
        # Try to start Airbyte (idempotent - won't error if already running)
        if abctl local start &> /dev/null; then
            echo -e "${GREEN}✓ Airbyte is running${NC}"
        else
            echo -e "${GREEN}✓ Airbyte is already running${NC}"
        fi
    else
        echo -e "${YELLOW}   Airbyte is not installed. Skipping startup.${NC}"
        echo -e "${YELLOW}   To install Airbyte, run: cd airbyte && ./setup_with_abctl.sh${NC}"
        echo -e "${YELLOW}   (Installation takes ~30 minutes)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ abctl not found. Airbyte setup skipped.${NC}"
    echo -e "${YELLOW}   To install Airbyte, run: cd airbyte && ./setup_with_abctl.sh${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All services started successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Service URLs:"
echo "  📊 PostgreSQL:     localhost:5432"
echo "  📈 Streamlit:      http://localhost:8501"
echo "  📚 dbt Docs:       http://localhost:8080"
if command -v abctl &> /dev/null; then
    AIRBYTE_STATUS=$(abctl local status 2>&1 || echo "")
    if echo "$AIRBYTE_STATUS" | grep -qi "running\|installed"; then
        echo "  🔄 Airbyte:        http://localhost:8000"
    fi
fi
echo ""
echo "Useful commands:"
echo "  View logs:         docker-compose logs -f [service_name]"
echo "  Stop services:     ./stop.sh"
echo "  Check status:      docker-compose ps"
echo ""

