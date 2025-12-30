#!/bin/bash

# Adventure Works Installation Script for SQL Server
# This script downloads and installs the Adventure Works sample database on SQL Server

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the project root directory (parent of adventureworks)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Starting Adventure Works installation for SQL Server..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# SQL Server connection details
SQLSERVER_SA_PASSWORD="${SQLSERVER_SA_PASSWORD:-YourStrong@Passw0rd}"
SQLSERVER_HOST="${SQLSERVER_HOST:-localhost}"
SQLSERVER_PORT="${SQLSERVER_PORT:-1433}"

# Check if SQL Server container is running
echo -e "${YELLOW}Checking if SQL Server container is running...${NC}"
if ! docker ps | grep -q data_warehouse_sqlserver; then
    echo -e "${RED}❌ SQL Server container is not running. Starting it...${NC}"
    cd "$PROJECT_ROOT"
    docker-compose up -d sqlserver
    echo -e "${YELLOW}⏳ Waiting for SQL Server to be ready...${NC}"
    sleep 10
    
    # Wait for SQL Server to be ready
    MAX_RETRIES=30
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if docker exec data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SQLSERVER_SA_PASSWORD" -C -Q "SELECT 1" -b > /dev/null 2>&1; then
            echo -e "${GREEN}✓ SQL Server is ready${NC}"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "   Waiting for SQL Server... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 2
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo -e "${RED}❌ SQL Server failed to start within timeout period${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ SQL Server container is running${NC}"
fi

