# Natureza da Operação — BCB Classification System

## What Is Natureza da Operação?

Every foreign exchange contract settled in Brazil must declare a **natureza da operação** (operation nature/purpose code). This is the BCB-level classification that:

1. Identifies the economic purpose of the FX transaction
2. Determines which Art. 15-B inciso applies
3. Is recorded in the RD Câmbio (Registro Declaratório Câmbio) system
4. Is used by Receita Federal for IOF audits and BCB for balance of payments statistics

The natureza code is **assigned by the authorized FX dealer** (banco, corretora de câmbio, fintech with BCB authorization) based on the purpose declared by the customer. If the customer lies about the purpose to get a lower rate, the customer bears the legal risk — but the institution is also at risk if it fails to conduct adequate due diligence.

## Regulatory Basis

The RD Câmbio system replaced the older SISBACEN FX registration system. It is governed by:
- **Resolução BCB nº 277/2022** — establishes the RD Câmbio framework
- **Instrução Normativa BCB nº 183/2022** — defines the technical specifications, natureza code hierarchy, and documentation requirements
- **Circular BCB nº 3.691/2013** (partially superseded) — prior rules for FX contract documentation

The complete official list of natureza codes is published by BCB on its regulatory portal (normativos.bcb.gov.br) and updated periodically as new operation types are recognised.

## Natureza Code Hierarchy

Natureza codes are structured hierarchically:

```
Grupo (Group) — broad economic category
└── Subgrupo (Subgroup) — narrower economic segment
    └── Natureza (Specific code) — precise operation type
```

Example hierarchy:
```
Group 01 — Exportação de bens (goods export)
  Subgroup 01.01 — Exportação de mercadorias
    Natureza 01.01.01 — Exportação com câmbio contratado antecipadamente
    Natureza 01.01.02 — Exportação com câmbio contratado concomitantemente

Group 05 — Serviços (services)
  Subgroup 05.04 — Viagens internacionais (international travel)
    Natureza 05.04.01 — Cartão pré-pago / prepaid card
    Natureza 05.04.02 — Compra de moeda espécie / cash purchase

Group 09 — Transferências unilaterais (unilateral transfers)
  Subgroup 09.01 — Transferências de pessoas físicas
    Natureza 09.01.01 — Manutenção de residentes no exterior
    Natureza 09.01.02 — Doações e heranças
```

The precise code table is BCB's authoritative reference (bcb.gov.br portal, IN BCB 183/2022 annexes). The codes are updated annually.

## How Natureza Maps to IOF Rate

The relationship between natureza code/group and IOF rate is **indirect**: the natureza determines which Art. 15-B inciso applies, and the inciso determines the rate.

| Natureza Category | Art. 15-B Inciso | IOF Rate (2025) |
|---|---|---|
| Export revenue (bens e serviços) | I | 0% |
| Import goods (mercadorias) | Art. 16 I (isenção) | 0% (exempt) |
| Import services | XXI (contested) | 1.10% |
| Foreign investment inflow (capital) | XVI | 0% |
| Foreign investment outflow (repatriation) | XVII | 0% |
| Foreign investment outflow (new direct investment) | XVI | 0% |
| Profit/dividend/JCP remittance | XIII | 0% |
| Foreign loans — qualifying (≥ 180-day avg.) | XI | 0% |
| Foreign loans — short-term (< 180-day avg.) | XII | 6.00% |
| International travel — credit card settlement | VII / XXII | 0% (Decreto 11.547/2023) |
| International travel — ATM withdrawal | IX | 3.38% (Art. 15-C) |
| International travel — prepaid card | X | 3.38% (Art. 15-C) |
| International travel — cash (espécie) purchase | XX | 1.10% |
| Outbound resident wire (personal, student, medical) | XXI | 1.10% |
| Interbank operations | II | 0% |
| All other | *(base rate)* | 0.38% |

## Platform Natureza Groups (Simplified Mapping)

