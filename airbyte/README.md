# Airbyte Core

This directory contains setup scripts and documentation for Airbyte Core, an open-source data integration platform.

> **⚠️ Important:** Airbyte does **not** publish pre-built Docker images to Docker Hub. Use the official `abctl` tool for installation.

## Why Use `abctl` Instead of Docker Compose?

Airbyte deprecated Docker Compose in version 1.0 (September 2024). `abctl` is the only officially supported local deployment method because:

- **Images not on Docker Hub**: Airbyte images are only available via Helm charts from GitHub Container Registry
- **Official support**: `abctl` is actively maintained and receives updates
- **Automatic management**: Handles Kubernetes, Helm charts, and image pulling automatically
- **Better experience**: One command setup vs. manual image building

See the [main README](../README.md#4-airbyte-setup) for detailed explanation.

## Quick Setup

### Using the Setup Script (Recommended)

```bash
cd airbyte
./setup_with_abctl.sh
```

This script will:
1. Install `abctl` if needed
2. Set up Airbyte using Kubernetes (via `kind`)
3. Deploy using Helm charts
4. Provide you with credentials

### Manual Setup

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

## Integration with Data Warehouse

To connect Airbyte to your PostgreSQL data warehouse:

1. In Airbyte UI, create a destination connection
2. Use the following connection details:
   - Host: `host.docker.internal` (or your Docker host IP)
   - Port: `5432`
   - Database: `data_warehouse` (or your `POSTGRES_DB` env var)
   - Username: `postgres` (or your `POSTGRES_USER` env var)
   - Password: `postgres` (or your `POSTGRES_PASSWORD` env var)

## Common Commands

```bash
# Check status
abctl local status

# Start Airbyte
abctl local start

# Stop Airbyte
abctl local stop

# View credentials
abctl local credentials

# Set password
abctl local credentials --password YourPassword

# Uninstall
abctl local uninstall
```

## Troubleshooting

### DNS Resolution Errors

If you encounter DNS lookup errors:

1. **Configure Docker Desktop DNS:**
   - Docker Desktop → Settings → Resources → Network
   - Set DNS servers to: `8.8.8.8, 1.1.1.1`
   - Click "Apply & Restart"

2. **Disable VPN** temporarily
3. **Flush DNS cache** (macOS: `sudo dscacheutil -flushcache`)
4. **Restart Docker Desktop**
5. Retry: `abctl local install`

### TLS Handshake Timeout Errors

This usually indicates insufficient resources:

1. **Increase Docker Desktop Resources:**
   - Docker Desktop → Settings → Resources
   - CPUs: At least 4 CPUs (6-8 recommended)
   - Memory: At least 8GB (12-16GB recommended)
   - Swap: At least 2GB
   - Click "Apply & Restart"

2. **Reset Kubernetes Cluster** (if needed):
   - Docker Desktop → Settings → Kubernetes
   - Click "Reset Kubernetes Cluster"
   - Restart Docker Desktop

3. **Retry installation:**
   ```bash
   abctl local uninstall
   abctl local install
   ```

### Resource Constraints

Check if Kubernetes has enough resources:

```bash
# Check if pods are stuck
kubectl get pods --all-namespaces

# Check node resources
kubectl top nodes
```

## Additional Resources

- [Airbyte Documentation](https://docs.airbyte.com/)
- [Airbyte OSS Quickstart](https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart)
- [Airbyte GitHub](https://github.com/airbytehq/airbyte)
- [Detailed Troubleshooting Guide](troubleshooting.md)
