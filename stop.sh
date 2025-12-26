#!/bin/bash

# Data Warehouse Stack Shutdown Script
# This script stops all services in the correct order:
# 1. Airbyte (if running)
# 2. Docker Compose services (dbt-docs, streamlit, postgres)

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Stopping Data Warehouse Stack...${NC}"
echo ""

# Step 1: Stop Airbyte (if running)
echo -e "${YELLOW}Step 1: Checking Airbyte status...${NC}"
if command -v abctl &> /dev/null; then
    AIRBYTE_STATUS=$(abctl local status 2>&1 || echo "not_installed")
    if echo "$AIRBYTE_STATUS" | grep -qi "running\|installed"; then
        echo -e "${YELLOW}   Stopping Airbyte...${NC}"
        if abctl local stop &> /dev/null; then
            echo -e "${GREEN}✓ Airbyte stopped${NC}"
        else
            echo -e "${YELLOW}⚠ Airbyte stop command failed (may already be stopped)${NC}"
        fi
    else
        echo -e "${GREEN}✓ Airbyte is not running${NC}"
    fi
else
    echo -e "${GREEN}✓ abctl not found, skipping Airbyte${NC}"
fi
echo ""

# Step 2: Stop Docker Compose services
echo -e "${YELLOW}Step 2: Stopping Docker Compose services...${NC}"
if docker-compose ps | grep -q "Up"; then
    echo -e "${YELLOW}   Stopping containers...${NC}"
    docker-compose down
    echo -e "${GREEN}✓ All Docker Compose services stopped${NC}"
else
    echo -e "${GREEN}✓ No Docker Compose services running${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All services stopped successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "To start services again:"
echo "  ./start.sh"
echo ""
echo "Useful commands:"
echo "  View stopped containers: docker-compose ps -a"
echo "  Remove volumes (⚠️ deletes data): docker-compose down -v"
echo "  Check Airbyte status: abctl local status"
echo ""

