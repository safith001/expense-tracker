import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_model.dart';
import '../services/database_service.dart';

/// Result object returned by the sync operation.
class SyncResult {
  final bool success;
  final String? aiSummary;
  final String? errorMessage;
  final int syncedCount;

  const SyncResult({
    required this.success,
    this.aiSummary,
    this.errorMessage,
    this.syncedCount = 0,
  });
}

/// Handles the HTTP POST to the Google Apps Script webhook.
/// Schema of the payload is defined in SCHEMA.md §3.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  // SharedPreferences keys (from SCHEMA.md §2)
  static const _keyWebhookUrl = 'gas_webhook_url';
  static const _keyCurrency = 'active_currency';
  static const _keyLastSyncedMonth = 'last_synced_month';
  static const _keyAiSummary = 'latest_ai_summary';

  /// Syncs all unsynced transactions for the given [year] and [month]
  /// to the configured Google Apps Script Web App URL.
  ///
  /// On success:
  ///   - marks transactions as synced in SQLite
  ///   - saves aiSummary to SharedPreferences
  ///   - saves last_synced_month key
  ///
  /// Returns a [SyncResult] with success status + AI summary text.
  Future<SyncResult> syncMonth({required int year, required int month}) async {
    final prefs = await SharedPreferences.getInstance();
    final webhookUrl = prefs.getString(_keyWebhookUrl) ?? '';

    if (webhookUrl.isEmpty) {
      return const SyncResult(
        success: false,
        errorMessage: 'No Google Apps Script URL configured. Go to Settings to add it.',
      );
    }

    final currency = prefs.getString(_keyCurrency) ?? 'BYN';

    // Fetch unsynced transactions for this month
    final List<Transaction> transactions =
        await DatabaseService.instance.getUnsyncedTransactionsForMonth(year, month);

    if (transactions.isEmpty) {
      return const SyncResult(
        success: true,
        aiSummary: null,
        errorMessage: 'No unsynced transactions for this period.',
        syncedCount: 0,
      );
    }

    // Compute summary totals
    final summary = await DatabaseService.instance.getMonthlySummary(year, month);

    // Format month name e.g. "September 2026" (as expected by Code.gs)
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    // Build the JSON payload matching SCHEMA.md §3
    final payload = {
      'month': monthName,
      'currency': currency,
      'summary': summary.toJson(),
      'transactions': transactions.map((t) => t.toSyncJson()).toList(),
    };

    try {
      http.Response response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 45));

      // Google Apps Script web apps return a 302 redirect with a Location header
      if ((response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307) &&
          response.headers.containsKey('location')) {
        final redirectUrl = response.headers['location']!;
        response = await http.get(Uri.parse(redirectUrl)).timeout(const Duration(seconds: 45));
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final status = responseData['status'] as String?;

        if (status == 'success') {
          final aiSummary = responseData['aiSummary'] as String? ?? '';

          // Mark all synced transactions in SQLite
          await DatabaseService.instance
              .markTransactionsAsSynced(transactions.map((t) => t.id).toList());

          // Persist AI summary and sync month to SharedPreferences
          await prefs.setString(_keyAiSummary, aiSummary);
          await prefs.setString(_keyLastSyncedMonth, monthName);

          return SyncResult(
            success: true,
            aiSummary: aiSummary,
            syncedCount: transactions.length,
          );
        } else {
          return SyncResult(
            success: false,
            errorMessage: responseData['message'] as String? ?? 'Unknown error from server.',
          );
        }
      } else {
        return SyncResult(
          success: false,
          errorMessage: 'Server returned HTTP ${response.statusCode}.',
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Checks if the previous month has unsynced transactions.
  /// Used by the App Launch Failsafe Guard (MOBILE_PRD.md §3).
  Future<bool> hasPreviousMonthUnsynced() async {
    final now = DateTime.now();
    // Previous month: if current month is January (1), go back to December of prev year
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;

    final prefs = await SharedPreferences.getInstance();
    final lastSynced = prefs.getString(_keyLastSyncedMonth) ?? '';
    final prevMonthName = DateFormat('MMMM yyyy').format(DateTime(prevYear, prevMonth));

    // If last synced month is not the previous month, check for unsynced records
    if (lastSynced != prevMonthName) {
      final unsynced = await DatabaseService.instance
          .getUnsyncedTransactionsForMonth(prevYear, prevMonth);
      return unsynced.isNotEmpty;
    }
    return false;
  }

  /// Returns the previous month as (year, month) pair.
  (int year, int month) getPreviousMonth() {
    final now = DateTime.now();
    return now.month == 1
        ? (now.year - 1, 12)
        : (now.year, now.month - 1);
  }

  /// Reads cached AI summary from SharedPreferences.
  Future<String> getCachedAiSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAiSummary) ?? '';
  }
}
