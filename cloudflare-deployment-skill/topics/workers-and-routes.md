# Workers & Route-Based Deployment

## The Problem

When deploying a new app to a domain that already has a Worker serving the root, you can't use a custom domain — it would conflict with the existing worker. You need route-based deployment to serve your app under a sub-path while leaving the rest of the domain untouched.

## Route-Based vs Custom Domain

Cloudflare Workers can be deployed in two ways:

| Method | Use Case | Routing |
|---|---|---|
| Custom domain | App owns the entire domain | All traffic goes to this worker |
| Route pattern | App shares a domain | Only matching paths go to this worker |

Routes are matched by **specificity** — `domain.com/x9.150/*` takes priority over a catch-all `domain.com/*` worker. This allows coexistence.

## Wrangler Configuration

```jsonc
{
  "name": "x9-150-wallet",
  "account_id": "45281eba1857e04d45fe46d31bdc2f0b",
  "compatibility_date": "2026-02-23",
  "main": "./worker.ts",
  "assets": {
    "directory": "./dist",
    "binding": "ASSETS"       // REQUIRED — without this, env.ASSETS is undefined
  },
  "routes": [
    { "pattern": "materalabs.us/x9.150/*", "zone_name": "materalabs.us" },
    { "pattern": "materalabs.us/x9.150", "zone_name": "materalabs.us" }
  ],
  "vars": {
    "API_TUNNEL_URL": "https://x9-api.materalabs.us",
    "BASE_PATH": "/x9.150"
  }
}
```

**Two route entries** are needed: one with `/*` (for sub-paths) and one without (for the exact path). Without the second, requests to `/x9.150` (no trailing slash) won't match.

## Worker Pattern: Prefix Strip + API Proxy + SPA Fallback

```typescript
export default {
  async fetch(request: Request, env: any): Promise<Response> {
    const url = new URL(request.url);
    const basePath = env.BASE_PATH || '/x9.150';

    // 1. Strip the base path prefix
    let pathname = url.pathname;
    if (pathname.startsWith(basePath)) {
      pathname = pathname.slice(basePath.length) || '/';
    }

    // 2. Proxy API calls to the tunnel
    const apiPaths = ['/fetch', '/generate', '/notify'];
    if (apiPaths.includes(pathname)) {
      if (request.method === 'OPTIONS') {
        return new Response(null, {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
          },
        });
      }
      const targetUrl = `${env.API_TUNNEL_URL}${pathname}`;
      const proxyRequest = new Request(targetUrl, {
        method: request.method,
        headers: request.headers,
        body: request.body,
      });
      const response = await fetch(proxyRequest);
      const newResponse = new Response(response.body, response);
      newResponse.headers.set('Access-Control-Allow-Origin', '*');
      return newResponse;
    }

    // 3. Serve static assets (strip prefix so /x9.150/assets/... → /assets/...)
    const assetUrl = new URL(request.url);
    assetUrl.pathname = pathname;
    const assetRequest = new Request(assetUrl.toString(), request);
    const assetResponse = await env.ASSETS.fetch(assetRequest);

    // 4. SPA fallback: 404 → index.html
    if (assetResponse.status === 404) {
      const fallbackUrl = new URL(request.url);
      fallbackUrl.pathname = '/index.html';
      return env.ASSETS.fetch(new Request(fallbackUrl.toString(), request));
    }

    return assetResponse;
  },
};
```

## API Proxy: Never Copy the Entire Request Object

When proxying API calls from the Worker to a backend tunnel, **do not** use `fetch(new Request(apiUrl, request))`. This copies `credentials: 'include'` from the browser request into the Worker's outbound fetch, which is invalid in the Worker runtime and causes a `TypeError`.

```typescript
// BAD — copies credentials: 'include' from browser request, throws TypeError
return fetch(new Request(apiUrl, request));

// GOOD — construct the outbound request explicitly
return fetch(apiUrl, {
  method: request.method,
  headers: request.headers,
  body: request.method !== 'GET' && request.method !== 'HEAD' ? request.body : undefined,
  redirect: 'follow',
});
```

