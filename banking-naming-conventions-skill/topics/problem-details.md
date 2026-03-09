# Problem Details — API Error Responses (RFC 9457 / RFC 7807)

## The Problem

Banking APIs return errors in dozens of ad-hoc formats — `{ "error": "bad request" }`, `{ "code": 400, "message": "..." }`, `{ "errors": [...] }` — making it impossible for clients to handle failures consistently. Every integration requires custom error parsing.

RFC 9457 (which obsoletes RFC 7807) defines a single, standard JSON format for API error responses: **Problem Details**. It is the required error envelope for banking APIs.

## The Standard Fields

A Problem Details object has five standard members. All are optional, but `type` and `status` should always be provided:

| Field | Type | Description |
|---|---|---|
| `type` | `string` (URI) | Identifies the problem category. Defaults to `"about:blank"`. Should resolve to human-readable docs. |
| `title` | `string` | Short, human-readable summary of the problem **type** (not the occurrence). Stable across occurrences. |
| `status` | `number` | HTTP status code. Advisory — must match the actual HTTP response status. |
| `detail` | `string` | Human-readable explanation specific to **this occurrence**. Focus on helping the client correct the problem. |
| `instance` | `string` (URI) | Identifies this specific occurrence. Useful for support tickets and log correlation. |

```typescript
interface ProblemDetails {
  type: string;               // URI — problem category
  title: string;              // stable summary of the type
  status: number;             // HTTP status code
  detail?: string;            // occurrence-specific explanation
  instance?: string;          // URI identifying this occurrence
  [extension: string]: unknown; // domain-specific extensions
}
```

## Content Type

Always use the registered media type:

```
Content-Type: application/problem+json
```

Clients detect a Problem Details response by checking this content type, not by inspecting the body structure.

## URI Design — ISO Codes in the `type` Path

Embed the ISO standard and reason code directly in the `type` URI. This makes the problem type machine-routable without parsing extensions:

```
https://api.{bank}.com/problems/{standard}/{code}
```

| Standard | URI Pattern | Example |
|---|---|---|
| ISO 20022 | `.../problems/iso20022/{code}` | `.../problems/iso20022/AC04` |
| ISO 8583 | `.../problems/iso8583/{code}` | `.../problems/iso8583/51` |
| Internal | `.../problems/{error-name}` | `.../problems/validation-error` |

### Client Routing

Clients can match at three levels of specificity:

```typescript
const type = problem.type;

// 1. Exact code match
if (type.endsWith('/iso20022/AC04')) {
  // handle closed account specifically
}

// 2. Category match (ISO 20022 prefix = first two letters)
if (type.match(/\/iso20022\/AC/)) {
  // handle any account-related error
}

// 3. Standard match
if (type.includes('/iso20022/')) {
  // handle any ISO 20022 payment error
} else if (type.includes('/iso8583/')) {
  // handle any card transaction error
}
```

### Hosting Documentation

Each `type` URI should dereference to a human-readable page. Host a docs site that maps codes to descriptions:

```
GET https://api.bank.com/problems/iso20022/AC04
Accept: text/html

→ "AC04 — Closed Account Number. The account specified has been
   closed on the bank of account's books. Not retryable."
```

## Payment Error Examples (ISO 20022)

### Closed Account (AC04) — Reject

```json
{
  "type": "https://api.bank.com/problems/iso20022/AC04",
  "title": "Closed account number.",
  "status": 422,
  "detail": "The creditor's account 67890 has been closed.",
  "instance": "/payments/pay-456",
  "reasonCode": "AC04",
  "failureType": "reject",
  "retryable": false,
  "transactionId": "pay-456"
}
```

### Insufficient Funds (AM04) — Reject

```json
{
  "type": "https://api.bank.com/problems/iso20022/AM04",
  "title": "Insufficient funds.",
  "status": 422,
  "detail": "Account 12345 has insufficient funds. Available: 30.00 USD, required: 50.00 USD.",
  "instance": "/payments/pay-789",
  "reasonCode": "AM04",
  "failureType": "reject",
  "retryable": true,
  "accountId": "12345",
  "availableBalance": 3000,
  "requiredAmount": 5000,
  "currency": "USD",
  "transactionId": "pay-789"
}
```

### Blocked Account (AC06) — Return

```json
{
  "type": "https://api.bank.com/problems/iso20022/AC06",
  "title": "Blocked account.",
  "status": 422,
  "detail": "Account 67890 is blocked due to a compliance hold.",
  "instance": "/payments/pay-101",
  "reasonCode": "AC06",
  "failureType": "return",
  "retryable": false,
  "accountId": "67890",
  "accountStatus": "frozen",
  "transactionId": "pay-101"
}
```

### Regulatory Rejection (RR04)

