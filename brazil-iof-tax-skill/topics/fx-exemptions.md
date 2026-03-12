# IOF FX Exemptions — Art. 16 Isenções

## Isenção vs. Alíquota Zero — A Critical Distinction

Both result in zero IOF payment, but they are legally very different:

| | Isenção (Art. 16) | Alíquota Zero (Art. 15-B) |
|---|---|---|
| **Legal nature** | No taxable event — the tax obligation never arises | Taxable event exists; rate is 0% |
| **How to change** | Requires a Congressional law (Lei ordinária) | Executive can change by decree overnight |
| **Audit treatment** | No IOF line on the contract | IOF line present, amount = R$ 0.00 |
| **Future risk** | High legal certainty — harder to reverse | Zero rate can be raised by Presidential decree without Congress |
| **Example** | Import of goods (Art. 16 I) | Credit card abroad (Art. 15-B VII, zeroed by Decreto 11.547/2023) |

### Practical implication for systems

When storing the result of an IOF computation:
- `is_exempt = true` + `rate = 0.0000` → isenção; legal basis must cite Art. 16, not Art. 15-B
- `is_exempt = false` + `rate = 0.0000` → alíquota zero; legal basis cites Art. 15-B and the zeroing decree

The distinction must be preserved in audit records. A tax auditor examining historical transactions will expect isenção records to cite Art. 16 and alíquota zero records to cite Art. 15-B with the specific decree that set the rate to zero.

---

## Art. 16 — Complete Isenção List

**Decreto 6.306/2007, Art. 16** lists operations that are fully exempt from IOF. These are permanent unless removed by a new law (not a decree).

| Art. 16 Item | Operation | Notes |
|---|---|---|
| **Art. 16, I** | **Payment for imported goods (mercadorias importadas)** | The most commercially significant exemption. Covers CIF and FOB import payments. Goods only — imported services are NOT covered here. |
| Art. 16, II | Operations by foreign diplomatic missions and officials | Consulates, embassies, accredited diplomatic staff |
| Art. 16, III | Operations by international organizations with headquarters agreements (sede) in Brazil | UN agencies, multilateral banks with HQ in Brazil |
| Art. 16, IV | Operations under bilateral or multilateral agreements in which Brazil has expressly committed to exemption | MERCOSUL instruments, IDA/IBRD framework agreements |
| Art. 16, V | Donations from abroad for disaster relief or humanitarian purposes | Narrowly applied; requires BCB evidence |
| Art. 16, VI | Operations by the Banco Central do Brasil itself in the FX market | BCB interventions |

### Art. 16 I in Detail — Imported Goods

This is the exemption that matters most for fintech and trade finance platforms:

- **Covers:** Payment for imported goods. The BCB natureza group is Group 02 (importação de bens/mercadorias).
- **Does not cover:** Imported services (legal services, software licenses, consulting, SaaS subscriptions, freight paid separately to a foreign carrier, royalties). Services fall under Art. 15-B XXI (outbound wire, 1.10%) or the residual 0.38%.
- **Goods vs. services boundary:** Brazilian tax law follows the general CTN distinction. Physical goods with a customs declaration (DI — Declaração de Importação) qualify. Pure services without any physical component do not. Mixed contracts (e.g., equipment purchase + installation/training) may need legal analysis.
- **Documentation:** An import invoice (fatura comercial) and customs declaration (Declaração de Importação / DI in SISCOMEX) are typically required as evidence.

**Why "goods" are exempt but "services" are not:**

Brazil's tax policy treats import of goods and services differently:
- Imported goods are already subject to II (Import Duty), IPI, ICMS-Importação, PIS-Importação, and COFINS-Importação at the border. Adding IOF on top was considered cumulative.
- Imported services are not subject to II/IPI at the border (though CIDE-Tecnologia, PIS, COFINS, and ISS may apply). The IOF on the FX contract is considered one of several levies on service imports.

---

## Near-Zero and Instrument-Zeroed Rates That Are NOT Isenção

These operations have 0% IOF but through **alíquota zero** (Art. 15-B), not exemption:

| Operation | Legal Path to Zero | Reversal Risk |
|---|---|---|
| International credit card purchases | Decreto 11.547/2023 zeroed Art. 15-B VII/XXII | High: could be reversed by Presidential decree |
| Foreign investor buying Brazilian instruments | Art. 15-B XVI — permanent alíquota zero | Moderate: would require a decree change |
| Export revenue inflow | Art. 15-B I — permanent alíquota zero | Moderate |
| Dividend/profit remittance to foreign shareholder | Art. 15-B XIII — permanent alíquota zero | Moderate |
| Qualifying foreign loans | Art. 15-B XI — permanent alíquota zero | Moderate |

"Permanent" here means the decree provision has no sunset clause — not that it is constitutionally protected. The Executive can always issue a new decree. Historical precedent shows these permanent zeros are politically stable (they facilitate foreign investment), but they are not legally untouchable the way a Congressional isenção is.

---

## Commonly Confused Cases

### SaaS subscriptions and software licenses paid to foreign vendors

- **Category:** Imported services (not goods)
- **Natureza:** typically Group 05 (services)
- **IOF:** Art. 15-B XXI — **1.10%** (contested by some — see imported services note in fx-rates.md)
- **NOT covered** by Art. 16 I (which is goods only)

### Freight (frete internacional)

- If paid as part of a CIF import contract to the same foreign supplier: arguably part of the goods transaction → Art. 16 I (exempt)
- If paid separately to a foreign freight company: imported service → Art. 15-B XXI (1.10%)
- The boundary is fact-specific; legal counsel recommended for material amounts

### Royalties and intellectual property licensing

- **Category:** Imported services / financial income (depending on structure)
- **IOF:** Art. 15-B XXI or residual 0.38% — not exempt
- CIDE-Tecnologia (10%) may also apply in parallel

### Foreign currency account transfers (e.g., between two Wise accounts)

- If both accounts are held abroad (no Brazilian FX contract): **no IOF taxable event**
- If the transfer involves a Brazilian FX contract registration: IOF applies based on natureza
- Many global account products (Nomad, Wise, Remessa Online) are structured to avoid creating a Brazilian FX contract, which is why their customers pay 0% IOF even on what looks like an FX operation

### PIX Internacional

BCB's framework for cross-border PIX (Instant Payment System extended to FX):
- If the FX contract is registered in Brazil: IOF applies per natureza code
- Rate depends on declared purpose: typically Art. 15-B XXI (1.10%) for outbound personal transfers
- BCB is still developing the regulatory framework; monitor for changes
