#!/bin/bash

# Data Warehouse Stack Startup Script
# This script starts all services in the correct order:
# 1. PostgreSQL
# 2. Streamlit
# 3. dbt Documentation Server
# 4. AdventureWorks Database (if not exists)
# 5. Airbyte (installs abctl and Airbyte if needed, then starts)

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

# Step 5: Install and Start Airbyte
echo -e "${YELLOW}Step 5: Checking Airbyte status...${NC}"

# Ensure abctl is installed
if ! command -v abctl &> /dev/null; then
    echo -e "${YELLOW}   abctl not found. Installing abctl...${NC}"
    curl -LsfS https://get.airbyte.com | bash -
    
    if ! command -v abctl &> /dev/null; then
        echo -e "${YELLOW}⚠ abctl installation failed. Skipping Airbyte setup.${NC}"
        echo -e "${YELLOW}   Install manually: curl -LsfS https://get.airbyte.com | bash -${NC}"
        echo ""
    else
        echo -e "${GREEN}✓ abctl installed${NC}"
    fi
fi

# Check Airbyte status and install/start if needed
if command -v abctl &> /dev/null; then
    # Check if Airbyte is installed (capture both output and exit code)
    set +e
    AIRBYTE_STATUS_OUTPUT=$(abctl local status 2>&1)
    AIRBYTE_STATUS_EXIT=$?
    set -e
    
    # Check for various status indicators
    # Note: abctl doesn't have a 'start' command, so we use docker start directly
    if echo "$AIRBYTE_STATUS_OUTPUT" | grep -qi "not.*installed\|does not appear to be installed"; then
        echo -e "${YELLOW}   Airbyte is not installed. Installing now...${NC}"
        echo -e "${YELLOW}   ⚠️  This will take approximately 30 minutes. Please be patient.${NC}"
        echo ""
        
        # Temporarily disable exit on error for installation (it's a long process and optional)
        set +e
        abctl local install
        INSTALL_RESULT=$?
        set -e
        
        if [ $INSTALL_RESULT -eq 0 ]; then
            echo -e "${GREEN}✓ Airbyte installed successfully${NC}"
            echo -e "${YELLOW}   Starting Airbyte container...${NC}"
            # Give it a moment after installation
            sleep 5
            # Start the kind cluster container directly
            set +e
            docker start airbyte-abctl-control-plane &> /dev/null 2>&1
            START_RESULT=$?
            set -e
            if [ $START_RESULT -eq 0 ]; then
                echo -e "${GREEN}✓ Airbyte started${NC}"
            else
                echo -e "${YELLOW}⚠ Airbyte installed. Container may take a moment to start. Check with: abctl local status${NC}"
            fi
        else
            echo -e "${YELLOW}⚠ Airbyte installation encountered issues.${NC}"
            echo -e "${YELLOW}   You can retry manually: cd airbyte && ./setup_with_abctl.sh${NC}"
        fi
    elif echo "$AIRBYTE_STATUS_OUTPUT" | grep -qi "ERROR.*not running\|container.*is not running\|status.*exited"; then
        # Container exists but is not running - start it
        echo -e "${YELLOW}   Airbyte container is stopped. Starting...${NC}"
        set +e
        docker start airbyte-abctl-control-plane
        START_RESULT=$?
        set -e
        if [ $START_RESULT -eq 0 ]; then
            echo -e "${GREEN}✓ Airbyte started${NC}"
        else
            echo -e "${YELLOW}⚠ Failed to start Airbyte container. Check with: docker ps -a | grep airbyte${NC}"
        fi
    elif echo "$AIRBYTE_STATUS_OUTPUT" | grep -qi "deployed\|SUCCESS.*Found.*cluster"; then
        # Check if container is actually running
        if docker ps --format "{{.Names}}" | grep -q "airbyte-abctl-control-plane"; then
            echo -e "${GREEN}✓ Airbyte is already running${NC}"
        else
            # Cluster exists but container not running
            echo -e "${YELLOW}   Airbyte cluster found but container not running. Starting...${NC}"
            set +e
            docker start airbyte-abctl-control-plane
            START_RESULT=$?
            set -e
            if [ $START_RESULT -eq 0 ]; then
                echo -e "${GREEN}✓ Airbyte started${NC}"
            else
                echo -e "${YELLOW}⚠ Failed to start Airbyte container${NC}"
            fi
        fi
    else
        # Unknown status - check container directly
        if docker ps --format "{{.Names}}" | grep -q "airbyte-abctl-control-plane"; then
            echo -e "${GREEN}✓ Airbyte is running${NC}"
        elif docker ps -a --format "{{.Names}}" | grep -q "airbyte-abctl-control-plane"; then
            # Container exists but stopped
            echo -e "${YELLOW}   Airbyte container found but stopped. Starting...${NC}"
            set +e
            docker start airbyte-abctl-control-plane
            START_RESULT=$?
            set -e
            if [ $START_RESULT -eq 0 ]; then
                echo -e "${GREEN}✓ Airbyte started${NC}"
            else
                echo -e "${YELLOW}⚠ Could not start Airbyte. Check manually: docker ps -a | grep airbyte${NC}"
            fi
        else
            # Container doesn't exist - might need installation
            if [ $AIRBYTE_STATUS_EXIT -ne 0 ] && echo "$AIRBYTE_STATUS_OUTPUT" | grep -qi "not.*installed\|does not appear"; then
                echo -e "${YELLOW}   Airbyte not installed. Attempting installation...${NC}"
                echo -e "${YELLOW}   ⚠️  This will take approximately 30 minutes.${NC}"
                set +e
                abctl local install
                INSTALL_RESULT=$?
                set -e
                if [ $INSTALL_RESULT -eq 0 ]; then
                    sleep 5
                    set +e
                    docker start airbyte-abctl-control-plane &> /dev/null 2>&1
                    FINAL_START_RESULT=$?
                    set -e
                    if [ $FINAL_START_RESULT -eq 0 ]; then
                        echo -e "${GREEN}✓ Airbyte installed and started${NC}"
                    else
                        echo -e "${YELLOW}⚠ Installed. Container may take a moment to start. Check status: abctl local status${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠ Installation failed. See troubleshooting: airbyte/troubleshooting.md${NC}"
                fi
            else
                echo -e "${YELLOW}⚠ Could not determine Airbyte status. Check manually: abctl local status${NC}"
                echo -e "${YELLOW}   Status output: ${AIRBYTE_STATUS_OUTPUT:0:100}...${NC}"
            fi
        fi
    fi
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

