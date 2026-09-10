import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';

// Palette for category slices — distinct, soft, readable on both light/dark
const _sliceColors = [
  Color(0xFF5A7A6A), // sage green
  Color(0xFF805AD5), // lavender
  Color(0xFFED8936), // amber
  Color(0xFF3182CE), // blue
  Color(0xFFE53E3E), // red
  Color(0xFF38A169), // forest green
  Color(0xFF00B5D8), // cyan
  Color(0xFFD69E2E), // yellow
  Color(0xFF9F7AEA), // purple
  Color(0xFF667EEA), // indigo
];

/// Interactive donut (PieChart) showing per-category expense breakdown.
/// Built with fl_chart ^0.68.0 (pinned in MOBILE_RULES.md).
class CategoryDonutChart extends ConsumerStatefulWidget {
  const CategoryDonutChart({super.key});

  @override
  ConsumerState<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends ConsumerState<CategoryDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final breakdown = ref.watch(categoryBreakdownProvider);
    final currency = ref.watch(activeCurrencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (breakdown.isEmpty) {
      return _EmptyChart(isDark: isDark);
    }

    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (sum, e) => sum + e.value);
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut chart
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    centerSpaceRadius: 38,
                    sectionsSpace: 2,
                    sections: entries.asMap().entries.map((entry) {
                      final i = entry.key;
                      final cat = entry.value;
                      final isTouched = i == _touchedIndex;
                      final pct = (cat.value / total * 100).toStringAsFixed(1);
                      return PieChartSectionData(
                        color: _sliceColors[i % _sliceColors.length],
                        value: cat.value,
                        radius: isTouched ? 52 : 44,
                        title: isTouched ? '$pct%' : '',
                        titleStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  children: entries.asMap().entries.take(6).map((entry) {
                    final i = entry.key;
                    final cat = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _sliceColors[i % _sliceColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.key,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFFCBD5E0)
                                    : const Color(0xFF4A5568),
                              ),
                            ),
                          ),
                          Text(
                            '${fmt.format(cat.value)} $currency',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final bool isDark;
  const _EmptyChart({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            Icons.donut_large_rounded,
            size: 48,
            color: isDark ? const Color(0xFF4A5568) : const Color(0xFFCBD5E0),
          ),
          const SizedBox(width: 16),
          Text(
            'No expenses logged\nthis month yet.',
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? const Color(0xFF718096) : const Color(0xFF9AA5B4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
