# Ledger and Entries — Double-Entry Bookkeeping in Code

## The Problem

Banking systems at their core are ledger systems. Code that moves money without proper ledger entries creates reconciliation nightmares. Inconsistent naming of ledger concepts — entries, postings, journal lines — leads to bugs where money appears or disappears.

## Core Concepts

| Concept | Name in Code | Description |
|---|---|---|
| Ledger | `ledger` | A complete record of all entries for a scope (account, entity) |
| Journal | `journal` | A chronological record of transactions before posting |
| Entry | `entry` | A single line in a ledger (one debit or one credit) |
| Journal Entry | `journalEntry` | A complete transaction record: two or more entries that balance |
| Posting | `posting` | The act of recording an entry to a ledger |
| Account | `ledgerAccount` | A named bucket in the chart of accounts |

## Double-Entry Pattern

Every transaction creates at least two entries that sum to zero:

```typescript
interface LedgerEntry {
  entryId: string;
  journalEntryId: string;        // groups entries that must balance
  ledgerAccountId: string;       // which account in the chart of accounts
  direction: 'debit' | 'credit';
  amount: number;                // always positive; direction indicates sign
  currency: string;              // ISO 4217
  effectiveDate: string;         // when it counts for accounting
  postedAt: string;              // when it was recorded in the system
  description: string;
}
```

A transfer of $100 from checking to savings creates:

```typescript
// Journal Entry: "Internal Transfer"
const entries = [
  { ledgerAccountId: 'checking-123', direction: 'debit',  amount: 10000 },
  { ledgerAccountId: 'savings-456',  direction: 'credit', amount: 10000 },
];
// Sum of debits === sum of credits → balanced
```

## Chart of Accounts Naming

The chart of accounts organizes ledger accounts into categories. Use standard hierarchy:

| Category | Code Prefix | Examples |
|---|---|---|
| Assets | `1xxx` | `1010 Cash`, `1020 Loans Receivable` |
| Liabilities | `2xxx` | `2010 Customer Deposits`, `2020 Accounts Payable` |
| Equity | `3xxx` | `3010 Share Capital`, `3020 Retained Earnings` |
| Revenue | `4xxx` | `4010 Interest Income`, `4020 Fee Income` |
| Expenses | `5xxx` | `5010 Interest Expense`, `5020 Operating Expense` |

```typescript
interface ChartOfAccount {
  accountCode: string;        // "1010"
  accountName: string;        // "Cash and Cash Equivalents"
  accountCategory: 'asset' | 'liability' | 'equity' | 'revenue' | 'expense';
  normalBalance: 'debit' | 'credit'; // expected direction
  parentAccountCode?: string; // for hierarchical charts
  isActive: boolean;
}
```

## Normal Balance Convention

Each account category has a "normal" side. An increase goes on the normal side:

| Category | Normal Balance | Increase | Decrease |
|---|---|---|---|
| Asset | Debit | Debit | Credit |
| Liability | Credit | Credit | Debit |
| Equity | Credit | Credit | Debit |
| Revenue | Credit | Credit | Debit |
| Expense | Debit | Debit | Credit |

Customer deposit accounts are **liabilities** (the bank owes the customer), so their normal balance is **credit**. A deposit (money in) is a credit; a withdrawal (money out) is a debit.

## Key Dates

Ledger entries have multiple timestamps — don't conflate them:

| Date | Field Name | Description |
|---|---|---|
| Transaction date | `transactionDate` | When the customer initiated it |
| Value date | `valueDate` | When it takes effect for interest calculation |
| Posting date | `postingDate` | When it was recorded in the ledger |
| Settlement date | `settlementDate` | When funds actually moved between banks |

## Pitfalls

- **Never use signed amounts** — use `amount` (always positive) + `direction` (`debit`/`credit`). Signed amounts cause double-negative bugs.
- **Never post one-sided entries** — every debit must have a matching credit. If entries don't balance, the transaction must be rejected.
- **Don't confuse `entry` and `journalEntry`** — a `journalEntry` is the whole transaction (multiple entries); an `entry` is a single line.
- **Don't use `transaction` for ledger entries** — `transaction` is the business event; `entry` is the ledger record it produces.
- **Don't skip `valueDate`** — posting date and value date can differ (e.g., a check deposited Friday may have a Monday value date). Interest calculations depend on value date.
