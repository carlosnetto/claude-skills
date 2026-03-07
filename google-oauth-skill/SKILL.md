---
name: google-oauth-dev
description: Battle-tested patterns for Google OAuth integration in web apps with Spring Boot backends. Covers Google Cloud Console setup, domain restrictions, Internal vs External user type, Spring Session vs JWT, auto-provisioning, and frontend integration. Learned from production incidents.
user-invocable: false
---

# Google OAuth Integration

You are an expert in integrating Google OAuth into web applications with Spring Boot backends. You follow battle-tested patterns for secure, maintainable auth flows.

## Operating Procedure

1. When the user asks about Google OAuth, Google Cloud Console setup, login restrictions, sessions, or auth flow, load the relevant topic file(s) from the `topics/` directory.
2. Apply the patterns and avoid the pitfalls described in the topic files.
3. Always clarify which layer is responsible for each restriction — Google Cloud Console controls who can attempt login; the backend controls who is allowed through.

## Quick Reference

### Auth Flow (Spring Boot + Google OAuth)
```
Browser → Google popup → access token
       → POST /api/auth/google (with token)
       → Backend calls Google userinfo API
       → Backend checks allowed domains
       → Backend queries/inserts user in DB
       → Spring Session created → session cookie returned
       → All subsequent API calls use session cookie
```

### Key Configuration
| Setting | Where | Purpose |
|---|---|---|
| OAuth app User Type | Google Cloud Console → Audience | Internal = org only; External = any Google account |
| Allowed domains | `application.yml` → `google.allowed-domains` | Comma-separated list of allowed email domains |
| Session store | Spring Session JDBC / Redis | Server-side session — no JWT needed |
| OAuth scopes | Frontend `useGoogleLogin` | `openid email profile` |

### Critical Rules
- **Two layers control access** — Google Cloud Console controls who can attempt login; your backend domain check controls who gets through. Both must be configured correctly.
- **`org_internal` error means Google blocked it before your code ran** — changing backend config alone has no effect. Fix it in Google Cloud Console → Audience.
- **Use Spring Session, not JWT** — server-side sessions are enterprise-grade, support true logout, and are unaffected by post-quantum cryptography. JWT is redundant for browser-only apps.
- **Never hardcode a single domain** — use a comma-separated config property so adding domains requires no code change.
- **Auto-provision unknown users from allowed domains** — insert on first login, don't require manual DB seeding.

## Topic Files

Load these for detailed patterns:

- `topics/google-cloud-setup.md` — OAuth app creation, Internal vs External, Audience navigation, client ID and secret
- `topics/backend-integration.md` — Spring Boot auth service, domain check, auto-provisioning, Spring Session
- `topics/frontend-integration.md` — useGoogleLogin, token flow, API calls, session cookie handling
- `topics/security-decisions.md` — Spring Session vs JWT, Redis upgrade path, PQC implications, API key future
