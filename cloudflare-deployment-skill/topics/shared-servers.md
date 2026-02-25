# Shared Servers: Multiple Tunnels on One Machine

## The Problem

A server running multiple cloudflared tunnels (potentially for different Cloudflare accounts) has shared state in `~/.cloudflared/` that causes hard-to-debug failures:

1. **`cert.pem`** — Tied to one Cloudflare account/zone. Tunnel name lookups use this cert, so tunnels on other accounts fail with "not found".
2. **`config.yml`** — Default config read by all `cloudflared` commands. Its ingress rules silently override CLI flags like `--url`.
3. **Credential files** — Multiple `<UUID>.json` files from different accounts/tunnels can accumulate.

## Symptoms

| Symptom | Cause |
|---|---|
| `cloudflared tunnel run <name>` says "not found" | `cert.pem` is for a different account |
| Tunnel connects (4 connections) but no traffic reaches your service | Default `config.yml` ingress catches requests first |
| DNS route goes to wrong tunnel | Name collision across accounts or `config.yml` override |
| `--url http://localhost:5010` is ignored | `config.yml` ingress rules take priority |

## Solution: Fully Self-Contained Tunnels

Each tunnel must be independent of shared state. Three rules:

### 1. Run by UUID, not by name

```bash
# BAD — requires cert.pem lookup
cloudflared tunnel run x9-api-materalabs

# GOOD — UUID + credentials, no cert.pem needed
cloudflared tunnel --config ~/.cloudflared/x9-api-materalabs.yml run
```

Running by UUID with `--credentials-file` (specified in the config) bypasses `cert.pem` entirely. No account login needed on the server.

### 2. Dedicated config file per tunnel

```yaml
# ~/.cloudflared/x9-api-materalabs.yml (dedicated to this tunnel)
tunnel: 6eb8781a-6b88-4fc9-aa8b-195f4e9e2d04
credentials-file: /home/user/.cloudflared/6eb8781a-6b88-4fc9-aa8b-195f4e9e2d04.json

ingress:
  - hostname: x9-api.materalabs.us
    service: http://localhost:5010
  - service: http_status:404
```

**Always** pass `--config` to select this file. Without it, cloudflared reads `~/.cloudflared/config.yml` and applies its ingress rules — even when you specify `--url` and `--credentials-file` on the command line.

### 3. Startup script auto-creates config

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

## The `config.yml` Override Trap

This is the most insidious issue. Here's what happens:

1. Another tunnel's `config.yml` exists in `~/.cloudflared/` with a catch-all ingress:
   ```yaml
   # ~/.cloudflared/config.yml (belongs to zoripay tunnel)
   tunnel: abc123
   credentials-file: ~/.cloudflared/abc123.json
   ingress:
     - hostname: zoripay.example.com
       service: http://localhost:3000
     - service: http_status:404    # <-- catches ALL other hostnames
   ```

2. You run your tunnel with CLI flags:
   ```bash
   cloudflared tunnel --url http://localhost:5010 --credentials-file ~/.cloudflared/6eb8781a.json run 6eb8781a
   ```

3. Cloudflared connects successfully (4 connections) — **but reads `config.yml` for ingress rules**. Your hostname `x9-api.materalabs.us` doesn't match `zoripay.example.com`, so it hits the catch-all `http_status:404`. **Zero traffic reaches your service. No error messages.**

4. **Fix**: Use `--config` to point to your dedicated config file. This completely replaces the default `config.yml`.

## Debugging Checklist

When a tunnel connects but traffic doesn't reach your service:

1. Check connectors: `cloudflared tunnel info <UUID>`
2. Check for default config: `cat ~/.cloudflared/config.yml`
3. Verify your config: `cat ~/.cloudflared/your-tunnel.yml`
4. Test locally: `curl http://localhost:5010/health` (is the backend running?)
5. Check DNS: `dig x9-api.materalabs.us` (does it point to the tunnel?)

## Keep `~/.cloudflared/` Clean

Stale files cause confusion. Keep only:
- Active tunnel credentials (`<UUID>.json`)
- Dedicated config files per tunnel (`<tunnel-name>.yml`)
- `cert.pem` (only needed for administrative commands like creating tunnels — not needed for running them)

Remove old credential files and any default `config.yml` that isn't actively needed.