For a fintech platform that does not need the full BCB code hierarchy, a simplified set of **platform natureza groups** can be used internally. These map unambiguously to Art. 15-B incisos. The authorized FX dealer converts the platform's category into the precise BCB natureza code when registering the contract.

| Platform Group | Description | BCB Group (approximate) | Art. 15-B | IOF |
|---|---|---|---|---|
| `IMPORT_GOODS` | Payment for imported goods | Group 02 (imports) | Art. 16 I | 0% exempt |
| `IMPORT_SERVICES` | Payment for imported services | Group 05 (services) | XXI | 1.10% |
| `EXPORT_PROCEEDS` | Inbound export revenue | Group 01 (exports) | I | 0% |
| `PERSONAL_TRANSFER` | Family maintenance abroad | Group 09 (unilateral) | XXI | 1.10% |
| `STUDENT_SUPPORT` | Support for student abroad | Group 09 (unilateral) | XXI | 1.10% |
| `MEDICAL_TREATMENT` | Medical treatment abroad | Group 05 (services) | XXI | 1.10% |
| `TOURISM_CASH` | Buying foreign banknotes | Group 05.04 (travel) | XX | 1.10% |
| `TOURISM_PREPAID_CARD` | Loading prepaid international card | Group 05.04 (travel) | X | 3.38% |
| `CREDIT_CARD_SETTLEMENT` | Credit card FX settlement | Group 08 (payment arrangements) | VII / XXII | 0% |
| `ATM_WITHDRAWAL_ABROAD` | ATM cash withdrawal abroad | Group 08 (payment arrangements) | IX | 3.38% |
| `FOREIGN_DIRECT_INVESTMENT` | Investing abroad or repatriating | Group 07 (capital flows) | XVI / XVII | 0% |
| `DIVIDEND_REMITTANCE` | Remitting profits/dividends to foreign shareholder | Group 04 (income) | XIII | 0% |
| `FOREIGN_LOAN_QUALIFYING` | Drawing down or repaying a qualifying foreign loan | Group 06 (financing) | XI | 0% |
| `FOREIGN_LOAN_SHORT_TERM` | Drawing down a short-term foreign loan | Group 06 (financing) | XII | 6.00% |
| `DEFAULT` | Any other purpose | *(base)* | *(base)* | 0.38% |

## Customer Purpose Declaration

The platform must collect the purpose from the customer for outbound wire transfers. **The institution cannot simply assume a purpose.** BCB requires documentation proportional to the transaction amount:

| Amount (USD equivalent) | Typical documentation |
|---|---|
| Up to ~USD 3,000 | Self-declaration by customer sufficient (simplified procedures per Resolução CMN 3.568/2008 and successors) |
| USD 3,001 – USD 10,000 | Supporting documentation may be requested (invoice, enrollment letter, medical referral) |
| Above USD 10,000 | Documentation typically required; COAF reporting threshold considerations |
| Above USD 100,000 | Enhanced due diligence; BCB reporting obligations |

> Note: Documentation thresholds are set by BCB regulation and change over time. Always verify current thresholds with the authorized FX dealer or legal counsel.

## Instrument-Deterministic Cases

Some operation types are determined entirely by the payment **instrument** — no customer purpose declaration is needed because the instrument itself identifies the natureza:

| Instrument | Natureza Determined By | IOF Rate |
|---|---|---|
| Credit card (international purchase) | Card network settlement | 0% (since Oct 2023) |
| Debit/credit card ATM withdrawal abroad | Card network settlement | 3.38% |
| International prepaid card loading | Prepaid card product type | 3.38% |
| Foreign currency cash (espécie) exchange | FX desk transaction type | 1.10% |

For these, the institution assigns the natureza code automatically. The customer does not choose.

## Balance of Payments (BoP) Usage

BCB's balance of payments statistics are compiled from natureza code data across all registered FX contracts. This is a secondary use of the same natureza system. While BoP accuracy is BCB's concern, the platform's accurate natureza classification contributes to national statistics and incorrect declarations can attract BCB scrutiny beyond just the IOF audit.
