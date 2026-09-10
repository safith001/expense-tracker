import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';

import '../models/transaction_model.dart';

/// Singleton SQLite service.
/// All transaction reads/writes go through this class.
/// Schema is defined in SCHEMA.md §1.
class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService instance = DatabaseService._internal();

  static Database? _db;

  /// Returns the open database, initializing it on first access.
  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medexpense.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createSchema,
    );
  }

  /// Creates the transactions table as specified in SCHEMA.md §1
  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id            TEXT    PRIMARY KEY,
        amount        REAL    NOT NULL,
        currency      TEXT    NOT NULL DEFAULT 'BYN',
        type          TEXT    NOT NULL,
        category      TEXT    NOT NULL,
        paymentMethod TEXT    NOT NULL DEFAULT 'Card',
        date          TEXT    NOT NULL,
        note          TEXT,
        isSynced      INTEGER NOT NULL DEFAULT 0,
        createdAt     INTEGER NOT NULL
      )
    ''');
  }

  // ─── WRITE ─────────────────────────────────────────────────────────────────

  /// Inserts a new transaction. Returns the number of rows affected.
  Future<int> insertTransaction(Transaction t) async {
    final db = await database;
    return db.insert(
      'transactions',
      t.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing transaction in SQLite by its UUID.
  Future<int> updateTransaction(Transaction t) async {
    final db = await database;
    return db.update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  /// Deletes a transaction by its UUID id.
  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  /// Marks a list of transaction IDs as synced (isSynced = 1).
  Future<void> markTransactionsAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = ids.map((_) => '?').join(', ');
    await db.rawUpdate(
      'UPDATE transactions SET isSynced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  // ─── READ ──────────────────────────────────────────────────────────────────

  /// Returns all transactions, newest first.
  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  /// Returns all transactions for a given year + month.
  /// Used by the sync engine and dashboard.
  Future<List<Transaction>> getTransactionsForMonth(int year, int month) async {
    final db = await database;
    // ISO-8601 dates allow simple string prefix matching
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final rows = await db.query(
      'transactions',
      where: "date LIKE ?",
      whereArgs: ['$prefix%'],
      orderBy: 'date DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  /// Returns unsynced transactions from a given year + month.
  Future<List<Transaction>> getUnsyncedTransactionsForMonth(
      int year, int month) async {
    final db = await database;
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final rows = await db.query(
      'transactions',
      where: "date LIKE ? AND isSynced = 0",
      whereArgs: ['$prefix%'],
      orderBy: 'date DESC',
    );
    return rows.map(Transaction.fromMap).toList();
  }

  /// Computes the monthly summary: totalIncome, totalExpense, netSavings.
  /// Returns a named map for easy access.
  Future<MonthlySummary> getMonthlySummary(int year, int month) async {
    final transactions = await getTransactionsForMonth(year, month);
    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in transactions) {
      if (t.isExpense) {
        totalExpense += t.amount;
      } else {
        totalIncome += t.amount;
      }
    }

    return MonthlySummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: totalIncome - totalExpense,
    );
  }

  // ─── CSV Export ─────────────────────────────────────────────────────────────

  /// Exports all transactions as a CSV string (Settings screen export feature).
  Future<String> exportToCsv() async {
    final transactions = await getAllTransactions();
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Payment Method,Amount,Currency,Note,Synced');
    for (final t in transactions) {
      final note = (t.note ?? '').replaceAll(',', ';');
      buffer.writeln(
          '${t.date},${t.type.value},${t.category},${t.paymentMethod},${t.amount},${t.currency},$note,${t.isSynced == 1 ? "Yes" : "No"}');
    }
    return buffer.toString();
  }
}

// ─── Monthly Summary DTO ─────────────────────────────────────────────────────

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
  });

  Map<String, dynamic> toJson() => {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netSavings': netSavings,
      };
}
