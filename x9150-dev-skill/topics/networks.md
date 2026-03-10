# Payment Networks Configuration

## Supported Networks

X9.150 supports both emerging (crypto) and traditional payment networks in the same PaymentRequest. The payer's wallet picks the network it supports.

| Network | Currency | Type | Key Fields |
|---|---|---|---|
| `Solana` | USDC | Crypto | `address` |
| `FedNow` | USD | Traditional instant | `routingNumber`, `accountNumber`, `protectionType` |
| `RTP` | USD | Traditional instant | `routingNumber`, `accountNumber`, `protectionType` |
| `ACH` | USD | Traditional batch | `routingNumber`, `accountNumber`, `protectionType` |
| `Zelle` | USD | P2P | `key`, `keyType` |
| `Pix` | BRL | Brazilian instant | `key`, `keyType` |
| `EVM` | USDC/WETH | Ethereum-compatible | `address` |

---

## Solana (USDC)

```json
{
  "currency": "USDC",
  "amount": 890000,
  "networks": {
    "Solana": {
      "address": "<merchant_solana_pubkey>"
    }
  }
}
```

### Amount: USDC has 6 decimal places

```
1 USDC = 1,000,000 atomic units

$0.89  → 890,000
$1.75  → 1,750,000
$12.50 → 12,500,000
```

```python
amount_usdc = round(float(dollars) * 1_000_000)
```

```typescript
const amountUsdc = Math.round(parseFloat(dollars) * 1_000_000);
```

This is NOT the same as USD cents (×100). Factor between cents and USDC units is 10,000.

### Solana constants
```
RPC:       https://solana-rpc.publicnode.com  (CORS-friendly, no Origin header 403)
USDC Mint: EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v
Decimals:  6
Derivation Path: m/44'/501'/0'/0'
```

---

## FedNow and RTP (USD Instant Payments)

```json
{
  "currency": "USD",
  "amount": 89,
  "networks": {
    "FedNow": {
      "routingNumber": "021000021",
      "accountNumber": "4111111111111111",
      "protectionType": "tokenized"
    },
    "RTP": {
      "routingNumber": "021000021",
      "accountNumber": "4111111111111111",
      "protectionType": "tokenized"
    }
  }
}
```

### protectionType values

| Value | Meaning | Use |
|---|---|---|
| `"tokenized"` | Network-issued token (replaces account number) | Production |
| `"encrypted"` | Encrypted with payer's public key | Production |
| `"plaintext"` | Raw account number in clear | Test environments only |

**`"clear"` is NOT a valid value** — causes 500 error. Use `"plaintext"` for tests.

### Amount: USD in cents

```
$0.89 → 89
$1.75 → 175
```

---

## ACH (USD Batch Payments)

ACH is typically used for `deferred` payments (invoices with due dates). Structure is identical to FedNow/RTP:

```json
"ACH": {
  "routingNumber": "021000021",
  "accountNumber": "4111111111111111",
  "protectionType": "tokenized"
}
```

For deferred bills, include all three networks:
```json
"networks": {
  "FedNow": { ... },
  "RTP":    { ... },
  "ACH":    { ... }
}
```

---

## Zelle (USD P2P)

```json
{
  "currency": "USD",
  "amount": 89,
  "networks": {
    "Zelle": {
      "key": "+12135550001",
      "keyType": "phone"
    }
  }
}
```

`keyType` values: `"phone"` or `"email"`

---

## Pix (BRL — Brazilian Instant Payments)

```json
{
  "currency": "BRL",
  "amount": 450,
  "networks": {
    "Pix": {
      "key": "merchant@example.com.br",
      "keyType": "email"
    }
  }
}
```

`keyType` values: `"email"`, `"phone"`, `"cpf"`, `"uuid"`

BRL amount is in **centavos** (×100): R$4.50 = 450

---

## EVM (Ethereum-Compatible Chains)

```json
{
  "currency": "USDC",
  "amount": 890000,
  "networks": {
    "EVM": {
      "address": "0x742d35Cc6634C0532925a3b8D4C9C1E2F6B4e5f6"
    }
  }
}
```

For WETH-V2:
```json
{
  "currency": "WETH-V2",
  "amount": 890000,
  "networks": {
    "WETH-V2": {
      "address": "0x..."
    }
  }
}
```

---

## Multiple Networks in One PaymentRequest

Offer multiple payment methods — the payer's wallet picks the one it supports:

```json
"paymentMethods": [
  {
    "currency": "USDC",
    "amount": 890000,
    "networks": {
      "Solana": { "address": "<pubkey>" }
    }
  },
  {
    "currency": "USD",
    "amount": 89,
    "networks": {
      "FedNow": { "routingNumber": "...", "accountNumber": "...", "protectionType": "tokenized" },
      "RTP":    { "routingNumber": "...", "accountNumber": "...", "protectionType": "tokenized" }
    }
  },
  {
    "currency": "BRL",
    "amount": 450,
    "networks": {
      "Pix": { "key": "merchant@email.com", "keyType": "email" }
    }
  }
]
```

---

## Editable Payment Range (Optional)

Allow the payer to adjust the payment amount — useful for partial payments or tip-inclusive flows:

```json
{
  "currency": "USDC",
  "amount": 890000,
  "editablePaymentDetails": {
    "range": {
      "min": { "amount": 100000, "currency": "USDC" },
      "max": { "amount": 890000, "currency": "USDC" }
    }
  },
  "networks": {
    "Solana": { "address": "<pubkey>" }
  }
}
```

---

## Amount Conversion Quick Reference

| Currency | Unit | $1.00 | $0.89 |
|---|---|---|---|
| USD (FedNow/RTP/ACH) | cents | 100 | 89 |
| BRL (Pix) | centavos | 100 | 89 |
| USDC (Solana/EVM) | atomic (6 dec) | 1,000,000 | 890,000 |
| ETH / WETH | wei (18 dec) | 10^18 | ~8.9×10^17 |