Also note: never pass a `body` for `GET`/`HEAD` requests — some runtimes throw on this.

## Sub-Path API Routing: Scope APIs Under the App Prefix

When multiple apps share a domain (e.g. `materalabs.us/app-a`, `materalabs.us/app-b`), global API paths like `/api/...` create naming conflicts. Scope your API calls under the app's sub-path using `import.meta.env.BASE_URL` in the frontend:

```typescript
// BAD — /api/auth/google conflicts with other apps' /api routes
fetch('/api/auth/google', ...)

// GOOD — scoped under /digitaltwin-app/api/auth/google
fetch(`${import.meta.env.BASE_URL}api/auth/google`, ...)
```

In `vite.config.ts`, proxy the scoped path and rewrite before forwarding to the backend:

```typescript
proxy: {
  '/digitaltwin-app/api': {
    target: 'http://localhost:8081',
    changeOrigin: true,
    rewrite: (path) => path.replace(/^\/digitaltwin-app/, ''),
  },
},
```

The worker strips the base path before proxying, so the backend always sees `/api/...` unchanged.

## ASSETS Binding Pitfall

When using Workers Static Assets (`assets.directory` in wrangler config) with a custom worker (`main`), you **must** set `"binding": "ASSETS"` in the assets config. Without it:

- `env.ASSETS` is `undefined` at runtime
- The worker crashes with Cloudflare error **1101** (worker threw an exception)
- No build-time warning — the error only appears at runtime

## Debug Pattern: Identifying 403 Source

When a 403 appears and it's unclear whether it comes from Cloudflare WAF, the Worker itself, or the proxied backend, add a debug capture block to the Worker:

```typescript
if (!proxyResponse.ok) {
  const body = await proxyResponse.text();
  let parsed: any = {};
  try { parsed = JSON.parse(body); } catch { parsed = { raw: body.slice(0, 300) }; }
  return Response.json({ ...parsed, _status: proxyResponse.status }, { status: proxyResponse.status });
}
```

Reading the result:
- `raw` contains HTML → Cloudflare WAF blocked the request (never reached backend), or Spring Whitelabel page (backend reached but crashed)
- `error` is a JSON string → backend returned a structured error (backend reached)
- `"Invalid CORS request"` → Spring rejected the CORS preflight (origin not in allowed list)

Test the CORS preflight directly from curl before spending time in the browser:

```bash
curl -X OPTIONS https://your-domain.com/your-app/api/endpoint \
  -H "Origin: https://your-domain.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type"
# Expected: 200 with Access-Control-Allow-Origin header
# Got 403: origin not in allowed list
```

## Spring CORS: Profile Files Don't Auto-Load

When the backend is Spring Boot, `application-local.yml` (or any `application-{profile}.yml`) only loads when that profile is **explicitly activated** at startup. Without it, `@Value("${app.allowed-origins:...}")` falls back to its default — often just `http://localhost:3000` — silently blocking all production origins.

**Fix**: Put non-secret production origins directly in `application.yml`. Reserve profile files for secrets (DB credentials) and environment-specific overrides.

```yaml
# application.yml — always loaded
app:
  allowed-origins: http://localhost:3000,https://your-domain.com

# application-local.yml — only with --spring.profiles.active=local
spring:
  datasource:
    username: admin
    password: secret
```

Start with the profile explicitly:
```bash
mvn spring-boot:run -Dspring-boot.run.profiles=local
```

## Cache Invalidation

After deploying, stale content may persist in Cloudflare's edge cache. Fix:

1. **Purge cache**: Dashboard → domain → Caching → Configuration → Purge Everything
2. **Hard refresh**: Cmd+Shift+R in browser, or test in incognito
3. **Check headers**: `curl -I https://domain.com/path` — look at `cf-cache-status`

## Don't Upload Source Files

Only deploy `dist/` (built output). If the source `index.html` (referencing `index.tsx`) gets deployed, the browser shows a white page — it can't load uncompiled TypeScript. The `assets.directory` in wrangler config must point to `dist/`, not the project root.
