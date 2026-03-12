# IOF on Credit Operations (Art. 7)

> This topic covers IOF on **credit operations** — a completely separate regime from FX IOF. Do not confuse them. The PF/PJ distinction, the daily rate structure, and the applicable article are all different.

## Legal Basis

**Decreto 6.306/2007, Art. 7** — covers IOF on credit operations (operações de crédito). Unlike FX IOF (Art. 15-B), credit IOF has:
- Different rates for natural persons (PF) and legal entities (PJ)
- A **daily rate** applied to the outstanding balance over the loan term, in addition to a flat rate on the principal
- No Art. 15-C scheduled reductions
- A broader set of exempt products

## Rate Structure

Credit IOF has two components that are always charged together:

### Component 1 — Daily Rate (Alíquota Diária)

Applied to the **outstanding balance** for each day the credit is outstanding, up to a maximum of 365 days.

| Taxpayer Type | Daily Rate | Annual Equivalent (approx.) |
|---|---|---|
| **Pessoa Física (PF)** | **0.0082% per day** | ~3.00% per year |
| **Pessoa Jurídica (PJ)** | **0.0041% per day** | ~1.50% per year |

The daily rate is computed on the outstanding principal. For a fixed-term loan, the IOF is front-loaded (calculated on the full term up front) and collected at disbursement, up to a maximum of 365 days. For revolving credit (credit card), it is assessed monthly on the average daily balance.

**Maximum daily IOF** (cap): 365 days × daily rate. After 365 days, no further daily IOF accrues regardless of loan duration.

### Component 2 — Flat Rate (Alíquota Adicional)

A one-time flat charge on the **principal amount** disbursed:

| All taxpayer types | Flat Rate |
|---|---|
| All (PF and PJ) | **0.38%** |

This flat rate is the same for PF and PJ. It is the same 0.38% that appears as the residual FX rate — they share the same base decree provision.

### Combined Formula

```
IOF_total = principal × flat_rate + principal × daily_rate × min(term_days, 365)

Example: PF personal loan of R$ 10,000 for 180 days
  Flat:  R$ 10,000 × 0.0038 = R$  38.00
  Daily: R$ 10,000 × 0.000082 × 180 = R$ 147.60
  Total: R$ 185.60  (effective rate: 1.856%)
```

For revolving credit (credit card bill not paid in full):
```
IOF_monthly = avg_daily_balance × 0.000082 × days_in_period  (for PF)
```

## Credit Card — IOF Treatment (Domestic)

When a Brazilian credit card is used domestically and the invoice is not paid in full (revolving balance):
- IOF is charged on the **revolving balance** at the daily rate (0.0082% per day for PF)
- This is **credit IOF** (Art. 7), not FX IOF (Art. 15-B)
- It appears on the credit card statement as "IOF" or "IOF de crédito"
- The card issuer is the responsible party; it is collected monthly

When the same card is used internationally (FX component):
- The **FX IOF** (Art. 15-B VII/XXII) was 0% since October 2023
- The domestic **credit IOF** on revolving balance is separate and unchanged
- Two different IOF regimes apply to the same card, for different aspects

## Exempt Credit Products

Several credit products are exempt from IOF on credit under Art. 8 (isenções — credit):

| Product | Exemption basis |
|---|---|
| Rural credit (crédito rural) — financing agricultural production | Art. 8 — longstanding policy support for agribusiness |
| Export financing (Financiamento à exportação) — funds tied to export contracts | Art. 8 — promotes exports |
| FGTS (Fundo de Garantia do Tempo de Serviço) — worker severance fund withdrawals | Art. 8 — social policy |
| Social housing (habitação popular) — below-income-threshold mortgage programs | Art. 8 |
| Operations by Banco Nacional de Desenvolvimento Econômico e Social (BNDES) | Art. 8 — development bank |
| Microfinance (crédito popular / microcrédito) — small loans to low-income borrowers | Art. 8 — financial inclusion |
| Mortgage-backed securities operations under SFH (Sistema Financeiro da Habitação) | Art. 8 |

## Key Differences: Credit IOF vs FX IOF

| Dimension | FX IOF (Art. 15-B) | Credit IOF (Art. 7) |
|---|---|---|
| **Taxable event** | Settlement of FX contract | Disbursement of credit |
| **Tax base** | BRL equivalent of FX operation | Outstanding credit balance (daily) + principal (flat) |
| **PF vs PJ** | **No distinction** — same rate for all | **Critical distinction** — PF pays 2× the daily rate of PJ |
| **Rate structure** | Single rate per operation type | Flat + daily rate, up to 365 days |
| **Art. 15-C reductions** | Yes (for cross-border payment arrangements) | No |
| **Responsible party** | Authorized FX dealer | Credit institution (bank, finance company, fintech) |
| **Common rate in 2025** | 0% to 3.38% depending on type | ~2.38% effective annual for PF (daily + flat) |

## When Both Apply: Trade Finance

Some financing operations have both an FX component and a credit component:

**Advance on Foreign Exchange Contract (ACC — Adiantamento sobre Contratos de Câmbio):**
- An exporter receives BRL funding in advance of the export FX settlement
- IOF applies on the credit component (Art. 7, with the qualifying loan provision if ≥ 180-day avg. maturity)
- When the FX contract settles, the FX IOF applies (typically Art. 15-B I — export revenue, 0%)

**Import financing:**
- A company borrows USD from a foreign bank to finance an import payment
- Credit IOF may apply on the loan (Art. 7)
- FX IOF applies when the USD is converted to BRL (or vice versa) at settlement

## IOF in the Fintech Context

### Personal loans via fintech app

If a fintech offers personal loans (crédito pessoal):
- IOF credit (Art. 7, PF rate) is mandatory
- Flat 0.38% + 0.0082% per day × term (max 365 days)
- Must be disclosed to the customer in the CET (Custo Efetivo Total) — the APR equivalent required by BCB

### Buy Now Pay Later (BNPL)

BNPL products where the consumer pays in installments:
- If the merchant is pre-paid and the consumer repays the fintech over time: this is credit → IOF Art. 7 applies
- If the fintech is merely a payment intermediary (consumer pays upfront via financing already contracted with a bank): IOF is the bank's obligation
- Structuring matters significantly for IOF exposure

### Crypto-backed loans

If a fintech lends BRL against crypto collateral:
- This is a domestic credit operation → IOF Art. 7 applies
- The crypto collateral does not change the credit IOF treatment
- If the collateral is liquidated through an FX contract: FX IOF may also arise depending on structure

### "Interest-free" installments (parcelamento sem juros)

When a retailer offers "12× sem juros" (12 installments, zero interest) and pays the card network upfront:
- The card issuer discounts the merchant and extends credit implicitly to the consumer
- IOF technically applies on the implicit credit, but in practice card issuers in Brazil have structured these as IOF-inclusive product pricing
- BCB has periodic guidance on this — monitor for regulatory evolution
