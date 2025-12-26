# Data Warehouse Stack

A modern data stack that can be quickly deployed and is ready to scale. This repository includes:

- **PostgreSQL**: Database and storage
- **Adventure Works**: Sample dataset from Microsoft
- **dbt Core**: Data transformation
- **Streamlit**: Interactive dashboards
- **Airbyte**: Extract and Load (via `abctl` - see [Airbyte Setup](#airbyte-setup))

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Git (for Adventure Works installation)
- For Airbyte: 8GB+ RAM, 4+ CPUs recommended

### Starting All Services

All services are configured in `docker-compose.yml`. Start them with:

**Option 1: Using the startup script (recommended)**
```bash
./start.sh
```

**Option 2: Using Docker Compose directly**
```bash
# Start all services
docker-compose up -d

# Or start services individually
docker-compose up -d postgres      # PostgreSQL database
docker-compose up -d streamlit     # Streamlit dashboard
docker-compose up -d dbt-docs      # dbt documentation server
```

### Service URLs

Once started, access the services at:

- **PostgreSQL**: `localhost:5432`
  - Default credentials: `postgres/postgres`
  - Default database: `data_warehouse`
  
- **Streamlit Dashboard**: `http://localhost:8501`

- **dbt Documentation**: `http://localhost:8080`

- **Airbyte Web UI**: `http://localhost:8000` (see [Airbyte Setup](#airbyte-setup) below)

### Verify Services are Running

```bash
# Check all containers
docker-compose ps

# View logs
docker-compose logs -f [service_name]

# Check specific service
docker-compose logs -f postgres
docker-compose logs -f streamlit
docker-compose logs -f dbt-docs
```

## Step-by-Step Setup

### 1. Start PostgreSQL

```bash
docker-compose up -d postgres
```

Wait for PostgreSQL to be ready (healthcheck will verify):

```bash
docker-compose ps postgres
```

**Connection Details:**
- Host: `localhost`
- Port: `5432` (or value from `POSTGRES_PORT` env var)
- User: `postgres` (or value from `POSTGRES_USER` env var)
- Password: `postgres` (or value from `POSTGRES_PASSWORD` env var)
- Database: `data_warehouse` (or value from `POSTGRES_DB` env var)

**Quick Connection Test:**
```bash
docker exec -it data_warehouse_postgres psql -U postgres -d data_warehouse
```

### 2. Start Streamlit

```bash
docker-compose up -d streamlit
```

The Streamlit dashboard will be available at `http://localhost:8501` (or the port specified in `STREAMLIT_PORT` environment variable).

**Note:** Streamlit depends on PostgreSQL, so ensure PostgreSQL is running first.

### 3. Start dbt Documentation Server

```bash
docker-compose up -d dbt-docs
```

The dbt documentation will be available at `http://localhost:8080` (or the port specified in `DBT_DOCS_PORT` environment variable).

**Note:** The dbt-docs service will automatically generate documentation on startup. It depends on PostgreSQL being healthy.

### 4. Airbyte Setup

Airbyte is **not** included in `docker-compose.yml` because:

- **Docker Compose is deprecated**: Airbyte deprecated Docker Compose in version 1.0 (September 2024)
- **Images not available**: Airbyte doesn't publish images to Docker Hub - they're only available via Helm charts
- **Official method**: `abctl` is the only officially supported local deployment method
- **Better experience**: `abctl` handles everything automatically (Kubernetes, Helm charts, image management)

**To install Airbyte:**

```bash
cd airbyte
./setup_with_abctl.sh
```

This will:
1. Install `abctl` if needed
2. Set up Airbyte using Kubernetes (via `kind`)
3. Deploy using Helm charts
4. Provide you with credentials

The Airbyte web UI will be available at `http://localhost:8000`.

**Note:** Airbyte requires significant resources (recommended: 8GB+ RAM, 4+ CPUs). See [airbyte/README.md](airbyte/README.md) for detailed setup and troubleshooting.

### 5. (Optional) Install Adventure Works Sample Data

To install the Adventure Works sample database:

```bash
./adventureworks/install_adventureworks.sh
```

This will:
1. Start PostgreSQL if not running
2. Download and install the Adventure Works database
3. Create the `Adventureworks` database

## Environment Variables

You can customize the configuration using environment variables or a `.env` file:

```bash
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=data_warehouse
POSTGRES_PORT=5432

# Streamlit
STREAMLIT_PORT=8501

# dbt Docs
DBT_DOCS_PORT=8080
```

## Stopping Services

```bash
# Stop all services
docker-compose down

# Stop specific service
docker-compose stop [service_name]

# Stop and remove volumes (⚠️ deletes data)
docker-compose down -v
```

## Project Structure

```
data_warehouse/
├── docker-compose.yml          # Core services (postgres, streamlit, dbt-docs)
├── postgres/                   # PostgreSQL configuration (if any)
├── dbt/                        # dbt project
│   ├── models/                 # SQL models
│   ├── profiles.yml            # Database connection config
│   └── README.md               # dbt-specific documentation
├── streamlit/                  # Streamlit dashboard
│   ├── app.py                  # Main dashboard application
│   └── README.md               # Streamlit-specific documentation
├── adventureworks/             # Adventure Works installation files
│   ├── install_adventureworks.sh  # Installation script
│   ├── cleanup_empty_schemas.sql  # Cleanup script
│   └── README.md               # Adventure Works documentation
└── airbyte/                    # Airbyte Core setup
    ├── README.md               # Airbyte setup instructions
    ├── setup_with_abctl.sh     # Official Airbyte setup script
    └── troubleshooting.md      # Troubleshooting guide
```

### Why Airbyte is Not in Docker Compose

Airbyte is **not** included in `docker-compose.yml` for several important reasons:

1. **Docker Compose Deprecated**: Airbyte officially deprecated Docker Compose deployments in version 1.0 (September 2024). It's no longer supported or maintained.

2. **Images Not on Docker Hub**: Airbyte doesn't publish pre-built images to Docker Hub. The images (`airbyte/server`, `airbyte/worker`, `airbyte/scheduler`) don't exist there. They're only available via Helm charts from GitHub Container Registry.

3. **Official Method**: `abctl` is the only officially supported local deployment method. It:
   - Uses Kubernetes (via `kind`) for orchestration
   - Automatically pulls images from the correct registry (ghcr.io)
   - Handles all configuration via Helm charts
   - Gets automatic updates and support

4. **Better Experience**: `abctl` is simpler and more reliable:
   - One command: `abctl local install`
   - Automatic image management
   - No manual image building required
   - Official support and updates

**For Airbyte setup, use:**
```bash
cd airbyte
./setup_with_abctl.sh
```

See [airbyte/README.md](airbyte/README.md) for detailed explanation of why `abctl` works but Docker Compose doesn't.

## Development

### Working with dbt

See [dbt/README.md](dbt/README.md) for detailed dbt setup and usage instructions.

### Working with Streamlit

See [streamlit/README.md](streamlit/README.md) for Streamlit development instructions.

## Troubleshooting

### Services Won't Start

1. Check if ports are already in use:
   ```bash
   lsof -i :5432  # PostgreSQL
   lsof -i :8501  # Streamlit
   lsof -i :8080  # dbt-docs
   ```

2. Check container logs:
   ```bash
   docker-compose logs [service_name]
   ```

3. Verify Docker is running:
   ```bash
   docker ps
   ```

### Rebuild Services After Changes

```bash
# Rebuild specific service
docker-compose build [service_name]

# Rebuild and restart
docker-compose up -d --build [service_name]
```

## Additional Resources

- [dbt Documentation](dbt/README.md)
- [Streamlit Documentation](streamlit/README.md)
- [Adventure Works Installation](adventureworks/README.md)
- [Airbyte Setup](airbyte/README.md)

## License

See [LICENSE](LICENSE) file for details.
