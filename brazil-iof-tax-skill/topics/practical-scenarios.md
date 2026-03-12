# IOF — Practical Scenarios with Full Rate Derivation

All amounts are illustrative. Tax base is always the BRL equivalent at the contracted exchange rate.

---

## Scenario 1: Brazilian student in the US — parent sends money monthly

**Situation:** Parent in Brazil sends USD 1,500/month to support a child studying at a US university. Transaction via SWIFT wire through a Brazilian bank.

**Classification:**
- Direction: OUTBOUND
- Instrument: WIRE
- Natureza group: `STUDENT_SUPPORT`
- Art. 15-B inciso: **XXI** (resident outbound transfer)

**Rate:** 1.10%

**Calculation** (assuming BRL/USD = 5.80):
```
BRL equivalent = USD 1,500 × R$ 5.80 = R$ 8,700.00
IOF = R$ 8,700.00 × 0.0110 = R$ 95.70
Net sent to student account: USD 1,500 minus whatever the bank deducts
```

**Note:** The USD 1,500 is the face amount. IOF is computed on R$ 8,700 (the BRL amount delivered by the parent). The bank withholds R$ 95.70 and remits to Receita Federal. This appears as a line item on the exchange contract.

---

## Scenario 2: Brazilian uses credit card to buy a laptop in the US (in-store)

**Situation:** Brazilian traveling in New York buys a MacBook for USD 1,299 using their Nubank credit card.

**Classification:**
- Direction: OUTBOUND (card network settlement is the FX event)
- Instrument: CREDIT_CARD
- Natureza group: `CREDIT_CARD_SETTLEMENT`
- Art. 15-B inciso: **VII / XXII**

**Rate:** **0%** (since Decreto 11.547/2023, effective October 26, 2023)

**Calculation:**
```
BRL equivalent = USD 1,299 × R$ 5.80 = R$ 7,534.20
IOF = R$ 7,534.20 × 0.0000 = R$ 0.00
```

**Historical note:** Before October 26, 2023, this same purchase would have attracted:
- 5.38% in 2023 (after Decreto 11.374 restored the rate)
- 6.38% before 2023
At 5.38%: IOF = R$ 7,534.20 × 0.0538 = R$ 405.34 — a significant amount on a laptop purchase.

---

## Scenario 3: Brazilian withdraws EUR 200 from ATM in Lisbon

**Situation:** Brazilian tourist withdraws €200 from an ATM in Lisbon using their Brazilian debit card.

**Classification:**
- Direction: OUTBOUND
- Instrument: ATM_WITHDRAWAL
- Natureza group: `ATM_WITHDRAWAL_ABROAD`
- Art. 15-B inciso: **IX** + Art. 15-C

**Rate (2025):** 3.38%

**Calculation** (assuming EUR/BRL = 6.20):
```
BRL equivalent = EUR 200 × R$ 6.20 = R$ 1,240.00
IOF = R$ 1,240.00 × 0.0338 = R$ 41.91
```

**Future trajectory:**
- 2026: 2.38% → IOF = R$ 29.51
- 2027: 1.38% → IOF = R$ 17.11
- 2028+: 0%

---

## Scenario 4: Brazilian buys USD 500 in cash at a câmbio house before travel

**Situation:** Traveler exchanges R$ 2,900 for USD 500 in banknotes (espécie) at a currency exchange desk at GRU airport.

**Classification:**
- Direction: OUTBOUND
- Instrument: CASH (espécie)
- Natureza group: `TOURISM_CASH`
- Art. 15-B inciso: **XX**

**Rate:** 1.10% (NOT on the Art. 15-C track — this is a fixed 1.10%)

**Calculation:**
```
BRL equivalent = R$ 2,900.00 (the BRL the customer delivers — this IS the tax base)
IOF = R$ 2,900.00 × 0.0110 = R$ 31.90
Customer pays: R$ 2,900.00 + R$ 31.90 = R$ 2,931.90 total
```

**Comparison with prepaid card:**
If the traveler loads R$ 2,900 onto an international prepaid card instead:
- Inciso X, Art. 15-C track: 3.38% in 2025
- IOF = R$ 2,900 × 0.0338 = R$ 98.02
Cash is cheaper than prepaid card in 2025 — the reverse of the pre-2023 situation.

---

## Scenario 5: Brazilian company pays for AWS cloud services (SaaS import)

**Situation:** A Brazilian startup pays USD 5,000/month to Amazon AWS (imported cloud services).

**Classification:**
- Direction: OUTBOUND
- Instrument: WIRE (or card — depends on method)
- Natureza group: `IMPORT_SERVICES`
- Art. 15-B inciso: **XXI** (contested — see note)

**Rate:** 1.10% (under Art. 15-B XXI interpretation)

**Calculation** (assuming USD/BRL = 5.80):
```
BRL equivalent = USD 5,000 × R$ 5.80 = R$ 29,000.00
IOF = R$ 29,000.00 × 0.0110 = R$ 319.00/month
Annual IOF: R$ 3,828.00
```

**Note:** Some tax practitioners argue imported services fall under the residual 0.38% rather than Art. 15-B XXI. At 0.38%: IOF = R$ 110.20/month. The dispute is material for large service import contracts. Legal counsel recommended.

**What is NOT applicable:** Art. 16 I (isenção for goods) does not cover services. AWS cloud is a service, not a good, regardless of how it is contracted.

---

## Scenario 6: Brazilian company exports software and receives USD payment

