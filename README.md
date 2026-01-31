# Data Warehouse Stack

A modern data stack that can be quickly deployed and is ready to scale. This repository includes:

- **PostgreSQL**: Database and storage
- **Adventure Works**: Sample dataset from Microsoft
- **dbt Core**: Data transformation
- **Streamlit**: Interactive dashboards with **AI Analytics Assistant**
- **Airbyte**: Extract and Load (via `abctl` - see [Airbyte Setup](#airbyte-setup))
- **AI Assistant**: Natural language queries powered by OpenAI GPT-4 (see [AI Setup](#ai-assistant-setup))

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Git (for Adventure Works installation)
- For Airbyte: 8GB+ RAM, 4+ CPUs recommended

### 1. Start All Services

Start all infrastructure services (PostgreSQL, SQL Server, Streamlit, dbt-docs, Airbyte):

```bash
./start.sh
```

This script will:
- Start PostgreSQL, Streamlit, dbt-docs, and SQL Server
- Automatically install AdventureWorks database on SQL Server if it doesn't exist
- Automatically install and start Airbyte if not already installed (takes ~30 minutes on first run)

### 2. Launch Analytics (After Data Ingestion)

Use Airbyte to ingest data from SQLServer AdventureWorks database to PostgresSQL data_warehouse database.
Remember to bring schema.table from source to data_warehouse database to match with dbt source.
Once data has been ingested into PostgreSQL, run the analytics stack:

```bash
./launch.sh
```

This script will:
- Run dbt models to transform AdventureWorks data
- Generate dbt documentation
- Build and launch Streamlit dashboard
- Build and launch dbt documentation
- Open both applications in your browser

### 3. Stop All Services

Stop all services:

```bash
./stop.sh
```

This will stop all services including Airbyte (if running).

### Service URLs

Once started, access the services at:

- **PostgreSQL**: `localhost:5432`
  - Default credentials: `postgres/postgres`
  - Default database: `data_warehouse`
  
- **Streamlit Dashboard**: `http://localhost:8501`

- **dbt Documentation**: `http://localhost:8080`

- **SQL Server**: `localhost:1433`
  - Default credentials: `sa/YourStrong@Passw0rd` (or value from `SQLSERVER_SA_PASSWORD` env var)
  - Default database: `AdventureWorks2022` (after installation)
  
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
docker-compose logs -f sqlserver
```

---

## Manual Setup and Configuration

### Starting Services Manually

**Option 1: Using Docker Compose directly**
```bash
# Start all services
docker-compose up -d

# Or start services individually
docker-compose up -d postgres      # PostgreSQL database
docker-compose up -d streamlit     # Streamlit dashboard
docker-compose up -d dbt-docs      # dbt documentation server
docker-compose up -d sqlserver     # SQL Server database
```

### Step-by-Step Setup

The `./start.sh` script automates all of this (including Airbyte installation), but here's the manual process:

#### 1. Start PostgreSQL

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

#### 2. Start Streamlit

```bash
docker-compose up -d streamlit
```

Access at `http://localhost:8501` (or the port specified in `STREAMLIT_PORT`).

#### 3. Start dbt Documentation Server

```bash
docker-compose up -d dbt-docs
```

Access at `http://localhost:8080` (or the port specified in `DBT_DOCS_PORT`).

**Note:** The dbt-docs service automatically generates documentation on startup.

#### 4. Airbyte Setup

Airbyte is **not** included in `docker-compose.yml` because:

- **Docker Compose is deprecated**: Airbyte deprecated Docker Compose in version 1.0 (September 2024)
- **Images not available**: Airbyte doesn't publish images to Docker Hub - they're only available via Helm charts
- **Official method**: `abctl` is the only officially supported local deployment method
- **Better experience**: `abctl` handles everything automatically (Kubernetes, Helm charts, image management)

**Automatic Installation (Recommended):**

The `./start.sh` script automatically installs and starts Airbyte if it's not already installed:
- Installs `abctl` if needed
- Installs Airbyte (takes ~30 minutes on first run)
- Starts the Airbyte server

**Manual Installation:**

If you prefer to install Airbyte manually:

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

#### 5. (Optional) Install AdventureWorks Sample Data

The `./start.sh` script automatically installs AdventureWorks on SQL Server if it doesn't exist. To install manually:

```bash
./adventureworks/install_adventureworks_sqlserver.sh
```

This will:
1. Start SQL Server if not running
2. Download and restore the AdventureWorks2022 database
3. Verify the installation

See [adventureworks/README.md](adventureworks/README.md) for detailed installation instructions.

### Environment Variables

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

# SQL Server
SQLSERVER_SA_PASSWORD=YourStrong@Passw0rd
SQLSERVER_PORT=1433
```

### Stopping Services Manually

**Option 1: Using the stop script (recommended)**
```bash
./stop.sh
```
This will stop all services including Airbyte (if running).

**Option 2: Using Docker Compose directly**
```bash
# Stop all services
docker-compose down

# Stop specific service
docker-compose stop [service_name]

# Stop and remove volumes (⚠️ deletes data)
docker-compose down -v
```

**To stop Airbyte separately:**
```bash
abctl local stop
```

## Project Structure

```
data_warehouse/
├── docker-compose.yml          # Core services (postgres, streamlit, dbt-docs, sqlserver)
├── start.sh                    # Startup script for all services
├── launch.sh                   # Launch analytics stack (dbt, docs, streamlit)
├── stop.sh                     # Shutdown script for all services
├── dbt/                        # dbt project
│   ├── models/                 # SQL models (staging, intermediate, marts)
│   │   └── schema_ai.md        # Auto-generated AI context (by run_dbt.sh)
│   ├── scripts/
│   │   └── generate_ai_schema.py  # AI sync script (auto-run on dbt run)
│   ├── profiles.yml            # Database connection config
│   ├── run_dbt.sh              # Convenience script for running dbt commands
│   ├── setup_venv.sh           # Virtual environment setup script
│   ├── setup_schema.sh         # Database schema setup script
│   ├── generate_docs.sh        # Documentation generation script
│   └── README.md               # dbt-specific documentation
├── streamlit/                  # Streamlit dashboard
│   ├── app.py                  # Main dashboard application
│   ├── pages/                  # Multi-page analytics modules
│   ├── ai/                     # AI Analytics Assistant module
│   │   └── allowed_tables.json # Auto-generated table whitelist (by dbt run)
│   ├── run.sh                  # Convenience script for local development
│   ├── requirements.txt        # Python dependencies
│   └── README.md               # Streamlit-specific documentation
├── adventureworks/             # AdventureWorks installation files
│   ├── install_adventureworks_sqlserver.sh  # SQL Server installation script
│   ├── README_SQLSERVER.md     # SQL Server installation documentation
│   └── README.md               # AdventureWorks documentation
└── airbyte/                    # Airbyte Core setup
    ├── README.md               # Airbyte setup instructions
    ├── setup_with_abctl.sh     # Official Airbyte setup script
    └── troubleshooting.md      # Troubleshooting guide
```

## AI Assistant Setup

The Streamlit dashboard includes an **AI Analytics Assistant** that lets you query your data using natural language (e.g., "What is our revenue by territory?").

### 1. Get an OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Create an account or sign in
3. Click **"Create new secret key"**
4. Copy the key (starts with `sk-`)

### 2. Configure Your API Key

Create a `.env` file in the `streamlit/` directory:

```bash
cd streamlit
cat > .env << 'EOF'
OPENAI_API_KEY=sk-proj-your-actual-key-here
EOF
```

> ⚠️ **Security:** The `.env` file is already in `.gitignore` and will NOT be committed to Git.

### 3. Use the AI Assistant

1. Start the dashboard: `http://localhost:8501`
2. Navigate to **🤖 AI Assistant** in the sidebar
3. Ask questions in plain English!

For more details, see [streamlit/ai/README.md](streamlit/ai/README.md).

### AI Sync with dbt Models

When you add new dbt models, the AI components are **automatically synchronized**:

```bash
cd dbt
./run_dbt.sh run   # Runs dbt AND syncs AI components
```

This auto-generates:
- `dbt/models/schema_ai.md` - Optimized LLM context
- `streamlit/ai/allowed_tables.json` - SQL validator whitelist

**No manual updates needed!** New tables are automatically available to the AI assistant.

---

## Component Documentation

Each component has its own README with component-specific details:

- **[dbt/README.md](dbt/README.md)** - dbt project setup, local development, and usage
- **[streamlit/README.md](streamlit/README.md)** - Streamlit dashboard development
- **[streamlit/ai/README.md](streamlit/ai/README.md)** - AI Analytics Assistant setup
- **[adventureworks/README.md](adventureworks/README.md)** - AdventureWorks database installation
- **[airbyte/README.md](airbyte/README.md)** - Airbyte setup and troubleshooting

## Troubleshooting

### Services Won't Start

1. Check if ports are already in use:
   ```bash
   lsof -i :5432  # PostgreSQL
   lsof -i :8501  # Streamlit
   lsof -i :8080  # dbt-docs
   lsof -i :1433  # SQL Server
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

- [dbt Documentation](dbt/README.md) - dbt project details
- [Streamlit Documentation](streamlit/README.md) - Dashboard development
- [Adventure Works Installation](adventureworks/README.md) - Sample database setup
- [Airbyte Setup](airbyte/README.md) - Data integration platform

## License

See [LICENSE](LICENSE) file for details.
