# Payment Notification Flow

## Overview

After the payer completes payment, the app sends **two** notifications to `qr_appserver /notify`:

1. **PAYMENT_INITIATED** — immediately when the user confirms they will pay (before blockchain tx)
2. **PAID** — after the blockchain transaction confirms, with the transaction ID

Both are POSTed as plain JSON to `/notify`. The proxy signs them as JWS and forwards to `qr_server /notify/{id}`.

## NotificationPayload Schema

```json
{
  "paymentRequestId": "a1b2c3d4e5f6...",
  "status": "PAYMENT_INITIATED",
  "paymentDetails": {
    "amount": {
      "amount": 890000,
      "currency": "USDC"
    },
    "tipAmount": {
      "amount": 133500,
      "currency": "USDC"
    },
    "network": "Solana",
    "transactionId": null
  },
  "payer": {
    "name": "John Smith",
    "phone": "+14155551234",
    "email": "john@example.com"
  }
}
```

## Notification 1: PAYMENT_INITIATED

Sent immediately when the payer taps "Confirm" — before any blockchain transaction is attempted.

```json
{
  "paymentRequestId": "a1b2c3d4e5f6...",
  "status": "PAYMENT_INITIATED",
  "paymentDetails": {
    "amount": { "amount": 890000, "currency": "USDC" },
    "tipAmount": { "amount": 0, "currency": "USDC" },
    "network": "Solana",
    "transactionId": null
  }
}
```

`transactionId` is `null` at this stage — the tx hasn't been submitted yet.

## Notification 2: PAID

Sent after the blockchain transaction confirms successfully.

```json
{
  "paymentRequestId": "a1b2c3d4e5f6...",
  "status": "PAID",
  "paymentDetails": {
    "amount": { "amount": 890000, "currency": "USDC" },
    "tipAmount": { "amount": 133500, "currency": "USDC" },
    "network": "Solana",
    "transactionId": "5KtCqtQ3...base58sig"
  }
}
```

## Field Reference

| Field | Notes |
|---|---|
| `paymentRequestId` | The `id` from the PaymentRequest (32 hex chars, no dashes) |
| `status` | `"PAYMENT_INITIATED"` or `"PAID"` |
| `paymentDetails.amount` | Actual amount paid (may differ from requested if tip or editable range) |
| `paymentDetails.tipAmount` | Tip amount in same currency (0 if no tip) |
| `paymentDetails.network` | Network used: `"Solana"`, `"FedNow"`, `"RTP"`, etc. |
| `paymentDetails.transactionId` | Blockchain tx signature or bank reference. `null` for PAYMENT_INITIATED |
| `payer` | Optional payer identity (name, phone, email) |

## Amounts in Notifications

Notification amounts use the same unit as the paymentMethod that was used:

```
USDC paid:  amount = round(total_dollars * 1_000_000)
USD paid:   amount = round(total_dollars * 100)
```

Total = base amount + tip:
```typescript
const totalUsdc = baseAmountUsdc + tipAmountUsdc;
// $0.89 base + 15% tip = $0.89 + $0.13 = $1.02
// baseAmountUsdc = 890000, tipAmountUsdc = 133500
// total = 1023500 (but notify separately)
```

## TypeScript Implementation Pattern

```typescript
const sendNotification = async (
  paymentRequestId: string,
  status: 'PAYMENT_INITIATED' | 'PAID',
  amountUsdc: number,
  tipUsdc: number,
  transactionId: string | null
) => {
  const payload = {
    paymentRequestId,
    status,
    paymentDetails: {
      amount: { amount: amountUsdc, currency: 'USDC' },
      tipAmount: { amount: tipUsdc, currency: 'USDC' },
      network: 'Solana',
      transactionId,
    },
  };

  const response = await fetch(`${QRAPPSERVER_URL}/notify`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`Notify failed: ${response.status}`);
  }
};

// Usage:
await sendNotification(id, 'PAYMENT_INITIATED', 890000, 133500, null);
// ... execute blockchain tx ...
await sendNotification(id, 'PAID', 890000, 133500, txSignature);
```

## Python Implementation (from qr_payer.py)

```python
def send_notification(payload_id, status, amount, currency, network, transaction_id=None):
    notification = {
        "paymentRequestId": payload_id,
        "status": status,
        "paymentDetails": {
            "amount": {"amount": amount, "currency": currency},
            "network": network,
            "transactionId": transaction_id,
        }
    }
    response = requests.post(
        f"{APPSERVER_URL}/notify",
        json=notification,
        headers={"Content-Type": "application/json"}
    )
    response.raise_for_status()
    return response.json()

# Send PAYMENT_INITIATED
send_notification(payload_id, "PAYMENT_INITIATED", usdc_amount, "USDC", "Solana")

# After blockchain tx:
send_notification(payload_id, "PAID", usdc_amount, "USDC", "Solana",
                  transaction_id=tx_signature)
```

## PaymentRequest Status Lifecycle

```
ACTIVE             ← Initial state when QR is generated
  ↓
PAYMENT_INITIATED  ← After first notification
  ↓
PAID               ← After second notification with transactionId
  (or)
CANCELLED          ← If payment times out or is cancelled
```

The `qr_server` transitions the PaymentRequest status based on incoming notifications. The payer app can poll `/fetch` to check status changes.
