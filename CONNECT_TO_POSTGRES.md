# Connecting to PostgreSQL Database

This guide shows you different ways to connect to your PostgreSQL database running in Docker.

## Connection Details

Based on your `docker-compose.yml` and `.env` file:

- **Host**: `localhost` (from host machine) or `data_warehouse_postgres` (from Docker network)
- **Port**: `5432` (default, or as specified in `.env`)
- **User**: `postgres` (default, or as specified in `.env`)
- **Password**: `postgres` (default, or as specified in `.env`)
- **Default Database**: `data_warehouse` (default, or as specified in `.env`)

## Method 1: Using Docker Exec (Easiest)

Connect directly to the PostgreSQL container:

```bash
# Connect to default database (data_warehouse)
docker exec -it data_warehouse_postgres psql -U postgres

# Connect to a specific database
docker exec -it data_warehouse_postgres psql -U postgres -d data_warehouse

# Connect to AdventureWorks database (if installed)
docker exec -it data_warehouse_postgres psql -U postgres -d Adventureworks
```

## Method 2: Using psql from Host Machine

If you have `psql` installed on your host machine:

```bash
# Connect to default database
psql -h localhost -p 5432 -U postgres -d data_warehouse

# Connect to AdventureWorks database
psql -h localhost -p 5432 -U postgres -d Adventureworks
```

You'll be prompted for the password (default: `postgres`).

### Installing psql on macOS

If you don't have `psql` installed:

```bash
# Using Homebrew
brew install postgresql@16

# Or install just the client tools
brew install libpq
brew link --force libpq
```

## Method 3: Connection String Format

Use these connection strings with various tools:

### Standard PostgreSQL Connection String

```
postgresql://postgres:postgres@localhost:5432/data_warehouse
```

### For AdventureWorks Database

```
postgresql://postgres:postgres@localhost:5432/Adventureworks
```

### With Custom Credentials

If you've changed the credentials in `.env`:

```
postgresql://USERNAME:PASSWORD@localhost:PORT/DATABASE_NAME
```

## Method 4: Using GUI Tools

### pgAdmin

1. Download and install [pgAdmin](https://www.pgadmin.org/download/)
2. Create a new server connection:
   - **Name**: Data Warehouse
   - **Host**: `localhost`
   - **Port**: `5432`
   - **Username**: `postgres`
   - **Password**: `postgres`
   - **Database**: `data_warehouse` (or leave blank for default)

### DBeaver

1. Download and install [DBeaver](https://dbeaver.io/download/)
2. Create a new connection:
   - Select **PostgreSQL**
   - **Host**: `localhost`
   - **Port**: `5432`
   - **Database**: `data_warehouse`
   - **Username**: `postgres`
   - **Password**: `postgres`

### TablePlus

1. Download and install [TablePlus](https://tableplus.com/)
2. Create a new connection:
   - Select **PostgreSQL**
   - **Host**: `localhost`
   - **Port**: `5432`
   - **User**: `postgres`
   - **Password**: `postgres`
   - **Database**: `data_warehouse`

### VS Code Extensions

- **PostgreSQL** by Chris Kolkman
- **SQLTools** by Matheus Teixeira

Use the connection string: `postgresql://postgres:postgres@localhost:5432/data_warehouse`

## Method 5: Using Python (psycopg2)

```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="data_warehouse",
    user="postgres",
    password="postgres"
)

cursor = conn.cursor()
cursor.execute("SELECT version();")
print(cursor.fetchone())
conn.close()
```

## Method 6: Using Node.js (pg)

```javascript
const { Client } = require('pg');

const client = new Client({
  host: 'localhost',
  port: 5432,
  database: 'data_warehouse',
  user: 'postgres',
  password: 'postgres',
});

client.connect();
client.query('SELECT version()', (err, res) => {
  console.log(err, res);
  client.end();
});
```

## Common Commands Once Connected

Once you're connected via `psql`, here are some useful commands:

```sql
-- List all databases
\l

-- List all tables in current database
\dt

-- List all schemas
\dn

-- Describe a table
\d table_name

-- List all tables in a schema
\dt schema_name.*

-- Switch database
\c database_name

-- Show current database
SELECT current_database();

-- Show current user
SELECT current_user;

-- Exit psql
\q
```

## Troubleshooting

### Connection Refused

Make sure the PostgreSQL container is running:

```bash
docker ps | grep data_warehouse_postgres
```

If not running, start it:

```bash
docker-compose up -d postgres
```

### Authentication Failed

Check your `.env` file for the correct credentials:

```bash
cat .env
```

### Port Already in Use

If port 5432 is already in use, change it in your `.env` file:

```
POSTGRES_PORT=5433
```

Then restart the container:

```bash
docker-compose down
docker-compose up -d
```

### Can't Connect from Host

Ensure the port is properly mapped. Check with:

```bash
docker port data_warehouse_postgres
```

You should see: `5432/tcp -> 0.0.0.0:5432`

