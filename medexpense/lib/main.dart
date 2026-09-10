import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'services/database_service.dart';
import 'services/background_worker.dart';

/// WorkManager callback dispatcher — must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == BackgroundWorker.taskName) {
      await BackgroundWorker.runSyncIfEndOfMonth();
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database
  await DatabaseService.instance.database;

  // Register WorkManager for daily end-of-month sync check
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await BackgroundWorker.registerPeriodicTask();

  runApp(
    // ProviderScope is the root of Riverpod — wraps the entire widget tree
    const ProviderScope(
      child: MedExpenseApp(),
    ),
  );
}
