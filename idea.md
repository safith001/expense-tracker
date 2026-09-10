# TASK SPECIFICATION FOR GOOGLE ANTIGRAVITY
**Goal:** Build and verify "MedExpense", a production-ready, offline-first Android Flutter mobile finance app with automated month-end Google Sheets sync and Gemini AI coaching.

---

## 1. AGENT WORKFLOW & ARTIFACT PROTOCOL
1. **Implementation Plan Artifact:** Before writing code, inspect the workspace and produce a structured file map and implementation plan.
2. **Terminal Execution:** You have full terminal access. Initialize the Flutter project if not present, run `flutter pub add` / `flutter pub get`, configure Android native manifests, and verify the build with `flutter analyze`.
3. **Walkthrough Artifact:** At the conclusion of the task, output a comprehensive deployment walkthrough detailing:
   - Exactly how to paste and deploy the generated `backend/Code.gs` in Google Sheets.
   - How to link the generated Web App URL inside the Android app settings.

---

## 2. APP SPECIFICATION & PERSONA
- **User:** Single-user international female MBBS student studying in Belarus.
- **Design Language:** Modern, soft pastel aesthetic (sage green `#8DA399`, dusty lavender `#B8A9C9`, warm cream `#FAF9F6`, charcoal `#2D3748`). 18dp rounded corners, smooth micro-interactions, full Dark Mode support.
- **Default Currency:** Belarusian Ruble (`BYN`), toggleable to `USD`.
- **Target OS:** Android (minSdkVersion: 23, compileSdkVersion: 34).

---

## 3. REQUIRED CODEBASE ARCHITECTURE

### A. Dependencies (`pubspec.yaml`)
- `sqflite` & `path`: 100% offline local transaction ledger.
- `workmanager`: Scheduled background triggers at month-end.
- `http`: POSTing payloads to Google Apps Script.
- `intl`: Localized date/currency formatting.
- `fl_chart`: Category breakdown donut charts.
- `shared_preferences`: Storing Webhook URL, currency preference, and AI summary text.
- `google_fonts`: Plus Jakarta Sans or Inter typography.

### B. SQLite Local Ledger (`lib/services/database_service.dart`)
- Store transactions with fields: `id`, `amount`, `currency`, `type` (`income` | `expense`), `category`, `paymentMethod` (`Cash` | `Card`), `date` (ISO-8601), `note`, `isSynced` (0 or 1), `createdAt`.
- Helper queries:
  - `getTransactionsForMonth(int year, int month)`
  - `getMonthlySummary(int year, int month)` -> `{totalIncome, totalExpense, netSavings}`
  - `markTransactionsAsSynced(List<String> ids)`

### C. MBBS Specialized Categories (`lib/models/transaction_model.dart`)
- **Expense Chips:** Groceries & Food, Hostel / Rent, University Tuition, Medical Books & Atlas, Lab Equipment & Scrubs, Metro & Transit, Cafes & Study, Personal Care, Utilities / Wi-Fi, Emergency.
- **Income Chips:** Family Allowance, Stipend / Scholarship, Savings, Other.

### D. End-of-Month Auto-Sync Engine (`lib/services/sync_service.dart` & `background_worker.dart`)
1. **WorkManager Setup:**
   - Run a daily background check.
   - Detect if `now.add(Duration(days: 1)).day == 1` (last day of the month).
   - If true, bundle all transactions for the month, calculate totals, and execute an HTTP POST to the configured Google Apps Script Web App URL.
2. **Launch Guard (Failsafe):**
   - In the dashboard `initState`, check if the previous month finished without syncing (e.g., if phone was off or on airplane mode at 11:59 PM). If unsynced, trigger silent sync and save the returned AI summary to `SharedPreferences`.

### E. Frontend Screens & Components
1. `lib/screens/dashboard_screen.dart`:
   - Hero balance card (Inflow, Outflow, Net Savings).
   - `fl_chart` donut breakdown of categories.
   - **Gemini AI Coaching Card**: Displays the latest 3-paragraph summary returned by the sync endpoint.
   - Chronological daily transaction feed.
2. `lib/widgets/add_transaction_sheet.dart`:
   - Bottom sheet with an inline numeric keypad for logging expenses in under 5 seconds between hospital rounds.
3. `lib/screens/settings_screen.dart`:
   - Input field for Google Apps Script Webhook URL.
   - Currency toggle (`BYN` / `USD`).
   - "Test Sync Now" button with spinner and status badge.
   - "Export to CSV" local backup option.

---

## 4. BACKEND SPECIFICATION (`backend/Code.gs`)
Create a self-contained Google Apps Script file ready for "Web App" deployment containing:

