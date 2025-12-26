# dbt Project

dbt (data build tool) project for transforming data in the PostgreSQL data warehouse.

## Quick Start

The dbt documentation server is configured in the root `docker-compose.yml`. To start it:

```bash
# From project root - start all services
docker-compose up -d

# Or start just dbt-docs (PostgreSQL must be running first)
docker-compose up -d dbt-docs
```

Access the documentation at `http://localhost:8080` (or the port specified in `DBT_DOCS_PORT` environment variable).

## Local Development

### Setup Virtual Environment

```bash
cd dbt
./setup_venv.sh
```

This creates a Python virtual environment and installs dbt-postgres and dependencies.

### Configure Connection

The `profiles.yml` file contains the database connection configuration. Use the convenience script:

```bash
cd dbt
./run_dbt.sh debug
```

Or manually:

```bash
cd dbt
source venv/bin/activate
export DBT_PROFILES_DIR=.
dbt debug
```

### Create dbt Schema

Before running dbt, create the schema in PostgreSQL:

```bash
./setup_schema.sh
```

Or manually:

```bash
docker exec -i data_warehouse_postgres psql -U postgres -d data_warehouse -c "CREATE SCHEMA IF NOT EXISTS dbt;"
```

## Usage

Always activate the virtual environment or use the convenience script:

```bash
cd dbt
./run_dbt.sh <command>
```

### Common Commands

```bash
# Test connection
./run_dbt.sh debug

# Run all models
./run_dbt.sh run

# Run specific model
./run_dbt.sh run --select model_name

# Run tests
./run_dbt.sh test

# Generate documentation
./run_dbt.sh docs generate

# Serve documentation locally
./run_dbt.sh docs serve
```

## Docker Documentation Server

The dbt docs can be hosted in a Docker container. The container automatically generates docs on startup and serves them via nginx.

**Using Docker Compose:**
```bash
docker-compose up -d dbt-docs
```

**Docker Commands:**
- View logs: `docker-compose logs -f dbt-docs`
- Stop: `docker-compose stop dbt-docs`
- Restart: `docker-compose restart dbt-docs`
- Rebuild: `docker-compose build dbt-docs`

## Project Structure

```
dbt/
├── profiles.yml          # Database connection configuration
├── dbt_project.yml       # dbt project configuration
├── requirements.txt      # Python dependencies
├── models/               # SQL model files
│   └── example/          # Example models
├── seeds/                # CSV seed files
├── tests/                # Custom tests
├── macros/               # Reusable SQL macros
└── analyses/             # Ad-hoc analysis queries
```

## Connection Details

- **Host**: localhost (from host) or postgres (from Docker network)
- **Port**: 5432
- **Database**: data_warehouse
- **Schema**: dbt
- **User**: postgres
- **Password**: postgres (update in profiles.yml or use environment variable)

## Environment Variables

For better security, use environment variables:

```bash
export DBT_PASSWORD=postgres
export DBT_USER=postgres
```

Then update `profiles.yml` to use `${DBT_PASSWORD}` and `${DBT_USER}`.

## Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Postgres Adapter](https://docs.getdbt.com/reference/warehouse-profiles/postgres-profile)

For more information about the overall project setup, see the [main README](../README.md).
