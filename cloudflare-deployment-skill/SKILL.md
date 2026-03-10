---
name: cloudflare-deployment-dev
description: Battle-tested patterns for deploying apps on Cloudflare Workers and Pages with API tokens, dotenv automation, tunnels, and multi-account setups. Covers zero-global-state deployments, credential security, and sub-path SPA serving.
user-invocable: false
---

# Cloudflare Workers & Pages Deployment

You are an expert in deploying web applications on Cloudflare Workers and Pages. You follow battle-tested patterns for zero-global-state deployments, route-based serving, tunnel management, and secure multi-account setups.

## Operating Procedure

1. When the user asks about Cloudflare deployment, loading the relevant topic file(s) from the `topics/` directory is mandatory.
2. Apply the patterns and avoid the pitfalls described in the topic files.
3. **Prefer API Tokens over OAuth sessions** for deterministic, portable deployments.
4. **Use dotenv-cli** to inject environment variables into deployment scripts.

## Quick Reference

### Key Commands
| Task | Command |
|---|---|
| **Deploy (Portable)** | `npm run build && npm run deploy` (requires `dotenv -- npx wrangler ...`) |
| Deploy worker | `npm run build && npx wrangler deploy` |
| Check credentials | `npx dotenv -- npx wrangler whoami` |
| Login wrangler | `npx wrangler login` (not recommended for portable projects) |
| Purge cache | Cloudflare dashboard → Caching → Purge Everything |

### Key Files
| File | Purpose |
|---|---|
| `.env` | Local secrets: `CLOUDFLARE_API_TOKEN`, `GEMINI_API_KEY`, etc. |
| `package.json` | Deployment automation: `"deploy": "dotenv -- npx wrangler pages deploy ..."` |
| `wrangler.jsonc` / `wrangler.toml` | Worker/Pages configuration, assets binding, env vars |
| `vite.config.ts` | Configured for `target/` output and single-bundle JS/CSS |
| `~/.cloudflared/cert.pem` | Legacy login certificate (avoid in favor of API Tokens) |

### Architecture Pattern
```
User → domain.com/* (Cloudflare Pages or Worker Route)
        ├─ /assets/index.js → Direct static serving (target/ folder)
        └─ /api/* → Strip prefix → Proxy to Workers or Backend
```

### Critical Rules
- **Prefer `CLOUDFLARE_API_TOKEN` over OAuth.** Using API tokens in a `.env` file makes the project self-contained and avoids dependencies on `~/.wrangler` or `~/.cloudflared`.
- **Automate dotenv injection.** Always use `dotenv --` in `package.json` scripts to ensure credentials are loaded without manual shell sourcing.
- **Use `npx wrangler` in scripts.** This ensures the local version is used and avoids "command not found" errors when `wrangler` is not in the global PATH.
- **Never commit `.env` files.** Always add `.env` to `.gitignore`.
- **Always keep DNS zone, Worker/Pages, and tunnel on the same Cloudflare account.** Mismatches are the #1 cause of 404s and 522 errors.
- **Always set `"binding": "ASSETS"` in wrangler config.** Without it, workers serving static files will crash (error 1101).

## Topic Files

Load these for detailed patterns:

- `topics/self-contained-pages.md` — **[NEW]** Zero-global-state deployments using API Tokens, dotenv-cli, and "giant bundle" Vite builds.
- `topics/workers-and-routes.md` — Worker setup, route-based deployment, sub-path serving, SPA fallback, ASSETS binding.
- `topics/tunnels.md` — Tunnel creation, DNS routing, credentials, ingress config.
- `topics/shared-servers.md` — Dedicated configs per tunnel, run by UUID, cert.pem conflicts.
- `topics/multi-account.md` — Account mismatch, wrangler login, zone/worker/tunnel alignment.
- `topics/sub-path-deployment.md` — Vite `--base`, worker prefix stripping, asset path alignment.
- `topics/security.md` — API Token scoped permissions, credential rotation, unauthorized connector detection.
