---
name: cloudflare-deployment-dev
description: Battle-tested patterns for deploying apps on Cloudflare Workers with tunnels, sub-path routing, and multi-account setups. Covers worker configuration, tunnel management, shared-server pitfalls, credential security, and sub-path SPA deployment. Learned from production incidents.
user-invocable: false
---

# Cloudflare Workers & Tunnel Deployment

You are an expert in deploying web applications on Cloudflare Workers with cloudflared tunnels. You follow battle-tested patterns for route-based deployment, sub-path serving, tunnel management, and multi-account setups.

## Operating Procedure

1. When the user asks about Cloudflare Workers deployment, tunnels, or related infrastructure, load the relevant topic file(s) from the `topics/` directory adjacent to this SKILL.md.
2. Apply the patterns and avoid the pitfalls described in the topic files.
3. Always verify that DNS zone, Worker, and tunnel are on the same Cloudflare account before deploying.
4. When setting up tunnels on shared servers, always use dedicated config files and run by UUID.

## Quick Reference

### Key Commands
| Task | Command |
|---|---|
| Deploy worker | `npm run build && npx wrangler deploy` |
| Check wrangler account | `npx wrangler whoami` |
| Login wrangler | `npx wrangler login` |
| Login cloudflared | `cloudflared tunnel login` |
| Create tunnel | `cloudflared tunnel create <name>` |
| Route DNS | `cloudflared tunnel -f route dns <UUID> <hostname>` |
| Start tunnel | `cloudflared tunnel --config <file> run` |
| Check tunnel connectors | `cloudflared tunnel info <name-or-UUID>` |
| Purge cache | Cloudflare dashboard → Caching → Purge Everything |

### Key Files
| File | Purpose |
|---|---|
| `wrangler.jsonc` | Worker name, account ID, routes, vars, assets binding |
| `worker.ts` | Request handling: prefix stripping, API proxy, static assets, SPA fallback |
| `.env.production` | Build-time vars (e.g., `VITE_QRAPPSERVER_URL`) |
| `tunnel.sh` | Tunnel startup with dedicated config (auto-creates YAML) |
| `~/.cloudflared/<UUID>.json` | Tunnel credentials (secret — never commit) |
| `~/.cloudflared/cert.pem` | Cloudflared login certificate (tied to one zone) |

### Architecture Pattern
```
User → domain.com/subpath/* (Worker route, matched by specificity)
        ├─ /subpath/api-endpoints → strip prefix → proxy to tunnel
        │     → api.domain.com → cloudflared → localhost:PORT → backend
        └─ /subpath/* → strip prefix → static assets (dist/) + SPA fallback
```

### Critical Rules
- **Always keep DNS zone, Worker, and tunnel on the same Cloudflare account** — mismatches cause assets to 404 even when HTML loads.
- **Never rely on default `~/.cloudflared/config.yml` on shared servers** — its ingress rules silently override CLI flags. Use `--config` with a dedicated file per tunnel.
- **Always run tunnels by UUID, not by name** — name lookup requires `cert.pem` tied to the correct account. UUID + `--credentials-file` bypasses cert entirely.
- **Always use `-f` flag when routing DNS** — prevents routing to the wrong tunnel when names collide across accounts.
- **Never commit tunnel credentials** — `<UUID>.json` files are secrets. Use pack/unpack scripts for transfer.
- **Always set `"binding": "ASSETS"` in wrangler config** — without it, `env.ASSETS` is undefined and the worker crashes (error 1101).
- **Put production origins in the base config, not profile files** — Spring `application-local.yml` only loads with explicit profile activation. A CORS allowed-origin defaulting to `localhost` silently blocks all production traffic with `403 Invalid CORS request`.
- **Test CORS preflight with curl before debugging in the browser** — `curl -X OPTIONS ... -H "Origin: ..." -H "Access-Control-Request-Method: POST"` pinpoints the problem faster than browser DevTools.

## Topic Files

Load these for detailed patterns:

- `topics/workers-and-routes.md` — Worker setup, route-based deployment, sub-path serving, SPA fallback, ASSETS binding
- `topics/tunnels.md` — Tunnel creation, DNS routing, credentials, ingress config, `--url` vs config file
- `topics/shared-servers.md` — Dedicated configs per tunnel, run by UUID, cert.pem conflicts, config.yml override
- `topics/multi-account.md` — Account mismatch, wrangler login, cloudflared login, zone/worker/tunnel alignment
- `topics/sub-path-deployment.md` — Vite `--base`, env files per mode, worker prefix stripping, asset path alignment
- `topics/security.md` — Credential rotation, unauthorized connector detection, tunnel info inspection
