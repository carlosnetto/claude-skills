# Cloudflare Tunnels

## Overview

Cloudflare Tunnels (`cloudflared`) create a secure connection from a local service to the Cloudflare network, making it accessible via a hostname without exposing ports or configuring firewalls.

```
Browser → x9-api.materalabs.us (CNAME → tunnel)
           → cloudflared (on your server)
           → localhost:5010 (your backend)
```

## Two Auth Methods — Know Which One You're Using

cloudflared has two ways to authenticate a tunnel. They look similar but behave differently and require different config files.

### Method 1: credentials-file (legacy CLI flow)

Created with `cloudflared tunnel create`. Generates a credentials JSON on disk. The config file must tell cloudflared where to find it:

```yaml
# ~/.cloudflared/my-tunnel.yml
tunnel: 6eb8781a-...
credentials-file: ~/.cloudflared/6eb8781a-....json  # on-disk secret

ingress:
  - service: http://localhost:5010
```

The credentials file is a **secret** — it must never be committed to git. The config file itself is not secret (tunnel UUID is not sensitive) but references the secret file, so it's typically also kept out of git.

### Method 2: `--token` (preferred — dashboard-managed)

Generated in the Cloudflare dashboard (Zero Trust → Networks → Tunnels → configure → copy token). The token is a base64 blob that encodes the tunnel UUID, account ID, and credentials all in one string. cloudflared decodes everything from `--token` at runtime.

Because the token carries the credentials, the config file only needs the ingress rule — **nothing else**:

```yaml
# tunnel-config.yml — committed to git, no secrets
ingress:
  - service: http://localhost:8081
```

```bash
cloudflared tunnel --config tunnel-config.yml run --token "$TOKEN"
```

The token is the only secret. Store it in a gitignored file (`.tunnel-token`). The config file is clean and travels with the repo.

### Comparison

| | credentials-file | `--token` (preferred) |
|---|---|---|
| Credentials location | `~/.cloudflared/<uuid>.json` on disk | Encoded in the token string |
| Config file needs `tunnel:` + `credentials-file:` | Yes | No — just `ingress:` |
| Config file safe to commit? | No (references on-disk secret) | **Yes** |
| Machine setup on migration | Copy credentials JSON + config | `git pull` + store token |
| Created via | `cloudflared tunnel create` (CLI) | Cloudflare dashboard |

**Recommendation:** use `--token` for all new tunnels. The config file becomes a plain ingress declaration with no secrets, safe to commit alongside the app.

---

## Creating a Tunnel

```bash
# 1. Login (selects the Cloudflare zone for cert.pem)
cloudflared tunnel login    # Opens browser — select the correct zone

# 2. Create tunnel (generates credentials JSON)
cloudflared tunnel create x9-api-materalabs
# Output: Created tunnel x9-api-materalabs with id 6eb8781a-...
# Credentials: ~/.cloudflared/6eb8781a-....json

# 3. Route DNS (create CNAME pointing to the tunnel)
cloudflared tunnel -f route dns 6eb8781a-6b88-4fc9-aa8b-195f4e9e2d04 x9-api.materalabs.us
# Always use UUID and -f flag (see pitfalls below)

# 4. Run the tunnel
cloudflared tunnel --config ~/.cloudflared/x9-api-materalabs.yml run
```

## Config File Pattern

Always use a dedicated config file per tunnel. Never rely on `--url` or default `config.yml`.

```yaml
# ~/.cloudflared/x9-api-materalabs.yml
tunnel: 6eb8781a-6b88-4fc9-aa8b-195f4e9e2d04
credentials-file: /home/user/.cloudflared/6eb8781a-6b88-4fc9-aa8b-195f4e9e2d04.json

ingress:
  - hostname: x9-api.materalabs.us
    service: http://localhost:5010
  - service: http_status:404
```

The catch-all `http_status:404` at the end is **required** by cloudflared — it handles requests that don't match any hostname rule.

## Tunnel Startup Script

Auto-create the config file if it doesn't exist:

```bash
#!/bin/bash
TUNNEL_ID="6eb8781a-6b88-4fc9-aa8b-195f4e9e2d04"
CONFIG_FILE="$HOME/.cloudflared/x9-api-materalabs.yml"

if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << EOF
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/${TUNNEL_ID}.json

ingress:
  - hostname: x9-api.materalabs.us
    service: http://localhost:5010
  - service: http_status:404
EOF
  echo "Created config: $CONFIG_FILE"
fi

cloudflared tunnel --config "$CONFIG_FILE" run
```

## `--url` vs Config File

| Method | How It Works | When to Use |
|---|---|---|
| `--url http://localhost:5010` | CLI flag, quick start | Quick testing only |
| `--config file.yml` | Explicit ingress rules | Production — always use this |

**Pitfall**: If `~/.cloudflared/config.yml` exists, its ingress rules override `--url` even when `--url` is specified on the command line. The `--config` flag is the only way to fully bypass the default config.

## `--token` + Temp Config: Safe Multi-Tunnel Pattern

When running a named tunnel with `--token` (dashboard-managed), do NOT rely on `--url` to define the ingress. If `~/.cloudflared/config.yml` exists on the machine (because another tunnel is running there), its `ingress:` block silently overrides `--url` — your requests hit the wrong backend and return 404 with no error message.