```json
{
  "type": "https://api.bank.com/problems/iso20022/RR04",
  "title": "Regulatory reason.",
  "status": 422,
  "detail": "Payment rejected for regulatory compliance. Contact support for details.",
  "instance": "/payments/pay-202",
  "reasonCode": "RR04",
  "failureType": "reject",
  "retryable": false,
  "transactionId": "pay-202"
}
```

### Timeout at Creditor Agent (AB05) — System Error

```json
{
  "type": "https://api.bank.com/problems/iso20022/AB05",
  "title": "Timeout at creditor agent.",
  "status": 504,
  "detail": "The creditor's bank did not respond within the processing window.",
  "instance": "/payments/pay-303",
  "reasonCode": "AB05",
  "failureType": "reject",
  "retryable": true,
  "retryAfter": 60,
  "transactionId": "pay-303"
}
```

## Card Error Examples (ISO 8583)

### Insufficient Funds (51) — Soft Decline

```json
{
  "type": "https://api.bank.com/problems/iso8583/51",
  "title": "Insufficient funds.",
  "status": 422,
  "detail": "The card issuer declined the transaction due to insufficient funds.",
  "instance": "/card-payments/cp-456",
  "responseCode": "51",
  "declineCategory": "soft_decline",
  "retryable": true,
  "transactionId": "cp-456"
}
```

### Expired Card (54) — Hard Decline

```json
{
  "type": "https://api.bank.com/problems/iso8583/54",
  "title": "Expired card.",
  "status": 422,
  "detail": "The card has expired. Please use a different card.",
  "instance": "/card-payments/cp-789",
  "responseCode": "54",
  "declineCategory": "hard_decline",
  "retryable": false,
  "transactionId": "cp-789"
}
```

### Issuer Inoperative (91) — System Error

```json
{
  "type": "https://api.bank.com/problems/iso8583/91",
  "title": "Issuer or switch inoperative.",
  "status": 504,
  "detail": "The card issuer's system is temporarily unavailable.",
  "instance": "/card-payments/cp-101",
  "responseCode": "91",
  "declineCategory": "system_error",
  "retryable": true,
  "retryAfter": 30,
  "transactionId": "cp-101"
}
```

## Internal API Error Examples

For errors not originating from ISO standards, use descriptive path names:

### Validation Error

```json
{
  "type": "https://api.bank.com/problems/validation-error",
  "title": "Request validation failed.",
  "status": 400,
  "detail": "2 fields failed validation.",
  "errors": [
    {
      "field": "destinationAccountId",
      "reason": "Account number format is invalid.",
      "pointer": "/destinationAccountId"
    },
    {
      "field": "amount",
      "reason": "Amount must be greater than zero.",
      "pointer": "/amount"
    }
  ]
}
```

### Rate Limited

```json
{
  "type": "https://api.bank.com/problems/rate-limited",
  "title": "Too many requests.",
  "status": 429,
  "detail": "Rate limit of 100 requests per minute exceeded.",
  "retryAfter": 12
}
```

## Extension Members

### Payment Extensions (ISO 20022)

| Extension | Type | Description |
|---|---|---|
| `reasonCode` | `string` | The ISO 20022 code (`AC04`, `AM04`). Redundant with `type` URI but useful for parsing. |
| `failureType` | `string` | `"reject"` (never settled) or `"return"` (settled then sent back) |
| `retryable` | `boolean` | Whether the client should retry |
| `retryAfter` | `number` | Seconds to wait before retrying |
| `transactionId` | `string` | The payment that failed |
| `accountId` | `string` | The account involved |
| `availableBalance` | `number` | Current balance in minor units |
| `requiredAmount` | `number` | Amount needed in minor units |
| `currency` | `string` | ISO 4217 code |

### Card Extensions (ISO 8583)

| Extension | Type | Description |
|---|---|---|
| `responseCode` | `string` | The ISO 8583 DE 39 code (`51`, `54`). Redundant with `type` URI. |
| `declineCategory` | `string` | `"soft_decline"`, `"hard_decline"`, or `"system_error"` |
| `retryable` | `boolean` | Whether the client should retry |
| `retryAfter` | `number` | Seconds to wait before retrying |
| `transactionId` | `string` | The card payment that failed |

### Extension Naming Rules

Extension member names must:
- Start with a letter
- Contain only letters, digits, and underscores
- Be three or more characters long

```
GOOD: reasonCode, failureType, availableBalance
BAD:  rc, type, bal (too short, reserved, or ambiguous)
```

## The Pattern: Building Problem Details from ISO Codes

### ISO 20022 Payments

