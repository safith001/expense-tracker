import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';

/// Hero balance card at the top of the Dashboard.
/// Shows: Total Inflow, Total Outflow, Net Savings.
class HeroBalanceCard extends ConsumerWidget {
  const HeroBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final currency = ref.watch(activeCurrencyProvider);
    final now = DateTime.now();
    final monthLabel = DateFormat('MMMM yyyy').format(now);

    // Formatter for currency values
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A7A6A), Color(0xFF3D5E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A7A6A).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month label
          Text(
            monthLabel,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Financial Overview',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          // Three KPI columns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _KpiColumn(
                label: 'Income',
                value: '${fmt.format(summary.totalIncome)} $currency',
                icon: Icons.arrow_downward_rounded,
                iconColor: const Color(0xFF68D391),
              ),
              _Divider(),
              _KpiColumn(
                label: 'Expenses',
                value: '${fmt.format(summary.totalExpense)} $currency',
                icon: Icons.arrow_upward_rounded,
                iconColor: const Color(0xFFFC8181),
              ),
              _Divider(),
              _KpiColumn(
                label: 'Savings',
                value: '${fmt.format(summary.netSavings)} $currency',
                icon: Icons.savings_rounded,
                iconColor: const Color(0xFF90CDF4),
                valueColor: summary.netSavings >= 0
                    ? const Color(0xFF68D391)
                    : const Color(0xFFFC8181),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? valueColor;

  const _KpiColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        width: 1,
        color: Colors.white24,
      );
}
