# dbt Project

dbt (data build tool) project for transforming data in the PostgreSQL data warehouse.

## Quick Start

The dbt documentation server is automatically started with `./start.sh` from the repository root. Access it at `http://localhost:8080`.

For manual startup, see the [main README](../README.md#step-by-step-setup).

## dbt Documentation

### Which Docs Are Being Served?

The dbt-docs container serves documentation for **all models in your dbt project**:

- **Staging models** (`models/staging/`) - Raw data transformations
- **Intermediate models** (`models/intermediate/`) - Dimensions and facts
  - Dimensions: `dim_customer`, `dim_date`, `dim_employee`, `dim_product`, `dim_territory`, `dim_vendor`
  - Facts: `fact_employee_quota`, `fact_inventory`, `fact_purchase_order`, `fact_sales_order`, `fact_sales_order_line`, `fact_work_order`
- **Mart models** (`models/marts/`) - Analytics-ready tables
  - `mart_customer_analytics`
  - `mart_employee_territory_performance`
  - `mart_operations`
  - `mart_product_analytics`
  - `mart_sales`

The docs are **automatically regenerated** each time the dbt-docs container starts, based on the current state of your dbt project files.

### How to Update the Docs

**Option 1: Restart the Container (Recommended)**
```bash
# From repository root
docker-compose restart dbt-docs

# Or use the stop/start scripts
./stop.sh
./start.sh
```

This will regenerate docs from the current dbt project files.

**Option 2: Rebuild the Container (If dbt Project Files Changed)**
```bash
# From repository root
docker-compose build dbt-docs
docker-compose up -d dbt-docs
```

Use this if you've added new models, changed model structure, or updated schema files.

**Option 3: Generate Docs Locally**
```bash
cd dbt
./generate_docs.sh
```

This generates docs in `dbt/target/` directory. To view locally:
```bash
cd dbt
./run_dbt.sh docs serve
```

**Option 4: Force Regeneration in Running Container**
```bash
# Regenerate docs inside the container
docker exec data_warehouse_dbt_docs dbt docs generate

# Restart nginx to serve new docs
docker exec data_warehouse_dbt_docs nginx -s reload
```

### When Do Docs Update?

- **On container start**: Docs are automatically regenerated when the container starts
- **After model changes**: Rebuild or restart the container to see changes
- **After schema updates**: Update `.yml` files and restart the container
- **After running dbt**: If you run `dbt run` or `dbt build`, restart the container to refresh docs

### Viewing the Docs

Access the documentation at: **http://localhost:8080**

The docs include:
- **Lineage graph**: Visual representation of model dependencies
- **Model documentation**: Descriptions, columns, tests, and relationships
- **Source documentation**: Raw table schemas and descriptions
- **Test results**: Data quality test outcomes

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
docker exec -i data_warehouse_postgres psql -U postgres -d data_warehouse <<EOF
CREATE SCHEMA IF NOT EXISTS dbt;
GRANT ALL PRIVILEGES ON SCHEMA dbt TO postgres;
EOF
```

### Run dbt Commands

Use the convenience script:

```bash
cd dbt
./run_dbt.sh [command]
```

Or manually:

```bash
cd dbt
source venv/bin/activate
export DBT_PROFILES_DIR=.
dbt [command]
```

Common commands:
- `dbt run` - Run all models
- `dbt test` - Run all tests
- `dbt build` - Run models and tests
- `dbt docs generate` - Generate documentation
- `dbt docs serve` - Serve docs locally (port 8080)

### Project Structure

```
dbt/
├── models/
│   ├── staging/          # Raw data transformations
│   ├── intermediate/     # Dimensions and facts
│   └── marts/            # Analytics-ready tables
├── macros/               # Reusable SQL macros
├── seeds/                # Seed data files
├── tests/                # Custom tests
├── analyses/             # Ad-hoc analyses
├── dbt_project.yml       # Project configuration
├── profiles.yml          # Database connection config
└── README.md            # This file
```

## Troubleshooting

### Docs Not Updating

1. **Check if container is running**:
   ```bash
   docker-compose ps dbt-docs
   ```

2. **Check container logs**:
   ```bash
   docker-compose logs dbt-docs
   ```

3. **Verify dbt project files are in container**:
   ```bash
   docker exec data_warehouse_dbt_docs ls -la /app/models/
   ```

4. **Regenerate docs manually**:
   ```bash
   docker exec data_warehouse_dbt_docs dbt docs generate
   ```

### Database Connection Issues

1. **Verify PostgreSQL is running**:
   ```bash
   docker-compose ps postgres
   ```

2. **Test connection**:
   ```bash
   docker exec data_warehouse_dbt_docs dbt debug
   ```

3. **Check environment variables in docker-compose.yml**

For more information about the overall project setup, see the [main README](../README.md).
