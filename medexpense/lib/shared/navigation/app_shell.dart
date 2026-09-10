import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../screens/dashboard_screen.dart';
import '../../screens/history_screen.dart';
import '../../screens/settings_screen.dart';
import '../../widgets/add_transaction_sheet.dart';


/// Single-activity shell with Bottom Navigation Bar + FAB.
/// Navigation architecture from NAVIGATION.md.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // Rounded top corners for the bottom sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        // IndexedStack keeps state of each tab alive (no re-fetch on tab switch)
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        tooltip: 'Log Transaction',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              selected: _selectedIndex == 0,
              onTap: () => _onNavTap(0),
            ),
            // Empty space for FAB notch
            const SizedBox(width: 48),
            _NavItem(
              icon: Icons.history_rounded,
              label: 'History',
              selected: _selectedIndex == 1,
              onTap: () => _onNavTap(1),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              selected: _selectedIndex == 2,
              onTap: () => _onNavTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