# Check if AdventureWorks database already exists
echo -e "${YELLOW}Checking if AdventureWorks database exists...${NC}"
DB_EXISTS=$(docker exec data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$SQLSERVER_SA_PASSWORD" \
    -C \
    -Q "SELECT name FROM sys.databases WHERE name = 'AdventureWorks2022'" \
    -h -1 -W 2>/dev/null | tr -d ' \r\n' || echo "")

if [ -n "$DB_EXISTS" ] && [ "$DB_EXISTS" = "AdventureWorks2022" ]; then
    echo -e "${GREEN}✓ AdventureWorks database already exists${NC}"
    echo ""
    echo "You can connect to the database using:"
    echo "  docker exec -it data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '$SQLSERVER_SA_PASSWORD' -d AdventureWorks2022"
    echo ""
    echo "Or from your host machine:"
    echo "  sqlcmd -S localhost,${SQLSERVER_PORT} -U sa -P '$SQLSERVER_SA_PASSWORD' -d AdventureWorks2022"
    echo ""
    exit 0
fi

# Create a temporary directory for the installation
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo -e "${YELLOW}Step 1: Downloading AdventureWorks backup file...${NC}"
# Download AdventureWorks2022 backup file
BACKUP_URL="https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak"
BACKUP_FILE="AdventureWorks2022.bak"

if command -v wget &> /dev/null; then
    wget --no-verbose --continue -O "$BACKUP_FILE" "$BACKUP_URL" || {
        echo -e "${RED}❌ Failed to download backup file${NC}"
        exit 1
    }
elif command -v curl &> /dev/null; then
    curl -L -o "$BACKUP_FILE" "$BACKUP_URL" || {
        echo -e "${RED}❌ Failed to download backup file${NC}"
        exit 1
    }
else
    echo -e "${RED}❌ Error: Neither wget nor curl is available. Please install one of them.${NC}"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Backup file not found after download${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Backup file downloaded${NC}"

echo -e "${YELLOW}Step 2: Copying backup file into SQL Server container...${NC}"

# Verify container is running and accessible
if ! docker ps | grep -q data_warehouse_sqlserver; then
    echo -e "${RED}❌ SQL Server container is not running${NC}"
    exit 1
fi

# Ensure backup directory exists in container
echo -e "${YELLOW}   Creating backup directory in container...${NC}"
docker exec data_warehouse_sqlserver mkdir -p /var/opt/mssql/backup || {
    echo -e "${RED}❌ Failed to create backup directory${NC}"
    exit 1
}

# Get file size for progress indication
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo -e "${YELLOW}   Copying backup file ($FILE_SIZE) to container...${NC}"

# Copy backup file directly to backup directory
# Retry up to 3 times in case container needs more time
COPY_SUCCESS=false
for i in {1..3}; do
    if docker cp "$BACKUP_FILE" data_warehouse_sqlserver:/var/opt/mssql/backup/AdventureWorks2022.bak 2>/dev/null; then
        COPY_SUCCESS=true
        break
    fi
    if [ $i -lt 3 ]; then
        echo -e "${YELLOW}   Copy attempt $i failed, retrying in 2 seconds...${NC}"
        sleep 2
        # Verify container is still running
        if ! docker ps | grep -q data_warehouse_sqlserver; then
            echo -e "${RED}❌ SQL Server container stopped during copy${NC}"
            exit 1
        fi
    fi
done

if [ "$COPY_SUCCESS" = false ]; then
    echo -e "${RED}❌ Failed to copy backup file to container after 3 attempts${NC}"
    echo -e "${YELLOW}   This might be due to:${NC}"
    echo -e "${YELLOW}   - Container not fully ready${NC}"
    echo -e "${YELLOW}   - Insufficient disk space${NC}"
    echo -e "${YELLOW}   - Network issues${NC}"
    echo -e "${YELLOW}   Check container logs: docker logs data_warehouse_sqlserver${NC}"
    exit 1
fi

# Fix file permissions - SQL Server needs to be able to read the backup file
echo -e "${YELLOW}   Setting file permissions...${NC}"
docker exec data_warehouse_sqlserver chmod 644 /var/opt/mssql/backup/AdventureWorks2022.bak || {
    echo -e "${YELLOW}   ⚠ Warning: Could not set file permissions (may still work)${NC}"
}

# Verify file was copied successfully
if docker exec data_warehouse_sqlserver test -f /var/opt/mssql/backup/AdventureWorks2022.bak; then
    echo -e "${GREEN}✓ Backup file copied successfully${NC}"
else
    echo -e "${RED}❌ Backup file not found in container after copy${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 3: Restoring AdventureWorks database...${NC}"
echo "This may take a few minutes..."

# Restore the database
RESTORE_SQL="
RESTORE DATABASE AdventureWorks2022
FROM DISK = '/var/opt/mssql/backup/AdventureWorks2022.bak'
WITH MOVE 'AdventureWorks2022' TO '/var/opt/mssql/data/AdventureWorks2022.mdf',
     MOVE 'AdventureWorks2022_Log' TO '/var/opt/mssql/data/AdventureWorks2022_Log.ldf',
     REPLACE;
"

docker exec data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$SQLSERVER_SA_PASSWORD" \
    -C \
    -Q "$RESTORE_SQL" || {
    echo -e "${RED}❌ Failed to restore database${NC}"
    exit 1
}

echo -e "${GREEN}✓ AdventureWorks database restored successfully!${NC}"

# Verify the database
echo -e "${YELLOW}Step 4: Verifying installation...${NC}"
TABLE_COUNT=$(docker exec data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$SQLSERVER_SA_PASSWORD" \
    -C \
    -d AdventureWorks2022 \
    -Q "SELECT COUNT(*) FROM sys.tables" \
    -h -1 -W 2>/dev/null | tr -d ' \r\n' || echo "0")

if [ -n "$TABLE_COUNT" ] && [ "$TABLE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Database verified: $TABLE_COUNT tables found${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Could not verify table count${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo ""
echo "You can now connect to the database using:"
echo "  docker exec -it data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '$SQLSERVER_SA_PASSWORD' -d AdventureWorks2022"
echo ""
echo "Or from your host machine:"
echo "  sqlcmd -S localhost,${SQLSERVER_PORT} -U sa -P '$SQLSERVER_SA_PASSWORD' -d AdventureWorks2022"
echo ""
echo "Connection string example:"
echo "  Server=localhost,${SQLSERVER_PORT};Database=AdventureWorks2022;User Id=sa;Password=$SQLSERVER_SA_PASSWORD;"

# Cleanup
cd /
rm -rf "$TEMP_DIR"
# Clean up backup file from container (optional, can keep for future restores)
# docker exec data_warehouse_sqlserver rm -f /var/opt/mssql/backup/AdventureWorks2022.bak

echo -e "${GREEN}✓ Cleanup complete${NC}"

