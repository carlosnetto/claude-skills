# JWS Security Model

## Overview

X9.150 uses JWS (JSON Web Signature, RFC 7515) for mutual authentication between all system components. Every request and response between the Digital Channel Backend and the QR Payment Server is cryptographically signed.

**App developers do not handle JWS.** The Digital Channel Backend signs outbound messages and verifies inbound responses. Apps only send and receive plain JSON.

---

## JWS Header Structure

X9.150 extends the standard JWS header with custom fields declared as critical (`crit`):

```json
{
  "alg": "ES256",
  "typ": "payreq+jws",
  "kid": "payee-key-001",
  "iat": 1741530600,
  "ttl": 1741530900000,
  "correlationId": "550e8400-e29b-41d4-a716-446655440000",
  "crit": ["iat", "ttl", "correlationId"],
  "x5t#S256": "base64url-sha256-thumbprint",
  "x5c": ["base64-der-encoded-leaf-cert", "optional-intermediate"]
}
```

| Header | Description | Notes |
|---|---|---|
| `alg` | Signing algorithm | `"ES256"` (ECC P-256) or `"RS256"` (RSA) |
| `typ` | Message type | `"payreq+jws"` (request) or `"payresp+jws"` (response) |
| `kid` | Key ID | Identifies which key pair signed this message |
| `iat` | Issued At | Unix **seconds**. Must be within 8 minutes of current time. |
| `ttl` | Time To Live | Unix **milliseconds**. Must be in the future. |
| `correlationId` | Correlation ID | UUID **with dashes**. Response must echo the request's exact value. |
| `crit` | Critical headers | Always `["iat", "ttl", "correlationId"]` — receivers MUST validate all three |
| `x5t#S256` | Cert thumbprint | SHA-256 fingerprint of the signing certificate (base64url) |
| `x5c` | Certificate chain | Base64-encoded DER certificates — embeds cert so no external lookup needed |
| `jku` | JWK Set URL | URL to fetch signer's JWKS from Certificate Server (alternative to `x5c`) |

---

## Signing a JWS Message

Any JWS library can be used. The key requirements are:

1. Generate a fresh `correlationId` (UUID with dashes) for each request
2. Set `iat` to current Unix seconds
3. Set `ttl` to `(iat + validity_seconds) * 1000` (milliseconds)
4. Include `crit: ["iat", "ttl", "correlationId"]`
5. Include either `x5c` (embedded cert) or `jku` (cert server URL)
6. Sign with the private key corresponding to `kid`

```python
# Conceptual (any JWS library)
headers = {
    "alg": "ES256",
    "typ": "payreq+jws",
    "kid": key_id,
    "iat": int(time.time()),
    "ttl": (int(time.time()) + 300) * 1000,   # 5-minute TTL, in milliseconds
    "correlationId": str(uuid.uuid4()),         # UUID with dashes
    "crit": ["iat", "ttl", "correlationId"],
    "x5t#S256": cert_thumbprint,
    "x5c": [base64_der_cert],
}
token = jws_library.sign(payload_bytes, private_key, headers=headers)
```

---

## Verifying a JWS Message

A compliant receiver must:

1. **Find the certificate** — in priority order:
   - Check local cache using `x5t#S256` thumbprint
   - Extract from `x5c` header (embedded cert chain)
   - Fetch from `jku` URL (Certificate Server)
2. **Verify the cryptographic signature** using the certificate's public key
3. **Validate critical headers:**
   - `iat` — age must be ≤ 480 seconds (8 minutes)
   - `ttl` — must be > current time in milliseconds
   - `correlationId` — response must echo the request's exact value
4. **Validate `crit`** — all three headers must be listed; fail if any is missing

---

## Critical Header Validation Rules

```
iat freshness:     |now_seconds - iat| ≤ 480
ttl not expired:   ttl > now_milliseconds
correlationId:     response.correlationId == request.correlationId
crit completeness: ["iat", "ttl", "correlationId"] all present in crit array
```

**`iat` in seconds, `ttl` in milliseconds** — this mismatch is intentional and a common bug source. Double-check units in every implementation.

---

## Certificate Discovery Strategies

Implementations should support all three, tried in order:

### 1. Thumbprint Cache (fastest)
```
If x5t#S256 is in JWS header:
    Look up {x5t#S256}.pem in local certificate cache
    If found: use it → skip network calls
```

### 2. Embedded x5c (self-contained)
```
If x5c is in JWS header:
    Base64-decode the first entry → DER certificate
    Parse the DER → extract public key
    Cache it under x5t#S256 for future use
```

The `x5c` approach makes the system independent of a Certificate Server. Recommended for new implementations.

### 3. Remote jku (Certificate Server)
```
If jku is in JWS header:
    GET {jku} → JWKS document
    Find key by kid
    Extract x5c from JWKS → parse certificate
```

Used when certificates are managed centrally (e.g., X9 PKI infrastructure).

---

## Key Pair and Certificate Requirements

- **Algorithm:** ECC P-256 (ES256) recommended; RSA (RS256) also supported
- **Certificate format:** X.509, self-signed acceptable for POC; CA-signed for production
- **JWKS format:** Standard JSON Web Key Set with `x5c` (DER chain), `x5t#S256` (thumbprint), `alg`, `kid`
- **Private key:** PKCS8 PEM format; never transmitted, never committed to version control

Each identity (the Digital Channel Backend has one; the QR Payment Server has one) needs its own key pair. They use each other's public keys to verify incoming messages.

---

## Security Properties

| Property | Mechanism |
|---|---|
| **Authenticity** | Signature verifiable against known certificate |
| **Integrity** | JWS signature covers the full payload |
| **Freshness** | `iat` ± 480s window prevents replay attacks |
| **Non-repudiation** | Signed messages with embedded cert chain are auditable |
| **Correlation** | `correlationId` echo prevents response substitution |
| **Forward validity** | `ttl` limits how long a message can be used |

---

## Common JWS Implementation Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| `ttl` in seconds instead of milliseconds | TTL always "expired" | Multiply by 1000 |
| `iat` in milliseconds instead of seconds | `iat` appears far in the future | Divide by 1000 |
| Missing `crit` array | Receiver rejects as non-compliant | Always include `crit: ["iat", "ttl", "correlationId"]` |
| Not echoing `correlationId` in response | Correlation check fails | Copy request's `correlationId` into response header verbatim |
| UUID with dashes in `correlationId` format not matching | Comparison fails | UUID with dashes: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| Cert thumbprint mismatch | Cache miss on every request | Compute SHA-256 of the raw DER bytes, then base64url encode |
