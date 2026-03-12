# IOF System Design — Computing, Storing, and Auditing IOF

## Core Design Challenges

Building a system that correctly computes and audits IOF is non-trivial because:

1. **Rates change on scheduled future dates** (Art. 15-C) — the system must know today what the rate will be in 2027
2. **Rates can change unexpectedly by decree** (the 2023 events) — the system must accept new rate rows without code changes
3. **Classification rules and rates are independent** — "which inciso applies" and "what is that inciso's current rate" are separate concerns
4. **Historical audit is mandatory** — given a transaction from 3 years ago, reproduce the exact IOF computation with its legal basis
5. **The isenção / alíquota zero distinction must be preserved** — both result in 0% payment but are legally distinct
6. **No PF/PJ distinction for FX IOF** — but the system must still be extensible for credit IOF which does have the distinction

---

## Two-Table Architecture

Separate the two independent concerns:

### Table 1: `tax.iof_fx_classification`

Maps `(natureza_group, instrument, direction)` → `rate_key`. This is the **policy** layer — which rule applies to this type of transaction.

Changes rarely — only when a new decree restructures Art. 15-B incisos or adds new operation types.

```sql
CREATE TABLE tax.iof_fx_classification (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    natureza_group   VARCHAR(50)   NOT NULL,
    instrument       VARCHAR(30),               -- null = any instrument
    direction        VARCHAR(10),               -- OUTBOUND, INBOUND, null = both
    rate_key         VARCHAR(50)   NOT NULL,
    priority         INTEGER       NOT NULL DEFAULT 10,  -- lower = checked first
    legal_basis      VARCHAR(500)  NOT NULL,
    notes            TEXT,
    valid_from       TIMESTAMPTZ   NOT NULL,
    valid_to         TIMESTAMPTZ   NOT NULL DEFAULT '9999-12-31 00:00:00+00',
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by       VARCHAR(255),
    change_reason    TEXT
);

-- One active rule per (natureza_group, instrument, direction) at a time
CREATE UNIQUE INDEX uq_iof_fx_classification_active
    ON tax.iof_fx_classification (natureza_group, COALESCE(instrument,''), COALESCE(direction,''))
    WHERE valid_to = '9999-12-31 00:00:00+00';
```

### Table 2: `tax.iof_rate_schedule`

Maps `rate_key` → `rate` for a given time period. This is the **rate** layer.

Critically: Art. 15-C future steps are **pre-seeded at migration time** with closed `valid_to` dates. The active row query works correctly for all dates, past and future.

```sql
CREATE TABLE tax.iof_rate_schedule (
    id           UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    rate_key     VARCHAR(50)   NOT NULL,
    rate         NUMERIC(8,6)  NOT NULL,    -- 0.033800 = 3.38%
    is_exempt    BOOLEAN       NOT NULL DEFAULT false,  -- true = Art. 16 isenção
    legal_basis  VARCHAR(500)  NOT NULL,
    valid_from   TIMESTAMPTZ   NOT NULL,
    valid_to     TIMESTAMPTZ   NOT NULL DEFAULT '9999-12-31 00:00:00+00',
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_by   VARCHAR(255),
    change_reason TEXT
);

-- One active rate per rate_key at any time
CREATE UNIQUE INDEX uq_iof_rate_active
    ON tax.iof_rate_schedule (rate_key)
    WHERE valid_to = '9999-12-31 00:00:00+00';
```

---

## Handling Art. 15-C Pre-Seeded Future Rows

The Art. 15-C schedule is unique: future rates are legislated in advance. This means we can pre-seed ALL steps at migration time.

**Key insight:** The `ART15C_TRACK` rate key has multiple rows, each with a **closed** `valid_to` date (not `9999-12-31`) except the final step. The rate lookup query uses date-range matching, not the sentinel:

```sql
-- Rate lookup for any date (past, present, or pre-seeded future)
SELECT rate, is_exempt, legal_basis, id
FROM tax.iof_rate_schedule
WHERE rate_key = :rateKey
  AND valid_from <= :settlementDate
  AND valid_to > :settlementDate
LIMIT 1;
```

This query works for ALL rate keys:
- For `ZERO_PERMANENT`: returns the single row with `valid_to = '9999-12-31'` for any date
- For `ART15C_TRACK`: returns the correct step based on settlement date
- For `CREDIT_CARD_ZERO` (post-Oct-2023): returns 0% for any date ≥ 2023-10-26

**Pre-seeded migration example:**

