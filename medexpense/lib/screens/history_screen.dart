import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/transaction_tile.dart';

/// Full transaction history screen — shows all transactions, grouped by month.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(activeCurrencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return _EmptyHistory(isDark: isDark);
          }

          // Group by "MMMM yyyy" (e.g., "September 2026")
          final Map<String, List<Transaction>> grouped = {};
          for (final t in transactions) {
            final key = DateFormat('MMMM yyyy').format(t.parsedDate);
            grouped.putIfAbsent(key, () => []).add(t);
          }

          final monthKeys = grouped.keys.toList()
            ..sort((a, b) {
              final fmt = DateFormat('MMMM yyyy');
              return fmt.parse(b).compareTo(fmt.parse(a));
            });

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: monthKeys.length,
            itemBuilder: (_, i) {
              final monthKey = monthKeys[i];
              final txns = grouped[monthKey]!;

              // Compute month totals for the header
              double income = 0, expense = 0;
              for (final t in txns) {
                if (t.isExpense) {
                  expense += t.amount;
                } else {
                  income += t.amount;
                }
              }
              final net = income - expense;
              final fmt = NumberFormat('#,##0.00', 'en_US');

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month header with summary
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2D3748)
                          : const Color(0xFFF0F4F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          monthKey,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF2D3748),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Net: ${fmt.format(net)} $currency',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: net >= 0
                                    ? const Color(0xFF38A169)
                                    : const Color(0xFFE53E3E),
                              ),
                            ),
                            Text(
                              '${txns.length} transactions',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF718096)
                                    : const Color(0xFF9AA5B4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Transaction tiles
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
            },
          );
        },
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final bool isDark;
  const _EmptyHistory({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text(
            'No transactions yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? const Color(0xFF718096)
                  : const Color(0xFF9AA5B4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging expenses with the + button',
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
