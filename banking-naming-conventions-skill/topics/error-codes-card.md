# Error Codes — Card Transactions (ISO 8583)

## The Problem

Card transaction responses use ISO 8583 **Data Element 39 (DE 39)** — a two-digit numeric code that indicates approval, decline, or system error. Codebases that treat these as opaque strings or map them inconsistently lose the ability to distinguish retryable soft declines from permanent hard declines, leading to lost revenue or repeated futile retries.

## Code Structure

ISO 8583 DE 39 codes are **two-digit numeric strings** (not integers). Always store and compare as strings:

```typescript
interface CardAuthResponse {
  responseCode: string;        // ISO 8583 DE 39: "00", "05", "51", etc.
  responseText: string;        // human-readable description
  isApproved: boolean;         // responseCode === '00' (or '08', '10', '11')
  declineCategory?: DeclineCategory;
}

type DeclineCategory =
  | 'soft_decline'             // temporary — may succeed on retry
  | 'hard_decline'             // permanent — do NOT retry
  | 'system_error';            // infrastructure — retry after delay
```

## Response Code Reference

### Approved

| Code | Description | Notes |
|---|---|---|
| `00` | Approved | Transaction completed successfully |
| `08` | Honor with identification | Approved with ID verification |
| `10` | Partial amount approved | Only part of the amount was authorized |
| `11` | Approved (VIP) | Approved for VIP customer |

### Soft Declines (retryable)

| Code | Description | Notes |
|---|---|---|
| `01` | Refer to card issuer | Issuer wants voice authorization |
| `02` | Refer to issuer's special conditions | Similar to 01 |
| `05` | Do not honor | Generic decline — most common code |
| `19` | Re-enter transaction | Input error, try again |
| `51` | Insufficient funds | Balance too low — retryable later |
| `61` | Exceeds withdrawal amount limit | Daily limit reached |
| `65` | Exceeds withdrawal frequency limit | Too many transactions |

### Hard Declines (DO NOT retry)

| Code | Description | Notes |
|---|---|---|
| `04` | Pick up card (no fraud) | Card should be confiscated |
| `07` | Pick up card (fraud) | Suspected stolen card |
| `12` | Invalid transaction | Transaction type not supported |
| `14` | Invalid card number | PAN does not exist |
| `15` | No such issuer | Issuer not found in network |
| `33` | Expired card — pick up | Card expired, confiscate |
| `34` | Suspected fraud — pick up | Fraud detected, confiscate |
| `41` | Lost card — pick up | Reported lost |
| `43` | Stolen card — pick up | Reported stolen |
| `54` | Expired card | Card past expiration date |
| `57` | Transaction not permitted to cardholder | Restricted card/transaction type |
| `R0` | Stop payment order | Account holder revoked authorization |
| `R1` | Revocation of authorization order | Specific authorization revoked |
| `R3` | Revocation of all authorizations | All standing authorizations revoked |

### System / Network Errors (retry after delay)

| Code | Description | Notes |
|---|---|---|
| `06` | Error | Generic processing error |
| `09` | Request in progress | Transaction still being processed |
| `50` | Host down | Issuer system unavailable |
| `68` | Response received too late | Timeout at issuer |
| `91` | Issuer or switch inoperative | Network/issuer offline |
| `92` | Financial institution not found | Routing failure |
| `96` | System malfunction | Generic system error |

### Other Common Codes

| Code | Description | Notes |
|---|---|---|
| `03` | Invalid merchant ID | Merchant not recognized |
| `13` | Invalid amount | Amount format/value incorrect |
| `17` | Customer cancellation | Cardholder cancelled |
| `38` | Allowable PIN tries exceeded | Too many wrong PIN attempts |
| `46` | Closed account | Card account is closed |
| `55` | Incorrect PIN | Wrong PIN entered |
| `59` | Suspected fraud | Fraud suspicion but no pick-up |
| `62` | Restricted card | Card has restrictions |

## The Pattern: Decline Categorization

Map every response code to a decline category for retry logic:

```typescript
const APPROVED_CODES = new Set(['00', '08', '10', '11']);
const HARD_DECLINE_CODES = new Set([
  '04', '07', '12', '14', '15', '33', '34',
  '41', '43', '54', '57', 'R0', 'R1', 'R3',
]);
const SYSTEM_ERROR_CODES = new Set([
  '06', '09', '50', '68', '91', '92', '96',
]);

function categorizeResponse(code: string): {
  isApproved: boolean;
  declineCategory?: DeclineCategory;
} {
  if (APPROVED_CODES.has(code)) return { isApproved: true };
  if (HARD_DECLINE_CODES.has(code)) return { isApproved: false, declineCategory: 'hard_decline' };
  if (SYSTEM_ERROR_CODES.has(code)) return { isApproved: false, declineCategory: 'system_error' };
  return { isApproved: false, declineCategory: 'soft_decline' }; // default: assume retryable
}
```

## Pitfalls

- **Don't store response codes as integers** — leading zeros matter: `05` is not `5`. Always use `string`.
- **Don't retry hard declines** — codes like `14` (invalid card) and `54` (expired) will never succeed. Retrying wastes processing and can trigger fraud flags.
- **Don't treat `05` as permanent** — "Do not honor" is the most common code and often succeeds on retry (different time, different amount, updated card details).
- **Don't ignore partial approvals (`10`)** — if you don't handle partial amounts, you must reverse the partial authorization.
- **Don't assume two digits** — some networks extend to three digits or use alphanumeric codes (`R0`, `R1`, `R3`). Use `string`, not a two-char fixed field.
- **Don't show raw codes to customers** — map to human-friendly messages: `51` → "Insufficient funds", `54` → "Card expired".
