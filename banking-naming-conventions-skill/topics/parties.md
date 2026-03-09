# Parties — The Canonical Entity Model

## The Problem

Banking codebases conflate identity with role — using `Customer`, `Client`, or `User` as if they were entity types, when they are actually roles that an entity plays. This leads to duplicate records, broken references, and models that can't represent a person who is simultaneously a customer, an employee, and a guarantor.

Both **BIAN** (Banking Industry Architecture Network) and **FIBO** (Financial Industry Business Ontology) independently converge on the same solution: **Party** is the canonical, overarching term for any entity — individual or organization — known to the bank. Everything else (`Customer`, `Borrower`, `Guarantor`) is a **role** that a Party plays in a specific context.

## The FIBO Entity Hierarchy

FIBO defines the canonical class hierarchy. Use these as your type names:

```
AutonomousAgent              # anything that can act on its own
├── Party                    # human or organizational entity
│   ├── Person               # natural person (individual human being)
│   ├── Organization         # formally recognized group
│   │   ├── FormalOrganization
│   │   └── InformalOrganization
│   └── LegalPerson          # entity capable of legal liability
│       └── LegalEntity      # inherits from both LegalPerson + FormalOrganization
│           ├── Corporation
│           ├── Partnership
│           └── Polity       # sovereign state, municipality
└── AutomatedSystem          # software agent
```

Key principle: **what an entity IS (Party hierarchy) is separate from what it DOES (Role hierarchy).**

```typescript
// WHAT IT IS — identity, immutable classification
type PartyType = 'person' | 'organization' | 'legal_entity';

// WHAT IT DOES — contextual, can change, can be multiple
type PartyRole =
  | 'customer'
  | 'borrower'
  | 'lender'
  | 'guarantor'
  | 'beneficiary'
  | 'account_holder'
  | 'authorized_signer'
  | 'employee'
  | 'supplier'
  | 'counterparty';
```

## The BIAN Party Model

BIAN's Business Object Model (BOM) enforces a canonical `Party` object. The dedicated **Party Reference Data Directory** service domain (formerly "Customer Reference Data Management") is the single source of truth for party data.

A Party becomes a `Customer` only when it enters a product relationship with the bank:

```
Party (canonical entity)
  └── has role → Customer (when buying a product)
  └── has role → Employee (when working for the bank)
  └── has role → Supplier (when providing services to the bank)
  └── has role → Counterparty (in a financial contract)
```

## Party Data Model

```typescript
// The canonical entity — ONE record per real-world person or organization
interface Party {
  partyId: string;              // internal system identifier (UUID)
  partyType: PartyType;

  // Natural person (partyType === 'person')
  firstName?: string;
  lastName?: string;
  fullName: string;             // display name
  dateOfBirth?: string;         // ISO 8601

  // Organization (partyType === 'organization' | 'legal_entity')
  legalName?: string;           // registered legal name
  tradingName?: string;         // "doing business as" (DBA)
  leiCode?: string;             // Legal Entity Identifier (ISO 17442)

  // Identifiers — use FIBO's "Designation" concept
  taxId?: string;               // CPF (BR), SSN (US), TIN (generic)
  nationalId?: string;          // RG (BR), national ID card
  passportNumber?: string;

  // Contact
  email?: string;
  phoneNumber?: string;         // E.164 format: "+5511999999999"
}

// The role — links a Party to a context
interface PartyRole {
  partyRoleId: string;
  partyId: string;              // FK to Party
  roleType: PartyRole;
  effectiveFrom: string;        // ISO 8601
  effectiveTo?: string;         // null = still active
  status: 'active' | 'inactive' | 'suspended';
}

// Customer is just a specialization of PartyRole
interface CustomerRole extends PartyRole {
  roleType: 'customer';
  customerSegment?: 'retail' | 'corporate' | 'private_banking' | 'sme';
  relationshipManagerId?: string;
  onboardedAt: string;
}
```

## Transaction Context Roles

When a Party participates in a specific transaction, it takes on a transaction-scoped role:

