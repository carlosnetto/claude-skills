# Cloudflare Tunnels

## Overview

Cloudflare Tunnels (`cloudflared`) create a secure connection from a local service to the Cloudflare network, making it accessible via a hostname without exposing ports or configuring firewalls.

```
Browser → x9-api.materalabs.us (CNAME → tunnel)
           → cloudflared (on your server)
           → localhost:5010 (your backend)
```

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

## `--token` + `--url`: Simplest Production Setup

When running a named tunnel with `--token` (dashboard-managed), you can skip the dashboard ingress configuration entirely by passing `--url` on the command line:

```bash
cloudflared tunnel run --token "$TOKEN" --url http://localhost:8081
```

This routes all traffic for the tunnel's hostname to `localhost:8081` without touching the Cloudflare dashboard's "Hostname routes" or creating any config file. Far simpler than configuring ingress rules through the UI.

Store the token in a gitignored file and wrap it in a script:

```bash
#!/usr/bin/env bash
# .tunnel-token is gitignored
TOKEN=$(cat "$(dirname "$0")/.tunnel-token")
cloudflared tunnel run --token "$TOKEN" --url http://localhost:PORT
```

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
