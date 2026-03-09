# Money and Amounts — Representation, Currency, and Precision

## The Problem

Money looks simple but is a minefield in code. Floating-point errors cause rounding bugs, missing currency codes create ambiguity, and inconsistent precision across systems causes reconciliation failures.

## The Pattern: Minor Units (Integer Cents)

Store and transmit money as **integers in the smallest currency unit** (cents, centavos, pence):

```typescript
// CORRECT — integer minor units
const amount = 1050;     // represents $10.50 (USD, 2 decimal places)
const amount = 10500;    // represents R$105.00 (BRL, 2 decimal places)
const amount = 1050;     // represents ¥1050 (JPY, 0 decimal places)

// WRONG — floating point
const amount = 10.50;    // 0.1 + 0.2 !== 0.3 in IEEE 754
```

### Currency Decimal Places (ISO 4217)

| Currency | Code | Minor Unit | Decimals | 1 major = N minor |
|---|---|---|---|---|
| US Dollar | `USD` | cent | 2 | 100 |
| Brazilian Real | `BRL` | centavo | 2 | 100 |
| Euro | `EUR` | cent | 2 | 100 |
| British Pound | `GBP` | penny | 2 | 100 |
| Japanese Yen | `JPY` | — | 0 | 1 |
| Kuwaiti Dinar | `KWD` | fils | 3 | 1000 |
| Bitcoin | `XBT` | satoshi | 8 | 100,000,000 |

## Money Object Pattern

Always pair an amount with its currency:

```typescript
interface Money {
  amount: number;      // integer in minor units
  currency: string;    // ISO 4217 code: "USD", "BRL", "EUR"
}
```

Never pass a bare number as a money value. A function that takes `amount: number` without `currency` is a bug waiting to happen.

## Naming Conventions for Amount Fields

Always qualify `amount` with its context:

| Field | Name | Description |
|---|---|---|
| Transaction amount | `transactionAmount` | The principal amount of the transaction |
| Fee | `feeAmount` | Any fee charged |
| Tax | `taxAmount` | Tax withheld or charged |
| Net amount | `netAmount` | After deductions (amount - fees - taxes) |
| Gross amount | `grossAmount` | Before deductions |
| Total | `totalAmount` | Sum of multiple items |
| Interest | `interestAmount` | Interest earned or charged |
| Principal | `principalAmount` | Original loan/deposit amount |
| Outstanding | `outstandingAmount` | Remaining unpaid balance |

## Balance Types

An account has multiple balances at any given time:

```typescript
interface AccountBalances {
  currentBalance: number;     // all posted entries (ledger balance)
  availableBalance: number;   // current minus holds/pending debits
  pendingBalance: number;     // sum of uncleared entries
  holdAmount: number;         // funds reserved (pre-auth, legal hold)
  overdraftLimit: number;     // maximum allowed negative balance
}
```

- **`currentBalance`** (or `ledgerBalance`) — the accounting truth.
- **`availableBalance`** — what the customer can actually spend. This is what to show on the UI.
- **Never show `currentBalance` to customers** — it doesn't account for pending debits or holds.

## Display Formatting

Format money for display at the UI layer only — never store formatted strings:

```typescript
function formatMoney(amount: number, currency: string): string {
  const decimals = getDecimalPlaces(currency); // 2 for USD/BRL, 0 for JPY
  const major = amount / Math.pow(10, decimals);
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
  }).format(major);
}

// formatMoney(1050, 'USD') → "$10.50"
// formatMoney(1050, 'JPY') → "¥1,050"
```

## Pitfalls

- **Never use `float` or `double` for money** — `0.1 + 0.2 !== 0.3` in IEEE 754. Use integer minor units or a `Decimal` library.
- **Never store formatted amounts** — `"$10.50"` is not searchable, not sortable, and locale-dependent.
- **Never assume 2 decimal places** — JPY has 0, KWD has 3. Always derive from the currency.
- **Never add amounts in different currencies** — `1000 USD + 1000 BRL` is meaningless without a conversion rate.
- **Don't call it `price`** — `price` is for goods/services; `amount` is for transactions; `balance` is for accounts.
- **Don't use `value`** — too generic. Use `amount`, `balance`, or `rate` depending on context.
