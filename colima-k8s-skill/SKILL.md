# Colima Kubernetes — Skill Definition

Local Kubernetes (K3s) and Docker on macOS via Colima. Covers Apple Silicon + Rosetta 2 for x86_64 container compatibility, resource sizing, profiles, autostart, and troubleshooting.

**Use when:** Setting up local Kubernetes on macOS, running Docker without Docker Desktop, testing K8s manifests/Helm charts locally, running x86_64 containers on Apple Silicon, or troubleshooting Colima VM issues.

---

## Quick Reference

### Prerequisites (install ALL before first `colima start`)

```bash
brew install docker kubectl qemu colima
softwareupdate --install-rosetta        # Required for Rosetta 2 x86_64 translation
brew install lima-additional-guestagents # Required for x86_64 arch via qemu
```

### Start: Apple Silicon + Rosetta 2 + Kubernetes (recommended)

```bash
colima start \
  --arch aarch64 \
  --vm-type vz \
  --vz-rosetta \
  --cpu 4 \
  --memory 8 \
  --disk 900 \
  --kubernetes
```

This runs an ARM64 VM using Apple's Virtualization framework with Rosetta 2 translating x86_64 container images at near-native speed. K3s provides the Kubernetes cluster.

### Start: Full x86_64 emulation via qemu (slow, rarely needed)

```bash
colima start \
  --arch x86_64 \
  --vm-type qemu \
  --cpu 4 \
  --memory 8 \
  --disk 100 \
  --kubernetes
```

True x86_64 kernel emulation. Much slower. Only use if you specifically need an x86_64 kernel, not just x86_64 containers.

### Verify

```bash
colima status
colima list
kubectl get nodes
docker ps
```

### Lifecycle

```bash
colima stop                  # Stop VM (preserves data)
colima start                 # Restart with same config
colima delete                # Destroy VM and all data
colima start --edit          # Edit config in $EDITOR before starting
colima template              # Edit default template for future instances
```

---

## Critical Rules

1. **`--vm-type vz` does NOT support `--arch x86_64`.**
   Apple Virtualization framework only runs the native architecture (aarch64 on Apple Silicon).
   Use `--arch aarch64 --vm-type vz --vz-rosetta` for x86_64 *container* support.
   Use `--arch x86_64 --vm-type qemu` only if you need a true x86_64 *kernel*.

2. **Install Rosetta 2 at the macOS level first.**
   `softwareupdate --install-rosetta` must succeed before `--vz-rosetta` will work.
   Colima warns but continues without it — then containers fail silently.

3. **Install ALL brew dependencies before first start.**
   `docker`, `kubectl`, `qemu`, `colima` — missing any causes cryptic failures.
   Also install `lima-additional-guestagents` if using x86_64 + qemu.

4. **Delete stale instances after config changes.**
   If you change architecture or VM type, `colima delete` first. Old cached configs
   persist on the instance name and cause startup failures.

5. **Docker socket location.**
   Colima's socket is at `~/.colima/default/docker.sock`.
   Some tools need `DOCKER_HOST=unix://$HOME/.colima/default/docker.sock`.
   Colima sets itself as the default Docker context automatically.

6. **Default resources are tiny.** 2 CPU, 2 GB RAM, 100 GB disk.
   Always specify `--cpu`, `--memory`, `--disk` explicitly.

7. **`brew services start colima` loses custom flags.**
   The LaunchAgent plist uses bare `colima start` with no args.
   To autostart with custom flags, edit `~/Library/LaunchAgents/homebrew.mxcl.colima.plist`
   and add your flags to `ProgramArguments`, or use `colima template` to set defaults.

---

## Topics

| File | Covers |
|------|--------|
| [topics/setup.md](topics/setup.md) | Full installation, first start, profiles, config editing |
| [topics/kubernetes.md](topics/kubernetes.md) | K3s specifics, kubectl, namespaces, persistent volumes, Helm |
| [topics/troubleshooting.md](topics/troubleshooting.md) | Common errors, recovery, networking, volume mounts, certificates |
