import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../providers/settings_provider.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';

/// Settings screen: webhook URL, currency, sync, CSV export.
/// Spec: idea.md §3.E.3, MOBILE_PRD.md §2.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _webhookCtrl;
  bool _isSyncing = false;
  String? _syncStatusMessage;
  bool? _syncSuccess;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _webhookCtrl = TextEditingController(text: settings.webhookUrl);
  }

  @override
  void dispose() {
    _webhookCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveWebhookUrl() async {
    await ref
        .read(settingsProvider.notifier)
        .setWebhookUrl(_webhookCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Webhook URL saved.')),
      );
    }
  }

  Future<void> _testSync() async {
    setState(() {
      _isSyncing = true;
      _syncStatusMessage = null;
      _syncSuccess = null;
    });

    final now = DateTime.now();
    final result = await SyncService.instance.syncMonth(
      year: now.year,
      month: now.month,
    );

    if (result.success && result.aiSummary != null) {
      await ref
          .read(settingsProvider.notifier)
          .setAiSummary(result.aiSummary!);
    }

    if (result.success) {
      await ref.read(settingsProvider.notifier).setLastSyncedMonth(
            DateFormat('MMMM yyyy').format(now),
          );
    }

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _syncSuccess = result.success;
        _syncStatusMessage = result.success
            ? 'Synced ${result.syncedCount} transactions. AI summary updated.'
            : result.errorMessage ?? 'Sync failed.';
      });
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final csv = await DatabaseService.instance.exportToCsv();
      // Copy CSV to clipboard — user can paste into any spreadsheet app
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'CSV copied to clipboard! Paste into Google Sheets or Excel.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: \$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Currency ───────────────────────────────────────────────────
          _SectionHeader(title: 'Currency', isDark: isDark),
          _Card(
            isDark: isDark,
            child: Row(
              children: kCurrencies.map((c) {
                final selected = settings.currency == c;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(settingsProvider.notifier).setCurrency(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF5A7A6A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            c == 'BYN' ? '🇧🇾' : '🇺🇸',
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFFCBD5E0)
                                      : const Color(0xFF4A5568)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Google Apps Script ─────────────────────────────────────────
          _SectionHeader(title: 'Google Sheets Sync', isDark: isDark),
          _Card(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apps Script Web App URL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF718096)
                        : const Color(0xFF9AA5B4),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _webhookCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText:
                        'https://script.google.com/macros/s/.../.../exec',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.save_rounded),
                      onPressed: _saveWebhookUrl,
                      tooltip: 'Save URL',
                    ),
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Last synced info
                if (settings.lastSyncedMonth.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF38A169), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Last synced: ${settings.lastSyncedMonth}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF38A169),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Sync status message
                if (_syncStatusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_syncSuccess ?? false)
                          ? const Color(0xFF38A169).withOpacity(0.1)
                          : const Color(0xFFE53E3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          (_syncSuccess ?? false)
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: (_syncSuccess ?? false)
                              ? const Color(0xFF38A169)
                              : const Color(0xFFE53E3E),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _syncStatusMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: (_syncSuccess ?? false)
                                  ? const Color(0xFF38A169)
                                  : const Color(0xFFE53E3E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Test Sync Now button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSyncing ? null : _testSync,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      _isSyncing ? 'Syncing...' : 'Test Sync Now',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF805AD5),
                      side: const BorderSide(color: Color(0xFF805AD5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Data ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Data', isDark: isDark),
          _Card(
            isDark: isDark,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38A169).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.download_rounded,
                        color: Color(0xFF38A169), size: 20),
                  ),
                  title: Text(
                    'Export to CSV',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Download all transactions as a spreadsheet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF718096)
                          : const Color(0xFF9AA5B4),
                    ),
                  ),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _isExporting ? null : _exportCsv,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── About ──────────────────────────────────────────────────────
          _SectionHeader(title: 'About', isDark: isDark),
          _Card(
            isDark: isDark,
            child: Column(
              children: [
                _AboutRow(
                  label: 'App',
                  value: 'MedExpense v1.0.0',
                  isDark: isDark,
                ),
                _AboutRow(
                  label: 'Designed for',
                  value: 'MBBS Students in Belarus 🇧🇾',
                  isDark: isDark,
                ),
                _AboutRow(
                  label: 'Default Currency',
                  value: 'Belarusian Ruble (BYN)',
                  isDark: isDark,
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isDark
              ? const Color(0xFF718096)
              : const Color(0xFF9AA5B4),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool last;
  const _AboutRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF718096)
                      : const Color(0xFF9AA5B4),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF4A5568)
                : const Color(0xFFF0F4F2),
          ),
      ],
    );
  }
}


