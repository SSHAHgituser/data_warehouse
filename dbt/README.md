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

#### Local Generation

```bash
# Generate docs
./run_dbt.sh docs generate

# Or use the dedicated script
./generate_docs.sh

# Serve docs locally
./run_dbt.sh docs serve

# Or with venv activated
source venv/bin/activate
export DBT_PROFILES_DIR=.
dbt docs generate
dbt docs serve
```

#### Docker Deployment

The dbt docs can be hosted in a Docker container. The container will automatically generate docs on startup and serve them via nginx.

**Using Docker Compose (Recommended):**

```bash
# From project root - run dbt-docs service
docker-compose up -d dbt-docs

# Or run all services together
docker-compose up -d
```

The docs will be available at `http://localhost:8080` (or the port specified in `DBT_DOCS_PORT` environment variable).

**Using Docker directly:**

```bash
cd dbt

# Build the image
docker build -t dbt-docs .

# Run the container
docker run -d \
  -p 8080:80 \
  -e DBT_HOST=host.docker.internal \
  -e DBT_PORT=5432 \
  -e DBT_USER=postgres \
  -e DBT_PASSWORD=postgres \
  -e DBT_DBNAME=data_warehouse \
  -e DBT_SCHEMA=dbt \
  --name dbt-docs \
  dbt-docs
```

**Docker Commands:**

- View logs: `docker-compose logs -f dbt-docs` or `docker logs -f dbt-docs`
- Stop container: `docker-compose stop dbt-docs` or `docker stop dbt-docs`
- Restart container: `docker-compose restart dbt-docs` or `docker restart dbt-docs`
- Rebuild after changes: `docker-compose build dbt-docs` or `docker build -t dbt-docs .`

**Note:** The Docker container generates docs at startup. If you want to serve pre-generated docs, generate them locally first using `./generate_docs.sh`, then the container will use the existing docs if generation fails.

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