**Situation:** Brazilian software house receives USD 50,000 inbound wire from a US client for software development services.

**Classification:**
- Direction: INBOUND
- Instrument: WIRE
- Natureza group: `EXPORT_PROCEEDS`
- Art. 15-B inciso: **I**

**Rate:** 0% (permanent alíquota zero)

**Calculation:**
```
BRL equivalent = USD 50,000 × R$ 5.80 = R$ 290,000.00
IOF = R$ 290,000.00 × 0.0000 = R$ 0.00
```

No IOF on export revenue. This is a deliberate policy to encourage exports.

---

## Scenario 7: Foreign private equity fund invests in a Brazilian startup

**Situation:** A Cayman Islands PE fund wires USD 2,000,000 into Brazil to subscribe to shares in a Brazilian startup.

**Classification:**
- Direction: INBOUND
- Instrument: WIRE
- Natureza group: `FOREIGN_DIRECT_INVESTMENT`
- Art. 15-B inciso: **XVI**

**Rate:** 0% (permanent alíquota zero)

**Calculation:**
```
IOF = USD 2,000,000 equivalent × 0.0000 = R$ 0.00
```

Zero IOF on foreign investment inflows — one of Brazil's long-standing policies to attract foreign capital. Note: other taxes may apply (e.g., the investment vehicle's eventual income or capital gains), but not IOF on the FX contract itself.

---

## Scenario 8: Brazilian company takes a short-term foreign loan

**Situation:** A Brazilian company borrows USD 500,000 from a foreign bank for 90 days (short-term working capital).

**Classification:**
- Direction: INBOUND (loan drawdown)
- Natureza group: `FOREIGN_LOAN_SHORT_TERM`
- Art. 15-B inciso: **XII** (< 180-day average maturity)

**Rate:** **6.00%** (penalty rate to deter short-term hot money flows)

**Calculation** (assuming USD/BRL = 5.80):
```
BRL equivalent = USD 500,000 × R$ 5.80 = R$ 2,900,000.00
IOF = R$ 2,900,000.00 × 0.0600 = R$ 174,000.00
```

**Why 6%?** Brazil uses this as a capital flow management tool. High IOF on short-term foreign loans discourages speculative "hot money" inflows that can destabilize the exchange rate. This is one of Brazil's traditional macro-prudential measures.

**If the loan were ≥ 180-day average maturity:** Art. 15-B XI (qualifying), 0% → IOF = R$ 0. Structuring the loan to meet the maturity threshold saves R$ 174,000 in IOF — a significant consideration in deal structuring.

---

## Scenario 9: Dividend sent to a foreign shareholder

**Situation:** A Brazilian company distributes R$ 1,000,000 in dividends to its French parent company (France holds 80% equity stake).

**Classification:**
- Direction: OUTBOUND
- Natureza group: `DIVIDEND_REMITTANCE`
- Art. 15-B inciso: **XIII**

**Rate:** 0% (permanent alíquota zero)

**Calculation:**
```
IOF = R$ 1,000,000.00 × 0.0000 = R$ 0.00
```

Note: Brazilian dividends were historically income-tax-exempt at the source (a long-running policy debate in Brazil). As of 2025, dividend distributions remain income-tax-exempt at the Brazilian source for the receiving foreign shareholder, though this has been subject to legislative debate. IOF is separately 0%.

---

## Scenario 10: Crypto exchange — Brazilian resident buys USDC

**Situation:** A Brazilian uses a local crypto exchange (Mercado Bitcoin, Binance Brazil) to buy USDC with BRL.

**Is there an IOF taxable event?**

This depends on the exchange's structure:

**Case A: Exchange registers a formal FX contract in Brazil**
- IOF taxable event exists
- Natureza: typically falls under outbound personal/financial transfer or a specific crypto natureza code
- Rate: likely Art. 15-B XXI (1.10%) or residual 0.38%, depending on BCB guidance and the declared natureza
- IOF base: the BRL amount delivered

**Case B: Exchange holds customer BRL on-platform and uses offshore liquidity, no BCB FX contract**
- No formal FX contract → no IOF taxable event under current CTN interpretation
- The BRL/USDC exchange occurs "off-market" in accounting terms
- Regulatory gray area — BCB is actively clarifying this as crypto market grows

**The 2023 context:** The Bolsonaro zeroing decrees and the Lula reversal partly affected crypto exchanges that *did* register FX contracts, suddenly swinging from 0% → 5.38% → 0% again (for credit cards; crypto wires stayed at 1.10%).

---

## Summary Rate Cheat Sheet (2025)

| Who | Doing what | Rate |
|---|---|---|
| Any resident | Paying with credit card abroad | **0%** |
| Any resident | Withdrawing cash from ATM abroad | **3.38%** |
| Any resident | Loading a prepaid travel card | **3.38%** |
| Any resident | Buying foreign banknotes at a cambio | **1.10%** |
| Any resident | Sending wire abroad (personal, student, medical, services) | **1.10%** |
| Any resident | Receiving export revenue | **0%** |
| Any resident/company | Paying for imported goods | **0% (isenção)** |
| Any resident/company | Paying for imported services | **1.10%** (contested) |
| Brazilian company | Taking a foreign loan ≥ 180-day avg. maturity | **0%** |
| Brazilian company | Taking a foreign loan < 180-day avg. maturity | **6.00%** |
| Brazilian company | Sending dividends abroad | **0%** |
| Foreign investor | Buying Brazilian stocks/bonds | **0%** |
| Any | Unclassified FX | **0.38%** |
