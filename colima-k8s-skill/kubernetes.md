# Kubernetes — K3s, kubectl, Volumes & Helm

## Problem

Using Colima's built-in K3s cluster for local Kubernetes development, testing manifests, Helm charts, and understanding how it differs from production clusters.

## Pattern

### K3s basics

Colima bundles K3s (lightweight Kubernetes). When started with `--kubernetes`:
- Single-node cluster
- Automatic kubeconfig at `~/.kube/config`
- Traefik ingress controller included by default
- Local-path-provisioner for PersistentVolumes
- CoreDNS for service discovery

### Verify cluster

```bash
kubectl get nodes
# NAME      STATUS   ROLES                  AGE   VERSION
# colima    Ready    control-plane,master   1m    v1.28.x+k3s1

kubectl get pods -A               # All system pods
kubectl cluster-info              # API server endpoint
kubectl get storageclass          # local-path (default)
```

### Kubeconfig management

Colima automatically merges into `~/.kube/config`:

```bash
# Current context
kubectl config current-context    # Should show "colima"

# If you have multiple clusters
kubectl config get-contexts
kubectl config use-context colima

# For named profiles
# Context name = "colima-<profile-name>"
kubectl config use-context colima-k8s-heavy
```

### Deploy a test workload

```bash
# Quick test
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc nginx
# Access via: curl http://localhost:<nodeport>

# Clean up
kubectl delete deployment nginx
kubectl delete svc nginx
```

### Persistent Volumes

K3s includes `local-path-provisioner`. PVCs are auto-provisioned:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
```

Data lives inside the VM at `/opt/local-path-provisioner/`.

**To mount host directories into K8s pods**, configure Colima mounts:

```bash
colima start --mount $HOME/projects:w --kubernetes
# Then use hostPath volumes pointing to /Users/<you>/projects
```

Or edit via `colima template`:
```yaml
mounts:
  - location: /Users/you/projects
    writable: true
    mountPoint: /Users/you/projects
```

### Helm

```bash
brew install helm

# Add common repos
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable
helm repo update

# Install a chart
helm install my-redis bitnami/redis --set architecture=standalone

# List releases
helm list

# Uninstall
helm uninstall my-redis
```

### Namespaces for isolation

```bash
kubectl create namespace dev
kubectl create namespace staging

# Deploy to a specific namespace
kubectl -n dev apply -f deployment.yaml

# Set default namespace for current context
kubectl config set-context --current --namespace=dev
```

### Container images: Docker ↔ K3s

Docker and K3s share the same container runtime in Colima. Images built with `docker build` are available to K3s:

```bash
docker build -t myapp:latest .
# No need to push to a registry — K3s can see it

# In your K8s manifest, use:
#   image: myapp:latest
#   imagePullPolicy: Never    # Important! Prevents K3s from trying to pull
```

### K3s-specific features

```bash
# Access K3s config directly inside the VM
colima ssh -- cat /etc/rancher/k3s/k3s.yaml

# Disable Traefik (if you want nginx-ingress or nothing)
# Edit via colima template, add to kubernetes section:
#   k3sArgs:
#     - --disable=traefik

# Check K3s logs inside VM
colima ssh -- journalctl -u k3s
```

### Port forwarding

```bash
# Forward a specific service
kubectl port-forward svc/my-service 8080:80

# Forward a pod directly
kubectl port-forward pod/my-pod-abc123 8080:80

# NodePort services are accessible on localhost automatically with vz VM type
```

## Alternatives to Colima's built-in K8s

Colima's Docker runtime is compatible with:
- **Kind** (`kind create cluster`) — better for multi-node testing
- **K3d** (`k3d cluster create`) — K3s in Docker, faster restarts
- **Minikube** (`minikube start --driver=docker`) — more features, heavier

These run as containers inside Colima's Docker, giving you more flexibility (multiple clusters, custom configs) at the cost of an extra layer.

## Pitfalls

- **`imagePullPolicy: Always` with local images:** K3s tries to pull from a registry and fails. Set `imagePullPolicy: Never` or `IfNotPresent` for locally-built images.
- **PV data loss on `colima delete`:** All persistent volume data lives inside the VM. Deleting the instance destroys it.
- **Resource limits:** K3s system pods consume ~500MB RAM. Account for this when sizing `--memory`.
- **Traefik conflicts:** If you install nginx-ingress, disable K3s's built-in Traefik first.
- **Context confusion:** If you also use cloud K8s clusters, always verify `kubectl config current-context` before running destructive commands.
