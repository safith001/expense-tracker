import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared/navigation/app_shell.dart';

class MedExpenseApp extends StatelessWidget {
  const MedExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedExpense',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const AppShell(),
    );
  }

  ThemeData _buildLightTheme() {
    // Primary accent: Soft Sage Green #5A7A6A (from MOBILE_RULES.md)
    const seedColor = Color(0xFF5A7A6A);
    const background = Color(0xFFFAF9F6); // Warm Cream
    const surface = Color(0xFFFAF9F6);
    const charcoal = Color(0xFF2D3748);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        surface: surface,
        onSurface: charcoal,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: charcoal,
        displayColor: charcoal,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: charcoal,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF5A7A6A),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F4F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF5A7A6A),
        unselectedItemColor: Color(0xFF9AA5B4),
        elevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const seedColor = Color(0xFF5A7A6A);
    const background = Color(0xFF1A202C); // Deep Slate (MOBILE_RULES.md)
    const surface = Color(0xFF2D3748);
    const lightText = Color(0xFFE2E8F0);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        surface: surface,
        onSurface: lightText,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: lightText,
        displayColor: lightText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: lightText,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2D3748),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF5A7A6A),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF3D4A5C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
