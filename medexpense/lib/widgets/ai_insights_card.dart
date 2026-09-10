import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/settings_provider.dart';

/// Displays the cached Gemini AI financial coaching summary.
/// Styled with the dusty lavender (#805AD5) AI badge color from MOBILE_RULES.md.
class AiInsightsCard extends ConsumerWidget {
  const AiInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiSummary = ref.watch(aiSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D3748) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF805AD5).withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF805AD5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Gemini Financial Mentor',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AI',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Summary content
          Padding(
            padding: const EdgeInsets.all(16),
            child: aiSummary.isEmpty
                ? _EmptyState(isDark: isDark)
                : Text(
                    aiSummary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      height: 1.65,
                      color: isDark
                          ? const Color(0xFFCBD5E0)
                          : const Color(0xFF4A5568),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.pending_rounded,
          color: const Color(0xFF805AD5).withOpacity(0.5),
          size: 32,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Your AI coaching summary will appear here after your first month-end sync.\n\nConfigure your Google Apps Script URL in Settings to activate this feature.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF718096)
                  : const Color(0xFF9AA5B4),
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}
