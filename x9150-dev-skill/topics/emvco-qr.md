# EMVCo QR Code Format

## Overview

X9.150 QR codes use the **EMVCo Merchant Presented QR Code** specification — the same format used by Pix (Brazil), PayNow (Singapore), BHIM UPI (India), and others. The QR content is a TLV (Tag-Length-Value) encoded ASCII string ending with a CRC-16 checksum.

App developers typically never construct or parse this string directly — the Digital Channel Backend handles generation, and `/fetch` returns the decoded PaymentRequest. Understanding the format is useful for debugging and building parsers.

---

## TLV Format

Every field is encoded as: `{tag:2 digits}{length:2 digits}{value}`

- **Tag:** 2-digit decimal identifier
- **Length:** 2-digit decimal count of characters in value
- **Value:** ASCII string of exactly `length` characters

Example: `52045812`
- Tag `52` = MCC
- Length `04` = 4 characters
- Value `5812`

Fields can be nested (subtags follow the same TLV format within the parent's value).

---

## Tag Reference

| Tag | Name | Value |
|---|---|---|
| `00` | Payload Format Indicator | Always `"01"` |
| `01` | Point of Initiation Method | `"11"` = static (reusable), `"12"` = dynamic (one-time) |
| `26` | Merchant Account Information | Nested TLV with X9.150 URL |
| `52` | Merchant Category Code | 4-digit MCC |
| `53` | Transaction Currency | ISO 4217 **numeric** code (e.g., `"840"` for USD) |
| `54` | Transaction Amount | Decimal string, 2 decimal places (e.g., `"1.50"`) |
| `58` | Country Code | ISO 3166-1 alpha-2 (e.g., `"US"`) |
| `59` | Merchant Name | Max 25 characters |
| `60` | Merchant City | Max 15 characters |
| `63` | CRC | Always last; 4-char uppercase hex checksum |

### Tag 26 — X9.150 Merchant Account Information

Tag 26 contains a nested TLV with two subtags:

| Subtag | Name | Value |
|---|---|---|
| `00` | Global Unique Identifier | Always `"org.x9"` |
| `01` | Payment URL | Fetch URL with `https://` stripped |

The `org.x9` GUId is what distinguishes X9.150 QR codes from other EMVCo-based formats.

---

## URL Encoding

The `https://` prefix is stripped from the fetch URL. The receiving app prepends `https://` to reconstruct it.

```
Stored in QR:   x9-api.example.com/fetch/a1b2c3d4e5f6789012345678901234ab
Reconstructed:  https://x9-api.example.com/fetch/a1b2c3d4e5f6789012345678901234ab
```

The fetch URL contains the PaymentRequest UUID as the last path segment.

---

## CRC-16 Checksum

The last 4 characters of every X9.150 QR string are a **CRC-16/CCITT-FALSE** checksum. It is computed over the entire string up to and including the `6304` prefix (tag `63`, length `04`), then appended.

Algorithm parameters: polynomial `0x1021`, initial value `0xFFFF`, no reflection, no final XOR.

```python
def calculate_crc(data: str) -> str:
    """CRC-16/CCITT-FALSE over the QR string up to and including '6304'."""
    crc = 0xFFFF
    for ch in data:
        crc ^= ord(ch) << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) if (crc & 0x8000) else (crc << 1)
            crc &= 0xFFFF
    return format(crc, '04X')

# Usage:
partial = "00020101021226580014org.x9...6304"   # everything up to and including "6304"
qr_string = partial + calculate_crc(partial)    # append 4-char checksum
```

```typescript
function calculateCrc(data: string): string {
  let crc = 0xFFFF;
  for (const ch of data) {
    crc ^= ch.charCodeAt(0) << 8;
    for (let i = 0; i < 8; i++) {
      crc = (crc & 0x8000) ? ((crc << 1) ^ 0x1021) : (crc << 1);
      crc &= 0xFFFF;
    }
  }
  return crc.toString(16).toUpperCase().padStart(4, '0');
}
```

---

## Building a QR String (Example)

For a $0.47 USD payment to Big Burger Bar in Los Angeles, MCC 5812:

```
Tag 00: 0002 01                     → Format indicator
Tag 01: 0102 12                     → Dynamic QR (one-time use)
Tag 26: 2658                        → Length 58: Merchant Account Info
  Sub 00: 0014 org.x9               → GUId (14 chars)
  Sub 01: 0142 x9-api.example.com/fetch/a1b2c3d4...  → URL (42 chars)
Tag 52: 5204 5812                   → MCC
Tag 53: 5303 840                    → Currency: USD (numeric 840)
Tag 54: 5404 0.47                   → Amount
Tag 58: 5802 US                     → Country
Tag 59: 5916 Big Burger Bar         → Merchant name (16 chars)
Tag 60: 6009 Los Angeles            → City (9 chars)
Tag 63: 6304 XXXX                   → CRC (computed last)

Full string: 00020101021226580014org.x90142x9-api.example.com/fetch/a1b2...52045812530384054040.475802US5916Big Burger Bar6009Los Angeles6304XXXX
```

---

## Parsing a QR String

```python
def parse_emv_tlv(data: str) -> dict:
    """Parse EMVCo TLV string into {tag: value} dict."""
    result = {}
    i = 0
    while i + 4 <= len(data):
        tag = data[i:i+2]
        if tag == '63':  # CRC tag — stop before consuming it
            break
        length = int(data[i+2:i+4])
        value = data[i+4:i+4+length]
        result[tag] = value
        i += 4 + length
    return result

def extract_fetch_url(qr_content: str) -> str | None:
    """Extract the X9.150 fetch URL from Tag 26, Subtag 01."""
    tags = parse_emv_tlv(qr_content)
    subtags = parse_emv_tlv(tags.get('26', ''))
    path = subtags.get('01', '')
    return ('https://' + path) if path else None
```

---

## ISO 4217 Numeric Currency Codes (for Tag 53)

| Currency | Alpha | Numeric |
|---|---|---|
| US Dollar | USD | 840 |
| Brazilian Real | BRL | 986 |
| Euro | EUR | 978 |

Note: Crypto currencies (USDC, WETH) don't have ISO 4217 numeric codes. In practice, implementations use the dominant fiat currency of the merchant's country for Tag 53, regardless of which payment method the payer ultimately uses.

---

## Validating a QR String

A validator should check:
1. Payload Format Indicator (Tag 00) is `"01"`
2. Tag 26 Subtag 00 is `"org.x9"` (confirms this is X9.150)
3. MCC (Tag 52) matches `^\d{4}$`
4. Amount (Tag 54), if present, matches `^\d+\.\d{2}$`
5. Country (Tag 58) matches `^[A-Z]{2}$`
6. CRC (Tag 63) matches computed CRC over the preceding string
7. All field lengths match their declared `length` values