```sql
-- Art. 15-C track — all steps seeded at once
INSERT INTO tax.iof_rate_schedule (rate_key, rate, legal_basis, valid_from, valid_to) VALUES
  ('ART15C_TRACK', 0.063800, 'Art. 15-B incisos IX/X/XXII — original rate', '2007-12-14', '2023-01-02'),
  ('ART15C_TRACK', 0.053800, 'Art. 15-C step 1, Decreto 10.997/2022', '2023-01-02', '2024-01-02'),
  ('ART15C_TRACK', 0.043800, 'Art. 15-C step 2, Decreto 10.997/2022', '2024-01-02', '2025-01-02'),
  ('ART15C_TRACK', 0.033800, 'Art. 15-C step 3, Decreto 10.997/2022', '2025-01-02', '2026-01-02'),
  ('ART15C_TRACK', 0.023800, 'Art. 15-C step 4, Decreto 10.997/2022', '2026-01-02', '2027-01-02'),
  ('ART15C_TRACK', 0.013800, 'Art. 15-C step 5, Decreto 10.997/2022', '2027-01-02', '2028-01-02'),
  ('ART15C_TRACK', 0.000000, 'Art. 15-C final step, Decreto 10.997/2022', '2028-01-02', '9999-12-31');
```

No application code, no cron job, no redeployment — the right rate is always returned by the query.

