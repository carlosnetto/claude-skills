# Backend Integration (Spring Boot)

## Auth Flow

```
POST /api/auth/google  { accessToken }
  → call Google userinfo API with token
  → validate email domain against allowed-domains list
  → query users table (insert if new @allowed-domain user)
  → check status (reject if suspended)
  → create Spring Session → return session cookie
```

---

## Domain Restriction — Config-Driven List

Never hardcode a single domain. Use a comma-separated property so adding domains requires only a config change, no code change.

**application.yml:**
```yaml
google:
  allowed-domains: matera.com,zoripay.xyz
```

**GoogleAuthService.java:**
```java
@Value("${google.allowed-domains}")
private List<String> allowedDomains;

// Check in verify():
boolean domainAllowed = allowedDomains.stream()
        .anyMatch(d -> info.email().endsWith("@" + d));
if (!domainAllowed) {
    log.warn("Login attempt from non-allowed domain: {}", info.email());
    throw new ResponseStatusException(
            HttpStatus.FORBIDDEN,
            "Access restricted to: " + allowedDomains.stream().map(d -> "@" + d).toList());
}
```

Spring binds comma-separated `@Value` strings to `List<String>` automatically.

---

## Auto-Provisioning New Users

Don't require manual DB seeding for every new user. Insert on first successful login:

```java
String status;
try {
    status = jdbc.queryForObject(
            "SELECT status FROM digitaltwinapp.users WHERE email = ?",
            String.class, info.email());
} catch (EmptyResultDataAccessException e) {
    log.info("Auto-provisioning new user: {}", info.email());
    jdbc.update(
            "INSERT INTO digitaltwinapp.users (id, email, name, status) VALUES (gen_random_uuid(), ?, ?, 'active')",
            info.email(), info.name());
    status = "active";
}
```

This pattern:
- Existing users → normal path (status check only)
- New users from allowed domains → auto-inserted as `active`
- Subsequent logins → hit the existing row normally

**Downstream provisioning:** if the user needs accounts or resources created (e.g. mini-core accounts), trigger via `pg_notify` on the INSERT so provisioning happens asynchronously without blocking the login response.

---

## Spring Session JDBC

Sessions stored in PostgreSQL. Every API call validates the session cookie against the `SPRING_SESSION` table.

**application.yml:**
```yaml
spring:
  session:
    store-type: jdbc
    jdbc:
      initialize-schema: always
      table-name: SPRING_SESSION
    timeout: 7d
```

Features:
- Survives application restarts (session in DB, not memory)
- True server-side logout — delete the session row, cookie is immediately dead
- Works across multiple instances (shared DB)
- httpOnly + SameSite=Lax cookie by default (XSS and CSRF protection)

**Redis upgrade path:** swap `store-type: jdbc` for `store-type: redis` + add `spring-session-data-redis` dependency. Zero changes to controllers or services — Spring Session abstracts the store completely. Use Redis when session lookup latency becomes a concern at scale.

---

## User Status Enforcement

Support `active` / `suspended` statuses in the users table:

```java
if ("suspended".equals(status)) {
    log.warn("Login attempt from suspended account: {}", info.email());
    throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Account is suspended");
}
```

This lets you disable individual users without removing them from the DB or revoking their Google account.

---

## System Accounts

Some users must exist in the DB but must never be able to log in (e.g. a liquidity buffer account used as a transaction counterparty). Pattern: set their email to a non-Google-domain value (e.g. `liquidity-buffer@system`). The domain check rejects it automatically — no special code needed.

---

## CORS — Production Origins Must Be in the Base Config

`application-{profile}.yml` only loads when that profile is explicitly activated. If allowed origins are only in `application-local.yml`, production requests get `403 Invalid CORS request` because the property defaults to `http://localhost:3000`.

```yaml
# application.yml — non-secret origins always here
app:
  allowed-origins: http://localhost:3000,https://yourdomain.com
```

Reserve `application-local.yml` for secrets (DB credentials) and local overrides only.

**Diagnosing CORS rejections:**
```bash
curl -X OPTIONS https://your-api.com/api/auth/google \
  -H "Origin: https://your-frontend.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type"
# Expected: 200 with Access-Control-Allow-Origin header
# If 403 with body {"raw":"Invalid CORS request"} → Spring rejected the preflight
```

---

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/auth/google` | Exchange Google access token for session |
| `GET` | `/api/auth/me` | Return current session user (401 if not authenticated) |
| `POST` | `/api/auth/logout` | Destroy session |

All other endpoints should be session-protected. `GET /api/auth/me` returning `401` is the standard unauthenticated response — use it to verify the backend is reachable and auth is working before debugging further.
