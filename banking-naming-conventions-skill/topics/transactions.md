# Transactions — Types, Statuses, and Field Naming

## The Problem

"Transaction" is overloaded in banking. A deposit, a wire transfer, a card payment, and a fee charge are all transactions, but they have different fields and lifecycle states. Without consistent naming, code becomes ambiguous about what type of transaction it's handling.

## Transaction Types

Use specific subtypes instead of a generic `transaction` when possible:

| Type | Name in Code | Description |
|---|---|---|
| Deposit | `deposit` | Money added to an account (cash, check, ACH) |
| Withdrawal | `withdrawal` | Money removed from an account |
| Transfer | `transfer` | Money moved between accounts (internal or external) |
| Payment | `payment` | Money sent to pay an obligation (bill, invoice) |
| Invoice | `invoice` | A request for payment issued by an invoicer to an invoicee |
| Fee | `fee` | Bank-charged amount (maintenance, overdraft, wire) |
| Interest | `interestAccrual` | Interest earned or charged |
| Reversal | `reversal` | Undo of a previous transaction |
| Adjustment | `adjustment` | Manual correction by bank operations |
| Refund | `refund` | Return of previously collected funds |
| Chargeback | `chargeback` | Disputed card transaction reversed by issuer |

```typescript
type TransactionType =
  | 'deposit'
  | 'withdrawal'
  | 'transfer'
  | 'payment'
  | 'invoice'
  | 'fee'
  | 'interest_accrual'
  | 'reversal'
  | 'adjustment'
  | 'refund'
  | 'chargeback';
```

## Transaction Statuses

Model the lifecycle explicitly. Name statuses as past participles or adjectives:

| Status | Name in Code | Description |
|---|---|---|
| Initiated | `initiated` | Created, not yet processed |
| Pending | `pending` | Submitted, awaiting processing |
| Processing | `processing` | Currently being executed |
| Completed | `completed` | Successfully settled |
| Failed | `failed` | Could not be processed |
| Reversed | `reversed` | Successfully undone |
| Cancelled | `cancelled` | Cancelled before processing |
| On hold | `on_hold` | Paused for review (compliance, fraud) |

```typescript
type TransactionStatus =
  | 'initiated'
  | 'pending'
  | 'processing'
  | 'completed'
  | 'failed'
  | 'reversed'
  | 'cancelled'
  | 'on_hold';
```

## Standard Field Names

Use these consistently across all transaction types:

```typescript
interface Transaction {
  transactionId: string;          // unique identifier
  transactionType: TransactionType;
  status: TransactionStatus;

  // Money
  amount: number;                 // in minor units (cents)
  currency: string;               // ISO 4217: "USD", "BRL"

  // Parties
  sourceAccountId: string;        // who the money comes from
  destinationAccountId: string;   // who the money goes to

  // Timing
  initiatedAt: string;            // ISO 8601 timestamp — when created
  processedAt?: string;           // when processing started
  completedAt?: string;           // when settled
  valueDateAt?: string;           // effective date for accounting

  // Context
  description: string;            // human-readable summary
  referenceNumber: string;        // external reference (check number, wire ref)
  memo?: string;                  // optional note from the customer
}
```

## Direction Convention

From the account's perspective, a transaction is either a **credit** (money in) or a **debit** (money out):

```typescript
type EntryDirection = 'credit' | 'debit';
```

- A `deposit` is a `credit` to the receiving account.
- A `withdrawal` is a `debit` from the source account.
- A `transfer` creates both: a `debit` on the source and a `credit` on the destination.

Use `direction` or `entryType` as the field name — never `type` alone (too ambiguous).

## Invoice Fields

An invoice is a request for payment — it is not a payment itself. The invoice lifecycle is separate from the payment lifecycle. An invoice may result in zero, one, or many payments.

```typescript
interface Invoice {
  invoiceId: string;
  invoiceNumber: string;            // customer-facing reference
  status: InvoiceStatus;

  // Parties (see topics/parties.md for invoicer/invoicee)
  invoicerId: string;               // FK to Party — who issued the invoice (seller)
  invoiceeId: string;               // FK to Party — who received the invoice (buyer)

  // Money
  totalAmount: number;              // in minor units
  paidAmount: number;               // sum of all payments applied
  outstandingAmount: number;        // totalAmount - paidAmount
  currency: string;                 // ISO 4217

  // Timing
  issuedAt: string;                 // when the invoice was created
  dueAt: string;                    // payment deadline
  paidAt?: string;                  // when fully settled

  // Line items
  lineItems: InvoiceLineItem[];
}

type InvoiceStatus =
  | 'draft'
  | 'issued'
  | 'partially_paid'
  | 'paid'
  | 'overdue'
  | 'cancelled'
  | 'written_off';
```

When a payment settles an invoice, link them — don't merge them:

```typescript
interface PaymentInvoiceLink {
  paymentId: string;                // FK to Transaction (payment)
  invoiceId: string;                // FK to Invoice
  appliedAmount: number;            // how much of this payment applies to this invoice
}
```

## Pitfalls

- **Don't use `date` alone** — banking has multiple dates: `initiatedAt`, `processedAt`, `completedAt`, `valueDateAt`. Be explicit.
- **Don't use `from`/`to`** — use `sourceAccountId`/`destinationAccountId` for clarity.
- **Don't use `success`/`error` as statuses** — use the lifecycle terms: `completed`, `failed`.
- **Don't mix `transaction` and `transfer`** — a `transfer` is a specific type of `transaction`.
- **Don't use `txn`** — spell out `transaction`. Abbreviations cause confusion in larger codebases.
- **Don't confuse `invoice` and `payment`** — an invoice is a request; a payment is a settlement. They have separate lifecycles and a many-to-many relationship.
- **Don't use `bill` interchangeably with `invoice`** — `invoice` is the standard term; `bill` is informal and ambiguous (can also mean a banknote).
