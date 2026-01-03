#!/bin/bash

# Launch Script for Data Warehouse Analytics
# This script runs after data is already ingested to PostgreSQL:
# 1. Runs dbt models
# 2. Generates dbt documentation
# 3. Launches Streamlit app in browser
# 4. Launches dbt docs in browser

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Launching Data Warehouse Analytics...${NC}"
echo ""

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Step 1: Run dbt
echo -e "${YELLOW}Step 1: Running dbt models...${NC}"
if [ -f "$SCRIPT_DIR/dbt/run_dbt.sh" ]; then
    cd "$SCRIPT_DIR/dbt"
    # Temporarily disable exit on error for dbt run (it might have warnings)
    set +e
    ./run_dbt.sh run
    DBT_RUN_RESULT=$?
    set -e
    cd "$SCRIPT_DIR"
    if [ $DBT_RUN_RESULT -eq 0 ]; then
        echo -e "${GREEN}✓ dbt run completed${NC}"
    else
        echo -e "${RED}❌ dbt run failed. Please check the errors above.${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ dbt/run_dbt.sh not found.${NC}"
    exit 1
fi
echo ""

# Step 2: Generate dbt docs
echo -e "${YELLOW}Step 2: Generating dbt documentation...${NC}"
if [ -f "$SCRIPT_DIR/dbt/generate_docs.sh" ]; then
    cd "$SCRIPT_DIR/dbt"
    # Temporarily disable exit on error for dbt docs generate
    set +e
    ./generate_docs.sh
    DBT_DOCS_RESULT=$?
    set -e
    cd "$SCRIPT_DIR"
    if [ $DBT_DOCS_RESULT -eq 0 ]; then
        echo -e "${GREEN}✓ dbt documentation generated${NC}"
    else
        echo -e "${RED}❌ dbt docs generation failed. Please check the errors above.${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ dbt/generate_docs.sh not found.${NC}"
    exit 1
fi
echo ""

# Step 3: Launch Streamlit app
echo -e "${YELLOW}Step 3: Launching Streamlit app...${NC}"

# Check if Streamlit is already running via Docker
if docker ps --format "{{.Names}}" | grep -q "data_warehouse_streamlit"; then
    echo -e "${GREEN}✓ Streamlit is already running via Docker${NC}"
    STREAMLIT_URL="http://localhost:8501"
else
    # Check if we should use Docker or local
    if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
        echo -e "${YELLOW}   Building Streamlit Docker image...${NC}"
        cd "$SCRIPT_DIR"
        docker-compose build streamlit
        echo -e "${YELLOW}   Starting Streamlit via Docker...${NC}"
        docker-compose up -d streamlit
        echo "   Waiting for Streamlit to be ready..."
        sleep 5
        STREAMLIT_URL="http://localhost:8501"
        echo -e "${GREEN}✓ Streamlit started via Docker${NC}"
    elif [ -f "$SCRIPT_DIR/streamlit/run.sh" ]; then
        echo -e "${YELLOW}   Starting Streamlit locally...${NC}"
        cd "$SCRIPT_DIR/streamlit"
        # Start Streamlit in background
        nohup ./run.sh > streamlit.log 2>&1 &
        STREAMLIT_PID=$!
        echo "   Waiting for Streamlit to be ready..."
        sleep 5
        STREAMLIT_URL="http://localhost:8501"
        echo -e "${GREEN}✓ Streamlit started locally (PID: $STREAMLIT_PID)${NC}"
        echo -e "${YELLOW}   To stop Streamlit, run: kill $STREAMLIT_PID${NC}"
    else
        echo -e "${RED}❌ Could not find Streamlit setup. Please ensure Streamlit is configured.${NC}"
        exit 1
    fi
fi
echo ""

# Step 4: Launch dbt docs
echo -e "${YELLOW}Step 4: Launching dbt documentation...${NC}"

# Check if dbt-docs is already running via Docker
if docker ps --format "{{.Names}}" | grep -q "data_warehouse_dbt_docs"; then
    echo -e "${GREEN}✓ dbt docs is already running via Docker${NC}"
    DBT_DOCS_URL="http://localhost:8080"
else
    # Check if we should use Docker or local
    if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
        echo -e "${YELLOW}   Starting dbt docs via Docker...${NC}"
        cd "$SCRIPT_DIR"
        docker-compose build dbt-docs
        docker-compose up -d dbt-docs
        echo "   Waiting for dbt docs to be ready..."
        sleep 5
        DBT_DOCS_URL="http://localhost:8080"
        echo -e "${GREEN}✓ dbt docs started via Docker${NC}"
    elif [ -f "$SCRIPT_DIR/dbt/run_dbt.sh" ]; then
        echo -e "${YELLOW}   Starting dbt docs locally...${NC}"
        cd "$SCRIPT_DIR/dbt"
        # Check if virtual environment exists
        if [ ! -d "venv" ]; then
            echo -e "${RED}❌ Virtual environment not found. Please run dbt/setup_venv.sh first.${NC}"
            exit 1
        fi
        # Start dbt docs serve in background with venv activated
        export DBT_PROFILES_DIR="$SCRIPT_DIR/dbt"
        nohup bash -c "source venv/bin/activate && dbt docs serve --port 8080" > dbt_docs.log 2>&1 &
        DBT_DOCS_PID=$!
        echo "   Waiting for dbt docs to be ready..."
        sleep 5
        DBT_DOCS_URL="http://localhost:8080"
        echo -e "${GREEN}✓ dbt docs started locally (PID: $DBT_DOCS_PID)${NC}"
        echo -e "${YELLOW}   To stop dbt docs, run: kill $DBT_DOCS_PID${NC}"
    else
        echo -e "${RED}❌ Could not find dbt docs setup. Please ensure dbt is configured.${NC}"
        exit 1
    fi
fi
echo ""

# Step 5: Open browsers
echo -e "${YELLOW}Step 5: Opening applications in browser...${NC}"

# Function to open URL in browser
open_browser() {
    local url=$1
    if command -v xdg-open &> /dev/null; then
        # Linux
        xdg-open "$url" &
    elif command -v open &> /dev/null; then
        # macOS
        open "$url" &
    elif command -v start &> /dev/null; then
        # Windows (Git Bash)
        start "$url" &
    else
        echo -e "${YELLOW}⚠ Could not automatically open browser. Please visit: $url${NC}"
    fi
}

# Open Streamlit
echo -e "${YELLOW}   Opening Streamlit app...${NC}"
open_browser "$STREAMLIT_URL"
sleep 2

# Open dbt docs
echo -e "${YELLOW}   Opening dbt documentation...${NC}"
open_browser "$DBT_DOCS_URL"

echo -e "${GREEN}✓ Browsers opened${NC}"
echo ""

# Summary
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Launch complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Application URLs:"
echo "  📈 Streamlit:      $STREAMLIT_URL"
echo "  📚 dbt Docs:       $DBT_DOCS_URL"
echo ""
echo "Useful commands:"
if [ ! -z "$STREAMLIT_PID" ]; then
    echo "  Stop Streamlit:    kill $STREAMLIT_PID"
fi
if [ ! -z "$DBT_DOCS_PID" ]; then
    echo "  Stop dbt docs:     kill $DBT_DOCS_PID"
fi
if docker ps --format "{{.Names}}" | grep -q "data_warehouse_streamlit\|data_warehouse_dbt_docs"; then
    echo "  Stop Docker:       docker-compose stop streamlit dbt-docs"
fi
echo ""

