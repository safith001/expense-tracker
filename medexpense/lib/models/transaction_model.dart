import 'package:uuid/uuid.dart';

// ─── MBBS Specialized Categories ─────────────────────────────────────────────
// Source: idea.md §3.C and MOBILE_PRD.md §2

const List<String> kExpenseCategories = [
  'Groceries & Food',
  'Hostel / Rent',
  'University Tuition',
  'Medical Books & Atlas',
  'Lab Equipment & Scrubs',
  'Metro & Transit',
  'Cafes & Study',
  'Personal Care',
  'Utilities / Wi-Fi',
  'Emergency',
];

const List<String> kIncomeCategories = [
  'Family Allowance',
  'Stipend / Scholarship',
  'Savings',
  'Other',
];

/// Supported currency values
const List<String> kCurrencies = ['BYN', 'USD'];

/// Payment method options
const List<String> kPaymentMethods = ['Card', 'Cash'];

// ─── Transaction Type Enum ────────────────────────────────────────────────────

enum TransactionType {
  income('income'),
  expense('expense');

  const TransactionType(this.value);
  final String value;

  factory TransactionType.fromString(String s) =>
      s == 'income' ? TransactionType.income : TransactionType.expense;
}

// ─── Transaction Model ────────────────────────────────────────────────────────

class Transaction {
  /// UUID v4 string primary key (from SCHEMA.md)
  final String id;

  /// Monetary value e.g. 45.50
  final double amount;

  /// 'BYN' or 'USD'
  final String currency;

  /// 'income' or 'expense'
  final TransactionType type;

  /// One of kExpenseCategories / kIncomeCategories
  final String category;

  /// 'Card' or 'Cash'
  final String paymentMethod;

  /// ISO-8601 string YYYY-MM-DDTHH:mm:ss
  final String date;

  /// Optional user note
  final String? note;

  /// 0 = not synced, 1 = synced to Google Sheets
  final int isSynced;

  /// System epoch milliseconds
  final int createdAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.date,
    this.note,
    this.isSynced = 0,
    required this.createdAt,
  });

  /// Factory: create a brand new transaction (auto-generates id + createdAt)
  factory Transaction.create({
    required double amount,
    required String currency,
    required TransactionType type,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String? note,
  }) {
    return Transaction(
      id: const Uuid().v4(),
      amount: amount,
      currency: currency,
      type: type,
      category: category,
      paymentMethod: paymentMethod,
      date: date.toIso8601String(),
      note: note,
      isSynced: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ── SQLite interop ──────────────────────────────────────────────────────────

  /// Converts to a Map for SQLite insert/update
  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'type': type.value,
        'category': category,
        'paymentMethod': paymentMethod,
        'date': date,
        'note': note,
        'isSynced': isSynced,
        'createdAt': createdAt,
      };

  /// Reconstructs from a SQLite row Map
  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        amount: (map['amount'] as num).toDouble(),
        currency: map['currency'] as String,
        type: TransactionType.fromString(map['type'] as String),
        category: map['category'] as String,
        paymentMethod: map['paymentMethod'] as String,
        date: map['date'] as String,
        note: map['note'] as String?,
        isSynced: map['isSynced'] as int,
        createdAt: map['createdAt'] as int,
      );

  // ── Google Apps Script sync payload ────────────────────────────────────────

  /// Formats this transaction for the JSON POST payload (from SCHEMA.md §3)
  Map<String, dynamic> toSyncJson() => {
        'date': date.replaceFirst('T', ' ').substring(0, 16), // "YYYY-MM-DD HH:mm"
        'type': type.value[0].toUpperCase() + type.value.substring(1), // "Income" / "Expense"
        'category': category,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'note': note ?? '',
      };

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Returns the parsed DateTime from the ISO-8601 date string
  DateTime get parsedDate => DateTime.parse(date);

  /// Returns true if this is an expense
  bool get isExpense => type == TransactionType.expense;

  /// Returns a copy with isSynced = 1
  Transaction markSynced() => Transaction(
        id: id,
        amount: amount,
        currency: currency,
        type: type,
        category: category,
        paymentMethod: paymentMethod,
        date: date,
        note: note,
        isSynced: 1,
        createdAt: createdAt,
      );

  @override
  String toString() =>
      'Transaction(id: $id, amount: $amount $currency, type: ${type.value}, category: $category)';
}
