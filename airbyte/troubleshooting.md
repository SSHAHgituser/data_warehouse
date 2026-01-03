# Airbyte Troubleshooting Guide

## DNS Resolution Errors

If you encounter errors like:
```
ERROR   unable to install airbyte chart: unable to fetch helm chart "airbyte/airbyte": Get "https://airbytehq.github.io/charts/airbyte-2.0.19.tgz": dial tcp: lookup airbytehq.github.io: no such host
```

This indicates DNS resolution issues within Docker/Kubernetes.

### Quick Fixes

#### 1. Check DNS Resolution from Host

```bash
# Test if DNS works from your machine
nslookup airbytehq.github.io
ping -c 2 airbytehq.github.io
```

If this fails, you have a network/DNS issue on your host machine.

#### 2. Configure Docker Desktop DNS

**For Docker Desktop (macOS/Windows):**

1. Open **Docker Desktop**
2. Go to **Settings** → **Resources** → **Network**
3. Check DNS settings:
   - Ensure "Use kernel DNS resolver" is enabled, OR
   - Set custom DNS servers: `8.8.8.8, 1.1.1.1` (Google/Cloudflare DNS)
4. Click **"Apply & Restart"**
5. Wait for Docker Desktop to fully restart

#### 3. Configure Kubernetes DNS

If using Kubernetes (via `abctl`), check DNS configuration:

```bash
# Check if CoreDNS is running
kubectl get pods -n kube-system | grep coredns

# Check DNS service
kubectl get svc -n kube-system kube-dns
```

#### 4. Disable VPN/Proxy Temporarily

VPNs and proxies can interfere with DNS resolution:

- **Disable VPN** temporarily and retry
- **Check proxy settings** in Docker Desktop (Settings → Resources → Proxies)
- **Check system proxy settings** that might affect Docker

#### 5. Flush DNS Cache

**macOS:**
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

**Linux:**
```bash
sudo systemd-resolve --flush-caches
# or
sudo resolvectl flush-caches
```

**Windows:**
```cmd
ipconfig /flushdns
```

#### 6. Restart Docker Desktop

Sometimes a simple restart fixes DNS issues:

1. Quit Docker Desktop completely
2. Wait 10 seconds
3. Restart Docker Desktop
4. Wait for it to fully start
5. Retry: `abctl local install`

#### 7. Check Network Connectivity

```bash
# Test connectivity from within Docker
docker run --rm curlimages/curl curl -I https://airbytehq.github.io

# Test from Kubernetes pod (if cluster is running)
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl -I https://airbytehq.github.io
```

#### 8. Use Alternative DNS Servers

If your default DNS is having issues, configure Docker to use public DNS:

**Docker Desktop:**
- Settings → Resources → Network → DNS servers: `8.8.8.8, 8.8.4.4` (Google) or `1.1.1.1, 1.0.0.1` (Cloudflare)

**Or create/edit `/etc/docker/daemon.json` (Linux):**
```json
{
  "dns": ["8.8.8.8", "8.8.4.4"]
}
```

Then restart Docker.

#### 9. Check Firewall/Security Software

- Temporarily disable firewall
- Check if security software is blocking Docker network access
- Ensure Docker has necessary network permissions

#### 10. Manual Helm Chart Download (Workaround)

If DNS continues to fail, you can manually download the chart:

```bash
# Download the chart manually
curl -L -o airbyte-chart.tgz https://airbytehq.github.io/charts/airbyte-2.0.19.tgz

# Then modify abctl to use local chart (advanced - requires editing abctl config)
```

### Step-by-Step Recovery

1. **Test DNS from host:**
   ```bash
   nslookup airbytehq.github.io
   ```

2. **Configure Docker Desktop DNS:**
   - Settings → Resources → Network → Set DNS to `8.8.8.8, 1.1.1.1`
   - Restart Docker Desktop

3. **Disable VPN/Proxy** temporarily

4. **Flush DNS cache** (see commands above)

5. **Restart Docker Desktop** completely

6. **Retry installation:**
   ```bash
   abctl local uninstall  # Clean up any partial installation
   abctl local install
   ```

