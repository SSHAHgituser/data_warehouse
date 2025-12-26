# dbt Project for Data Warehouse

This folder contains the dbt (data build tool) project for transforming data in the PostgreSQL data warehouse.

## Setup

### 1. Set Up Virtual Environment and Install dbt

We use a Python virtual environment to manage dependencies. Run the setup script:

```bash
cd dbt
./setup_venv.sh
```

This will:
- Create a Python virtual environment (`venv/`)
- Install dbt-postgres and all dependencies from `requirements.txt`

**Manual setup (alternative):**
```bash
cd dbt
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 2. Configure Profiles

The `profiles.yml` file contains the connection configuration. You have two options:

**Option 1: Use the convenience script (recommended)**
```bash
cd dbt
./run_dbt.sh debug
```

**Option 2: Use profiles.yml in this folder manually**
```bash
cd dbt
source venv/bin/activate
export DBT_PROFILES_DIR=.
dbt debug
```

**Option 3: Copy to standard location (for production)**
```bash
mkdir -p ~/.dbt
cp dbt/profiles.yml ~/.dbt/profiles.yml
# Then just use: dbt debug (no need for DBT_PROFILES_DIR)
```

**Option 3: Use environment variables (recommended for security)**
```bash
export DBT_PASSWORD=postgres
# Then update profiles.yml to use: password: ${DBT_PASSWORD}
```

### 3. Create the dbt Schema

Before running dbt, create the schema in PostgreSQL:

```bash
./setup_schema.sh
```

Or manually:
```bash
docker exec -i data_warehouse_postgres psql -U postgres -d data_warehouse -c "CREATE SCHEMA IF NOT EXISTS dbt;"
```

Or connect and run:
```sql
CREATE SCHEMA IF NOT EXISTS dbt;
```

## Project Structure

```
dbt/
├── profiles.yml          # Database connection configuration
├── dbt_project.yml       # dbt project configuration
├── requirements.txt      # Python dependencies
├── setup_venv.sh         # Script to set up virtual environment
├── setup_schema.sh       # Script to create dbt schema in PostgreSQL
├── run_dbt.sh            # Convenience script to run dbt in venv
├── venv/                 # Python virtual environment (created by setup)
├── models/               # SQL model files
│   └── example/          # Example models
├── seeds/                # CSV seed files
├── tests/                # Custom tests
├── macros/               # Reusable SQL macros
└── analyses/             # Ad-hoc analysis queries
```

## Usage

**Important:** Always activate the virtual environment before running dbt commands:

```bash
cd dbt
source venv/bin/activate
```

Or use the convenience script (automatically activates venv):

```bash
cd dbt
./run_dbt.sh <command>
```

### Test Connection

```bash
# Using the convenience script (recommended)
./run_dbt.sh debug

# Or manually with venv activated
source venv/bin/activate
export DBT_PROFILES_DIR=.
dbt debug
```

### Run Models

```bash
# Run all models
./run_dbt.sh run

# Run specific model
./run_dbt.sh run --select model_name

# Run models in a folder
./run_dbt.sh run --select example.*

# Or with venv activated
source venv/bin/activate
export DBT_PROFILES_DIR=.
dbt run
```

### Test Models

```bash
# Run all tests
./run_dbt.sh test

# Test specific model
./run_dbt.sh test --select model_name

# Or with venv activated
source venv/bin/activate
export DBT_PROFILES_DIR=.
dbt test
```

### Generate Documentation

```bash
# Generate docs
./run_dbt.sh docs generate

# Serve docs
./run_dbt.sh docs serve

# Or with venv activated
source venv/bin/activate
export DBT_PROFILES_DIR=.
dbt docs generate
dbt docs serve
```

### Seed Data

```bash
# Load seed files
./run_dbt.sh seed

# Or with venv activated
source venv/bin/activate
export DBT_PROFILES_DIR=.
dbt seed
```

## Connection Details

- **Host**: localhost
- **Port**: 5432
- **Database**: data_warehouse
- **Schema**: dbt
- **User**: postgres
- **Password**: postgres (update in profiles.yml or use environment variable)

## Environment Variables

For better security, use environment variables for sensitive data:

```bash
export DBT_PASSWORD=postgres
export DBT_USER=postgres
```

Then update `profiles.yml`:
```yaml
user: ${DBT_USER}
password: ${DBT_PASSWORD}
```

## Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Postgres Adapter](https://docs.getdbt.com/reference/warehouse-profiles/postgres-profile)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)