```typescript
import { ISO20022_CODES } from './iso20022-codes'; // code → title mapping

function toPaymentProblem(
  reasonCode: string,
  failureType: 'reject' | 'return',
  transactionId: string,
  extensions?: Record<string, unknown>,
): ProblemDetails {
  const codeInfo = ISO20022_CODES[reasonCode];
  const retryable = ['AM04', 'AB01', 'AB02', 'AB05', 'TM01', 'ED05'].includes(reasonCode);
  const status = retryable ? 504 : 422;

  return {
    type: `https://api.bank.com/problems/iso20022/${reasonCode}`,
    title: codeInfo?.title ?? 'Payment failed.',
    status,
    detail: codeInfo?.detail ?? `Reason: ${reasonCode}.`,
    instance: `/payments/${transactionId}`,
    reasonCode,
    failureType,
    retryable,
    transactionId,
    ...extensions,
  };
}
```

### ISO 8583 Card Payments

```typescript
import { ISO8583_CODES, HARD_DECLINE_CODES, SYSTEM_ERROR_CODES } from './iso8583-codes';

function toCardProblem(
  responseCode: string,
  transactionId: string,
  extensions?: Record<string, unknown>,
): ProblemDetails {
  const codeInfo = ISO8583_CODES[responseCode];
  const declineCategory = HARD_DECLINE_CODES.has(responseCode) ? 'hard_decline'
    : SYSTEM_ERROR_CODES.has(responseCode) ? 'system_error'
    : 'soft_decline';
  const retryable = declineCategory !== 'hard_decline';
  const status = declineCategory === 'system_error' ? 504 : 422;

  return {
    type: `https://api.bank.com/problems/iso8583/${responseCode}`,
    title: codeInfo?.title ?? 'Card payment failed.',
    status,
    detail: codeInfo?.detail ?? `Response code: ${responseCode}.`,
    instance: `/card-payments/${transactionId}`,
    responseCode,
    declineCategory,
    retryable,
    transactionId,
    ...extensions,
  };
}
```

## HTTP Status Code Mapping

Map ISO failure types to appropriate HTTP status codes:

| Scenario | HTTP Status | When |
|---|---|---|
| `422` | Unprocessable Content | Business rule failure (closed account, insufficient funds, invalid data) |
| `504` | Gateway Timeout | Upstream timeout (AB01, AB05, ISO 8583 `91`) |
| `409` | Conflict | Duplicate payment (AM05, DUPL) |
| `403` | Forbidden | Blocked/frozen account (AC06), stopped payment (SP01) |
| `400` | Bad Request | Format/validation errors (AC01, FF03, RC01) |
| `429` | Too Many Requests | Rate limiting (internal) |

```typescript
function mapIso20022ToHttpStatus(code: string): number {
  if (['AB01', 'AB02', 'AB05', 'TM01', 'ED05'].includes(code)) return 504;
  if (['AM05', 'DUPL'].includes(code)) return 409;
  if (['AC06', 'SP01', 'SP02', 'AG01'].includes(code)) return 403;
  if (['AC01', 'AC02', 'AC03', 'RC01', 'FF03'].includes(code)) return 400;
  return 422; // default: business rule failure
}
```

## RFC 9457 vs RFC 7807

RFC 9457 obsoletes RFC 7807. The JSON structure is **backward-compatible** — existing RFC 7807 responses are valid RFC 9457 responses. Key additions in 9457:

| Feature | RFC 7807 | RFC 9457 |
|---|---|---|
| Problem Type Registry | No | Yes — shared registry of common types |
| Multiple Problems | Undefined | Guidance on representing multiple problems |
| Non-resolvable URIs | Unclear | Explicit guidance for non-dereferenceable `type` URIs |

Always reference **RFC 9457** in new implementations. Accept both in clients.

## Pitfalls

- **Don't invent a custom error format** — use `application/problem+json`. It's an IETF standard with broad library support.
- **Don't put debugging info in `detail`** — no stack traces, no SQL errors, no internal paths. The `detail` field is for the API consumer, not the developer.
- **Don't parse `detail` programmatically** — the spec explicitly says consumers must not parse `detail` for structured data. Use extension members for machine-readable fields.
- **Don't use `type: "about:blank"` for all errors** — define specific problem type URIs per ISO code or error category.
- **Don't forget `Content-Type: application/problem+json`** — without it, clients can't distinguish a Problem Details response from a regular JSON response.
- **Don't omit `status`** — even though it's advisory, it's essential when the response body is stored or forwarded without HTTP headers.
- **Don't mix ISO 20022 and ISO 8583 in the same `type` namespace** — use `/iso20022/{code}` and `/iso8583/{code}` to keep them separate. They are different standards for different domains.
- **Don't forget `retryable`** — clients need this to decide whether to retry. It's the most important extension for payment errors.
- **Don't return `200 OK` with a Problem Details body** — the HTTP status must reflect the error. Problem Details is for error responses only.