```javascript
/**
 * MedExpense Google Sheets Webhook Backend
 */
const GEMINI_API_KEY = "YOUR_GEMINI_API_KEY"; // Configured via Script Properties or constant

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.tryLock(15000);

  try {
    const data = JSON.parse(e.postData.contents);
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheetName = data.month || Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "MMMM yyyy");
    
    let sheet = ss.getSheetByName(sheetName);
    if (!sheet) {
      sheet = ss.insertSheet(sheetName);
    } else {
      sheet.clear();
    }

    const currency = data.currency || "BYN";
    const summary = data.summary || { totalIncome: 0, totalExpense: 0, netSavings: 0 };
    const transactions = data.transactions || [];

    // 1. Call Gemini for MBBS Monthly Budget Review
    const aiReview = generateAiSummary(transactions, summary, currency, sheetName);

    // 2. Format KPI Block
    sheet.getRange("A1:E1").merge().setValue(`${sheetName} Financial & AI Review`)
      .setFontWeight("bold").setFontSize(14).setBackground("#2D3748").setFontColor("#FFFFFF").setHorizontalAlignment("center");

    const summaryHeaders = [["Total Income", "Total Expenses", "Net Savings", "Currency", "Sync Timestamp"]];
    sheet.getRange("A2:E2").setValues(summaryHeaders).setFontWeight("bold").setBackground("#EDF2F7").setHorizontalAlignment("center");

    const summaryValues = [[
      summary.totalIncome, summary.totalExpense, summary.netSavings, currency,
      Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm:ss")
    ]];
    sheet.getRange("A3:E3").setValues(summaryValues).setHorizontalAlignment("center");
    sheet.getRange("A3:C3").setNumberFormat(`0.00 "${currency}"`);
    sheet.getRange("C3").setBackground(summary.netSavings >= 0 ? "#C6F6D5" : "#FED7D7")
      .setFontColor(summary.netSavings >= 0 ? "#22543D" : "#742A2A");

    // 3. AI Insights Card
    sheet.getRange("A5:E5").merge().setValue("🤖 Gemini Monthly Financial Insights & MBBS Budget Coaching")
      .setFontWeight("bold").setBackground("#805AD5").setFontColor("#FFFFFF");
    
    const aiCell = sheet.getRange("A6:E8").merge();
    aiCell.setValue(aiReview).setWrap(true).setVerticalAlignment("top").setBackground("#F7FAFC");

    // 4. Raw Ledger Table
    const startRow = 10;
    const tableHeaders = [["Date & Time", "Type", "Category", "Payment Method", `Amount (${currency})`, "Note"]];
    sheet.getRange(startRow, 1, 1, 6).setValues(tableHeaders).setFontWeight("bold").setBackground("#4A5568").setFontColor("#FFFFFF");

    if (transactions.length > 0) {
      const rows = transactions.map(t => [
        t.date || "", t.type || "Expense", t.category || "General",
        t.paymentMethod || "Card", Number(t.amount) || 0, t.note || ""
      ]);
      sheet.getRange(startRow + 1, 1, rows.length, 6).setValues(rows);
      sheet.getRange(startRow + 1, 1, rows.length, 4).setHorizontalAlignment("center");
      sheet.getRange(startRow + 1, 5, rows.length, 1).setNumberFormat(`0.00 "${currency}"`).setHorizontalAlignment("right");
      
      for (let i = 0; i < rows.length; i++) {
        sheet.getRange(startRow + 1 + i, 2).setFontColor(rows[i][1].toLowerCase() === "income" ? "#2F855A" : "#C53030");
      }
    }

    for (let c = 1; c <= 6; c++) {
      sheet.autoResizeColumn(c);
      sheet.setColumnWidth(c, Math.max(sheet.getColumnWidth(c) + 15, 120));
    }

    return ContentService.createTextOutput(JSON.stringify({
      status: "success",
      message: `Synced ${transactions.length} records to "${sheetName}".`,
      aiSummary: aiReview
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "error", message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock();
  }
}

function generateAiSummary(transactions, summary, currency, monthName) {
  try {
    const url = `[https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$](https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$){GEMINI_API_KEY}`;
    const prompt = `
    You are a compassionate, practical financial mentor for an international MBBS student studying in Belarus.
    Analyze her monthly financial ledger for ${monthName}:
    - Currency: ${currency}
    - Total Income: ${summary.totalIncome}
    - Total Expenses: ${summary.totalExpense}
    - Net Savings: ${summary.netSavings}
    - Sample Transactions: ${JSON.stringify(transactions.slice(0, 70))}

    Write a concise 3-paragraph summary:
    1. Financial health overview and top spending drivers (medical books, hostel, food, lifestyle).
    2. Compassionate, practical advice on saving in Belarus without compromising health or studies.
    3. An encouraging closing note for her medical training. Keep it flowing without markdown headings.
    `;

    const response = UrlFetchApp.fetch(url, {
      method: "post", contentType: "application/json",
      payload: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      muteHttpExceptions: true
    });
    return JSON.parse(response.getContentText()).candidates[0].content.parts[0].text;
  } catch (error) {
    return "Monthly records logged successfully. (AI Summary generation skipped: " + error.message + ")";
  }
}