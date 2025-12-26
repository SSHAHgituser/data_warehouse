#!/bin/bash

# Data Warehouse Stack Startup Script
# This script starts all services in the correct order

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

# Summary
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All services started successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Service URLs:"
echo "  📊 PostgreSQL:     localhost:5432"
echo "  📈 Streamlit:      http://localhost:8501"
echo "  📚 dbt Docs:       http://localhost:8080"
echo ""
echo "Useful commands:"
echo "  View logs:         docker-compose logs -f [service_name]"
echo "  Stop services:     docker-compose down"
echo "  Check status:      docker-compose ps"
echo ""

