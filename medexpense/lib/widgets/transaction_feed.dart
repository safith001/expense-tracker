import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import 'transaction_tile.dart';

/// Groups transactions into Today / Yesterday / [Day Name] / [Date] headers.
class TransactionFeed extends ConsumerWidget {
  /// If [limit] is set, only shows that many groups (for dashboard preview).
  final int? limit;

  const TransactionFeed({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(currentMonthTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return transactionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading transactions: $e'),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return _EmptyFeed(isDark: isDark);
        }

        // Group by date string (yyyy-MM-dd)
        final Map<String, List<Transaction>> grouped = {};
        for (final t in transactions) {
          final dateKey = t.date.substring(0, 10);
          grouped.putIfAbsent(dateKey, () => []).add(t);
        }

        var keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
        if (limit != null) keys = keys.take(limit!).toList();

        return Column(
          children: keys.map((dateKey) {
            final dayLabel = _dayLabel(dateKey);
            final txns = grouped[dateKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date group header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    dayLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF718096)
                          : const Color(0xFF9AA5B4),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...txns.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TransactionTile(
                        transaction: t,
                        onDelete: () => ref
                            .read(transactionNotifierProvider.notifier)
                            .deleteTransaction(t.id),
                      ),
                    )),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  /// Returns human-friendly day label: "TODAY", "YESTERDAY", or "MON, 04 SEP"
  String _dayLabel(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'TODAY';
    if (target == yesterday) return 'YESTERDAY';
    return DateFormat('EEE, dd MMM').format(date).toUpperCase();
  }
}

class _EmptyFeed extends StatelessWidget {
  final bool isDark;
  const _EmptyFeed({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Text('🩺', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'No transactions this month',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFF718096)
                  : const Color(0xFF9AA5B4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to log your first expense',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF4A5568)
                  : const Color(0xFFCBD5E0),
            ),
          ),
        ],
      ),
    );
  }
}
