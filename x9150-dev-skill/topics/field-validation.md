# Field Validation & Sanitization

## Why Validate Client-Side

X9.150 servers validate templates against the OpenAPI spec using a schema validator. When validation fails, servers typically return a generic 500 with no indication of which field failed — the actual error is in server logs only.

Client-side validation catches these early and gives actionable feedback to users.

## Pre-Flight Checklist (before calling /generate)

```typescript
function validateTemplate(settings: MerchantSettings): string | null {
  // 1. Phone: must start with +
  if (!settings.phone?.startsWith('+')) {
    return 'Phone must start with + (E.164 format, e.g. +12135550006).';
  }
  // 2. MCC: exactly 4 digits
  if (!/^\d{4}$/.test(settings.mcc || '')) {
    return 'MCC must be exactly 4 digits (e.g. 5812).';
  }
  // 3. Business name: non-empty after sanitization
  if (!toAscii(settings.businessName || '').trim()) {
    return 'Business name is required.';
  }
  return null;
}
```

---

## Phone Number: E.164

**Spec pattern:** `^\+[1-9]\d{1,20}$`

```
INVALID: "12135550006"        → missing +
INVALID: "+1 213 555 0006"    → spaces not allowed
INVALID: "+1-213-555-0006"    → dashes not allowed
VALID:   "+12135550006"
VALID:   "+5511999990000"     (Brazil)
```

**Three enforcement layers:**

```typescript
// 1. On input — force + prefix as user types
const handlePhoneInput = (value: string) =>
  value.startsWith('+') ? value : '+' + value.replace(/^\+*/, '');

// 2. On app/session load — migrate old stored values without +
const sanitizePhone = (p: string) =>
  p && !p.startsWith('+') ? '+' + p : p;

// 3. Pre-flight gate — block the API call
if (!phone.startsWith('+')) {
  showError('Phone must start with + (e.g. +12135550006).');
  return;
}
```

---

## Business Name: Printable ASCII

**Spec pattern:** `^[ -~]*$` (Unicode codepoints 0x20–0x7E), max 50 chars.

The invisible failure mode: mobile keyboards and rich text editors silently insert Unicode characters that look identical on screen but fail the regexp.

Common culprits:
| Original | Unicode | Replacement |
|---|---|---|
| `'` | U+2019 RIGHT SINGLE QUOTATION MARK | `'` |
| `'` | U+2018 LEFT SINGLE QUOTATION MARK | `'` |
| `"` `"` | U+201C/201D CURLY DOUBLE QUOTES | `"` |
| `—` | U+2014 EM DASH | `-` |
| `–` | U+2013 EN DASH | `-` |
| ` ` | U+00A0 NON-BREAKING SPACE | ` ` |

**Sanitizer — apply before building the payload, not before storing:**

```typescript
const toAscii = (s: string): string =>
  s
    .replace(/[\u2018\u2019\u201A\u201B]/g, "'")
    .replace(/[\u201C\u201D\u201E\u201F]/g, '"')
    .replace(/[\u2013\u2014]/g, '-')
    .replace(/\u00A0/g, ' ')
    .replace(/[^ -~]/g, '');  // strip anything still outside printable ASCII

// In payload builder:
creditor.name = toAscii(settings.businessName || 'Merchant');
```

Do NOT modify the stored/displayed value — only sanitize when constructing the payload. The user sees their original name; the server receives the ASCII equivalent.

---

## MCC: Merchant Category Code

**Spec pattern:** `^\d{4}$` — exactly 4 decimal digits.

```typescript
if (!/^\d{4}$/.test(mcc)) {
  showError(`Invalid MCC "${mcc}" — must be exactly 4 digits.`);
  return;
}
```

Common MCC values: `5812` (restaurants), `5411` (grocery), `5942` (bookstore), `7372` (software), `4900` (utilities).

---

## Monetary Amounts

**Spec type:** uint64, non-negative integer. Never a float.

```typescript
// USD, BRL — minor unit is cent (×100)
const cents = Math.round(parseFloat(input) * 100);

// USDC — minor unit is atomic unit (×1,000,000)
const usdcUnits = Math.round(parseFloat(input) * 1_000_000);
```

`Math.round()` is essential: `0.1 * 100 === 10.000000000000002` in IEEE 754 floating point.

**Runtime guard:**
```typescript
if (!Number.isInteger(amount) || amount < 0) {
  throw new Error(`Amount must be a non-negative integer, got: ${amount}`);
}
```

---

## Timestamps

**Spec pattern:** `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$`

Exactly 3 millisecond digits. Always `Z` (UTC). No timezone offsets.

```typescript
// JavaScript Date.toISOString() always produces the correct format
new Date().toISOString()  // "2026-03-09T14:30:00.000Z" ✓
```

```python
# Python
from datetime import datetime, timezone
now = datetime.now(timezone.utc)
ts = now.strftime('%Y-%m-%dT%H:%M:%S.') + f"{now.microsecond // 1000:03d}Z"
```

---

## UUIDs

**Spec pattern:** `^[0-9a-fA-F]{32}$` — 32 hex chars, **no dashes**.

```typescript
// Correct
const id = crypto.randomUUID().replace(/-/g, '');  // "550e8400e29b41d4a716446655440000"

// Wrong — dashes cause validation failure
const id = crypto.randomUUID();  // "550e8400-e29b-41d4-a716-446655440000"
```

---

## Country Code

**Format:** ISO 3166-1 alpha-2, exactly 2 uppercase letters.

```
VALID:   "US", "BR", "DE", "JP"
INVALID: "USA", "us", "United States"
```

---

## Complete Validation Checklist

Before POSTing to `/generate`:

1. `creditor.phone` starts with `+`
2. `creditor.MCC` matches `^\d{4}$`
3. `creditor.name` contains only printable ASCII (after `toAscii()`)
4. `creditor.address.country` is 2-letter ISO code
5. `bill.amountDue.amount` is a non-negative integer (cents)
6. All `paymentMethods[].amount` are non-negative integers (correct minor units)
7. `bill.paymentTiming` is `"immediate"` or `"deferred"`
8. If `"deferred"`, `bill.invoices[]` with `dueDate` is present
9. If `tip.allowed` is `true`, `range` and `presets` are present
10. Template does NOT include `id`, `revision`, `status`, `qrCodeContent`, `timestamps`
11. All `protectionType` values are `"tokenized"`, `"encrypted"`, or `"plaintext"`
