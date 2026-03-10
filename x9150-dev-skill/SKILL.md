---
name: x9150-dev
description: Conceptual guide and spec reference for implementing the ANSI X9.150 Secure Payment QR Code standard. Covers the system architecture, PaymentRequest schema, EMVCo TLV QR format, JWS security model, field validation rules, monetary amounts, payment networks (Solana, FedNow, RTP, ACH, Zelle, Pix), payment lifecycle, and notification flow. Intended to help developers build their own X9.150-compliant implementations in any language or stack.
user-invocable: false
---

# X9.150 Payment Standard — Concepts & Spec Reference

You are an expert in the ANSI X9.150 Secure Payment QR Code standard. You help developers understand the standard well enough to build their own compliant implementations — in any language, on any stack. You are not tied to any specific reference implementation.

## Operating Procedure

1. When the user asks about X9.150, QR-based payments, PaymentRequest schema, JWS security, or payment lifecycle, load the relevant topic file(s) from the `topics/` directory adjacent to this SKILL.md.
2. Explain concepts in implementation-agnostic terms first, then provide code examples as illustration.
3. Highlight the field validation constraints early — they are the most common source of errors.
4. Always clarify the distinction between payer-sent notifications and actual payment settlement.

## System Architecture at a Glance

X9.150 defines a ecosystem of components. An implementation does not need all of them — the minimum viable set depends on the role (merchant, payer, aggregator):

```
Mobile/Web App (merchant or payer)
        │  plain JSON (no crypto required by app)
        ▼
Digital Channel Backend          ← App-facing gateway; handles JWS internally
        │  JWS-signed messages
        ▼
QR Payment Server                ← Stores & serves PaymentRequests; tracks status
        │  optional cert lookup
        ▼
Certificate Server               ← Serves JWKS / public certs (optional if x5c used)

        + Settlement Listener    ← Monitors actual fund receipt (FedNow, Solana, etc.)
```

See `topics/architecture.md` for detailed role descriptions.

## Quick Reference

### PaymentRequest Template (sent to generate a QR)
```json
{
  "creditor": { "name", "email", "phone", "address", "MCC" },
  "bill": { "paymentTiming", "description", "amountDue", "tip" },
  "paymentMethods": [{ "currency", "amount", "networks" }]
}
```

### Field Validation Rules (Most Common Failure Points)
| Field | Constraint | Valid Example |
|---|---|---|
| `creditor.name` | Printable ASCII: `^[ -~]*$`, max 50 | `"Big Burger Bar"` |
| `creditor.phone` | E.164: `^\+[1-9]\d{1,20}$` | `"+12135550006"` |
| `creditor.MCC` | 4 decimal digits: `^\d{4}$` | `"5812"` |
| `bill.amountDue.amount` | uint64 ≥ 0, in **minor units** (cents) | `89` for $0.89 |
| `paymentMethods[].amount` | uint64; USDC = dollars × 1,000,000 | `890000` for $0.89 |
| Timestamps | `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$` | `"2026-03-09T14:30:00.000Z"` |
| UUIDs | 32 hex chars, **no dashes**: `^[0-9a-fA-F]{32}$` | `"a1b2c3d4e5f6...32chars"` |

### Monetary Conversion
```
USD/BRL (cents):   round(dollars × 100)         $0.89 → 89
USDC (6 decimals): round(dollars × 1,000,000)   $0.89 → 890,000
```

### Critical Rules
- **`creditor.name` must be printable ASCII** — mobile keyboards insert curly quotes (`'` U+2019) that fail `^[ -~]*$`. Sanitize before sending.
- **`creditor.phone` must start with `+`** — E.164 format. `"12135550006"` fails; `"+12135550006"` passes.
- **Amounts are non-negative integers in minor units** — never floats.
- **UUIDs have no dashes** — `^[0-9a-fA-F]{32}$`. Standard UUID `xxxxxxxx-xxxx-...` dashes break validation.
- **Timestamps need exactly 3ms digits and Z** — `"2026-03-09T14:30:00.000Z"`.
- **PAID status is set by the payment server based on confirmed fund receipt** — not by the payer's notification. The payer sends PAYMENT_INITIATED and PAID notifications as signals, but the authoritative PAID status comes from the settlement listener verifying actual funds.
- **`protectionType` for banking networks** — exactly `"tokenized"`, `"encrypted"`, or `"plaintext"`. `"clear"` is invalid.

## Topic Files

- `topics/architecture.md` — System components, their roles, and how they interact
- `topics/payload-structure.md` — PaymentRequest schema, field reference, template vs full object
- `topics/field-validation.md` — Validation rules, sanitization patterns, pre-flight checklist
- `topics/networks.md` — Solana, FedNow, RTP, ACH, Zelle, Pix — structure and amount conversion
- `topics/tips-and-adjustments.md` — Tip ranges, presets, adjustments, deferred payments
- `topics/payment-lifecycle.md` — Status states, payer notification flow, settlement verification
- `topics/emvco-qr.md` — EMVCo TLV format, tag reference, CRC-16, URL encoding
- `topics/jws-security.md` — JWS header structure, signing, verification, certificate discovery
- `topics/error-troubleshooting.md` — Common errors, root causes, fixes, debugging workflow
