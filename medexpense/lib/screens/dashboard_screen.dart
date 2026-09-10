import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/settings_provider.dart';
import '../services/sync_service.dart';
import '../widgets/hero_balance_card.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/transaction_feed.dart';

/// Main dashboard screen.
/// On initState: runs App Launch Failsafe Guard (MOBILE_PRD.md §3).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // App Launch Failsafe Guard: check if previous month has unsynced records
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runFailsafeGuard();
    });
  }

  /// Silently syncs the previous month if it was never synced.
  /// E.g., phone was off at month-end — catches up on next cold launch.
  Future<void> _runFailsafeGuard() async {
    final hasUnsynced = await SyncService.instance.hasPreviousMonthUnsynced();
    if (!hasUnsynced || !mounted) return;

    final (year, month) = SyncService.instance.getPreviousMonth();
    final result = await SyncService.instance.syncMonth(
      year: year,
      month: month,
    );

    if (result.success && result.aiSummary != null && mounted) {
      await ref
          .read(settingsProvider.notifier)
          .setAiSummary(result.aiSummary!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MedExpense',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM').format(now),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? const Color(0xFF718096)
                    : const Color(0xFF9AA5B4),
              ),
            ),
          ],
        ),
        titleSpacing: 16,
      ),
      body: const RefreshableBody(),
    );
  }
}

/// Extracted so we can wrap in RefreshIndicator without losing const semantics.
class RefreshableBody extends StatelessWidget {
  const RefreshableBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 8),
        HeroBalanceCard(),
        SizedBox(height: 16),
        CategoryDonutChart(),
        SizedBox(height: 16),
        AiInsightsCard(),
        SizedBox(height: 8),
        _FeedSection(),
        SizedBox(height: 100), // Bottom padding for FAB clearance
      ],
    );
  }
}

class _FeedSection extends StatelessWidget {
  const _FeedSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Recent Transactions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const TransactionFeed(),
      ],
    );
  }
}
