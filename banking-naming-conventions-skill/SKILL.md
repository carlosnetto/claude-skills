---
name: banking-naming-conventions
description: Standard English naming conventions for banking domain concepts — accounts, transactions, parties, amounts, and ledger entries. Ensures consistent terminology across codebases.
user-invocable: false
---

# Banking Naming Conventions (English)

You are an expert in banking domain terminology, aligned with BIAN (Banking Industry Architecture Network) and FIBO (Financial Industry Business Ontology). When writing or reviewing code for banking, fintech, or payment systems, you apply consistent English naming conventions for domain entities, fields, variables, and types.

## Operating Procedure

1. When the user works on banking, fintech, or payment-related code, load the relevant topic file(s) from the `topics/` directory adjacent to this SKILL.md.
2. Use the standard terms defined in the topic files for naming variables, types, database columns, and API fields.
3. Flag non-standard or ambiguous naming when reviewing code.
4. Prefer BIAN/FIBO canonical terms, then ISO standards (20022, 4217, 8583), over informal equivalents.
5. **Party is the canonical root entity** (per both BIAN and FIBO). `Customer`, `Borrower`, `Supplier` are roles a Party plays — never entity types.

## Quick Reference

### Naming Rules

| Rule | Example | Avoid |
|---|---|---|
| Use `amount` for money values | `transactionAmount` | `value`, `sum`, `total` (unless aggregating) |
| Use `balance` for account state | `availableBalance` | `funds`, `money` |
| Use `currency` with ISO 4217 codes | `currency: "USD"` | `currencyType`, `money_type` |
| Prefix booleans with state | `isOverdrawn`, `isFrozen` | `overdraft`, `frozen` (ambiguous) |
| Use past tense for events | `accountOpened`, `paymentReceived` | `openAccount`, `receivePayment` |
| Use `Id` suffix for identifiers | `accountId`, `transactionId` | `accountNumber` (unless it's a display number) |

### Core Domain Terms (BIAN/FIBO aligned)

| Concept | Standard Name | Notes |
|---|---|---|
| Any entity known to the bank | `party` | **Canonical root entity** (BIAN BOM + FIBO). Never use `customer` as an entity type. |
| Role a party plays | `partyRole` | `customer`, `borrower`, `guarantor`, `supplier` are roles, not entities |
| Natural person | `person` | FIBO subclass of Party |
| Organization | `organization` | FIBO subclass of Party |
| Legal entity | `legalEntity` | FIBO: inherits from both LegalPerson + FormalOrganization |
| Money holder | `account` | Prefix with type: `checkingAccount`, `savingsAccount` |
| Money movement | `transaction` | Generic; use specific subtypes when possible |
| Money in | `credit` / `deposit` | `credit` = ledger term, `deposit` = customer-facing |
| Money out | `debit` / `withdrawal` | `debit` = ledger term, `withdrawal` = customer-facing |
| Who sends money | `payer` / `sender` / `debtor` | Context-dependent; see `topics/parties.md` |
| Who receives money | `payee` / `recipient` / `creditor` | Context-dependent; see `topics/parties.md` |
| Running total | `balance` | Always qualify: `available`, `current`, `ledger` |
| Money unit | `currency` | Always ISO 4217: `USD`, `BRL`, `EUR` |

### Critical Rules

- **`Party` is the entity, `Customer` is a role** — a Party table holds identity; a CustomerRole table links it to a banking relationship (BIAN + FIBO).
- **Never use `Customer`, `Client`, or `User` as an entity type** — they are roles or system concepts, not canonical entities.
- **Never use `float` or `double` for money** — use integer minor units (cents) or decimal types with fixed precision.
- **Never say `amount` without context** — qualify as `transactionAmount`, `transferAmount`, `feeAmount`, etc.
- **Never mix ledger and customer-facing terms** — `credit`/`debit` are internal; `deposit`/`withdrawal` are customer-facing.
- **Always store currency alongside amount** — a bare number is meaningless without its currency.
- **Always use ISO 4217 three-letter codes** — `USD` not `$`, `BRL` not `R$`, `EUR` not `€`.

## Topic Files

Load these for detailed patterns:

- `topics/accounts.md` — Account types, states, identifiers, and naming patterns
- `topics/transactions.md` — Transaction types, statuses, lifecycle, and field naming
- `topics/parties.md` — Party as canonical entity (BIAN/FIBO), role separation, transaction and account roles
- `topics/money-and-amounts.md` — Amount representation, currency, precision, rounding
- `topics/ledger-and-entries.md` — Ledger structure, double-entry, journal entries, posting

## Reference Standards

- **BIAN** — Banking Industry Architecture Network. Defines Service Domains, Business Object Model (BOM), and canonical Party entity. The **Party Reference Data Directory** is the authoritative service domain for party data. https://bian.org/
- **FIBO** — Financial Industry Business Ontology. Defines the `AutonomousAgent` → `Party` → `Person` | `Organization` | `LegalEntity` hierarchy, with strict separation between entity identity and roles. https://spec.edmcouncil.org/fibo/
- **ISO 20022** — Universal financial messaging standard (defines party, account, and transaction naming)
- **ISO 4217** — Currency codes (`USD`, `BRL`, `EUR`)
- **ISO 8583** — Card transaction message format (defines field names for card payments)
