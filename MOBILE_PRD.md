# Mobile App Specification (PRD) — MedExpense (Belarus Edition)

## 1. Problem Statement
International medical (MBBS) students living in Belarus have rigorous academic and hospital schedules. Traditional personal finance applications introduce high friction via forced account linking, cloud lockouts, multi-step subcategories, and regional network limitations. 

The student requires a zero-friction, single-user mobile ledger operating 100% offline, capable of auto-archiving data to Google Sheets at month-end and providing AI coaching via Google Gemini without cloud hosting overhead.

## 2. Core MVP Features
- **Rapid Transaction Input:** Single-tap bottom sheet entry with an inline custom numeric keypad and MBBS category chips (completable in < 5 seconds).
- **Offline Ledger:** Direct SQLite writes on-device with zero network latency.
- **Hero Dashboard:** High-level monthly overview (Inflow, Outflow, Net Balance) with an interactive donut chart (`fl_chart`).
- **End-of-Month Auto-Archival:** Background execution via Android `WorkManager` on the last calendar day of each month at 11:59 PM to bundle, format, and push the ledger to a Google Apps Script webhook.
- **AI Financial Mentorship:** Ingestion of monthly records by Google Gemini Flash via the Apps Script backend, generating a 3-paragraph compassionate budget evaluation returned directly to the app dashboard and Google Sheet.
- **Settings & Config:** Non-hardcoded Google Apps Script Web App URL, currency switcher (`BYN` / `USD`), manual sync trigger, and CSV export.

## 3. Offline & Connectivity Handling
- All reads and writes target the local SQLite database directly.
- The app operates with complete fidelity during network dropouts or airplane mode.
- Monthly sync tasks check for active network connectivity (`NetworkType.connected`). If disconnected during month-end:
  - The transaction records retain `isSynced = 0`.
  - The **App Launch Failsafe Guard** detects unarchived transactions from the prior month on the next cold launch and dispatches them silently.

## 4. Push & Background Triggers
- **Periodic Trigger:** `WorkManager` scheduled daily check (runs every 12–24 hours).
- **Execution Condition:** `tomorrow.day == 1` (identifies the 28th, 29th, 30th, or 31st depending on the month).
- **Failsafe Trigger:** App lifecycle `initState` check on launch.
- **Out of Scope for MVP:** Remote push notifications (FCM), GPS/location tracking, multi-user accounts, automated bank SMS scrapers.