---

## Kubernetes API Server Connection Refused

If you encounter errors like:
```
ERROR   unable to get the secret airbyte-auth-secrets: Get "https://127.0.0.1:64738/api/v1/namespaces/airbyte-abctl/secrets/airbyte-auth-secrets": dial tcp 127.0.0.1:64738: connect: connection refused
```

or

```
ERROR   unable to initialize local command: error communicating with kubernetes: unable to fetch kubernetes server version: Get "https://127.0.0.1:64738/version": dial tcp 127.0.0.1:64738: connect: connection refused
```

This indicates that the Kubernetes API server inside the kind cluster is not accessible. The container may be running, but the API server hasn't started or is not responding.

### Quick Fixes

#### 1. Restart the Kind Cluster Container

The simplest fix is to restart the kind cluster container:

```bash
# Stop the container
docker stop airbyte-abctl-control-plane

# Wait a few seconds
sleep 5

# Start it again
docker start airbyte-abctl-control-plane

# Wait for the API server to be ready (30-60 seconds)
sleep 30

# Check if it's working
abctl local status
```

#### 2. Check Container Status

Verify the container is running and healthy:

```bash
# Check if container is running
docker ps | grep airbyte-abctl-control-plane

# Check container logs for errors
docker logs airbyte-abctl-control-plane --tail 100

# Check if the API server is responding (inside the container)
docker exec airbyte-abctl-control-plane kubectl get nodes
```

#### 3. Wait for API Server to Start

The Kubernetes API server can take 30-60 seconds to fully start after the container starts. If you just started the container, wait and retry:

```bash
# Wait 60 seconds
sleep 60

# Then check status
abctl local status
```

#### 4. Restart via abctl (If Available)

If `abctl local stop` works, try restarting:

```bash
# Try to stop (may fail if cluster is in bad state)
abctl local stop 2>&1 || true

# Wait a moment
sleep 5

# Start the container manually
docker start airbyte-abctl-control-plane

# Wait for API server
sleep 60

# Check status
abctl local status
```

#### 5. Full Reset (If Above Don't Work)

If the cluster is in a bad state, you may need to uninstall and reinstall:

```bash
# Stop the container
docker stop airbyte-abctl-control-plane

# Remove the container (this won't delete your Airbyte data)
docker rm airbyte-abctl-control-plane

# Uninstall Airbyte (preserves data)
abctl local uninstall

# Reinstall
abctl local install
```

**Note:** `abctl local uninstall` preserves your Airbyte data (connections, sources, destinations) but removes the Kubernetes cluster. You'll need to reinstall, but your configurations will remain.

#### 6. Check Docker Resources

Insufficient Docker resources can cause the API server to fail to start:

1. Open **Docker Desktop**
2. Go to **Settings** → **Resources**
3. Ensure you have:
   - **CPUs**: At least 4 CPUs (6-8 recommended)
   - **Memory**: At least 8GB (12-16GB recommended)
4. Click **"Apply & Restart"**
5. Wait for Docker Desktop to fully restart
6. Restart the kind container:
   ```bash
   docker stop airbyte-abctl-control-plane
   docker start airbyte-abctl-control-plane
   sleep 60
   abctl local status
   ```

#### 7. Check for Port Conflicts

If another process is using the API server port, it can cause issues:

```bash
# Check what's using the port (replace 64738 with your actual port)
lsof -i :64738

# If something else is using it, stop that process or change Docker's port allocation
```

### Step-by-Step Recovery

1. **Stop the container:**
   ```bash
   docker stop airbyte-abctl-control-plane
   ```

2. **Wait 5 seconds:**
   ```bash
   sleep 5
   ```

3. **Start the container:**
   ```bash
   docker start airbyte-abctl-control-plane
   ```

4. **Wait for API server (60 seconds):**
   ```bash
   sleep 60
   ```

5. **Check status:**
   ```bash
   abctl local status
   ```

6. **If still failing, check container logs:**
   ```bash
   docker logs airbyte-abctl-control-plane --tail 100
   ```

