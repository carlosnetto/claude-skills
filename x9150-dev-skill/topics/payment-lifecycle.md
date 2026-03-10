# Payment Lifecycle

## PaymentRequest Status States

A PaymentRequest moves through a defined set of states from creation to settlement:

```
ACTIVE             ← Created when QR is generated; awaiting scan
    ↓
PAYMENT_INITIATED  ← Payer has confirmed intent; transfer in progress
    ↓
PAID               ← Funds confirmed received by payee (settlement-based, not payer-reported)
    (or)
CANCELLED          ← QR expired, payment timed out, or explicitly cancelled
```

### State Transitions

| Transition | Trigger | Who triggers it |
|---|---|---|
| → ACTIVE | PaymentRequest created | QR Payment Server (on generate) |
| → PAYMENT_INITIATED | PAYMENT_INITIATED notification received | Payer app (via notify endpoint) |
| → PAID | Funds confirmed received | **Settlement Listener** (authoritative) |
| → CANCELLED | QR expiry time exceeded, or explicit cancellation | QR Payment Server (timer or API) |

**Important:** The PAID state is set by the settlement listener after independently confirming that funds arrived in the payee's account or wallet — not by the payer's notification. The payer's PAID notification is a useful signal (it carries the transaction ID), but it is not the authoritative trigger for the PAID state.

---

## Payer Notification Flow

Payer apps send two notifications during a payment. Both are POSTed to the Digital Channel Backend's `/notify` endpoint as plain JSON, which proxies them (as JWS) to the QR Payment Server.

### Notification 1: PAYMENT_INITIATED

Sent immediately when the user taps "Confirm" — before the blockchain or bank transfer is submitted.

```json
{
  "paymentRequestId": "a1b2c3d4e5f6789012345678901234ab",
  "status": "PAYMENT_INITIATED",
  "paymentDetails": {
    "amount": { "amount": 890000, "currency": "USDC" },
    "tipAmount": { "amount": 133500, "currency": "USDC" },
    "network": "Solana",
    "transactionId": null
  }
}
```

### Notification 2: PAID

Sent after the transfer is submitted (and ideally confirmed). Includes the transaction ID.

```json
{
  "paymentRequestId": "a1b2c3d4e5f6789012345678901234ab",
  "status": "PAID",
  "paymentDetails": {
    "amount": { "amount": 890000, "currency": "USDC" },
    "tipAmount": { "amount": 133500, "currency": "USDC" },
    "network": "Solana",
    "transactionId": "5KtCqtQ3...base58signature"
  }
}
```

### NotificationPayload Fields

| Field | Type | Notes |
|---|---|---|
| `paymentRequestId` | string | 32 hex chars, no dashes — matches the PaymentRequest `id` |
| `status` | enum | `"PAYMENT_INITIATED"` or `"PAID"` |
| `paymentDetails.amount` | MonetaryAmount | Actual amount transferred (post-tip) |
| `paymentDetails.tipAmount` | MonetaryAmount | Tip amount separately (0 if no tip) |
| `paymentDetails.network` | string | `"Solana"`, `"FedNow"`, `"RTP"`, etc. |
| `paymentDetails.transactionId` | string\|null | Blockchain tx hash or bank reference; null for PAYMENT_INITIATED |
| `payer` | object | Optional: payer name, phone, email |

---

## Settlement Verification (Authoritative PAID)

The settlement listener independently verifies payment for each network:

### Solana / EVM

Monitor the payee's wallet address for incoming token transfers:

1. Subscribe to or poll the wallet's transaction history
2. Find transfers matching the expected token (USDC), amount, and time window
3. Confirm the transaction has sufficient confirmations
4. Match to a PaymentRequest by correlating amount + payer notification's `transactionId`
5. Mark PaymentRequest as PAID

### FedNow / RTP

1. Receive credit notification from the bank's real-time payment integration (webhook or polling)
2. Match incoming credit to a PaymentRequest by amount, reference, or end-to-end ID
3. Mark PaymentRequest as PAID

### ACH

ACH settles in batches (T+1 or T+2):

1. Receive settlement confirmation from the bank
2. Match to PaymentRequest
3. Mark PaymentRequest as PAID

**Settlement timing matters:** For immediate payment methods (Solana, FedNow, RTP), the PAID transition can happen within seconds of the transfer. For ACH, it takes 1–2 business days. The PaymentRequest may stay in PAYMENT_INITIATED state until settlement completes.

---

## Notification Amount Calculation

Amounts in notifications use the same currency and minor-unit convention as `paymentMethods`:

```
Total paid = base amount + tip (both in minor units)

Example: $0.89 USDC base + 15% tip
  tipAmount  = round(0.89 × 0.15 × 1,000,000) = 133,500
  baseAmount = 890,000
  total sent to chain = 890,000 + 133,500 = 1,023,500 USDC atomic units
  (but report them separately in the notification)
```

---

## QR Expiry

PaymentRequests are generated with an expiry time (`timestamps.expires`). The QR code is only valid for scanning within this window. After expiry:

- The QR Payment Server returns 404 or a CANCELLED status for `/fetch` requests on expired IDs
- The Digital Channel Backend should communicate the expiry to payer apps clearly

Typical expiry: 15 minutes for in-person merchant QR codes. Configurable for use cases like invoices or recurring payment links.

---

## Polling for Status (Optional)

Payer apps can poll the fetch endpoint to check if a PaymentRequest has been marked PAID (by the settlement listener) after sending their notification:

```
Payer: POST /fetch { qrCodeContent }
  → if response.status === "PAID": payment confirmed ✓
  → if response.status === "PAYMENT_INITIATED": still waiting for settlement
  → if response.status === "CANCELLED": payment expired
```

This allows payer apps to show a real-time "waiting for confirmation" state rather than trusting their own notification as the final word.
