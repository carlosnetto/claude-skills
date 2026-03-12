---
name: brazil-iof-tax
description: Comprehensive reference for IOF (Imposto sobre Operações Financeiras) in Brazil. Covers FX operations (câmbio), credit operations, rate schedules, legal basis, BCB natureza da operação classification, Art. 15-C phased reductions through 2029, 2023 legislative events, and system design patterns for computing, storing, and auditing IOF.
user-invocable: false
---

# Brazil IOF Tax — Reference Guide

You are an expert on Brazil's IOF (Imposto sobre Operações Financeiras). You help engineers, architects, and product teams understand the IOF rules well enough to build compliant fintech systems — covering rate determination, legal basis, data modelling, and audit requirements.

## Operating Procedure

1. When the user asks about IOF, FX taxation in Brazil, outbound wire transfers, international cards, credit operations, or related compliance topics, load the relevant topic file(s) from the `topics/` directory.
2. Always cite the specific legal basis (Decreto, artigo, inciso) alongside every rate or rule.
3. Distinguish clearly between **isenção** (Art. 16 — no taxable event) and **alíquota zero** (Art. 15-B — taxable event exists, rate is 0%). Both result in zero payment but have different legal weight.
4. Flag contested interpretations (e.g., IOF on imported services) and recommend tax counsel for those cases.
5. For system design questions, load `topics/system-design.md`.

## Topic Files

| File | Contents |
|---|---|
| `topics/legal-framework.md` | Constitutional basis, key decrees, taxable event, tax base, responsible party, PF vs PJ rules |
| `topics/fx-rates.md` | All Art. 15-B incisos with current rates, Art. 15-C phased reduction schedule (2023–2029), 2023 legislative events |
| `topics/fx-natureza.md` | BCB natureza da operação system, RD Câmbio, how declared purpose maps to Art. 15-B inciso |
| `topics/fx-exemptions.md` | Art. 16 isenções, zero-rate vs exempt distinction, practical examples |
| `topics/credit-iof.md` | IOF on credit operations (Art. 7): PF/PJ distinction, daily rate, revolving credit, exempt products |
| `topics/practical-scenarios.md` | Worked examples with full rate derivation for common fintech scenarios |
| `topics/system-design.md` | Data model for IOF computation, temporal rate schedules, pre-seeding Art. 15-C, audit trail, integration with FX and transaction services |

## Quick Reference — FX IOF Rates (2025)

> Full legal citations and rate history: `topics/fx-rates.md`

| Scenario | Rate | Legal Basis |
|---|---|---|
| International credit card purchase | **0%** | Art. 15-B VII/XXII — Decreto 11.547/2023 |
| Outbound wire transfer by resident | **1.10%** | Art. 15-B XXI — Decreto 11.153/2022 |
| Purchase of foreign banknotes (tourism) | **1.10%** | Art. 15-B XX |
| ATM cash withdrawal abroad | **3.38%** | Art. 15-B IX + Art. 15-C step 3 |
| International prepaid card loading | **3.38%** | Art. 15-B X + Art. 15-C step 3 |
| Export revenue inflow | **0%** | Art. 15-B I (permanent) |
| Payment for imported goods | **0%** | Art. 16 I — isenção (not alíquota zero) |
| Foreign investor in Brazilian instruments | **0%** | Art. 15-B XVI (permanent) |
| Dividend remittance to foreign shareholder | **0%** | Art. 15-B XIII (permanent) |
| Short-term foreign loan (< 180-day avg.) | **6.00%** | Art. 15-B XII |
| All other FX (residual) | **0.38%** | Art. 15-B (base rate) |

## Art. 15-C Reduction Track (pre-legislated)

Applies to ATM withdrawals abroad (inciso IX), prepaid card loading (inciso X), and payment arrangement operators (inciso XXII — but credit card purchases were separately zeroed in Oct 2023).

| Period | Rate |
|---|---|
| 2023-01-02 → 2024-01-01 | 5.38% |
| 2024-01-02 → 2025-01-01 | 4.38% |
| **2025-01-02 → 2026-01-01** | **3.38% ← current** |
| 2026-01-02 → 2027-01-01 | 2.38% |
| 2027-01-02 → 2028-01-01 | 1.38% |
| 2028-01-02 → | **0%** |

## Critical Distinctions

| Concept | What it means | Why it matters |
|---|---|---|
| **Isenção** (Art. 16) | No taxable event — the tax never arises | Cannot be reversed by rate decree; requires legislative change |
| **Alíquota zero** (Art. 15-B) | Taxable event exists; rate is 0% | Executive can raise it by decree without Congress |
| **No PF/PJ distinction** | For FX IOF, individuals and companies pay the same rate | Unlike credit IOF where PJ pays higher daily rates |
| **Tax base is BRL** | IOF is computed on the BRL equivalent at the contracted rate, not the foreign currency amount | Matters for FX volatility and rate calculation order |
| **Responsible party** | The authorized FX dealer withholds and remits — not the customer | Platform must know whether it is the dealer or just the originator |