7. **If logs show errors, try full reset:**
   ```bash
   docker stop airbyte-abctl-control-plane
   docker rm airbyte-abctl-control-plane
   abctl local uninstall
   abctl local install
   ```

### Prevention

To avoid this issue in the future:

- **Don't force-kill the container** - use `docker stop` instead of `docker kill`
- **Wait for full startup** - give the container 60 seconds after starting before running `abctl` commands
- **Ensure sufficient Docker resources** - allocate enough CPU and memory to Docker Desktop
- **Use `./stop.sh`** - use the provided stop script which handles Airbyte properly

---

## TLS Handshake Timeout Errors

If you encounter errors like:
```
net/http: TLS handshake timeout
failed to list *unstructured.Unstructured: Get "https://127.0.0.1:56619/api/v1/namespaces/airbyte-abctl/pods"
```

This indicates connectivity issues with your Kubernetes cluster.

### Common Causes and Solutions

#### 1. Kubernetes Cluster Not Running or Unhealthy

**Check if Kubernetes is running:**
```bash
# For Docker Desktop
kubectl cluster-info

# Check if nodes are ready
kubectl get nodes

# Check if pods are running
kubectl get pods --all-namespaces
```

**If Kubernetes is not running:**
- **Docker Desktop**: Enable Kubernetes in Settings → Kubernetes → Enable Kubernetes
- **Minikube**: Start with `minikube start`
- **Kind**: Create cluster with `kind create cluster`

#### 2. Insufficient Resources

Docker Desktop Kubernetes may need more resources allocated.

**Solution:**
1. Open Docker Desktop
2. Go to Settings → Resources
3. Increase:
   - **CPUs**: At least 4 CPUs (6-8 recommended)
   - **Memory**: At least 8GB (12-16GB recommended)
   - **Swap**: At least 2GB
4. Click "Apply & Restart"
5. Wait for Docker Desktop to fully restart

#### 3. Reset Kubernetes Cluster

If the cluster is in a bad state, try resetting it:

**For Docker Desktop:**
1. Docker Desktop → Settings → Kubernetes
2. Click "Reset Kubernetes Cluster"
3. Restart Docker Desktop

**For Minikube:**
```bash
minikube delete
minikube start --memory=8192 --cpus=4
```

#### 4. Clear abctl State and Retry

```bash
# Check abctl status
abctl local status

# If stuck, try to stop and clean up
abctl local stop
abctl local uninstall

# Then retry installation
abctl local install
```

#### 5. Network/Firewall Issues

**Check if port 56619 (or similar) is accessible:**
```bash
# Test Kubernetes API connectivity
kubectl get nodes

# If this fails, there's a connectivity issue
```

**Solutions:**
- Disable VPN temporarily
- Check firewall settings
- Ensure no proxy is interfering

#### 6. Increase Timeout Values

If the cluster is slow but working, you can try increasing timeouts (though this is usually not the root cause).

### Step-by-Step Recovery

1. **Verify Kubernetes is healthy:**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

2. **Check Docker Desktop resources:**
   - Ensure at least 8GB RAM and 4 CPUs allocated

3. **Reset if needed:**
   ```bash
   # Stop any existing Airbyte installation
   abctl local stop
   
   # Reset Kubernetes (Docker Desktop UI or minikube delete)
   
   # Restart Docker Desktop
   ```

4. **Retry installation:**
   ```bash
   abctl local install
   ```

### Alternative: Use Docker Compose (If Kubernetes Issues Persist)

If Kubernetes continues to have issues, you can try the Docker Compose approach (requires building images from source):

1. Clone Airbyte repository:
   ```bash
   git clone https://github.com/airbytehq/airbyte.git
   cd airbyte
   ```

2. Build images:
   ```bash
   ./gradlew :airbyte-docker:build
   ```

3. Use the docker-compose.yml from this directory (after building images)

### Getting Help

If issues persist:
- Check Airbyte logs: `abctl local logs`
- Check Kubernetes logs: `kubectl logs -n airbyte-abctl <pod-name>`
- Airbyte Community: https://github.com/airbytehq/airbyte/discussions
- Airbyte Documentation: https://docs.airbyte.com/

