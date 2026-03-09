# Error Codes — Payments, Transfers, Messaging (ISO 20022)

## The Problem

ISO 20022 payment messages use **External Code Sets** for rejection and return reasons — alphanumeric codes like `AC04` or `AM04` that are maintained separately from the message schemas. Codebases that hardcode these codes or confuse reject vs. return semantics mishandle payment failures and break reconciliation.

## Code Set Structure

ISO 20022 reason codes are **alphanumeric**, grouped by prefix. Two main code sets:

| Code Set | Message | When Used |
|---|---|---|
| `ExternalStatusReasonCode` | `pacs.002` (Payment Status Report) | Payment **rejected** before settlement |
| `ExternalReturnReasonCode` | `pacs.004` (Payment Return) | Payment **returned** after settlement |

A **reject** means the payment never settled. A **return** means it settled but was sent back.

```typescript
interface PaymentFailure {
  failureType: 'reject' | 'return';
  reasonCode: string;          // ISO 20022 code: "AC04", "AM04", etc.
  reasonText: string;          // human-readable description
  additionalInfo?: string;     // narrative details (code NARR)
}
```

## Code Prefixes

| Prefix | Category | Meaning |
|---|---|---|
| `AB` | Aborted | Clearing/settlement process aborted (timeout, fatal error) |
| `AC` | Account | Account-related issue (closed, blocked, invalid) |
| `AG` | Agreement | Transaction forbidden on account type, no agreement |
| `AM` | Amount | Amount issue (insufficient funds, zero, over limit) |
| `BE` | Beneficiary/End-customer | Party identification or address issue |
| `CN` | Cancellation | Authorization cancelled |
| `CURR` | Currency | Currency mismatch or invalid |
| `DS` | Direct debit specific | Order cancelled, signature issues |
| `DT` | Date | Invalid or unsupported date |
| `DUPL` | Duplicate | Duplicate payment detected |
| `ED` | Settlement | Correspondent bank or settlement failure |
| `FF` | Format/Field | Missing or invalid field (service level, purpose) |
| `FR` | Fraud | Fraudulent transaction |
| `MD` | Mandate | Direct debit mandate issue |
| `MS` | Not specified | Generic reason (customer or agent generated) |
| `NARR` | Narrative | Reason provided as free text |
| `RC` | Routing/BIC | Invalid or missing bank identifier |
| `RR` | Regulatory | Regulatory or compliance issue |
| `SL` | Service level | Debtor/creditor agent service restrictions |
| `SP` | Stop payment | Account holder stopped the payment |
| `TM` | Timing | Received after processing cut-off |

## Most Common Reason Codes

### Account Issues (AC)

| Code | Description | Reject/Return |
|---|---|---|
| `AC01` | Incorrect account number | Both |
| `AC02` | Debtor account number invalid or missing | Reject |
| `AC03` | Creditor account number invalid or missing | Reject |
| `AC04` | Closed account number | Both |
| `AC06` | Blocked account | Both |
| `AC07` | Creditor account number closed | Return |
| `AC13` | Debtor account type is missing or invalid | Both |
| `AC14` | Agent in the payment chain is invalid | Both |
| `AC15` | Account details have changed | Return |
| `AC16` | Account is in sequestration | Return |
| `AC17` | Account is in liquidation | Return |

### Amount Issues (AM)

| Code | Description | Reject/Return |
|---|---|---|
| `AM01` | Amount is zero | Reject |
| `AM02` | Amount exceeds allowed maximum | Both |
| `AM03` | Currency not processable | Both |
| `AM04` | Insufficient funds | Both |
| `AM05` | Duplication | Both |
| `AM06` | Amount below agreed minimum | Reject |
| `AM07` | Amount blocked by regulatory authorities | Both |
| `AM09` | Amount not as agreed or expected | Return |
| `AM10` | Instructed amounts don't equal control sum | Reject |

### Party / Beneficiary Issues (BE)

| Code | Description | Reject/Return |
|---|---|---|
| `BE01` | End customer identification inconsistent with account | Both |
| `BE04` | Missing or incorrect creditor address | Both |
| `BE05` | Initiating party not recognized | Both |
| `BE06` | End customer unknown at bank | Both |
| `BE07` | Missing or incorrect debtor address | Reject |
| `BE08` | Bank error | Return |
| `BE10` | Debtor country code missing or invalid | Reject |
| `BE11` | Creditor country code missing or invalid | Reject |
| `BE16` | Debtor/ultimate debtor identification invalid | Both |
| `BE17` | Creditor/ultimate creditor identification invalid | Both |

### Routing / Bank Identifier Issues (RC)

