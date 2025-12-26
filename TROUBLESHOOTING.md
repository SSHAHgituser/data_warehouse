# Troubleshooting: Can't See Databases

If you can't see the databases in your GUI tool, follow these steps:

## Step 1: Verify Databases Exist

Run this command to confirm the databases are there:

```bash
docker exec data_warehouse_postgres psql -U postgres -c "\l"
```

You should see:
- `Adventureworks`
- `data_warehouse`
- `postgres` (default)

## Step 2: Verify Container is Running

```bash
docker ps | grep data_warehouse_postgres
```

Should show the container as "Up" and healthy.

## Step 3: Check Connection Settings

Make sure you're using the correct connection details:

### Connection Parameters:
- **Host**: `localhost` (or `127.0.0.1`)
- **Port**: `5432`
- **Username**: `postgres`
- **Password**: `postgres` (or check your `.env` file)
- **Database**: Leave blank or use `postgres` to see all databases

### Test Connection from Command Line:

```bash
# Test basic connection
docker exec data_warehouse_postgres psql -U postgres -c "SELECT version();"

# List databases
docker exec data_warehouse_postgres psql -U postgres -c "\l"
```

## Step 4: GUI Tool-Specific Fixes

### TablePlus
1. **Create New Connection** → PostgreSQL
2. **Settings**:
   - Name: `Data Warehouse`
   - Host: `localhost`
   - Port: `5432`
   - User: `postgres`
   - Password: `postgres`
   - Database: `postgres` (leave as default to see all databases)
3. Click **Test** to verify connection
4. Click **Connect**
5. In the left sidebar, you should see all databases listed
6. **Right-click** on the connection → **Refresh** if databases don't appear

### DBeaver
1. **New Database Connection** → PostgreSQL
2. **Main Tab**:
   - Host: `localhost`
   - Port: `5432`
   - Database: `postgres` (to see all databases)
   - Username: `postgres`
   - Password: `postgres`
3. Click **Test Connection**
4. Click **Finish**
5. In Database Navigator, expand the connection
6. Expand **Databases** folder to see all databases
7. **Right-click** on connection → **Refresh** if needed

### pgAdmin
1. **Add New Server**
2. **General Tab**:
   - Name: `Data Warehouse`
3. **Connection Tab**:
   - Host: `localhost`
   - Port: `5432`
   - Maintenance database: `postgres`
   - Username: `postgres`
   - Password: `postgres`
4. Click **Save**
5. Expand server → **Databases** to see all databases
6. **Right-click** on server → **Refresh** if needed

### VS Code Extensions

**PostgreSQL Extension:**
1. Click PostgreSQL icon in sidebar
2. Click **+** to add connection
3. Use connection string: `postgresql://postgres:postgres@localhost:5432/postgres`
4. Expand connection to see databases

**SQLTools:**
1. Click SQLTools icon
2. Add new connection → PostgreSQL
3. Fill in connection details
4. Connect and expand to see databases

## Step 5: Common Issues

### Issue: "Connection Refused"
**Solution**: Container might not be running
```bash
docker-compose up -d postgres
```

### Issue: "Authentication Failed"
**Solution**: Check your `.env` file for correct password
```bash
cat .env
```

### Issue: "Database doesn't exist"
**Solution**: You might be connecting to a different PostgreSQL instance
- Verify you're connecting to `localhost:5432`
- Check if you have another PostgreSQL running: `lsof -i :5432`

### Issue: "Can see connection but no databases"
**Solution**: 
1. Make sure you're connected to the `postgres` database (not a specific database)
2. Refresh the connection in your GUI tool
3. Expand the "Databases" folder/node in the tree view

### Issue: "Port already in use"
**Solution**: Another service might be using port 5432
```bash
# Check what's using the port
lsof -i :5432

# Or change port in .env file
POSTGRES_PORT=5433
```

## Step 6: Verify from Command Line

If GUI tools aren't working, verify everything from command line:

```bash
# 1. Check container is running
docker ps | grep postgres

# 2. List all databases
docker exec data_warehouse_postgres psql -U postgres -c "\l"

# 3. Connect to AdventureWorks
docker exec -it data_warehouse_postgres psql -U postgres -d Adventureworks

# 4. List tables in AdventureWorks
docker exec data_warehouse_postgres psql -U postgres -d Adventureworks -c "\dt *.*"
```

## Step 7: Reset Connection

If nothing works, try:
1. **Disconnect** from the database in your GUI tool
2. **Delete** the connection/saved connection
3. **Create a new connection** with the exact settings above
4. **Test connection** before saving
5. **Connect** and refresh

## Still Not Working?

Run this diagnostic script:

```bash
echo "=== Container Status ==="
docker ps | grep postgres

echo -e "\n=== Database List ==="
docker exec data_warehouse_postgres psql -U postgres -c "\l"

echo -e "\n=== Port Check ==="
lsof -i :5432 || echo "Port 5432 is free"

echo -e "\n=== Connection Test ==="
docker exec data_warehouse_postgres psql -U postgres -c "SELECT current_database(), current_user;"
```

Share the output if you need further help!

