# AdventureWorks Sample Database

This directory contains the AdventureWorks sample database installation scripts for both PostgreSQL and SQL Server. AdventureWorks is a Microsoft sample database that provides realistic business data for testing and development.

## Available Installations

- **PostgreSQL**: See this README for PostgreSQL installation
- **SQL Server**: See [README_SQLSERVER.md](./README_SQLSERVER.md) for SQL Server installation

## Quick Installation

The easiest way to install AdventureWorks is using the automated script:

```bash
# From repository root
./adventureworks/install_adventureworks.sh

# Or from this directory
cd adventureworks
./install_adventureworks.sh
```

**Note:** The installation script is automatically run by `./start.sh` if the database doesn't exist.

The script will:
1. Check if PostgreSQL is running (start it if needed)
2. Download AdventureWorks data files
3. Create the `Adventureworks` database
4. Install schema and load data
5. Clean up empty schemas

## Files

- **install_adventureworks.sh** - Automated installation script
- **cleanup_empty_schemas.sql** - SQL script to remove empty schemas after installation
- **README.md** - This file

## Manual Installation

If you prefer manual installation or the script fails:

### Prerequisites

- Docker and Docker Compose installed
- PostgreSQL container running (via `docker-compose up -d postgres`)
- Git installed
- `wget` or `curl` installed
- Ruby (optional, for CSV preprocessing)

### Steps

1. **Ensure PostgreSQL is running:**
   ```bash
   docker-compose up -d postgres
   ```

2. **Clone and prepare AdventureWorks:**
   ```bash
   git clone https://github.com/lorint/AdventureWorks-for-Postgres.git
   cd AdventureWorks-for-Postgres
   
   # Download data files
   curl -L -o AdventureWorks-oltp-install-script.zip \
     'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip'
   
   unzip AdventureWorks-oltp-install-script.zip
   
   # Prepare CSV files (optional)
   ruby update_csvs.rb  # if Ruby is installed
   ```

3. **Create database and install:**
   ```bash
   docker exec -i data_warehouse_postgres psql -U postgres -c "CREATE DATABASE \"Adventureworks\";"
   docker exec -i data_warehouse_postgres psql -U postgres -d Adventureworks < install.sql
   ```

4. **Clean up empty schemas:**
   ```bash
   docker exec -i data_warehouse_postgres psql -U postgres -d Adventureworks < ../cleanup_empty_schemas.sql
   ```

## Verification

After installation, verify the database:

```bash
# Connect to database
docker exec -it data_warehouse_postgres psql -U postgres -d Adventureworks

# List schemas
\dn

# List tables in a schema
\dt humanresources.*
\dt sales.*

# Sample query
SELECT * FROM person.person LIMIT 5;
```

## Connecting from Host

If you have `psql` installed locally:

```bash
psql -h localhost -p 5432 -U postgres -d Adventureworks
```

Default password: `postgres` (or from your `.env` file)

## Troubleshooting

### Database Already Exists

If the database already exists, drop it first:

```bash
docker exec -i data_warehouse_postgres psql -U postgres -c "DROP DATABASE \"Adventureworks\";"
```

### Connection Issues

Check if PostgreSQL container is running:

```bash
docker ps | grep data_warehouse_postgres
```

Start it if needed:

```bash
docker-compose up -d postgres
```

## Resources

- [AdventureWorks-for-Postgres GitHub](https://github.com/lorint/AdventureWorks-for-Postgres)
- [Microsoft SQL Server Samples](https://github.com/Microsoft/sql-server-samples)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
