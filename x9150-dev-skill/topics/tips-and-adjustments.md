# Tips and Adjustments

## Tips

Tips are configured in the `bill.tip` object. When `allowed: true`, the payer's wallet shows a tip UI with the configured options.

### Basic Configuration

```json
"tip": {
  "allowed": true,
  "range": {
    "min": 0,
    "max": 25
  },
  "presets": [15, 18, 20]
}
```

| Field | Type | Notes |
|---|---|---|
| `allowed` | boolean | `false` disables tips entirely (no tip UI shown) |
| `range.min` | integer | Minimum tip % the payer can select |
| `range.max` | integer | Maximum tip % the payer can select |
| `presets` | integer[] | Suggested percentages shown as quick-select buttons |

### Disabling Tips

For retail/grocery where tips are not expected:

```json
"tip": { "allowed": false }
```

### Common Tip Configurations by Merchant Type

| Merchant Type | MCC | Typical Config |
|---|---|---|
| Coffee shop | 5812 | `min: 0, max: 25, presets: [15, 18, 20]` |
| Fine dining | 5812 | `min: 18, max: 30, presets: [18, 20, 22, 25]` |
| Fast food / burger | 5812 | `min: 0, max: 25, presets: [15, 18, 20]` |
| Grocery | 5411 | `allowed: false` |
| Bookstore | 5942 | `allowed: false` |
| Utility bill | 4900 | `allowed: false` |

### Tip Percentages in UI

The payer wallet uses `presets` as quick-select buttons and `range` to constrain a custom slider/input. Keep presets within the range.

```
INVALID: presets: [15, 18, 30] with range max: 25  (30 > max)
VALID:   presets: [15, 18, 20] with range max: 25
```

## Adjustments (Discounts and Surcharges)

Adjustments modify the base amount — used for early-payment discounts, late fees, or promotional pricing. Each adjustment has a validity window.

### Structure

```json
"bill": {
  "paymentTiming": "deferred",
  "description": "Electric bill",
  "amountDue": { "amount": 12300, "currency": "USD" },
  "adjustments": [
    {
      "description": "5% early payment discount",
      "validUntil": "2026-03-15T23:59:59Z",
      "adjustedAmountDue": { "amount": 11685, "currency": "USD" }
    },
    {
      "description": "Late fee",
      "validFrom": "2026-04-02T00:00:00Z",
      "adjustedAmountDue": { "amount": 13000, "currency": "USD" }
    }
  ],
  "tip": { "allowed": false }
}
```

| Field | Notes |
|---|---|
| `description` | Human-readable label shown in payer wallet |
| `validUntil` | RFC 3339 timestamp — adjustment expires after this time |
| `validFrom` | RFC 3339 timestamp — adjustment activates after this time |
| `adjustedAmountDue` | The total amount (including the adjustment) in minor units |

### Adjustment Amount Calculation

`adjustedAmountDue` is the **total adjusted amount**, not the delta:

```
Base amount:          $123.00  →  12300 cents
5% discount:          $  6.15  →   615 cents discount
adjustedAmountDue:    $116.85  →  11685 cents  ← send this, not the delta
```

### Timestamps

The spec requires **exactly 3 millisecond digits** and `Z` suffix:
`^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$`

```python
# Python (from qr_generator.py)
from datetime import datetime, timezone
now = datetime.now(timezone.utc)
ts = now.strftime('%Y-%m-%dT%H:%M:%S.') + f"{now.microsecond // 1000:03d}Z"
# → "2026-03-15T23:59:59.000Z"
```

```typescript
// TypeScript
const ts = new Date('2026-03-15T23:59:59').toISOString();
// → "2026-03-15T23:59:59.000Z"  ✓ (toISOString always gives 3ms digits + Z)
```

```
"2026-03-15T23:59:59.000Z"  ✓
"2026-03-15T23:59:59Z"      ✗ (missing .000)
"2026-03-15 23:59:59"       ✗ (missing T and Z)
```

## Building Tips Config from User Settings

When reading from merchant settings (stored as percentage strings):

```typescript
const tip = {
  allowed: true,
  range: {
    min: parseInt(settings.tipMin) || 0,
    max: parseInt(settings.tipMax) || 25,
  },
  presets: [
    parseInt(settings.tipPreset1) || 15,
    parseInt(settings.tipPreset2) || 18,
    parseInt(settings.tipPreset3) || 20,
  ].filter(n => !isNaN(n) && n >= 0),
};
```
