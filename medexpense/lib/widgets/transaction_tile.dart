import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';

/// A single row in the transaction feed.
/// Shows: category icon, category name, note, amount, and payment method badge.
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = transaction.isExpense;
    final amountColor = isExpense
        ? const Color(0xFFE53E3E)
        : const Color(0xFF38A169);
    final amountPrefix = isExpense ? '−' : '+';
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE53E3E).withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Color(0xFFE53E3E)),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Transaction'),
            content: const Text(
                'Are you sure you want to delete this transaction? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: isDark ? const Color(0xFF2D3748) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
            // Category icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _categoryColor(transaction.category).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _categoryEmoji(transaction.category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Category + note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF2D3748),
                    ),
                  ),
                  if (transaction.note != null &&
                      transaction.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF718096)
                            : const Color(0xFF9AA5B4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Payment method badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF4A5568)
                          : const Color(0xFFF0F4F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      transaction.paymentMethod,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFCBD5E0)
                            : const Color(0xFF5A7A6A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${fmt.format(transaction.amount)} ${transaction.currency}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(transaction.parsedDate),
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
    ),
  ),
),
);
  }

  // Maps MBBS categories to emojis for quick visual scanning
  String _categoryEmoji(String category) {
    const map = {
      'Groceries & Food': '🛒',
      'Hostel / Rent': '🏠',
      'University Tuition': '🎓',
      'Medical Books & Atlas': '📚',
      'Lab Equipment & Scrubs': '🥼',
      'Metro & Transit': '🚇',
      'Cafes & Study': '☕',
      'Personal Care': '✨',
      'Utilities / Wi-Fi': '📶',
      'Emergency': '🚨',
      'Family Allowance': '💝',
      'Stipend / Scholarship': '🏅',
      'Savings': '💰',
      'Other': '📋',
    };
    return map[category] ?? '💳';
  }

  Color _categoryColor(String category) {
    const map = {
      'Groceries & Food': Color(0xFF38A169),
      'Hostel / Rent': Color(0xFF3182CE),
      'University Tuition': Color(0xFF805AD5),
      'Medical Books & Atlas': Color(0xFF5A7A6A),
      'Lab Equipment & Scrubs': Color(0xFF00B5D8),
      'Metro & Transit': Color(0xFFED8936),
      'Cafes & Study': Color(0xFFD69E2E),
      'Personal Care': Color(0xFFE53E3E),
      'Utilities / Wi-Fi': Color(0xFF667EEA),
      'Emergency': Color(0xFFE53E3E),
      'Family Allowance': Color(0xFFED64A6),
      'Stipend / Scholarship': Color(0xFF38A169),
      'Savings': Color(0xFF5A7A6A),
      'Other': Color(0xFF718096),
    };
    return map[category] ?? const Color(0xFF718096);
  }
}
