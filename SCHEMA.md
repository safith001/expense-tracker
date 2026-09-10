# Data & Local Storage Schema

## 1. Local SQLite Schema (`medexpense.db`)

### Table: `transactions`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | UUID v4 string |
| `amount` | REAL | NOT NULL | Monetary value (e.g., `45.50`) |
| `currency` | TEXT | NOT NULL DEFAULT 'BYN' | Transaction currency (`BYN` or `USD`) |
| `type` | TEXT | NOT NULL | Value: `'income'` or `'expense'` |
| `category` | TEXT | NOT NULL | Predefined or custom category name |
| `paymentMethod` | TEXT | NOT NULL DEFAULT 'Card' | Value: `'Cash'` or `'Card'` |
| `date` | TEXT | NOT NULL | ISO-8601 string (`YYYY-MM-DDTHH:mm:ss`) |
| `note` | TEXT | NULLABLE | User notes or description |
| `isSynced` | INTEGER| NOT NULL DEFAULT 0 | Sync status flag: `0` (False), `1` (True) |
| `createdAt` | INTEGER| NOT NULL | System epoch millisecond timestamp |

## 2. Key-Value Storage (`SharedPreferences`)
| Key | Type | Default | Description |
|---|---|---|---|
| `gas_webhook_url` | String | `""` | User-configured Google Apps Script Web App URL |
| `active_currency` | String | `"BYN"` | Active display currency (`BYN` or `USD`) |
| `last_synced_month` | String | `""` | String key of the last archived month (e.g., `"September 2026"`) |
| `latest_ai_summary` | String | `""` | Cached Gemini financial mentor summary text |

## 3. Remote Cloud Ledger Contract (Google Apps Script Payload)
Dispatched at month-end to Google Apps Script (`doPost`):
```json
{
  "month": "September 2026",
  "currency": "BYN",
  "summary": {
    "totalIncome": 1850.00,
    "totalExpense": 920.40,
    "netSavings": 929.60
  },
  "transactions": [
    {
      "date": "2026-09-04 14:15",
      "type": "Expense",
      "category": "Medical Books & Atlas",
      "paymentMethod": "Card",
      "amount": 140.00,
      "note": "Netter Anatomy Atlas"
    }
  ]
}