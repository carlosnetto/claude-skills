# Tunnel Security & Credential Rotation

## The Threat

Tunnel credentials (`<UUID>.json`) are bearer tokens. Anyone with the JSON file can run a `cloudflared` connector against your tunnel, intercepting traffic meant for your service. There is no IP allowlist or secondary authentication.

## Detection: Unauthorized Connectors

Check active connectors regularly:

```bash
cloudflared tunnel info x9-api-materalabs
```

Output shows each connector's origin IP. If an IP doesn't match your machines, someone has your credentials.

### Signs of compromise
- **530 errors** from Cloudflare (origin unreachable) — the unauthorized connector is receiving traffic but not serving your app
- **Intermittent failures** — Cloudflare load-balances across connectors, so some requests hit the rogue connector and some hit yours
- **Unknown processes** — `lsof -i :<PORT>` shows unexpected processes on your server

## Credential Rotation

When credentials are compromised, the old tunnel must be destroyed and recreated:

```bash
# 1. Disconnect all connectors (including the rogue one)
cloudflared tunnel cleanup x9-api-materalabs

# 2. Delete the compromised tunnel
cloudflared tunnel delete x9-api-materalabs

# 3. Create a new tunnel (generates fresh credentials)
cloudflared tunnel create x9-api-materalabs
# Output: new UUID, new credentials JSON

# 4. Update DNS to point to the new tunnel
cloudflared tunnel -f route dns <NEW-UUID> x9-api.materalabs.us

# 5. Update all scripts with the new tunnel ID
# - tunnel.sh
# - tunnel-pack.sh / tunnel-unpack.sh
# - Any dedicated config files
```

The old credentials become **immediately useless** after the tunnel is deleted.

## Credential Transfer Between Machines

Never commit credentials to git. Use pack/unpack scripts to transfer securely:

```bash
# On the source machine — pack credentials
tar czf tunnel-creds.tar.gz \
  ~/.cloudflared/<UUID>.json \
  ~/.cloudflared/cert.pem

# Transfer via secure method (scp, etc.)
scp tunnel-creds.tar.gz user@server:~/

# On the target machine — unpack
tar xzf tunnel-creds.tar.gz -C /
rm tunnel-creds.tar.gz
```

**Note**: `cert.pem` is only needed for administrative commands (create, delete, route). For just running a tunnel, only the `<UUID>.json` credentials file is needed.

## Prevention

1. **Restrict credential file permissions**: `chmod 600 ~/.cloudflared/<UUID>.json`
2. **Don't store credentials in repos** — use `.gitignore` for `*.json` in cloudflared directories
3. **Use pack/unpack scripts** for transferring credentials between machines
4. **Monitor connectors** — run `cloudflared tunnel info` periodically or after any suspicious behavior
5. **Keep `~/.cloudflared/` clean** — remove credentials for deleted tunnels

## Incident Response Checklist

If you suspect a credential compromise:

1. `cloudflared tunnel info <name>` — check connector IPs
2. `cloudflared tunnel cleanup <name>` — disconnect all connectors
3. `cloudflared tunnel delete <name>` — invalidate credentials
4. `cloudflared tunnel create <name>` — fresh credentials
5. `cloudflared tunnel -f route dns <UUID> <hostname>` — update DNS
6. Update all deployment scripts with new UUID
7. Verify: `cloudflared tunnel info <name>` — should show only your connectors