| Code | Description | Reject/Return |
|---|---|---|
| `RC01` | BIC has incorrect format | Both |
| `RC03` | Debtor bank identifier invalid or missing | Reject |
| `RC04` | Creditor bank identifier invalid or missing | Both |
| `RC07` | Incorrect BIC of beneficiary bank | Return |
| `RC08` | Clearing system member identifier invalid | Both |
| `RC11` | Intermediary agent invalid or missing | Reject |

### Regulatory Issues (RR)

| Code | Description | Reject/Return |
|---|---|---|
| `RR01` | Debtor account/identification insufficient for regulatory | Both |
| `RR02` | Debtor name/address insufficient for regulatory | Both |
| `RR03` | Creditor name/address insufficient for regulatory | Both |
| `RR04` | Regulatory reason (generic) | Both |
| `RR05` | Regulatory reporting information missing or invalid | Both |
| `RR06` | Tax information missing or invalid | Reject |
| `RR07` | Remittance information doesn't comply with rules | Reject |
| `RR09` | Structured creditor reference invalid or missing | Reject |

### Process / System Issues

| Code | Description | Reject/Return |
|---|---|---|
| `AB01` | Clearing process aborted — timeout | Reject |
| `AB02` | Clearing process aborted — fatal error | Reject |
| `AB05` | Timeout at creditor agent | Reject |
| `CNOR` | Creditor bank not registered in clearing system | Both |
| `DNOR` | Debtor bank not registered in clearing system | Both |
| `DT01` | Invalid date (e.g., wrong settlement date) | Both |
| `DUPL` | Duplicate payment | Both |
| `ED05` | Settlement failed | Both |
| `TM01` | Received after processing cut-off time | Both |

### Customer / Mandate Actions

| Code | Description | Reject/Return |
|---|---|---|
| `CUST` | Cancellation requested by debtor | Both |
| `FOCR` | Return following a cancellation request | Return |
| `FR01` | Returned due to fraud | Return |
| `MD01` | No mandate | Both |
| `MD06` | Refund requested by end customer | Return |
| `MD07` | End customer is deceased | Return |
| `MS02` | Reason not specified — customer generated | Both |
| `MS03` | Reason not specified — agent generated | Both |
| `NARR` | Reason provided as narrative (see additional info) | Both |
| `SP01` | Payment stopped by account holder | Both |
| `UPAY` | Payment is not justified | Return |

## The Pattern: Handling Reason Codes

```typescript
// Categorize for retry logic and customer messaging
function categorizePaymentFailure(code: string): {
  retryable: boolean;
  category: string;
  customerMessage: string;
} {
  // Account issues — generally not retryable
  if (['AC01', 'AC04', 'AC06', 'AC07'].includes(code)) {
    return { retryable: false, category: 'account', customerMessage: 'Account issue — verify account details' };
  }
  // Insufficient funds — retryable later
  if (code === 'AM04') {
    return { retryable: true, category: 'amount', customerMessage: 'Insufficient funds' };
  }
  // System/timeout — retryable after delay
  if (['AB01', 'AB02', 'AB05', 'TM01', 'ED05'].includes(code)) {
    return { retryable: true, category: 'system', customerMessage: 'Temporary processing issue' };
  }
  // Regulatory — not retryable without fixing data
  if (code.startsWith('RR')) {
    return { retryable: false, category: 'regulatory', customerMessage: 'Compliance information required' };
  }
  // Default
  return { retryable: false, category: 'other', customerMessage: 'Payment could not be processed' };
}
```

## Canonical Source

The External Code Sets are maintained by ISO 20022 and updated quarterly. Always reference the latest version:

- **Download**: https://www.iso20022.org/catalogue-messages/additional-content-messages/external-code-sets
- **Formats**: XLSX, XSD, JSON
- **TypeScript types**: https://github.com/TransactionAuthorizationProtocol/iso20022-external-code-sets

## Pitfalls

- **Don't confuse reject and return** — a reject (`pacs.002`) means the payment never settled; a return (`pacs.004`) means it settled then came back. They have different reconciliation impacts.
- **Don't hardcode the full code list** — the External Code Sets are updated quarterly. Load from the canonical source or use a maintained library.
- **Don't retry regulatory rejects (`RR*`)** — these require fixing the data (missing address, invalid tax ID), not retrying the same message.
- **Don't ignore `NARR`** — when the reason code is `NARR`, the actual reason is in the `additionalInfo` free-text field. Always log and surface it.
- **Don't map ISO 20022 codes to ISO 8583 codes** — they are different standards for different domains. A card payment uses 8583; a bank transfer uses 20022. Don't conflate them.
- **Don't show raw codes to customers** — `AC04` means nothing to a user. Map to human-friendly messages per locale.
