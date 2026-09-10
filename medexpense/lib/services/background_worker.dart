import 'package:workmanager/workmanager.dart';

import '../services/sync_service.dart';

/// Manages WorkManager background task registration and execution.
/// Spec: MOBILE_PRD.md §4, idea.md §3.D
class BackgroundWorker {
  BackgroundWorker._();

  /// Unique task name registered with WorkManager
  static const String taskName = 'medexpense_end_of_month_sync';

  /// Registers a periodic background task that runs every 24 hours.
  /// WorkManager will enforce connectivity constraints (NetworkType.connected).
  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      // Run every 24 hours — WorkManager may fire within a ~15-min window of this
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        // Only sync when device has network (MOBILE_PRD.md §3)
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// The logic executed inside the WorkManager callback.
  ///
  /// Checks if today is the last day of the current month:
  ///   `DateTime.now().add(Duration(days: 1)).day == 1`
  /// If true, triggers the month-end sync.
  ///
  /// Called from the top-level [callbackDispatcher] in main.dart.
  static Future<void> runSyncIfEndOfMonth() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    // Is today the last day of this month?
    if (tomorrow.day == 1) {
      await SyncService.instance.syncMonth(
        year: now.year,
        month: now.month,
      );
    }
  }
}