**The safe pattern:** commit a `tunnel-config.yml` to the repo containing only the ingress rule (no secrets — those come from the token), and pass it via `--config`. This fully bypasses `~/.cloudflared/config.yml` regardless of what it contains. `--url` is redundant and should be omitted.

```yaml
# tunnel-config.yml — committed to git, no secrets
# Tunnel identity and credentials come from .tunnel-token (gitignored).
ingress:
  - service: http://localhost:PORT
```

```bash
#!/usr/bin/env bash
# .tunnel-token is gitignored; tunnel-config.yml is committed to git
TOKEN=$(cat "$(dirname "$0")/.tunnel-token")
CONFIG_FILE="$(dirname "$0")/tunnel-config.yml"

cloudflared tunnel --config "$CONFIG_FILE" run --token "$TOKEN"
```

The config travels with the repo — `git pull` on a new machine is all that's needed. No temp file generation, no machine-specific setup.

**If you choose to use `--url` instead** (simpler, single-line), add a guard that aborts when a default config exists — otherwise it will appear to work until the machine gets a second tunnel:

```bash
if [ -f "$HOME/.cloudflared/config.yml" ]; then
  echo "ERROR: ~/.cloudflared/config.yml exists and will override --url."
  echo "Use --config with a dedicated ingress file instead."
  exit 1
fi
cloudflared tunnel run --token "$TOKEN" --url http://localhost:PORT
```

### Why `--url` loses to `config.yml`

cloudflared config resolution order (highest wins):

| Source | Ingress authority |
|---|---|
| `--config FILE` with `ingress:` block | Wins — no other source consulted |
| `~/.cloudflared/config.yml` with `ingress:` block | Wins over `--url` |
| `--url http://...` flag | Only used when no config file defines ingress |

`--token` controls **which tunnel** to connect to but has no effect on ingress routing.

## Quick Tunnel Pitfalls (`--url` / `trycloudflare.com`)

`cloudflared tunnel --url http://localhost:PORT` creates a temporary tunnel with a random `https://xxxx.trycloudflare.com` URL. Useful for one-off testing but has critical limitations for app deployments:

- **URL rotates on every restart** — any Wrangler secret (`API_ORIGIN`) or env var storing the URL goes stale. Requires re-running `wrangler secret put` and redeploying the worker after each restart.
- **`~/.cloudflared/config.yml` overrides `--url`** — if a default config exists, its ingress rules silently take over regardless of the `--url` flag.
- **No stable DNS entry** — can't be used as a permanent `API_ORIGIN` for production.

**Recommendation**: Use quick tunnels only for initial smoke-testing. Switch to a named tunnel with a stable subdomain (`digitaltwinapp-api.materalabs.us`) for any persistent deployment.

## DNS Routing Pitfalls

### Route by UUID, not by name

```bash
# BAD — requires cert.pem to look up name, fails on shared servers
cloudflared tunnel route dns x9-api-materalabs x9-api.materalabs.us

# GOOD — UUID is unambiguous, no cert.pem needed for routing
cloudflared tunnel -f route dns 6eb8781a-6b88-4fc9-aa8b-195f4e9e2d04 x9-api.materalabs.us
```

### Always use `-f` flag

Without `-f`, `route dns` can pick up a tunnel ID from `~/.cloudflared/config.yml` instead of using the tunnel you specified. The `-f` flag forces it to use the specified tunnel.

## Minimal Footprint on Production Machines

When a machine only runs a tunnel (no `wrangler deploy`, no tunnel creation, no DNS routing), it needs exactly two things:

1. `cloudflared` installed
2. `.tunnel-token` file in the project directory (gitignored)

**Nothing in `~/.cloudflared` is needed or should be present.**

| File | What it unlocks | Risk if present on production |
|---|---|---|
| `cert.pem` | Full Cloudflare account admin via CLI — create/delete tunnels, route DNS, manage zones | Anyone with shell access can modify your DNS, create tunnels, reconfigure zones |
| `<uuid>.json` | Authenticate and run the specific tunnel it belongs to | Anyone can run that tunnel pointing to any backend |
| `config.yml` | Default ingress rules applied to all tunnels on the machine | Silently overrides `--url` and `--config` (see pitfall above) |

`cert.pem` is the most dangerous — it is the equivalent of having your Cloudflare account credentials on disk. It is generated by `cloudflared tunnel login` and is only needed for CLI admin operations (creating tunnels, routing DNS). These operations belong on a developer machine, not a server.

**Best practice:** keep `~/.cloudflared` empty (or absent) on any machine whose only job is to run a tunnel. The `--token` auth method was designed exactly for this — a single secret string that grants access to one tunnel only, scoped to routing traffic, nothing else.

## Zero Trust Requirement

Creating tunnels requires the **Cloudflare One** (Zero Trust) free plan. If `cloudflared tunnel login` fails with a permissions error about "Cloudflare One Connector: cloudflared Write", activate Zero Trust in the dashboard (Zero Trust → activate free plan).

## Inspecting Tunnel State

```bash
# Show active connectors (including origin IPs)
cloudflared tunnel info x9-api-materalabs

# List all tunnels
cloudflared tunnel list

# Clean up stale connections
cloudflared tunnel cleanup x9-api-materalabs
```

Check `tunnel info` regularly — if you see connectors from unknown IPs, your credentials may be compromised (see `security.md`).
