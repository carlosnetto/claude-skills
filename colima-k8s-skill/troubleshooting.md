# Troubleshooting — Common Errors, Recovery & Networking

## Error: "guest agent binary could not be found for Linux-x86_64"

```
FATA[0014] error starting vm: error at 'creating and starting': exit status 1
```

**Cause:** Missing guest agent for x86_64 architecture.
**Fix:**
```bash
brew install lima-additional-guestagents
```

## Error: "Unable to enable Rosetta: Rosetta2 is not installed"

```
WARN[0001] Unable to enable Rosetta: Rosetta2 is not installed
```

**Cause:** Rosetta 2 not installed at macOS level.
**Fix:**
```bash
softwareupdate --install-rosetta
colima delete
colima start --arch aarch64 --vm-type vz --vz-rosetta ...
```

## Error: "unsupported arch: x86_64" with vz VM type

```
FATA[0002] error starting vm: error at 'starting': exit status 1
```

**Cause:** Apple Virtualization framework (`vz`) does NOT support x86_64 architecture.
**Fix:** Use `--arch aarch64` with `--vm-type vz`, or switch to `--vm-type qemu` for true x86_64.

```bash
colima delete
# Option A: ARM + Rosetta (recommended)
colima start --arch aarch64 --vm-type vz --vz-rosetta --kubernetes ...
# Option B: True x86_64 (slow)
colima start --arch x86_64 --vm-type qemu --kubernetes ...
```

## Error: "accepts at most 1 arg(s), received N"

**Cause:** Extra arguments being passed. Usually from copy-paste with backslash continuations that broke.
**Fix:** Put the command on a single line or ensure backslashes have no trailing spaces:

```bash
colima start --arch aarch64 --vm-type vz --vz-rosetta --cpu 4 --memory 8 --disk 900 --kubernetes
```

## Error: Colima starts but old config persists

**Cause:** Instance name retains previous config. Changing flags on an existing instance doesn't always take effect.
**Fix:**
```bash
colima delete          # Or: colima delete <profile-name>
colima start ...       # Fresh start with new flags
```

## Error: "error getting qcow image" / download failures

```
error downloading '...ubuntu-24.04-minimal-cloudimg-arm64-docker.qcow2': exit status 60
```

**Cause:** Network/TLS issue downloading VM image. Exit status 60 = curl certificate error.
**Fix:**
```bash
# Check if corporate proxy/VPN is interfering
# Try downloading manually
curl -L -o /tmp/test.qcow2 "https://github.com/abiosoft/colima-core/releases/..."

# If behind corporate proxy with custom CA
colima ssh -- sudo cp /path/to/ca-cert.pem /usr/local/share/ca-certificates/
colima ssh -- sudo update-ca-certificates
```

## Error: Docker commands fail / "Cannot connect to Docker daemon"

**Cause:** Docker CLI not installed, or socket not configured.
**Fix:**
```bash
brew install docker                  # Install CLI
colima status                        # Confirm VM is running
docker context ls                    # Check active context
eval $(colima docker-env 2>/dev/null) || true  # Set env if needed
export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
```

## Error: kubectl can't connect / "connection refused"

**Cause:** Kubernetes not enabled, or kubeconfig not set.
**Fix:**
```bash
# Verify K8s is running
colima status   # Should show "runtime: docker+k3s"

# If not, restart with --kubernetes
colima stop
colima start --kubernetes ...

# Check kubeconfig
kubectl config current-context   # Should be "colima"
cat ~/.kube/config | grep colima
```

## Ports not reachable from host (localhost)

**Cause:** Known issue with x86_64 arch + vz VM type (which is an invalid combo anyway). Can also happen with qemu.
**Fix:**
```bash
# With vz (aarch64): ports should work via localhost automatically

# With qemu: try --network-address to get a VM IP
colima start --network-address ...

# Check VM IP
colima list    # ADDRESS column

# Use port-forward as workaround
kubectl port-forward svc/my-svc 8080:80
```

## Slow containers (performance issues)

**Cause:** Usually wrong VM type or architecture mismatch.
**Fix:**
```bash
# Check current config
colima list

# Ensure you're using vz + aarch64 (fastest on Apple Silicon)
colima delete
colima start --arch aarch64 --vm-type vz --vz-rosetta --cpu 4 --memory 8 ...

# For volume mounts, use virtiofs (default with vz)
# Avoid 9p mounts — they're slow
```

## Volume mount permission issues

**Cause:** UID/GID mismatch between host and VM.
**Fix:**
```bash
# Use writable mounts
colima start --mount $HOME/data:w ...

# Inside VM, check permissions
colima ssh -- ls -la /Users/you/data

# For Docker volumes, use named volumes instead of bind mounts when possible
docker volume create mydata
docker run -v mydata:/data ...
```

## Reset everything (nuclear option)

```bash
colima stop
colima delete
rm -rf ~/.colima          # Remove all Colima data
rm -rf ~/.lima            # Remove Lima data (Colima uses Lima under the hood)
brew reinstall colima lima

# Fresh start
colima start --arch aarch64 --vm-type vz --vz-rosetta --cpu 4 --memory 8 --disk 100 --kubernetes
```

## Useful diagnostic commands

```bash
colima status                        # VM state + config
colima list                          # All profiles with resources
colima version                       # Colima + Lima + QEMU versions
colima ssh                           # Shell into VM
colima ssh -- journalctl -u k3s      # K3s logs
colima ssh -- df -h                  # Disk usage inside VM
colima ssh -- free -h                # Memory usage inside VM
colima ssh -- uname -m               # Verify architecture
limactl list                         # Lima instances (lower level)
```
