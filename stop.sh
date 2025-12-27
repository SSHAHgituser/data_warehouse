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
echo -e "${YELLOW}Step 1: Stopping Airbyte...${NC}"

# Check for Airbyte kind cluster container and stop it
AIRBYTE_CONTAINER_RUNNING=$(docker ps --format "{{.Names}}" | grep -c "airbyte-abctl-control-plane" || echo "0")
if [ "$AIRBYTE_CONTAINER_RUNNING" -gt 0 ]; then
    echo -e "${YELLOW}   Found Airbyte kind cluster container. Stopping...${NC}"
    set +e
    docker stop airbyte-abctl-control-plane &> /dev/null
    STOP_RESULT=$?
    set -e
    
    if [ $STOP_RESULT -eq 0 ]; then
        echo -e "${GREEN}✓ Airbyte container stopped${NC}"
    else
        echo -e "${YELLOW}⚠ Failed to stop Airbyte container (may require sudo or already stopping)${NC}"
    fi
    
    # Wait a moment for the container to fully stop
    sleep 2
    
    # Verify it's stopped
    if docker ps --format "{{.Names}}" | grep -q "airbyte-abctl-control-plane"; then
        echo -e "${YELLOW}⚠ Airbyte container still running. Attempting force stop...${NC}"
        docker kill airbyte-abctl-control-plane &> /dev/null || true
        sleep 1
        if ! docker ps --format "{{.Names}}" | grep -q "airbyte-abctl-control-plane"; then
            echo -e "${GREEN}✓ Airbyte container force stopped${NC}"
        else
            echo -e "${RED}⚠ Could not stop Airbyte container. You may need to stop it manually:${NC}"
            echo -e "${YELLOW}   docker stop airbyte-abctl-control-plane${NC}"
        fi
    fi
elif command -v abctl &> /dev/null; then
    # Check status via abctl if container not found but abctl is available
    set +e
    AIRBYTE_STATUS_OUTPUT=$(abctl local status 2>&1)
    AIRBYTE_STATUS_EXIT=$?
    set -e
    
    if [ $AIRBYTE_STATUS_EXIT -eq 0 ]; then
        if echo "$AIRBYTE_STATUS_OUTPUT" | grep -qi "running\|SUCCESS.*running\|deployed"; then
            echo -e "${YELLOW}   Airbyte appears to be running but container not found.${NC}"
            echo -e "${YELLOW}   Note: abctl does not have a 'stop' command.${NC}"
            echo -e "${YELLOW}   To stop Airbyte, you may need to uninstall: abctl local uninstall${NC}"
        else
            echo -e "${GREEN}✓ Airbyte is not running${NC}"
        fi
    else
        echo -e "${GREEN}✓ Airbyte status check failed, but no containers found${NC}"
    fi
else
    echo -e "${GREEN}✓ No Airbyte containers found and abctl not available${NC}"
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

