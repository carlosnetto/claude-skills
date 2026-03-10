# Error Troubleshooting

## The Core Problem: Opaque Server Errors

The QR Payment Server validates every template against the OpenAPI spec. When validation fails, implementations typically return a generic error:

```
500 Internal Server Error
{ "error": "QR generation failed due to an invalid payment template." }
```

The response body usually doesn't say which field failed — the validation error appears in server logs only. Client-side validation is the first line of defense.

---

## Error: "invalid payment template" (500)

This almost always means a field is failing a regexp or type constraint in the OpenAPI spec.

### Cause 1: Non-ASCII in `creditor.name`

**Constraint:** `^[ -~]*$` (printable ASCII 0x20–0x7E), max 50 chars.

**Typical cause:** Mobile keyboards silently replace:
- `'` → `'` (U+2019, RIGHT SINGLE QUOTATION MARK) — most common
- `"..."` → `"..."` (U+201C/201D, CURLY DOUBLE QUOTES)
- `-` → `—` (U+2014, EM DASH)
- Regular space → non-breaking space (U+00A0) in copy-paste

**How to detect:** In a browser console:
```javascript
[...'Oregon\u2019s Burger'].map(c => `${c} (U+${c.charCodeAt(0).toString(16).toUpperCase()})`)
// 'U+2019' appears for the curly apostrophe
```

**Fix — sanitize before building the payload:**
```typescript
const toAscii = (s: string) =>
  s
    .replace(/[\u2018\u2019\u201A\u201B]/g, "'")
    .replace(/[\u201C\u201D\u201E\u201F]/g, '"')
    .replace(/[\u2013\u2014]/g, '-')
    .replace(/\u00A0/g, ' ')
    .replace(/[^ -~]/g, '');   // strip anything still outside printable ASCII

// In payload:
name: toAscii(settings.businessName || 'Merchant')
```

---

### Cause 2: Phone number missing `+`

**Constraint:** `^\+[1-9]\d{1,20}$`

```
"12135550006"     INVALID — missing +
"+12135550006"    VALID
"+5511999990000"  VALID (Brazil)
```

**Fix — three layers:**

1. On input (enforce `+` as user types):
```typescript
const enforced = value.startsWith('+') ? value : '+' + value.replace(/^\+*/, '');
```

2. On app load (migrate stored values from old users):
```typescript
if (phone && !phone.startsWith('+')) phone = '+' + phone;
```

3. Pre-flight gate (block the API call):
```typescript
if (!phone.startsWith('+')) {
  showError('Phone must start with + (e.g. +12135550006). Update in Settings.');
  return;
}
```

---

### Cause 3: Invalid MCC

**Constraint:** `^\d{4}$` — exactly 4 decimal digits.

```
"58A2"   INVALID — contains a letter
"581"    INVALID — only 3 digits
"5812"   VALID
```

```typescript
if (!/^\d{4}$/.test(mcc)) {
  showError('MCC must be exactly 4 digits (e.g. 5812).');
  return;
}
```

---

### Cause 4: Amount is a float or negative

**Constraint:** uint64, non-negative integer.

```
0.89   INVALID — float
-5     INVALID — negative
89     VALID (cents for $0.89 USD)
890000 VALID (USDC atomic units for $0.89)
```

```typescript
const cents = Math.round(parseFloat(input) * 100);
const usdc  = Math.round(parseFloat(input) * 1_000_000);
// Math.round() is essential — 0.1 * 100 = 10.000000000000002 without it
```

---

### Cause 5: Invalid `protectionType` for banking networks

**Valid values:** exactly `"tokenized"`, `"encrypted"`, or `"plaintext"`.

`"clear"` is a common mistake — it looks reasonable but is not in the enum.

---

### Cause 6: Deferred payment missing `invoices`

When `paymentTiming` is `"deferred"`, the spec requires `invoices[]` with `dueDate`.

```json
"bill": {
  "paymentTiming": "deferred",
  "invoices": [{ "dueDate": "2026-04-01", "amountDue": { "amount": 12300, "currency": "USD" } }]
}
```

---

### Cause 7: Including server-managed fields in the template

The template sent to `/generate` must NOT include fields the server sets:

```
id, revision, status, qrCodeContent, timestamps
```

Including them may cause validation errors or be silently overwritten, depending on implementation.

---

### Cause 8: Timestamp format wrong

**Constraint:** `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$`

Exactly 3 millisecond digits, `Z` suffix (UTC).

```
"2026-03-09T14:30:00.000Z"  VALID
"2026-03-09T14:30:00Z"      INVALID — missing .000
"2026-03-09 14:30:00"       INVALID — missing T and Z
```

---

### Cause 9: UUID with dashes

**Constraint:** `^[0-9a-fA-F]{32}$` — 32 hex chars, no dashes.

```
"550e8400-e29b-41d4-a716-446655440000"   INVALID — has dashes
"550e8400e29b41d4a716446655440000"       VALID
```

---

## JWS Validation Errors (Server-to-Server)

These appear when the Digital Channel Backend or QR Payment Server rejects a JWS message:

| Error | Cause | Fix |
|---|---|---|
| `"iat too old/future"` | Clock drift or stale message | Sync server clocks; `iat` must be within 480s of receiver's clock |
| `"TTL expired"` | `ttl` in the past | Set `ttl = (iat + 300) * 1000` — note: milliseconds, not seconds |
| `"correlationId mismatch"` | Response didn't echo request's ID | Server must copy request's `correlationId` into response header unchanged |
| `"Missing X in crit"` | `crit` list incomplete | Always include `["iat", "ttl", "correlationId"]` in `crit` |
| `"Cannot find certificate"` | No `x5c`, `jku`, or cached thumbprint | Embed `x5c` in every JWS header, or run a Certificate Server |
| `"iat in milliseconds"` | `iat` is current epoch × 1000 | `iat` is in **seconds**; `ttl` is in milliseconds — they differ |

---

## Debugging Workflow

When you get a validation error and don't have server logs:

1. **Log the full payload** before sending:
   ```typescript
   console.log(JSON.stringify(payload, null, 2));
   ```
2. **Check `creditor.name`** for non-ASCII characters (curly quotes, em-dashes)
3. **Check `creditor.phone`** starts with `+`
4. **Check `creditor.MCC`** is exactly 4 digits
5. **Check amounts** are integers: `Number.isInteger(amount) && amount >= 0`
6. **Check `protectionType`** is one of `tokenized` / `encrypted` / `plaintext`
7. **Check for server-managed fields** (`id`, `status`, etc.) in the template
8. **Check `paymentTiming`** — if `"deferred"`, `invoices` must be present
9. **Validate offline** using the OpenAPI spec schema directly with a validator library
