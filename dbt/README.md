# dbt Project

dbt (data build tool) project for transforming data in the PostgreSQL data warehouse.

## Quick Start

The dbt documentation server is automatically started with `./start.sh` from the repository root. Access it at `http://localhost:8080`.

For manual startup, see the [main README](../README.md#step-by-step-setup).

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

The dbt documentation is served via Docker container (see `docker-compose.yml`). The container automatically generates docs on startup and serves them via nginx.

For Docker commands, see the [main README](../README.md#stopping-services).

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
