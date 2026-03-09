# Accounts — Types, States, and Identifiers

## The Problem

Banking codebases drift into inconsistent account naming — `acct`, `userAccount`, `bankAccount`, `wallet` — making it unclear what kind of account is being referenced and what operations are valid on it.

## Account Types

Use the standard type as a prefix or enum value:

| Type | Name in Code | Description |
|---|---|---|
| Checking | `checkingAccount` | Day-to-day transactional account |
| Savings | `savingsAccount` | Interest-bearing, limited withdrawals |
| Current | `currentAccount` | Same as checking (UK/international term) |
| Deposit | `depositAccount` | Generic term covering checking + savings |
| Loan | `loanAccount` | Tracks borrowed principal + interest |
| Credit | `creditAccount` | Revolving credit (credit cards) |
| Escrow | `escrowAccount` | Funds held by third party until conditions met |
| Suspense | `suspenseAccount` | Temporary holding for unclassified entries |
| Nostro | `nostroAccount` | "Our account at their bank" (correspondent banking) |
| Vostro | `vostroAccount` | "Their account at our bank" (correspondent banking) |

```typescript
type AccountType =
  | 'checking'
  | 'savings'
  | 'current'
  | 'deposit'
  | 'loan'
  | 'credit'
  | 'escrow'
  | 'suspense';
```

## Account States

Use an explicit state machine. Name states as adjectives:

| State | Field Name | Description |
|---|---|---|
| Active | `active` | Open and operational |
| Inactive | `inactive` | No recent activity, not closed |
| Dormant | `dormant` | Inactive beyond regulatory threshold |
| Frozen | `frozen` | Blocked by compliance/legal hold |
| Closed | `closed` | Permanently closed |
| Pending | `pendingApproval` | Opened but not yet approved |
| Blocked | `blocked` | Temporarily restricted (e.g., suspicious activity) |

```typescript
type AccountStatus =
  | 'active'
  | 'inactive'
  | 'dormant'
  | 'frozen'
  | 'closed'
  | 'pending_approval'
  | 'blocked';
```

## Account Identifiers

Different identifiers serve different purposes. Never conflate them:

| Identifier | Field Name | Description |
|---|---|---|
| Internal ID | `accountId` | System-generated UUID or serial; never shown to customers |
| Account Number | `accountNumber` | Customer-facing display number |
| IBAN | `iban` | International Bank Account Number (ISO 13616) |
| Routing Number | `routingNumber` | Bank identifier (US: ABA, BR: ISPB) |
| Sort Code | `sortCode` | Bank + branch identifier (UK) |
| SWIFT/BIC | `bic` | Bank Identifier Code for international transfers |

```typescript
interface AccountIdentifiers {
  accountId: string;        // internal UUID
  accountNumber: string;    // customer-facing
  iban?: string;            // international, 2-letter country + 2 check digits + BBAN
  routingNumber?: string;   // US ABA routing number
  bic?: string;             // SWIFT/BIC code
}
```

## Relationship to Party (BIAN Model)

In BIAN, an Account exists because a **Party** (in the role of **Customer**) entered into an **Agreement** for a **Product**:

```
Party → (plays role) → Customer → (signs) → Agreement → (provisions) → Account
```

This means:
- An account always has an `accountHolderId` pointing to a `Party`, not to a `Customer` table.
- The **Product** defines the account type and rules (interest rates, fees, limits).
- The **Agreement** (or `SalesProductAgreement` in BIAN) binds the Party to the Product.

```typescript
interface Account {
  accountId: string;
  accountType: AccountType;
  accountStatus: AccountStatus;
  accountHolderId: string;      // FK to Party (not to Customer)
  productId: string;            // FK to Product (defines the account rules)
  agreementId: string;          // FK to Agreement (binds Party to Product)
  currency: string;             // ISO 4217
  openedAt: string;             // ISO 8601
  closedAt?: string;
}
```

## Pitfalls

- **`account` alone is too vague** — always qualify with type or context: `sourceAccount`, `destinationAccount`, `checkingAccount`.
- **Don't use `wallet` for bank accounts** — `wallet` implies crypto or e-money; use `account` for traditional banking.
- **Don't use `accountNumber` for the internal ID** — `accountNumber` is the customer-facing display number; `accountId` is the system identifier.
- **Don't abbreviate** — `acct`, `acc`, `acctNo` cause confusion; write the full word.
- **Don't link accounts directly to a `Customer` table** — link to `Party` via `accountHolderId`. The customer relationship is modeled through `PartyRole`, not duplicated on the account.
