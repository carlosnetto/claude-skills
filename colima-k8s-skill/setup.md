# Setup — Installation, First Start, Profiles & Config

## Problem

Setting up Colima with the right dependencies and configuration on macOS Apple Silicon, avoiding the many silent failure modes from missing packages or wrong flag combinations.

## Pattern

### 1. Install all dependencies first

```bash
# Core (all required)
brew install colima docker kubectl qemu

# Rosetta 2 (required for x86_64 container translation on Apple Silicon)
softwareupdate --install-rosetta

# Only needed if using --arch x86_64 --vm-type qemu
brew install lima-additional-guestagents
```

Optional but useful:
```bash
brew install docker-compose docker-credential-helper docker-buildx
brew install helm k9s  # For Kubernetes work
```

### 2. Choose your configuration

| Goal | Architecture | VM Type | Rosetta | Performance |
|------|-------------|---------|---------|-------------|
| ARM containers only | aarch64 | vz | no | Native |
| ARM + x86_64 containers | aarch64 | vz | yes | Near-native |
| True x86_64 kernel | x86_64 | qemu | n/a | Slow (emulated) |

### 3. First start (recommended for Apple Silicon)

```bash
colima start \
  --arch aarch64 \
  --vm-type vz \
  --vz-rosetta \
  --cpu 4 \
  --memory 8 \
  --disk 100 \
  --kubernetes
```

### 4. Verify everything works

```bash
colima status                    # VM status
colima list                      # All profiles
kubectl get nodes                # K8s node
kubectl get pods -A              # K8s system pods
docker run --rm hello-world      # Docker connectivity
docker run --rm --platform linux/amd64 hello-world  # x86_64 via Rosetta
```

## Profiles (multiple instances)

Colima supports named profiles for different configs:

```bash
# Create a separate lightweight Docker-only instance
colima start --profile docker-only --cpu 2 --memory 4 --disk 50

# Create a heavy K8s testing instance
colima start --profile k8s-heavy --cpu 6 --memory 16 --disk 200 --kubernetes

# List all
colima list

# Switch Docker context
colima start --profile docker-only   # activates this profile's Docker context

# Delete a specific profile
colima delete --profile docker-only
```

## Editing configuration

```bash
# Edit before starting (one-off)
colima start --edit

# Edit the default template (applies to future instances)
colima template

# Manual edit location
$HOME/.colima/_templates/default.yaml
```

The template YAML lets you set all options (cpu, memory, disk, arch, vmType, rosetta, kubernetes, mounts, env, etc.) so you don't need long CLI flags.

## Autostart on login

```bash
brew services start colima
```

**Pitfall:** This uses bare `colima start` with no custom flags. To keep your flags:

1. Run `brew services start colima` once to create the plist
2. Edit `~/Library/LaunchAgents/homebrew.mxcl.colima.plist`
3. Add your flags to `ProgramArguments`:

```xml
<key>ProgramArguments</key>
<array>
  <string>/opt/homebrew/opt/colima/bin/colima</string>
  <string>start</string>
  <string>-f</string>
  <string>--kubernetes</string>
  <string>--vm-type</string>
  <string>vz</string>
  <string>--vz-rosetta</string>
</array>
```

**Better alternative:** Set defaults via `colima template` so bare `colima start` uses your preferred config.

## Docker socket for third-party tools

Colima auto-sets the Docker context, but some tools ignore contexts:

```bash
# Check current socket
docker context ls

# If a tool needs explicit socket path
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"

# For named profiles
export DOCKER_HOST="unix://${HOME}/.colima/<profile-name>/docker.sock"

# Symlink for tools hardcoded to /var/run/docker.sock
sudo ln -sf $HOME/.colima/default/docker.sock /var/run/docker.sock
```

## Pitfalls

- **Missing `docker` CLI:** Colima provides the runtime, not the client. `brew install docker` is mandatory.
- **Missing `kubectl`:** Kubernetes starts but you can't interact with it. Install before or after, but don't forget.
- **Wrong arch + vm-type combo:** `--arch x86_64 --vm-type vz` silently fails. Always pair x86_64 with qemu.
- **Rosetta not installed at OS level:** Colima warns but proceeds — then x86_64 images fail at runtime.
- **Stale instance after config change:** Always `colima delete` before changing arch/vm-type on an existing instance.
- **`colima start` hangs:** Usually means the VM image download is slow. First start downloads ~500MB+. Check network.