**When a new decree changes a future step** (as Decreto 11.547/2023 did for credit cards):
1. Update the `valid_to` of the affected pre-seeded row to `now()` (or the decree's effective date)
2. Insert a new row with the new rate and `valid_from = decree_effective_date`
3. The pre-seeded rows for subsequent steps remain unchanged if they were not affected

---

## Rate Classification Lookup — Priority Ordering

The classification table uses a `priority` column for conflict resolution. The lookup finds the most specific matching rule:

```sql
SELECT c.rate_key, c.legal_basis, c.id AS classification_id
FROM tax.iof_fx_classification c
WHERE c.natureza_group = :naturezaGroup
  AND (c.instrument = :instrument OR c.instrument IS NULL)
  AND (c.direction = :direction OR c.direction IS NULL)
  AND c.valid_from <= :settlementDate
  AND c.valid_to > :settlementDate
ORDER BY c.priority ASC
LIMIT 1;
```

Rule: lower priority number = higher precedence. A specific rule (priority 10) overrides the catch-all DEFAULT (priority 99).

Example: if a new decree creates a special rate for `IMPORT_SERVICES via WIRE OUTBOUND`, that rule gets priority 10. The existing `DEFAULT` rule (priority 99) is unaffected and still catches everything else.

---

## IOF Computation — Full Algorithm

```java
public IofComputationResult computeIof(
        String naturezaGroup,
        String instrument,
        String direction,
        BigDecimal fxAmountBrl,
        Instant settlementDate) {

    // 1. Find the matching classification rule
    IofClassification classification = classificationRepo.findActive(
        naturezaGroup, instrument, direction, settlementDate)
        .orElseThrow(() -> new IofClassificationNotFoundException(...));

    // 2. Find the rate for that rule key at settlement time
    IofRateSchedule rateSchedule = rateRepo.findByKeyAndDate(
        classification.getRateKey(), settlementDate)
        .orElseThrow(() -> new IofRateNotFoundException(...));

    // 3. Compute IOF amount
    BigDecimal rate = rateSchedule.getRate();
    BigDecimal iofAmount = fxAmountBrl
        .multiply(rate)
        .setScale(2, RoundingMode.HALF_UP);

    // 4. Return result with full audit fields
    return IofComputationResult.builder()
        .rateKey(classification.getRateKey())
        .rate(rate)
        .isExempt(rateSchedule.isExempt())
        .iofAmountBrl(iofAmount)
        .legalBasis(rateSchedule.getLegalBasis())
        .classificationId(classification.getId())
        .rateScheduleId(rateSchedule.getId())
        .build();
}
```

---

## Transaction-Level Audit Table

Every FX transaction that computes IOF must store the result immutably:

```sql
CREATE TABLE tax.iof_transaction (
    id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    ledger_tx_id      VARCHAR(100)  NOT NULL UNIQUE,  -- mini-core transaction_id (string)
    operation_type    VARCHAR(50)   NOT NULL,
    natureza_group    VARCHAR(50)   NOT NULL,
    instrument        VARCHAR(30),
    direction         VARCHAR(10)   NOT NULL,
    fx_amount_brl     NUMERIC(20,8) NOT NULL,  -- the IOF tax base
    iof_rate          NUMERIC(8,6)  NOT NULL,
    iof_amount_brl    NUMERIC(20,8) NOT NULL,
    is_exempt         BOOLEAN       NOT NULL DEFAULT false,
    rate_key          VARCHAR(50)   NOT NULL,
    classification_id UUID          NOT NULL,  -- snapshot FK (intentionally not REFERENCES)
    rate_schedule_id  UUID          NOT NULL,  -- snapshot FK
    legal_basis       VARCHAR(500)  NOT NULL,  -- denormalised — self-contained audit record
    settled_at        TIMESTAMPTZ   NOT NULL,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT now()
);
```

**Why denormalised `legal_basis`?** The audit record must be self-contained. If a classification or rate schedule row is superseded and archived, the transaction record still carries the complete legal citation as it was at settlement time. A tax auditor examining a 3-year-old transaction does not need to query the classification tables — the transaction record itself is the audit artifact.

**Why no FK constraint on `classification_id` and `rate_schedule_id`?** These are snapshot references — they point to the rows that were used at the time. Those rows may be closed (have a `valid_to` in the past) but should not be deleted. Soft FKs (stored IDs without a DB constraint) allow the reference to survive even if the referenced tables are ever restructured.

---

## Storing IOF in Transaction Metadata

IOF computation results should also be stored in the transaction's metadata blob (alongside conversion rates, fee amounts, etc.) for the transaction display layer:

```json
{
  "schema_version": 1,
  "from_currency": "BRL",
  "to_currency": "USD",
  "from_amount": "8700.00",
  "to_amount": "1500.00",
  "fx_rate": "5.8000",
  "iof_rate": "0.011000",
  "iof_amount_brl": "95.70",
  "iof_is_exempt": false,
  "iof_rate_key": "WIRE_RESIDENT_OUTBOUND",
  "iof_legal_basis": "Art. 15-B XXI, Decreto 6.306/2007 (Decreto 11.153/2022)",
  "iof_natureza_group": "STUDENT_SUPPORT"
}
```

---

## Handling Decree Changes at Runtime

When a new decree changes an IOF rate:

### Case: Rate change (existing rate_key gets a new value)
1. Set `valid_to = decree_effective_date` on the current active row for that `rate_key`
2. Insert new row: `rate_key`, new rate, new `valid_from = decree_effective_date`, `valid_to = '9999-12-31'`
3. For Art. 15-C pre-seeded future rows affected by the change: update their `valid_to` accordingly

### Case: New inciso added to Art. 15-B (new rate_key)
1. Insert new row in `tax.iof_rate_schedule` with the new `rate_key`
2. Insert new row in `tax.iof_fx_classification` mapping the affected natureza to the new `rate_key`

### Case: Inciso removed or merged
1. Close the affected `tax.iof_fx_classification` row (`valid_to = decree_effective_date`)
2. Insert new classification row pointing to the appropriate rate_key
3. The old rate_schedule rows are not deleted — they are needed for historical audit

### What never changes
- Historical `tax.iof_transaction` rows are **immutable**
- Closed classification and rate rows are **archived, not deleted**
- `legal_basis` on transaction rows is **never updated retroactively**

---

## Multi-Jurisdiction Extension

The schema generalises to other jurisdictions by adding a `jurisdiction` column:

```sql
ALTER TABLE tax.iof_fx_classification ADD COLUMN jurisdiction VARCHAR(10) NOT NULL DEFAULT 'BRA';
ALTER TABLE tax.iof_rate_schedule ADD COLUMN jurisdiction VARCHAR(10) NOT NULL DEFAULT 'BRA';
```

A UK-based FTT (Financial Transaction Tax) or US FinCEN assessment would have separate classification and rate rows under `jurisdiction = 'GBR'` or `'USA'`. The computation algorithm queries by jurisdiction first.

---

## Testing Checklist

When implementing the IOF computation service, test:

- [ ] Rate at a historical date returns the correct Art. 15-C step (e.g., 2024-06-15 → 4.38%)
- [ ] Rate at a future pre-seeded date returns the correct step (e.g., 2027-03-01 → 1.38%)
- [ ] Credit card purchase returns 0% for any date ≥ 2023-10-26 and 5.38% for 2023-06-01
- [ ] Import goods returns 0% with `is_exempt = true`
- [ ] Import goods and import services return different rates (0% isenção vs 1.10%)
- [ ] `DEFAULT` catch-all returns 0.38% for any unknown natureza group
- [ ] Missing rate_key throws an error, not silently returns 0
- [ ] IOF amount is rounded `HALF_UP` to 2 decimal places on BRL amount
- [ ] Historical transaction audit reproduces the exact same result as at settlement time
- [ ] Decree change (closing one row, inserting another) does not affect past transaction audit records
