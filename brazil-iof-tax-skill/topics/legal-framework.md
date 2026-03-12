# IOF Legal Framework

## Constitutional Basis

IOF is a federal tax (imposto federal) levied by the Union (União). Its constitutional authority is:

- **Constituição Federal de 1988, Art. 153, V** — grants the Union competence to levy IOF on "operações de crédito, câmbio e seguro, ou relativas a títulos ou valores mobiliários"
- **CF Art. 153, §1º** — grants the Executive the power to alter IOF rates by decree, without going through Congress (the same exceptional flexibility applies to II, IE, and IPI). This makes IOF a macroeconomic policy tool: the President can raise or lower rates overnight.

The maximum rate for FX operations is **25%** (Lei nº 8.894/1994). The current rates are well below this ceiling, giving the government ample room for rate policy without needing a new law.

## Primary Regulatory Instrument

**Decreto nº 6.306, de 14 de dezembro de 2007** is the consolidated regulation for all IOF operations. It is amended by subsequent decrees, never replaced wholesale. Key articles for FX:

| Article | Content |
|---|---|
| Art. 11 | Defines the four IOF operation types: crédito, câmbio, seguro, títulos e valores mobiliários |
| Art. 12 | **Taxpayer (contribuinte):** the buyer or seller of foreign currency |
| Art. 13 | **Responsible party (responsável):** the authorized FX dealer (institution) — withholds and remits |
| Art. 14 | **Tax base (base de cálculo):** the BRL equivalent at the contracted exchange rate |
| Art. 15 | Maximum rate: **25%** |
| **Art. 15-B** | All FX rates by inciso (I through XXIII+) |
| **Art. 15-C** | Phased reduction schedule for cross-border payment arrangement incisos (introduced by Decreto 10.997/2022) |
| Art. 16 | **Isenções:** legally exempt operations (no taxable event) |

## Key Amending Decrees — Chronological

| Decree | Date | Material Change |
|---|---|---|
| Decreto nº 6.306/2007 | 2007-12-14 | Primary regulation — establishes Art. 15-B base structure |
| Decreto nº 8.325/2014 | 2014 | Revoked old Art. 15-A; consolidated FX rate structure |
| Decreto nº 10.997/2022 | 2022 | Introduced Art. 15-C: legislated annual rate reductions for cross-border payment arrangements through 2029 |
| Decreto nº 11.153/2022 | 2022 | Set Art. 15-B XXI (resident outbound wire) to 1.10% |
| Decreto nº 11.374/2023 | 2023-01-01 | Revoked Bolsonaro-era premature zeroing decrees; restored Art. 15-C rates for 2023 (credit card back to 5.38%) |
| Decreto nº 11.547/2023 | 2023-10-25 | Zeroed Art. 15-B VII and XXII (credit card FX settlements) ahead of Art. 15-C schedule; effective 2023-10-26 |

## Enabling Statutes

- **Lei nº 5.172/1966 (CTN), Art. 63** — defines the taxable event: settlement (liquidação) of a foreign exchange contract
- **Lei nº 8.894/1994** — rate ceiling authority
- **Resolução BCB nº 277/2022 + IN BCB nº 183/2022** — govern the RD Câmbio system (FX contract registration, natureza da operação codes)

## Taxable Event (Fato Gerador)

The IOF taxable event on FX is the **settlement (liquidação) of a foreign exchange contract** — the moment the BRL is delivered against the foreign currency.

Consequences:
- No FX contract = no taxable event. Transactions that never create a formal FX contract (e.g., transfers between foreign currency accounts held abroad) are not subject to IOF.
- The contract must be registered in Brazil's RD Câmbio system for the taxable event to be formally recognised. The authorized FX dealer (banco, corretora de câmbio, fintech with BCB authorization) performs this registration.
- **Delivery date vs. contract date:** IOF is computed at the settlement rate (the rate on the day of delivery), not the rate on the contract date. For spot transactions these are the same. For forward contracts, they differ.

## Tax Base (Base de Cálculo)

The tax base is the **BRL equivalent** of the FX operation, computed at the contracted exchange rate (Art. 14, Decreto 6.306/2007):

```
tax_base = foreign_currency_amount × contracted_exchange_rate_BRL_per_unit
iof_amount = tax_base × applicable_rate
```

Important: IOF is computed on BRL, **not** on the foreign currency amount. The USD amount is irrelevant; what matters is how many reais changed hands.

**Example:** Outbound wire of USD 1,000 at BRL 5.00 per USD
- Tax base = R$ 5,000.00
- IOF rate = 1.10% (Art. 15-B XXI)
- IOF = R$ 5,000.00 × 0.0110 = **R$ 55.00**

## Taxpayer vs. Responsible Party

| Role | Portuguese | Who | Obligation |
|---|---|---|---|
| Taxpayer | Contribuinte | The buyer or seller of foreign currency (the customer) | Bears the economic burden of the tax |
| Responsible party | Responsável tributário | The authorized FX dealer (bank, fintech, exchange) | Withholds from customer, remits to Receita Federal |

The customer **never pays IOF directly** to Receita Federal. The institution withholds it at the time of FX settlement and remits it (typically via DCTF periodic declaration). The customer sees IOF as a line item on their FX contract or statement.

A fintech platform that is not itself an authorized FX dealer settles FX through a partner institution. In that structure:
- The partner institution is the responsible party for IOF collection
- The platform is the **originator** — it informs the partner of the declared purpose (natureza da operação)
- IOF is collected by the partner; the platform may or may not surface it separately to the end customer depending on how the product is structured

## PF vs. PJ Distinction

**For FX IOF: there is no distinction.** Art. 15-B rates apply uniformly to natural persons (pessoa física, PF) and legal entities (pessoa jurídica, PJ) alike.

This is in sharp contrast to **credit IOF** (Art. 7), where:
- PF: 0.0082% per day + 0.38% flat on new credit
- PJ: 0.0041% per day + 0.38% flat (half the PF daily rate)

For any FX question, PF/PJ is irrelevant. For any credit question, PF/PJ is critical.

## Receita Federal vs. Banco Central do Brasil

These two authorities have overlapping but distinct roles in FX operations:

| Authority | Role |
|---|---|
| **Receita Federal do Brasil (RFB)** | Administers and collects IOF. Sets rules for IOF via Decreto (delegated to President). Audits compliance. |
| **Banco Central do Brasil (BCB)** | Regulates the FX market. Authorizes FX dealers. Requires RD Câmbio contract registration. Defines natureza da operação codes. Does not collect IOF. |
| **Conselho Monetário Nacional (CMN)** | Sets monetary and FX policy framework; BCB implements within CMN guidelines. |

Both the natureza code (BCB domain) and the IOF rate (RFB domain) are determined at the time the FX contract is registered. The authorized dealer applies the correct rate based on the declared natureza.
