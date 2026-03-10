# System Architecture

## Overview

X9.150 defines a set of interacting components for issuing, serving, and settling QR-code-based payments. Implementors choose which components to build based on their role. The components are logically separated — they can run as microservices, monoliths, or serverless functions.

```
┌──────────────────────────────────────┐
│        Merchant App / Payer App       │  Mobile or web — plain JSON, no JWS
└──────────────┬───────────────────────┘
               │ plain JSON
               ▼
┌──────────────────────────────────────┐
│      Digital Channel Backend          │  App-facing gateway
│  - QR generation endpoint            │  Handles JWS signing/verification
│  - Fetch endpoint (proxy)            │  internally — apps never touch JWS
│  - Notify endpoint (proxy)           │
└──────────────┬───────────────────────┘
               │ JWS-signed messages
               ▼
┌──────────────────────────────────────┐
│        QR Payment Server              │  Core payment logic
│  - Stores PaymentRequests            │
│  - Serves them (responds to /fetch)  │
│  - Receives notifications            │
│  - Manages PaymentRequest status     │
└──────┬───────────────┬───────────────┘
       │               │
       ▼               ▼
┌─────────────┐  ┌──────────────────────┐
│  Certificate │  │  Settlement Listener  │
│   Server     │  │  (FedNow, Solana,    │
│  (optional)  │  │   RTP, ACH, ...)     │
└─────────────┘  └──────────────────────┘
```

---

## Component Roles

### Digital Channel Backend

The bridge between apps (mobile/web) and the X9.150 payment infrastructure.

**Responsibilities:**
- Exposes simple JSON endpoints to apps — no JWS, no cryptography on the app side
- Handles all JWS signing and verification internally
- Calls `qr_generator` logic to build the EMVCo TLV string and PaymentRequest document
- Proxies fetch requests to the QR Payment Server (signs request, verifies response)
- Proxies notify requests to the QR Payment Server

**Key endpoints exposed to apps:**
| Endpoint | Input | Output |
|---|---|---|
| `POST /generate` | PaymentRequest template (JSON) | `{ qrContent, paymentRequestId }` |
| `POST /fetch` | `{ qrCodeContent }` | PaymentRequest (JSON) |
| `POST /notify` | NotificationPayload (JSON) | `{ statusCode: 200 }` |

**Design note:** The digital channel backend manages its own payer identity (key pair + certificate) used to sign outbound JWS messages to the QR Payment Server. This identity is the "app's voice" in the X9.150 trust chain.

---

### QR Payment Server

The authoritative backend for payment requests.

**Responsibilities:**
1. **QR generation** — receives templates, validates them against the OpenAPI spec, assigns UUIDs, builds the PaymentRequest document, generates the EMVCo TLV QR string, stores it
2. **Payment request retrieval** — serves the PaymentRequest document referenced by the URL in EMVCo Tag 26 Subtag 01; verifies the payer's JWS fetch request and returns a signed response
3. **Notification handling** — receives PAYMENT_INITIATED and PAID notifications from payer apps; updates PaymentRequest status accordingly
4. **Settlement verification** — the QR Payment Server (or a tightly integrated settlement listener) marks a PaymentRequest as truly PAID only after confirming that funds have arrived in the payee's account through the relevant network (FedNow credit, Solana tx confirmed, etc.) — not solely based on the payer's PAID notification

**Key internal endpoints (called by Digital Channel Backend via JWS):**
| Endpoint | Purpose |
|---|---|
| `POST /fetch/{id}` | Return signed PaymentRequest for given UUID |
| `POST /notify/{id}` | Receive payment notification |

---

### Certificate Server (Optional)

Serves public keys and certificates so that JWS recipients can verify signatures.

**Responsibilities:**
- Hosts JWKS (JSON Web Key Sets) files for payee and payer identities
- Serves PEM certificates when requested by `jku` URL in JWS headers
- Referenced via the `jku` header field in JWS messages

**When not needed:** If every JWS message includes the certificate chain embedded in the `x5c` header field, no external cert lookup is required and this server can be omitted.

---

### Settlement Listener

The component responsible for authoritative payment confirmation.

**Responsibilities:**
- Monitors the payment network (FedNow, RTP, ACH, Solana, etc.) for incoming funds to the payee's account/address
- When funds are confirmed received, marks the corresponding PaymentRequest as PAID
- Correlates incoming payments to PaymentRequests using transaction IDs, amounts, and network-specific identifiers

**Why this matters:** The payer's PAID notification is a signal of intent, not proof of receipt. Funds could fail to settle for many reasons (insufficient balance discovered on-chain, FedNow rejection, etc.). The payment is only definitively PAID when the payee's bank or blockchain confirms the credit.

**Implementation varies by network:**
- **Solana/EVM:** Monitor the wallet address for confirmed USDC transfers matching the amount and correlating with the expected payer
- **FedNow/RTP:** Receive credit notifications from the bank's real-time payment integration
- **ACH:** Receive settlement confirmation from the bank (T+1 or T+2)

---

## Interaction Patterns

### Generating a QR Code (Merchant Flow)

```
Merchant App → Digital Channel Backend: POST /generate (template JSON)
Digital Channel Backend:
  → validates template
  → assigns UUID (32 hex, no dashes)
  → builds PaymentRequest document
  → generates EMVCo TLV string with fetch URL in Tag 26.01
  → stores PaymentRequest in QR Payment Server
  → returns { qrContent, paymentRequestId }
Merchant App: displays QR code to customer
```

### Scanning and Paying (Payer Flow)

```
Payer App: scans QR → extracts fetch URL from Tag 26.01
Payer App → Digital Channel Backend: POST /fetch { qrCodeContent }
Digital Channel Backend → QR Payment Server: POST /fetch/{id} (signed JWS)
QR Payment Server: verifies JWS, returns signed PaymentRequest
Digital Channel Backend: verifies response JWS, returns plain JSON
Payer App: displays bill, tip options — user confirms

Payer App → Digital Channel Backend: POST /notify (PAYMENT_INITIATED)
  → QR Payment Server updates status to PAYMENT_INITIATED

Payer App: executes blockchain/bank transfer
Payer App → Digital Channel Backend: POST /notify (PAID + transactionId)
  → QR Payment Server records notification

Settlement Listener: independently confirms funds received
  → QR Payment Server marks PaymentRequest as definitively PAID
```

---

## Minimum Viable Implementation

To accept X9.150 payments, a merchant needs at minimum:

1. **Digital Channel Backend** with `/generate`, `/fetch`, `/notify` endpoints
2. **PaymentRequest storage** (can be as simple as a database table or JSON files)
3. **JWS signing capability** for the backend's payer identity
4. **Settlement listener** for at least one payment network

The certificate server is optional if `x5c` is embedded in every JWS header.
