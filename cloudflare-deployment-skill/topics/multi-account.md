# Multi-Account Cloudflare Deployments

## The Problem

When you have multiple Cloudflare accounts (personal + business, or multiple business accounts), three resources must be on the **same account**:

1. **DNS zone** (e.g., `materalabs.us`)
2. **Worker** (e.g., `x9-150-wallet`)
3. **Tunnel** (e.g., `x9-api-materalabs`)

If any of these are on different accounts, things break in subtle ways.

## Mismatch Symptoms

| Mismatch | Symptom |
|---|---|
| Worker on account A, DNS zone on account B | HTML loads but assets return 404 |
| Wrangler logged into wrong account | `"Could not find zone for domain.com"` during deploy |
| Cloudflared cert for wrong zone | DNS records created on wrong zone |
| Tunnel on wrong account | Tunnel connects but hostname doesn't resolve |

## How to Verify Account Alignment

### Check which account owns a zone
Look at the Cloudflare dashboard URL:
```
dash.cloudflare.com/<ACCOUNT_ID>/domain.com
```
The account ID in the URL tells you which account owns the zone.

### Check wrangler's active account
```bash
npx wrangler whoami
# Output shows account name and ID
# Verify: account ID should match your wrangler.jsonc account_id
```

### Check cloudflared's active zone
`~/.cloudflared/cert.pem` is tied to a single zone. To verify or change:
```bash
# Re-login to select the correct zone
rm ~/.cloudflared/cert.pem
cloudflared tunnel login    # Opens browser — select the correct zone
```

## Wrangler Login

Wrangler uses OAuth tokens stored in `~/.wrangler/`. If you get zone-not-found errors:

```bash
# Login with the account that owns the DNS zone
npx wrangler login    # Opens browser — log in with the correct email

# Verify
npx wrangler whoami   # Should show the expected account name and ID
```

The `account_id` in `wrangler.jsonc` must match the account you're logged into. If they don't match, wrangler won't find routes or zones.

## Cloudflared Login

Cloudflared login is **per-zone**, not per-account. The `cert.pem` determines which zone tunnel operations target.

```bash
# Login and select the zone where your tunnel DNS records should live
cloudflared tunnel login    # Opens browser — select "materalabs.us" (not "materalab.us")
```

**Pitfall**: If you have `materalab.us` (personal) and `materalabs.us` (business) — selecting the wrong zone means `cloudflared tunnel route dns` creates CNAME records on the wrong domain.

## The Account Alignment Checklist

Before deploying, verify all three match:

```bash
# 1. Wrangler account
npx wrangler whoami
# Expected: Tic.cloud / 45281eba...

# 2. Wrangler config account_id
cat wrangler.jsonc | grep account_id
# Expected: 45281eba1857e04d45fe46d31bdc2f0b

# 3. Tunnel credentials
cloudflared tunnel info x9-api-materalabs
# Expected: shows the correct tunnel ID and account

# 4. DNS zone
# Check dashboard URL: dash.cloudflare.com/45281eba.../materalabs.us
```

If any of these point to different accounts, fix them before deploying.

## Switching Between Accounts

When you need to work on a different account's resources:

```bash
# Switch wrangler
npx wrangler login    # Re-authenticate with the other account

# Switch cloudflared (only needed for admin commands)
rm ~/.cloudflared/cert.pem
cloudflared tunnel login    # Select the other zone
```

**Note**: Running a tunnel (`cloudflared tunnel run`) does NOT require `cert.pem` when using UUID + credentials file. Only administrative commands (create, delete, route) need it.
