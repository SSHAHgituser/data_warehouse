# AdventureWorks Sample Database

This directory contains the AdventureWorks sample database installation script for SQL Server. AdventureWorks is a Microsoft sample database that provides realistic business data for testing and development.

## Quick Installation

The easiest way to install AdventureWorks on SQL Server is using the automated script:

```bash
# From repository root
./adventureworks/install_adventureworks_sqlserver.sh

# Or from this directory
cd adventureworks
./install_adventureworks_sqlserver.sh
```

**Note:** The installation script is automatically run by `./start.sh` if the database doesn't exist.

The script will:
1. Check if SQL Server is running (start it if needed)
2. Download AdventureWorks2022 backup file (.bak)
3. Copy backup file into SQL Server container
4. Restore the database
5. Verify the installation

## Prerequisites

- Docker and Docker Compose installed
- SQL Server container running (via `docker-compose up -d sqlserver`)
- `wget` or `curl` installed
- Internet connection (to download backup file)

## Manual Installation

If you prefer manual installation or the script fails:

### Steps

1. **Ensure SQL Server is running:**
   ```bash
   docker-compose up -d sqlserver
   ```

2. **Wait for SQL Server to be ready:**
   ```bash
   # Check if SQL Server is ready
   docker exec data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd \
     -S localhost -U sa -P "YourStrong@Passw0rd" -C \
     -Q "SELECT 1"
   ```

3. **Download AdventureWorks backup file:**
   ```bash
   curl -L -o AdventureWorks2022.bak \
     'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak'
   ```

4. **Copy backup file to container:**
   ```bash
   docker cp AdventureWorks2022.bak data_warehouse_sqlserver:/var/opt/mssql/backup/
   ```

5. **Restore the database:**
   ```bash
   docker exec data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd \
     -S localhost -U sa -P "YourStrong@Passw0rd" -C \
     -Q "RESTORE DATABASE AdventureWorks2022 FROM DISK = '/var/opt/mssql/backup/AdventureWorks2022.bak' WITH MOVE 'AdventureWorks2022' TO '/var/opt/mssql/data/AdventureWorks2022.mdf', MOVE 'AdventureWorks2022_Log' TO '/var/opt/mssql/data/AdventureWorks2022_Log.ldf', REPLACE;"
   ```

## Verification

After installation, verify the database:

```bash
# Connect to database
docker exec -it data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourStrong@Passw0rd" -C \
  -d AdventureWorks2022

# List tables
SELECT TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;

# Sample query
SELECT TOP 5 * FROM Person.Person;
```

## Connecting from Host

If you have `sqlcmd` installed locally:

```bash
sqlcmd -S localhost,1433 -U sa -P "YourStrong@Passw0rd" -d AdventureWorks2022
```

Or using a connection string:
```
Server=localhost,1433;Database=AdventureWorks2022;User Id=sa;Password=YourStrong@Passw0rd;
```

### Using SQL Server Management Studio (SSMS)

1. Open SSMS
2. Connect to server: `localhost,1433`
3. Authentication: SQL Server Authentication
4. Login: `sa`
5. Password: `YourStrong@Passw0rd` (or your custom password from `.env`)

### Using Azure Data Studio

1. Open Azure Data Studio
2. Create new connection:
   - Server: `localhost,1433`
   - Authentication type: SQL Login
   - Username: `sa`
   - Password: `YourStrong@Passw0rd`
   - Database: `AdventureWorks2022`

## Environment Variables

You can customize the SQL Server password by setting environment variables:

```bash
# In .env file or export before running
export SQLSERVER_SA_PASSWORD="YourCustomPassword123!"
export SQLSERVER_PORT=1433
```

Then update `docker-compose.yml` or pass them when running:
```bash
SQLSERVER_SA_PASSWORD="YourCustomPassword123!" ./start.sh
```

## Troubleshooting

### Database Already Exists

If the database already exists, drop it first:

```bash
docker exec data_warehouse_sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourStrong@Passw0rd" -C \
  -Q "DROP DATABASE AdventureWorks2022;"
```

### Connection Issues

Check if SQL Server container is running:

```bash
docker ps | grep data_warehouse_sqlserver
```

Start it if needed:

```bash
docker-compose up -d sqlserver
```

### SQL Server Not Ready

SQL Server can take 30-60 seconds to start. Check logs:

```bash
docker-compose logs sqlserver
```

Wait for the message: "SQL Server is now ready for client connections."

### Password Issues

If you get authentication errors, verify the password matches:

```bash
# Check what password is set
docker exec data_warehouse_sqlserver printenv MSSQL_SA_PASSWORD

# Or check docker-compose.yml
grep SQLSERVER_SA_PASSWORD docker-compose.yml
```

### Backup File Download Fails

If the download fails, you can manually download and copy:

1. Download from: https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak
2. Copy to container: `docker cp AdventureWorks2022.bak data_warehouse_sqlserver:/var/opt/mssql/backup/`
3. Run restore command manually (see Manual Installation above)

## Database Details

- **Database Name**: `AdventureWorks2022`
- **Version**: AdventureWorks2022 (for SQL Server 2022)
- **Schemas**: Person, Production, Sales, Purchasing, HumanResources, etc.
- **Size**: ~200MB backup file, ~500MB restored database

## Files

- **install_adventureworks_sqlserver.sh** - Automated installation script for SQL Server
- **README.md** - This file

## Resources

- [Microsoft SQL Server Samples](https://github.com/Microsoft/sql-server-samples)
- [AdventureWorks Documentation](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure)
- [SQL Server Docker Documentation](https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-docker-container-configure)