| Role | Name in Code | When to Use |
|---|---|---|
| Payer | `payer` | The party making a payment |
| Payee | `payee` | The party receiving a payment |
| Sender | `sender` | Customer-facing term for the initiator |
| Recipient | `recipient` | Customer-facing term for the receiver |
| Debtor | `debtor` | ISO 20022 term for payer (formal messaging) |
| Creditor | `creditor` | ISO 20022 term for payee (formal messaging) |
| Ultimate Debtor | `ultimateDebtor` | ISO 20022: the original party on whose behalf the debtor initiates |
| Ultimate Creditor | `ultimateCreditor` | ISO 20022: the final party for whom the creditor receives funds |
| Remitter | `remitter` | The party ordering a remittance (international) |
| Beneficiary | `beneficiary` | The party receiving a remittance (international) |
| Invoicer | `invoicer` | The party that issued the invoice (seller/supplier) |
| Invoicee | `invoicee` | The party that received the invoice (buyer/customer) |

### The ISO 20022 Four-Party Chain

ISO 20022 payment messages (pain.001, pacs.008) distinguish up to four parties in a single payment. This matters when an intermediary initiates a payment on behalf of someone else:

```
Ultimate Debtor → Debtor → Creditor → Ultimate Creditor
(who owes)        (who sends)  (who receives)  (who is owed)
```

- **`debtor`** — the party whose account is debited (the sending bank's customer).
- **`ultimateDebtor`** — the original party on whose behalf the debtor pays. Used when a parent company pays on behalf of a subsidiary, or a payroll processor pays on behalf of an employer.
- **`creditor`** — the party whose account is credited (the receiving bank's customer).
- **`ultimateCreditor`** — the final party for whom the funds are intended. Used when a collecting agent receives on behalf of a merchant, or a tax authority receives via an intermediary.

When there is no intermediary, `ultimateDebtor` and `ultimateCreditor` are omitted — the chain collapses to `debtor` → `creditor`.

```typescript
interface PaymentParties {
  debtorId: string;               // required — who sends
  creditorId: string;             // required — who receives
  ultimateDebtorId?: string;      // optional — on whose behalf the debtor pays
  ultimateCreditorId?: string;    // optional — for whom the creditor receives
}
```

### Choosing the Right Term by Layer

```
Customer-facing UI:       sender / recipient
Internal transfer logic:  payer / payee
ISO 20022 messages:       debtor / creditor (+ ultimate variants)
International wires:      remitter / beneficiary
Invoicing / billing:      invoicer / invoicee
```

Pick one pair per layer and use it consistently throughout.

## Account Context Roles

| Role | Name in Code | Description |
|---|---|---|
| Account holder | `accountHolder` | The party that owns the account |
| Authorized signer | `authorizedSigner` | Party allowed to operate the account |
| Joint holder | `jointHolder` | Co-owner on a joint account |
| Power of attorney | `powerOfAttorney` | Legal representative authorized to act |
| Account beneficiary | `accountBeneficiary` | Party designated to inherit the account |

## KYC (Know Your Customer) States

KYC applies to the **Party**, not to the customer role — a party's identity is verified once, regardless of how many roles it holds:

```typescript
type KycStatus =
  | 'kyc_not_started'
  | 'kyc_in_progress'
  | 'kyc_verified'
  | 'kyc_rejected'
  | 'kyc_expired';
```

## Pitfalls

- **Don't use `Customer` as an entity type** — `Customer` is a role a `Party` plays. A `Party` table holds the identity; a `CustomerRole` table links it to a banking relationship. Both BIAN and FIBO agree on this.
- **Don't use `user`** — `user` is a system/auth concept (login credentials); `party` is the banking concept (real-world identity).
- **Don't use `client`** — ambiguous between a banking customer and a software API client, and not a standard term in BIAN or FIBO. Use `customer` for the role, `party` for the entity.
- **Don't use `beneficiary` for domestic transfers** — `beneficiary` implies international wire or inheritance; use `recipient` or `payee` for domestic.
- **Don't use `name` alone** — qualify as `fullName`, `legalName`, `tradingName`, `firstName`, `lastName`.
- **Don't mix `sender`/`creditor`** — pick one naming convention per layer and be consistent.
- **Don't duplicate party data across role tables** — the Party record is canonical; roles point to it via `partyId`. If you find name/address columns on a Customer table, that's a data model smell.
