import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_model.dart';
import '../services/database_service.dart';

// ─── Transaction List Provider ────────────────────────────────────────────────

/// Async provider that loads ALL transactions from SQLite.
/// Used by the History screen.
final allTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  return DatabaseService.instance.getAllTransactions();
});

/// Async provider for the CURRENT month's transactions.
/// Used by the Dashboard screen's transaction feed.
final currentMonthTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final now = DateTime.now();
  return DatabaseService.instance.getTransactionsForMonth(now.year, now.month);
});

// ─── Transaction CRUD Notifier ────────────────────────────────────────────────

/// Manages transaction write operations (add, delete).
/// After each mutation, invalidates the relevant read providers.
class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  TransactionNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// Adds a new transaction to SQLite and refreshes providers.
  Future<void> addTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseService.instance.insertTransaction(transaction);
      // Invalidate both list providers so the UI re-fetches
      _ref.invalidate(allTransactionsProvider);
      _ref.invalidate(currentMonthTransactionsProvider);
      _ref.invalidate(dashboardSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Deletes a transaction and refreshes providers.
  Future<void> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      await DatabaseService.instance.deleteTransaction(id);
      _ref.invalidate(allTransactionsProvider);
      _ref.invalidate(currentMonthTransactionsProvider);
      _ref.invalidate(dashboardSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>(
  (ref) => TransactionNotifier(ref),
);

// ─── Dashboard Summary Provider ───────────────────────────────────────────────

/// Computes totalIncome, totalExpense, netSavings for the current month.
/// Automatically recomputed when [currentMonthTransactionsProvider] changes.
final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final transactionsAsync = ref.watch(currentMonthTransactionsProvider);
  return transactionsAsync.when(
    data: (transactions) {
      double income = 0;
      double expense = 0;
      for (final t in transactions) {
        if (t.isExpense) {
          expense += t.amount;
        } else {
          income += t.amount;
        }
      }
      return DashboardSummary(
        totalIncome: income,
        totalExpense: expense,
        netSavings: income - expense,
      );
    },
    loading: () => const DashboardSummary(
        totalIncome: 0, totalExpense: 0, netSavings: 0),
    error: (_, __) => const DashboardSummary(
        totalIncome: 0, totalExpense: 0, netSavings: 0),
  );
});

/// Computes per-category spending totals for the donut chart.
final categoryBreakdownProvider =
    Provider<Map<String, double>>((ref) {
  final transactionsAsync = ref.watch(currentMonthTransactionsProvider);
  return transactionsAsync.when(
    data: (transactions) {
      final Map<String, double> breakdown = {};
      for (final t in transactions) {
        if (t.isExpense) {
          breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
        }
      }
      return breakdown;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// ─── DashboardSummary DTO ─────────────────────────────────────────────────────

class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
  });
}
