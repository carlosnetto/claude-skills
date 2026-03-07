# Google Cloud Console Setup

## Creating an OAuth App

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create or select a project
3. **APIs & Services → Credentials → Create Credentials → OAuth client ID**
4. Application type: **Web application**
5. Add authorized JavaScript origins (e.g. `https://yourdomain.com`, `http://localhost:3000`)
6. Add authorized redirect URIs if using redirect flow (not needed for implicit/token flow)
7. Copy the **Client ID** and **Client Secret** — store the secret securely

The Client ID is public (embedded in frontend code). The Client Secret is only needed if using server-side token exchange.

---

## Internal vs External User Type — The Most Common Gotcha

### The error
```
Error 403: org_internal
Access blocked: [App] can only be used within its organization.
```

This means your OAuth app is set to **Internal**, which restricts login to users within your Google Workspace organization only. Google blocks the attempt before your backend ever sees the request — **changing backend config alone has no effect**.

### Where to fix it (Google reorganized this menu — easy to miss)

**Google Cloud Console → correct project → left sidebar → Audience**

- NOT "OAuth Overview" (that's a metrics dashboard)
- NOT "OAuth consent screen" (may not appear in the sidebar depending on console version)
- Look specifically for **Audience** in the left menu under APIs & Services

Change **User Type** from `Internal` to `External` → Save.

No new client ID or secret is generated — credentials stay the same.

### Internal vs External comparison

| | Internal | External |
|---|---|---|
| Who can attempt login | Only users in your Google Workspace org | Any Google account |
| Your backend domain check | Never reached — Google blocks first | Runs normally |
| Use case | Pure internal tools | Any app with controlled domain logic |

### The two-layer model

With `External`, you control access via your backend:

```
Google OAuth (External) → allows any Google account to attempt login
Backend domain check    → only allowed domains get through (e.g. @matera.com, @zoripay.xyz)
```

This is more flexible — you can allow multiple domains, add new ones via config, and still block everyone else.

---

## Zero Trust / Cloudflare One Requirement

If using Cloudflare Tunnels alongside OAuth, the tunnel requires **Cloudflare One** (Zero Trust) free plan activated. This is separate from the Google Cloud setup.

---

## Scopes

For standard login (email, name, profile photo):
```
openid email profile
```

Maps to Google userinfo API fields: `email`, `name`, `picture`.

Do not request more scopes than needed — users see the permission list and excessive scopes reduce trust.

---

## Rotating Credentials

If the client secret is compromised:
1. Google Cloud Console → Credentials → edit the OAuth client → **Add new secret** (or regenerate)
2. Update the secret in your backend config / secrets manager
3. Delete the old secret after confirming the new one works

The client ID never changes — only the secret rotates.
