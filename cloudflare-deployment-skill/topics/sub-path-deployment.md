# Sub-Path Deployment (Serving an SPA Under a Sub-Path)

## The Problem

Deploying a single-page app under `/x9.150/` instead of root requires **three things to align**. If any one is wrong, the app breaks in different ways:

| Layer | What It Does | If Wrong |
|---|---|---|
| Vite `base` | Prefixes asset paths in `index.html` | Assets 404 (loaded from root, hitting wrong worker) |
| Worker prefix strip | Removes `/x9.150` before serving from `dist/` | Assets 404 (dist/ has `assets/...` not `x9.150/assets/...`) |
| Frontend API URL | API calls go to `/x9.150/fetch` | API calls hit wrong worker (the root domain worker) |

## Build-Time: Vite `base` Configuration

The `base` option in `vite.config.ts` rewrites all asset references in the built `index.html`:

```typescript
// vite.config.ts
export default defineConfig({
  base: '/x9.150/',   // All asset paths prefixed with /x9.150/
  // ...
});
```

Built `index.html` output:
```html
<!-- Without base: -->
<script src="/assets/index-abc123.js"></script>

<!-- With base: '/x9.150/': -->
<script src="/x9.150/assets/index-abc123.js"></script>
```

### Alternative: CLI flags for multi-target builds

If you need different base paths for different deployments, use CLI flags instead of hardcoding:

```bash
# Root deployment (default)
npx vite build

# Sub-path deployment
npx vite build --base=/x9.150/ --mode materalabs
```

The `--mode materalabs` flag loads `.env.materalabs` for runtime configuration.

## Runtime: Worker Prefix Stripping

The worker receives requests like `/x9.150/assets/index-abc123.js` but `dist/` contains `assets/index-abc123.js` (no prefix). The worker must strip the prefix before serving:

```typescript
let pathname = url.pathname;
if (pathname.startsWith(basePath)) {
  pathname = pathname.slice(basePath.length) || '/';
}
// Now: /x9.150/assets/index-abc123.js → /assets/index-abc123.js
```

## Runtime: Frontend API URL

The frontend must send API calls to `/x9.150/fetch` (not `/fetch`), so they match the worker's route pattern `materalabs.us/x9.150/*`:

```bash
# .env.production
VITE_QRAPPSERVER_URL=/x9.150
```

```bash
# .env.local (for local dev — talks directly to backend)
VITE_QRAPPSERVER_URL=http://localhost:5010
```

**Pitfall**: Vite loads `.env.local` in **all** modes (dev and production). To override a value for production builds only, use `.env.production` — it takes priority over `.env.local` in production mode.

## SPA Fallback

Client-side routing requires that all non-asset paths serve `index.html`. The worker handles this:

```typescript
const assetResponse = await env.ASSETS.fetch(assetRequest);

if (assetResponse.status === 404) {
  const fallbackUrl = new URL(request.url);
  fallbackUrl.pathname = '/index.html';
  return env.ASSETS.fetch(new Request(fallbackUrl.toString(), request));
}
```

Without this, direct navigation to `/x9.150/send` returns 404 because there's no `dist/send` file.

## Route Specificity

Cloudflare matches routes by specificity. A route `materalabs.us/x9.150/*` takes priority over a catch-all `materalabs.us/*` worker. This allows your sub-path app to coexist with an existing worker on the same domain.

**Important**: Define two route patterns — one with `/*` and one exact match:

```jsonc
"routes": [
  { "pattern": "materalabs.us/x9.150/*", "zone_name": "materalabs.us" },
  { "pattern": "materalabs.us/x9.150", "zone_name": "materalabs.us" }
]
```

Without the exact match, requests to `/x9.150` (no trailing slash or sub-path) fall through to the root worker.

## Complete Alignment Checklist

Before deploying a sub-path app, verify:

1. `vite.config.ts` has `base: '/x9.150/'` (or use `--base` CLI flag)
2. `.env.production` sets `VITE_QRAPPSERVER_URL=/x9.150`
3. `worker.ts` strips the `/x9.150` prefix before serving assets
4. `worker.ts` proxies API calls after stripping the prefix
5. `worker.ts` has SPA fallback (404 → index.html)
6. `wrangler.jsonc` has both route patterns (with and without `/*`)
7. `wrangler.jsonc` has `"binding": "ASSETS"` in the assets config
