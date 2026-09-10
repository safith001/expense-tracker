/**
 * MedExpense — Google Sheets Webhook Backend
 * 
 * Deploy as a Google Apps Script Web App:
 *   1. Open Google Sheets → Extensions → Apps Script
 *   2. Paste this file (rename to Code.gs if needed)
 *   3. Set GEMINI_API_KEY via: Project Settings → Script Properties
 *      Key: GEMINI_API_KEY, Value: <your key from aistudio.google.com>
 *   4. Click Deploy → New deployment → Web App
 *      - Execute as: Me
 *      - Who has access: Anyone
 *   5. Copy the Web App URL and paste it into MedExpense Settings
 * 
 * Receives POST from MedExpense Android app (payload defined in SCHEMA.md §3).
 * Returns: { status, message, aiSummary }
 */

// ─── Configuration ────────────────────────────────────────────────────────────
// Store your key via: Script Properties → GEMINI_API_KEY
// Or hardcode here for testing (not recommended for production):
const SCRIPT_PROPS = PropertiesService.getScriptProperties();

// ─── Main Entry Point ─────────────────────────────────────────────────────────

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.tryLock(15000);

  try {
    const data = JSON.parse(e.postData.contents);
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheetName = data.month || Utilities.formatDate(
      new Date(), Session.getScriptTimeZone(), "MMMM yyyy"
    );

    // Create or reset the month's sheet tab
    let sheet = ss.getSheetByName(sheetName);
    if (!sheet) {
      sheet = ss.insertSheet(sheetName);
    } else {
      sheet.clear();
    }

    const currency    = data.currency    || "BYN";
    const summary     = data.summary     || { totalIncome: 0, totalExpense: 0, netSavings: 0 };
    const transactions = data.transactions || [];

    // 1. Generate Gemini AI coaching summary
    const aiReview = generateAiSummary(transactions, summary, currency, sheetName);

    // 2. Title row
    sheet.getRange("A1:F1").merge()
      .setValue(`${sheetName} — Financial Report & AI Review`)
      .setFontWeight("bold")
      .setFontSize(14)
      .setBackground("#2D3748")
      .setFontColor("#FFFFFF")
      .setHorizontalAlignment("center");

    // 3. KPI summary block (row 2 headers, row 3 values)
    const summaryHeaders = [["Total Income", "Total Expenses", "Net Savings", "Currency", "Sync Timestamp", "Transactions"]];
    sheet.getRange("A2:F2")
      .setValues(summaryHeaders)
      .setFontWeight("bold")
      .setBackground("#EDF2F7")
      .setHorizontalAlignment("center");

    const summaryValues = [[
      summary.totalIncome,
      summary.totalExpense,
      summary.netSavings,
      currency,
      Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm:ss"),
      transactions.length
    ]];
    sheet.getRange("A3:F3").setValues(summaryValues).setHorizontalAlignment("center");
    sheet.getRange("A3:C3").setNumberFormat(`0.00 "${currency}"`);

    // Color the Net Savings cell green/red
    sheet.getRange("C3")
      .setBackground(summary.netSavings >= 0 ? "#C6F6D5" : "#FED7D7")
      .setFontColor(summary.netSavings >= 0 ? "#22543D" : "#742A2A")
      .setFontWeight("bold");

    // 4. AI Insights section (rows 5-9)
    sheet.getRange("A5:F5").merge()
      .setValue("🤖  Gemini Monthly Financial Insights & MBBS Budget Coaching")
      .setFontWeight("bold")
      .setFontSize(12)
      .setBackground("#805AD5")
      .setFontColor("#FFFFFF");

    sheet.getRange("A6:F9").merge()
      .setValue(aiReview)
      .setWrap(true)
      .setVerticalAlignment("top")
      .setBackground("#F7FAFC")
      .setFontSize(11);

    // 5. Raw ledger table (starts at row 11)
    const startRow = 11;
    const tableHeaders = [["Date & Time", "Type", "Category", "Payment Method", `Amount (${currency})`, "Note"]];
    sheet.getRange(startRow, 1, 1, 6)
      .setValues(tableHeaders)
      .setFontWeight("bold")
      .setBackground("#4A5568")
      .setFontColor("#FFFFFF");

    if (transactions.length > 0) {
      const rows = transactions.map(t => [
        t.date         || "",
        t.type         || "Expense",
        t.category     || "General",
        t.paymentMethod|| "Card",
        Number(t.amount) || 0,
        t.note         || ""
      ]);

      sheet.getRange(startRow + 1, 1, rows.length, 6).setValues(rows);
      sheet.getRange(startRow + 1, 1, rows.length, 4).setHorizontalAlignment("center");
      sheet.getRange(startRow + 1, 5, rows.length, 1)
        .setNumberFormat(`0.00 "${currency}"`)
        .setHorizontalAlignment("right");

      // Color type column: income = green, expense = red
      for (let i = 0; i < rows.length; i++) {
        const typeCell = sheet.getRange(startRow + 1 + i, 2);
        const isIncome = rows[i][1].toLowerCase() === "income";
        typeCell.setFontColor(isIncome ? "#2F855A" : "#C53030").setFontWeight("bold");

        // Alternate row background for readability
        if (i % 2 === 0) {
          sheet.getRange(startRow + 1 + i, 1, 1, 6).setBackground("#F7FAFC");
        }
      }
    }

    // 6. Auto-resize all columns
    for (let c = 1; c <= 6; c++) {
      sheet.autoResizeColumn(c);
      sheet.setColumnWidth(c, Math.max(sheet.getColumnWidth(c) + 15, 110));
    }

    // 7. Return response to Android app
    return ContentService.createTextOutput(JSON.stringify({
      status: "success",
      message: `Synced ${transactions.length} records to "${sheetName}".`,
      aiSummary: aiReview
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({
      status: "error",
      message: err.toString()
    })).setMimeType(ContentService.MimeType.JSON);

  } finally {
    lock.releaseLock();
  }
}

// ─── Gemini AI Summary Generator ─────────────────────────────────────────────

function generateAiSummary(transactions, summary, currency, monthName) {
  try {
    const apiKey = SCRIPT_PROPS.getProperty("GEMINI_API_KEY") || "YOUR_KEY_HERE";
    
    // Using gemini-2.5-flash for cost-efficient generation
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

    const prompt = `You are a compassionate, practical financial mentor for an international MBBS student studying in Belarus.

Analyze her monthly financial ledger for ${monthName}:
- Currency: ${currency}
- Total Income: ${summary.totalIncome} ${currency}
- Total Expenses: ${summary.totalExpense} ${currency}  
- Net Savings: ${summary.netSavings} ${currency}
- Savings Rate: ${summary.totalIncome > 0 ? ((summary.netSavings / summary.totalIncome) * 100).toFixed(1) : 0}%
- Transaction Count: ${transactions.length}
- Top spending categories: ${JSON.stringify(
  transactions
    .filter(t => t.type === "Expense")
    .reduce((acc, t) => {
      acc[t.category] = (acc[t.category] || 0) + Number(t.amount);
      return acc;
    }, {})
)}

Write a warm, concise 3-paragraph coaching summary:
1. Financial health overview: highlight top spending drivers, savings rate, and whether the month was healthy.
2. Compassionate, practical advice on reducing spending in Belarus without compromising health, study materials, or wellbeing. Give 2-3 specific, actionable tips.
3. An encouraging closing note acknowledging the challenge of studying medicine abroad and motivating her forward.

Write in plain flowing prose without markdown headings, bullet points, or formatting symbols.`;

    const payload = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 400
      }
    };

    const response = UrlFetchApp.fetch(url, {
      method: "post",
      contentType: "application/json",
      payload: JSON.stringify(payload),
      muteHttpExceptions: true
    });

    const result = JSON.parse(response.getContentText());
    
    if (result.candidates && result.candidates[0]?.content?.parts?.[0]?.text) {
      return result.candidates[0].content.parts[0].text.trim();
    }
    
    return `Your ${monthName} records have been archived successfully. Income: ${summary.totalIncome} ${currency}, Expenses: ${summary.totalExpense} ${currency}, Net Savings: ${summary.netSavings} ${currency}. (AI summary unavailable — check GEMINI_API_KEY in Script Properties.)`;

  } catch (error) {
    return `Monthly records for ${monthName} logged successfully. (AI Summary generation encountered an error: ${error.message}. Verify your GEMINI_API_KEY in Script Properties.)`;
  }
}

/**
 * TEST FUNCTION — run this manually from the Apps Script editor
 * to verify your setup before deploying the Android app.
 */
function testDoPost() {
  const mockPayload = {
    postData: {
      contents: JSON.stringify({
        month: "September 2026",
        currency: "BYN",
        summary: { totalIncome: 1850.00, totalExpense: 920.40, netSavings: 929.60 },
        transactions: [
          { date: "2026-09-04 14:15", type: "Expense", category: "Medical Books & Atlas", paymentMethod: "Card", amount: 140.00, note: "Netter Anatomy Atlas" },
          { date: "2026-09-05 09:30", type: "Expense", category: "Groceries & Food", paymentMethod: "Cash", amount: 45.00, note: "" },
          { date: "2026-09-01 12:00", type: "Income", category: "Family Allowance", paymentMethod: "Card", amount: 1850.00, note: "Monthly transfer" }
        ]
      })
    }
  };
  
  const result = doPost(mockPayload);
  Logger.log(result.getContent());
}
