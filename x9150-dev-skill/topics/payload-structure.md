# PaymentRequest Payload Structure

## Template vs Full PaymentRequest

There are two forms:

**Template** — what your app sends to `/generate`:
- Contains only the merchant-provided data
- Does NOT include `id`, `revision`, `status`, `qrCodeContent`, `timestamps` — those are server-assigned

**Full PaymentRequest** — what `/fetch` returns and what is stored:
- Includes all template fields plus server-assigned metadata

```json
{
  "id": "a1b2c3d4e5f6789012345678901234ab",  ← server: UUID, 32 hex, no dashes
  "revision": 1,                               ← server: version counter
  "qrCodeContent": "00020101...",              ← server: EMVCo TLV string
  "timestamps": {
    "created": "2026-03-09T14:30:00.000Z",
    "expires": "2026-03-09T14:45:00.000Z"
  },
  "status": "ACTIVE",                          ← ACTIVE | PAYMENT_INITIATED | PAID | CANCELLED
  "creditor": { ... },
  "bill": { ... },
  "paymentMethods": [ ... ]
}
```

---

## Template Schema

```json
{
  "creditor": {
    "name": "Big Burger Bar",
    "email": "hello@bigburger.com",
    "phone": "+12135550006",
    "address": {
      "line1": "789 Patty Blvd",
      "line2": "",
      "city": "Los Angeles",
      "state": "CA",
      "postalCode": "90001",
      "country": "US"
    },
    "MCC": "5812"
  },
  "bill": {
    "paymentTiming": "immediate",
    "description": "Dinner",
    "amountDue": { "amount": 47, "currency": "USD" },
    "tip": {
      "allowed": true,
      "range": { "min": 0, "max": 25 },
      "presets": [15, 18, 20]
    }
  },
  "paymentMethods": [
    {
      "currency": "USDC",
      "amount": 470000,
      "networks": {
        "Solana": { "address": "<merchant_wallet_pubkey>" }
      }
    }
  ]
}
```

---

## Field Reference

### creditor

| Field | Constraint | Notes |
|---|---|---|
| `name` | `^[ -~]*$`, max 50 | Printable ASCII only. Sanitize mobile keyboard curly quotes. |
| `email` | RFC 5322, max 254 | Optional but recommended |
| `phone` | `^\+[1-9]\d{1,20}$` | E.164. Must start with `+`. |
| `address.country` | ISO 3166-1 alpha-2 | `"US"`, `"BR"`, etc. |
| `MCC` | `^\d{4}$` | Exactly 4 decimal digits. See ISO 18245. |

### bill

| Field | Constraint | Notes |
|---|---|---|
| `paymentTiming` | `"immediate"` or `"deferred"` | Deferred requires `invoices[]` |
| `description` | string | Human-readable, shown to payer |
| `amountDue.amount` | uint64 ≥ 0 | Minor units (cents for USD). Never a float. |
| `amountDue.currency` | ISO 4217 | `"USD"`, `"BRL"` |
| `tip.allowed` | boolean | `false` = no tip UI shown |
| `tip.range.min/max` | integer | Tip percentage bounds |
| `tip.presets` | integer[] | Quick-select buttons in payer wallet UI |

### paymentMethods[]

| Field | Constraint | Notes |
|---|---|---|
| `currency` | string | `"USDC"`, `"USD"`, `"BRL"` |
| `amount` | uint64 ≥ 0 | USDC: dollars × 1,000,000. USD: cents. |
| `validUntil` | RFC 3339 timestamp | Optional: rate lock expiry for crypto amounts |
| `networks` | object | Keys are network names. See `networks.md`. |

---

## Deferred Payments (Invoices)

When `paymentTiming` is `"deferred"`, `invoices` with a `dueDate` is **required**:

```json
"bill": {
  "paymentTiming": "deferred",
  "description": "Electric bill - March 2026",
  "amountDue": { "amount": 12300, "currency": "USD" },
  "invoices": [
    {
      "dueDate": "2026-04-01",
      "amountDue": { "amount": 12300, "currency": "USD" }
    }
  ],
  "tip": { "allowed": false }
}
```

---

## ultimateCreditor (Marketplace / Aggregator Pattern)

When a payment aggregator is the direct creditor but a merchant is the real recipient. The payer sees both names:

```json
"creditor": {
  "name": "PayPal",
  "phone": "+14085555555",
  "MCC": "7372",
  ...
},
"ultimateCreditor": {
  "name": "Gadget Hub",
  "additionalInfo": [
    { "key": "paypalEmail", "value": "gadgethub@paypal.com" }
  ]
}
```

`additionalInfo` is a flexible key-value array for network-specific identifiers (cashtag, Pix alias, etc.).

---

## Common MCC Codes

| MCC | Category |
|---|---|
| `5812` | Restaurants / Eating Places |
| `5411` | Grocery Stores |
| `5942` | Book Stores |
| `5999` | Miscellaneous Retail |
| `7372` | Software / IT Services |
| `4900` | Utilities |

---

## Minimal Valid Template (Solana USDC, immediate, no tip)

```json
{
  "creditor": {
    "name": "Brew & Bean Coffee",
    "phone": "+14155550001",
    "address": { "line1": "123 Coffee Lane", "city": "San Francisco", "state": "CA", "postalCode": "94102", "country": "US" },
    "MCC": "5812"
  },
  "bill": {
    "paymentTiming": "immediate",
    "description": "Coffee",
    "amountDue": { "amount": 56, "currency": "USD" },
    "tip": { "allowed": false }
  },
  "paymentMethods": [
    {
      "currency": "USDC",
      "amount": 560000,
      "networks": { "Solana": { "address": "<wallet_pubkey>" } }
    }
  ]
}
```
