# Adventure Works Sample Database Installation Guide

This guide provides step-by-step instructions to install the Adventure Works sample database into your PostgreSQL instance.

## Prerequisites

- Docker and Docker Compose installed
- PostgreSQL container running (via `docker-compose up -d`)
- Git installed
- `wget` or `curl` installed
- Ruby (optional, for CSV preprocessing)

## Quick Installation (Automated)

Run the installation script from the repository root:

```bash
chmod +x install_adventureworks.sh
./install_adventureworks.sh
```

The script will automatically use the cleanup script located in the `adventureworks/` folder.

## Manual Installation Steps

If you prefer to install manually or the script fails, follow these steps:

### Step 1: Ensure PostgreSQL is Running

```bash
docker-compose up -d postgres
```

Wait for the container to be healthy (check with `docker ps`).

### Step 2: Clone the AdventureWorks-for-Postgres Repository

```bash
git clone https://github.com/lorint/AdventureWorks-for-Postgres.git
cd AdventureWorks-for-Postgres
```

### Step 3: Download AdventureWorks Data Files

Using `wget` (Linux):
```bash
wget --no-verbose --continue 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip'
```

Or using `curl` (macOS/Linux):
```bash
curl -L -o AdventureWorks-oltp-install-script.zip 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks-oltp-install-script.zip'
```

Then extract:
```bash
unzip AdventureWorks-oltp-install-script.zip
```

### Step 4: Prepare CSV Files (Optional but Recommended)

If you have Ruby installed:

```bash
ruby update_csvs.rb
```

This script modifies the CSV files to be compatible with PostgreSQL.

### Step 5: Create the AdventureWorks Database

```bash
docker exec -i data_warehouse_postgres psql -U postgres -c "CREATE DATABASE \"Adventureworks\";"
```

### Step 6: Install Schema and Load Data

```bash
docker exec -i data_warehouse_postgres psql -U postgres -d Adventureworks < install.sql
```

This step may take several minutes as it creates all tables, indexes, and loads the data.

### Step 7: Clean Up Empty Schemas (Optional but Recommended)

The installation creates some empty schemas (`hr`, `pe`, `pr`, `pu`, `sa`) that only contain view aliases. To clean these up, you can either:

**Option 1: Use the cleanup script file:**
```bash
docker exec -i data_warehouse_postgres psql -U postgres -d Adventureworks < adventureworks/cleanup_empty_schemas.sql
```

**Option 2: Run SQL directly:**
```bash
docker exec -i data_warehouse_postgres psql -U postgres -d Adventureworks <<EOF
DROP SCHEMA IF EXISTS hr CASCADE;
DROP SCHEMA IF EXISTS pe CASCADE;
DROP SCHEMA IF EXISTS pr CASCADE;
DROP SCHEMA IF EXISTS pu CASCADE;
DROP SCHEMA IF EXISTS sa CASCADE;
EOF
```

**Note:** The automated installation script includes this cleanup step automatically using the cleanup script file.

## Verification

After installation, verify the database was created successfully:

```bash
# List all databases
docker exec -it data_warehouse_postgres psql -U postgres -c "\l"

# Connect to AdventureWorks database
docker exec -it data_warehouse_postgres psql -U postgres -d Adventureworks

# List all schemas
\dn

# List tables in a specific schema
\dt humanresources.*
\dt sales.*

# List all tables across all schemas
\dt *.*

# Check table count by schema
SELECT schemaname, COUNT(*) as table_count 
FROM pg_tables 
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
GROUP BY schemaname 
ORDER BY schemaname;

# Sample query
SELECT * FROM person.person LIMIT 5;
```

## Connecting from Host Machine

If you have `psql` installed on your host machine, you can connect using:

```bash
psql -h localhost -p 5432 -U postgres -d Adventureworks
```

Use the password from your `.env` file (default: `postgres`).

## Troubleshooting

### Database Already Exists Error

If you get an error that the database already exists, you can drop it first:

```bash
docker exec -i data_warehouse_postgres psql -U postgres -c "DROP DATABASE \"Adventureworks\";"
```

Then rerun the installation.

### Connection Issues

Make sure the PostgreSQL container is running:

```bash
docker ps | grep data_warehouse_postgres
```

If not running, start it:

```bash
docker-compose up -d postgres
```

### Permission Issues

If you encounter permission issues, ensure the script is executable:

```bash
chmod +x install_adventureworks.sh
```

## Resources

- [AdventureWorks-for-Postgres GitHub Repository](https://github.com/lorint/AdventureWorks-for-Postgres)
- [Microsoft SQL Server Samples](https://github.com/Microsoft/sql-server-samples)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

