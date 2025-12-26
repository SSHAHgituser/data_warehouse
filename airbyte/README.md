# Airbyte Core

This directory contains setup scripts and documentation for Airbyte Core, an open-source data integration platform.

> **⚠️ Important:** Airbyte does **not** publish pre-built Docker images to Docker Hub. The images (`airbyte/server`, `airbyte/worker`, `airbyte/scheduler`) are not available publicly. 
>
> **Recommended Approach:** Use the official `abctl` tool (see [Official Setup](#official-setup-using-abctl) below) for the most reliable installation.
>
> **Note:** Airbyte services are included in the main `docker-compose.yml` at the project root using Docker Compose profiles. They require building images from source to work.

## Why `abctl` Works But Docker Compose Doesn't

### Key Differences

| Aspect | `abctl` (Works ✅) | Docker Compose (Doesn't Work ❌) |
|--------|-------------------|----------------------------------|
| **Deployment Method** | Kubernetes + Helm charts | Docker Compose |
| **Image Source** | GitHub Container Registry (ghcr.io) via Helm charts | Docker Hub (images don't exist there) |
| **Image Management** | Helm charts automatically pull correct images | Requires manual image building from source |
| **Support Status** | ✅ Officially supported (current method) | ❌ Deprecated since Airbyte 1.0 |
| **Configuration** | Kubernetes manifests + Helm values | docker-compose.yml + .env files |
| **Complexity** | Handled automatically by `abctl` | Requires manual setup and image building |

### Why Docker Compose Fails

1. **Images Not on Docker Hub**: 
   - Docker Compose tries to pull `airbyte/server:latest` from Docker Hub
   - These images don't exist on Docker Hub
   - Airbyte publishes images to GitHub Container Registry (ghcr.io), not Docker Hub

2. **Deprecated Method**:
   - Docker Compose was deprecated in Airbyte 1.0 (September 2024)
   - No official support or updates for Docker Compose deployments
   - `abctl` is the only officially supported local deployment method

3. **Image Registry Mismatch**:
   - `abctl` uses Helm charts that reference images from `ghcr.io/airbytehq/*`
   - Docker Compose references `airbyte/*` (Docker Hub namespace)
   - These are different registries and the Docker Hub ones don't exist

### How `abctl` Works

1. **Creates Kubernetes Cluster**: Uses `kind` (Kubernetes-in-Docker) to create a local K8s cluster
2. **Installs Helm Charts**: Downloads and installs Airbyte Helm charts from `airbytehq.github.io/charts`
3. **Pulls Images Automatically**: Helm charts reference images from GitHub Container Registry (ghcr.io)
4. **Manages Everything**: Handles all configuration, networking, and service orchestration

### Making Docker Compose Work (Advanced)

If you really need Docker Compose, you must:

1. **Build Images from Source**:
   ```bash
   git clone https://github.com/airbytehq/airbyte.git
   cd airbyte
   ./gradlew :airbyte-docker:build
   docker tag airbyte/server:dev airbyte/server:latest
   docker tag airbyte/worker:dev airbyte/worker:latest
   docker tag airbyte/scheduler:dev airbyte/scheduler:latest
   ```

2. **Update docker-compose.yml** to use the correct image tags

3. **Maintain Yourself**: No official support, you're on your own for updates

**Recommendation**: Use `abctl` - it's easier, officially supported, and handles everything automatically.

## Official Setup (Using `abctl`) - Recommended

The official and recommended way to install Airbyte is using `abctl`:

### Installation

1. **Install `abctl`**:
   ```bash
   curl -LsfS https://get.airbyte.com | bash -
   ```

2. **Install and start Airbyte**:
   ```bash
   abctl local install
   ```
   This will set up Airbyte using Kubernetes in a local environment. The process may take up to 30 minutes.

3. **Access Airbyte**:
   - Web UI: `http://localhost:8000`
   - Get credentials: `abctl local credentials`
   - Set custom password: `abctl local credentials --password YourPassword`

For more details, see the [Airbyte OSS Quickstart](https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart).

### Troubleshooting `abctl` Installation

#### DNS Resolution Errors

If you encounter **DNS lookup errors** like:
```
ERROR   unable to install airbyte chart: unable to fetch helm chart "airbyte/airbyte": Get "https://airbytehq.github.io/charts/airbyte-2.0.19.tgz": dial tcp: lookup airbytehq.github.io: no such host
```

**Quick Fix:**
1. **Configure Docker Desktop DNS:**
   - Docker Desktop → Settings → Resources → Network
   - Set DNS servers to: `8.8.8.8, 1.1.1.1` (Google/Cloudflare DNS)
   - Click "Apply & Restart"
2. **Disable VPN** temporarily
3. **Flush DNS cache** (macOS: `sudo dscacheutil -flushcache`)
4. **Restart Docker Desktop** completely
5. Retry: `abctl local install`

See [troubleshooting.md](troubleshooting.md) for detailed DNS troubleshooting steps.

#### TLS Handshake Timeout Errors

If you encounter **TLS handshake timeout** errors during installation:

#### 1. Check Kubernetes Cluster Health

```bash
# Verify Kubernetes is running
kubectl cluster-info

# Check node status
kubectl get nodes

# Should show nodes in "Ready" state
```

#### 2. Increase Docker Desktop Resources (Most Common Fix)

The TLS timeout is often caused by insufficient resources:

1. Open **Docker Desktop**
2. Go to **Settings** → **Resources**
3. Increase resources:
   - **CPUs**: At least **4 CPUs** (6-8 recommended)
   - **Memory**: At least **8GB** (12-16GB recommended)
   - **Swap**: At least **2GB**
4. Click **"Apply & Restart"**
5. Wait for Docker Desktop to fully restart
6. Retry: `abctl local install`

#### 3. Reset Kubernetes Cluster

If the cluster is in a bad state:

**Docker Desktop:**
1. Docker Desktop → Settings → Kubernetes
2. Click **"Reset Kubernetes Cluster"**
3. Restart Docker Desktop

**Then retry:**
```bash
abctl local uninstall  # Clean up any partial installation
abctl local install     # Retry installation
```

#### 4. Check for Resource Constraints

```bash
# Check if pods are stuck
kubectl get pods --all-namespaces

# Check node resources
kubectl top nodes
```

#### 5. Network Issues

- Temporarily disable VPN if active
- Check firewall settings
- Ensure no proxy is interfering

See [troubleshooting.md](troubleshooting.md) for more detailed troubleshooting steps.

---

## Docker Compose Setup (Alternative)

Airbyte services are included in the main `docker-compose.yml` at the project root using Docker Compose profiles. This allows you to start Airbyte services alongside other data warehouse services.

> **Note:** This setup requires building Airbyte images from source. See [Building from Source](#building-from-source) below.

### Overview

Airbyte Core provides:
- **Extract**: Connect to 300+ data sources
- **Load**: Load data into your data warehouse
- **Transform**: Basic transformations (advanced transformations via dbt)

### Services

The Airbyte Core stack includes:

- **airbyte-server**: API server that handles all Airbyte operations (includes Web UI)
- **airbyte-worker**: Executes sync jobs
- **airbyte-scheduler**: Schedules and manages sync jobs
- **airbyte-db**: PostgreSQL database for Airbyte metadata
- **temporal**: Workflow orchestration engine
- **temporal-db**: PostgreSQL database for Temporal
- **temporal-ui**: Temporal web UI at `http://localhost:8088`
- **minio**: Object storage for Airbyte data

### Prerequisites

- Docker and Docker Compose installed
- At least 8GB of available RAM (12-16GB recommended)
- Ports 8000, 8001, 8088, 9000, 9001, 5433, 5434 available
- Airbyte source code (for building images)

### Building from Source

To use the docker-compose setup, you need to build the Airbyte images from source:

1. **Clone Airbyte repository**:
   ```bash
   git clone https://github.com/airbytehq/airbyte.git
   cd airbyte
   ```

2. **Build the images**:
   ```bash
   # Build all Airbyte images
   ./gradlew :airbyte-docker:build
   ```

3. **Tag the images** (if needed):
   ```bash
   docker tag airbyte/server:dev airbyte/server:latest
   docker tag airbyte/worker:dev airbyte/worker:latest
   docker tag airbyte/scheduler:dev airbyte/scheduler:latest
   ```

### Starting Airbyte with Docker Compose

From the project root:

```bash
# Start all services including Airbyte (requires built images)
docker-compose --profile airbyte up -d

# Or using the startup script
./start.sh --airbyte

# Start only Airbyte services
docker-compose --profile airbyte up -d airbyte-server airbyte-worker airbyte-scheduler
```

**Note:** The official Airbyte quickstart recommends using `abctl` (Airbyte's CLI tool). The docker-compose setup provides an alternative containerized approach. For the official method, see the [Airbyte OSS Quickstart](https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart).

### Accessing Airbyte

Once all services are running:

1. **Web UI**: Open `http://localhost:8000` in your browser
2. **Default Credentials**: 
   - Email: `[email protected]`
   - Password: (check logs or set via environment variable)

### Setting Up Authentication

The default credentials are:
- Email: `[email protected]`
- Password: Generated on first startup (check container logs)

To set a custom password, you can:

1. Access the Airbyte server container:
   ```bash
   docker exec -it airbyte-server bash
   ```

2. Or set environment variables before starting (see Environment Variables section)

## Environment Variables

Create a `.env` file in the `airbyte` directory to customize configuration:

```bash
# Airbyte Database
AIRBYTE_DB_USER=airbyte
AIRBYTE_DB_PASSWORD=airbyte
AIRBYTE_DB_NAME=airbyte
AIRBYTE_DB_PORT=5433

# Temporal Database
TEMPORAL_DB_USER=temporal
TEMPORAL_DB_PASSWORD=temporal
TEMPORAL_DB_NAME=temporal
TEMPORAL_DB_PORT=5434

# MinIO
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=minio123
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001

# Airbyte Ports
AIRBYTE_WEBAPP_PORT=8000
AIRBYTE_SERVER_PORT=8001
TEMPORAL_UI_PORT=8088
```

## Service URLs

- **Airbyte Web UI**: `http://localhost:8000`
- **Airbyte API**: `http://localhost:8001`
- **Temporal UI**: `http://localhost:8088`
- **MinIO Console**: `http://localhost:9001`
- **MinIO API**: `http://localhost:9000`

## Verifying Services

From the project root:

```bash
# Check all containers (including Airbyte if running)
docker-compose ps

# View logs for all services
docker-compose logs -f

# Check specific Airbyte service
docker-compose logs -f airbyte-server
docker-compose logs -f airbyte-worker
docker-compose logs -f airbyte-scheduler
```

## Integration with Data Warehouse

Since Airbyte services are in the same Docker Compose file, they can communicate directly with the main PostgreSQL database:

1. In Airbyte UI, create a destination connection
2. Use the following connection details:
   - Host: `postgres` (service name in docker-compose)
   - Port: `5432`
   - Database: `data_warehouse` (or your `POSTGRES_DB` env var)
   - Username: `postgres` (or your `POSTGRES_USER` env var)
   - Password: `postgres` (or your `POSTGRES_PASSWORD` env var)

**Note**: Since all services are on the same network (`data_warehouse_network`), you can use the service name `postgres` directly as the hostname.

## Stopping Services

From the project root:

```bash
# Stop all services (including Airbyte if running)
docker-compose down

# Stop only Airbyte services
docker-compose --profile airbyte stop

# Stop and remove volumes (⚠️ deletes all Airbyte data)
docker-compose --profile airbyte down -v
```

## Troubleshooting

### Services Won't Start

1. **Check port conflicts**:
   ```bash
   lsof -i :8000  # Airbyte Web UI
   lsof -i :8001  # Airbyte API
   lsof -i :8088  # Temporal UI
   lsof -i :9000  # MinIO
   ```

2. **Check container logs**:
   ```bash
   docker-compose logs [service_name]
   ```

3. **Verify Docker is running**:
   ```bash
   docker ps
   ```

### Database Connection Issues

If Airbyte can't connect to its database:

1. Check if `airbyte-db` is healthy:
   ```bash
   docker-compose ps airbyte-db
   ```

2. Check database logs:
   ```bash
   docker-compose logs airbyte-db
   ```
   
3. Verify the service is running with the airbyte profile:
   ```bash
   docker-compose --profile airbyte ps
   ```

### Worker Not Processing Jobs

1. Check worker logs:
   ```bash
   docker-compose logs -f airbyte-worker
   ```

2. Verify Temporal is running:
   ```bash
   docker-compose ps temporal
   ```

3. Check Temporal UI at `http://localhost:8088`

### Out of Memory

If containers are being killed:

1. Increase Docker Desktop memory allocation (Settings → Resources)
2. Recommended: At least 4GB RAM for Airbyte Core

## Updating Airbyte

To update to the latest version (after rebuilding images from source):

```bash
# From project root
docker-compose --profile airbyte pull

# Restart services
docker-compose --profile airbyte up -d
```

## Additional Resources

- [Airbyte Documentation](https://docs.airbyte.com/)
- [Airbyte OSS Quickstart](https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart)
- [Airbyte GitHub](https://github.com/airbytehq/airbyte)

