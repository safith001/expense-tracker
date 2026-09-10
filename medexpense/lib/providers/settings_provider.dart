import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── SharedPreferences Keys ──────────────────────────────────────────────────
// Matches SCHEMA.md §2 exactly

const _keyCurrency = 'active_currency';
const _keyWebhookUrl = 'gas_webhook_url';
const _keyLastSyncedMonth = 'last_synced_month';
const _keyAiSummary = 'latest_ai_summary';

// ─── Settings State ──────────────────────────────────────────────────────────

class SettingsState {
  final String currency;           // 'BYN' or 'USD'
  final String webhookUrl;         // Google Apps Script Web App URL
  final String lastSyncedMonth;    // e.g. "September 2026"
  final String latestAiSummary;    // Gemini coaching text

  const SettingsState({
    this.currency = 'BYN',
    this.webhookUrl = '',
    this.lastSyncedMonth = '',
    this.latestAiSummary = '',
  });

  SettingsState copyWith({
    String? currency,
    String? webhookUrl,
    String? lastSyncedMonth,
    String? latestAiSummary,
  }) => SettingsState(
        currency: currency ?? this.currency,
        webhookUrl: webhookUrl ?? this.webhookUrl,
        lastSyncedMonth: lastSyncedMonth ?? this.lastSyncedMonth,
        latestAiSummary: latestAiSummary ?? this.latestAiSummary,
      );
}

// ─── Settings Notifier ───────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  /// Loads all values from SharedPreferences on startup
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      currency: prefs.getString(_keyCurrency) ?? 'BYN',
      webhookUrl: prefs.getString(_keyWebhookUrl) ?? '',
      lastSyncedMonth: prefs.getString(_keyLastSyncedMonth) ?? '',
      latestAiSummary: prefs.getString(_keyAiSummary) ?? '',
    );
  }

  Future<void> setCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, value);
    state = state.copyWith(currency: value);
  }

  Future<void> setWebhookUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWebhookUrl, value);
    state = state.copyWith(webhookUrl: value);
  }

  Future<void> setAiSummary(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiSummary, value);
    state = state.copyWith(latestAiSummary: value);
  }

  Future<void> setLastSyncedMonth(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSyncedMonth, value);
    state = state.copyWith(lastSyncedMonth: value);
  }

  /// Refreshes AI summary from SharedPreferences (called after a sync)
  Future<void> refreshFromPrefs() async {
    await _load();
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Main settings provider — survives widget rebuilds
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);

/// Convenience provider: just the active currency string ('BYN' or 'USD')
final activeCurrencyProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider).currency,
);

/// Convenience provider: the latest cached Gemini AI summary
final aiSummaryProvider = Provider<String>(
  (ref) => ref.watch(settingsProvider).latestAiSummary,
);
