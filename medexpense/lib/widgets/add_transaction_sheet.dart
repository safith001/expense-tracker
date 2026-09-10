import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';

/// Quick-add and edit bottom sheet.
/// No system keyboard — uses a fully custom numeric pad per MOBILE_RULES.md §3.
class AddTransactionSheet extends ConsumerStatefulWidget {
  final Transaction? initialTransaction;

  const AddTransactionSheet({super.key, this.initialTransaction});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  String _amountDisplay = '0';   // Raw digit string shown on display
  TransactionType _type = TransactionType.expense;
  String _selectedCategory = kExpenseCategories.first;
  String _selectedPayment = 'Card';
  DateTime _selectedDate = DateTime.now();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  late final AnimationController _slideCtrl;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    if (widget.initialTransaction != null) {
      final init = widget.initialTransaction!;
      _amountDisplay = init.amount % 1 == 0
          ? init.amount.toInt().toString()
          : init.amount.toString();
      _type = init.type;
      _selectedCategory = init.category;
      _selectedPayment = init.paymentMethod;
      _selectedDate = init.parsedDate;
      if (init.note != null) {
        _noteController.text = init.note!;
      }
    }
    _slideCtrl = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic);
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Keypad logic ──────────────────────────────────────────────────────────

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == '⌫') {
        if (_amountDisplay.length > 1) {
          _amountDisplay = _amountDisplay.substring(0, _amountDisplay.length - 1);
        } else {
          _amountDisplay = '0';
        }
      } else if (key == '.') {
        if (!_amountDisplay.contains('.')) {
          _amountDisplay += '.';
        }
      } else {
        if (_amountDisplay == '0') {
          _amountDisplay = key;
        } else if (_amountDisplay.length < 10) {
          // Limit decimal places to 2
          if (_amountDisplay.contains('.')) {
            final parts = _amountDisplay.split('.');
            if (parts[1].length < 2) _amountDisplay += key;
          } else {
            _amountDisplay += key;
          }
        }
      }
    });
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final amount = double.tryParse(_amountDisplay) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final currency = ref.read(activeCurrencyProvider);

    if (widget.initialTransaction != null) {
      final old = widget.initialTransaction!;
      final updated = Transaction(
        id: old.id,
        amount: amount,
        currency: currency,
        type: _type,
        category: _selectedCategory,
        paymentMethod: _selectedPayment,
        date: _selectedDate.toIso8601String(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        isSynced: 0,
        createdAt: old.createdAt,
      );
      await ref.read(transactionNotifierProvider.notifier).updateTransaction(updated);
    } else {
      final transaction = Transaction.create(
        amount: amount,
        currency: currency,
        type: _type,
        category: _selectedCategory,
        paymentMethod: _selectedPayment,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      await ref.read(transactionNotifierProvider.notifier).addTransaction(transaction);
    }

    if (mounted) Navigator.of(context).pop();
  }

  void _onTypeChange(TransactionType newType) {
    setState(() {
      _type = newType;
      // Reset category to first of the new type list
      _selectedCategory = newType == TransactionType.expense
          ? kExpenseCategories.first
          : kIncomeCategories.first;
    });
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedDate.hour,
            _selectedDate.minute,
          ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A202C) : const Color(0xFFFAF9F6);
    final cardColor = isDark ? const Color(0xFF2D3748) : Colors.white;
    final currency = ref.watch(activeCurrencyProvider);
    final categories = _type == TransactionType.expense
        ? kExpenseCategories
        : kIncomeCategories;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_slideAnim),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF4A5568)
                          : const Color(0xFFCBD5E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.initialTransaction != null
                            ? 'Edit Transaction'
                            : 'Log Transaction',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF2D3748),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // ── Expense / Income Toggle ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _TypeToggle(
                    selected: _type,
                    onChanged: _onTypeChange,
                    cardColor: cardColor,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Amount Display ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        currency,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF718096)
                              : const Color(0xFF9AA5B4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _amountDisplay,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: _type == TransactionType.expense
                              ? const Color(0xFFE53E3E)
                              : const Color(0xFF38A169),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Custom Numeric Keypad ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _NumericKeypad(onKeyTap: _onKeyTap),
                ),
                const SizedBox(height: 16),

                // ── Category Chips ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
                  child: Text(
                    'Category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF718096)
                          : const Color(0xFF9AA5B4),
                    ),
                  ),
                ),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final selected = cat == _selectedCategory;
                      return FilterChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        selectedColor:
                            const Color(0xFF5A7A6A).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF5A7A6A),
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF5A7A6A)
                              : (isDark
                                  ? const Color(0xFFCBD5E0)
                                  : const Color(0xFF4A5568)),
                        ),
                        backgroundColor:
                            isDark ? const Color(0xFF2D3748) : Colors.white,
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF5A7A6A)
                              : Colors.transparent,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ── Payment Method + Date Row ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Payment method toggle
                      Expanded(
                        child: _PaymentToggle(
                          selected: _selectedPayment,
                          onChanged: (v) =>
                              setState(() => _selectedPayment = v),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Date picker button
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_rounded,
                            size: 14),
                        label: Text(
                          DateFormat('dd MMM').format(_selectedDate),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Note Field ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add a note (optional)',
                      prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                    ),
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Save Button ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5A7A6A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              widget.initialTransaction != null
                                  ? 'Update Transaction'
                                  : 'Save Transaction',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Type Toggle ─────────────────────────────────────────────────────────────

class _TypeToggle extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;
  final Color cardColor;

  const _TypeToggle({
    required this.selected,
    required this.onChanged,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleBtn(
            label: 'Expense',
            icon: Icons.arrow_upward_rounded,
            selected: selected == TransactionType.expense,
            activeColor: const Color(0xFFE53E3E),
            onTap: () => onChanged(TransactionType.expense),
          ),
          _ToggleBtn(
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            selected: selected == TransactionType.income,
            activeColor: const Color(0xFF38A169),
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? activeColor : Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Payment Toggle ──────────────────────────────────────────────────────────

class _PaymentToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _PaymentToggle({
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: kPaymentMethods.map((method) {
          final sel = method == selected;
          return GestureDetector(
            onTap: () => onChanged(method),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFF5A7A6A)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                method,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : Colors.grey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Custom Numeric Keypad ────────────────────────────────────────────────────

class _NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;

  const _NumericKeypad({required this.onKeyTap});

  static const _keys = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: _keys.map((row) {
        return Row(
          children: row.map((key) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _KeyButton(
                  label: key,
                  onTap: () => onKeyTap(key),
                  isDark: isDark,
                  isBackspace: key == '⌫',
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isBackspace;

  const _KeyButton({
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isBackspace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF2D3748) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: isBackspace
              ? Icon(
                  Icons.backspace_rounded,
                  color: isDark
                      ? const Color(0xFFCBD5E0)
                      : const Color(0xFF4A5568),
                  size: 20,
                )
              : Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF2D3748),
                  ),
                ),
        ),
      ),
    );
  }
}
