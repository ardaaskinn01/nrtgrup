import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Turuncu / Siyah / Beyaz Renk Paleti
  static const Color primaryOrange = Color(0xFFFF7A00);
  static const Color primaryOrangeLight = Color(0xFFFF9A3C);
  static const Color primaryOrangeDark = Color(0xFFD96500);

  static const Color pureBlack = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF151515);
  static const Color darkSurfaceElevated = Color(0xFF1F1F1F);
  static const Color darkBorder = Color(0xFF2B2B2B);

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightBackground = Color(0xFFF6F6F6);
  static const Color lightInputFill = Color(0xFFF0F0F0);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // Durum Renkleri
  static const Color successColor = Color(0xFF16A34A);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFF59E0B);

  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF616161);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA3A3A3);

  // Açık Tema
  static ThemeData get lightTheme {
    final baseText = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryOrange,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        secondary: pureBlack,
        tertiary: primaryOrangeDark,
        error: errorColor,
        surface: pureWhite,
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onError: pureWhite,
        onSurface: lightTextPrimary,
        outline: lightBorder,
      ),
      scaffoldBackgroundColor: lightBackground,
      dividerColor: lightBorder,
      hintColor: lightTextSecondary,
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: lightTextPrimary),
        displayMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: lightTextPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: lightTextPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: lightTextPrimary),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: lightTextPrimary),
        bodyLarge: GoogleFonts.inter(color: lightTextPrimary),
        bodyMedium: GoogleFonts.inter(color: lightTextSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: lightTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: pureWhite,
        foregroundColor: lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: lightTextPrimary),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: pureWhite,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        color: pureWhite,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputFill,
        hintStyle: const TextStyle(color: lightTextSecondary),
        labelStyle: const TextStyle(color: lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: pureWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: pureWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightTextPrimary,
          side: const BorderSide(color: lightBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryOrangeDark),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightInputFill,
        selectedColor: primaryOrange.withValues(alpha: 0.16),
        checkmarkColor: primaryOrange,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: lightTextPrimary),
        side: const BorderSide(color: lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: pureWhite,
        elevation: 3,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: pureBlack,
        contentTextStyle: GoogleFonts.inter(color: pureWhite),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Koyu Tema
  static ThemeData get darkTheme {
    final baseText = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: pureWhite,
        tertiary: primaryOrangeLight,
        error: errorColor,
        surface: darkSurface,
        onPrimary: pureBlack,
        onSecondary: pureBlack,
        onError: pureWhite,
        onSurface: darkTextPrimary,
        outline: darkBorder,
      ),
      scaffoldBackgroundColor: pureBlack,
      dividerColor: darkBorder,
      hintColor: darkTextSecondary,
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: darkTextPrimary),
        displayMedium: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: darkTextPrimary),
        headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge: GoogleFonts.inter(color: darkTextPrimary),
        bodyMedium: GoogleFonts.inter(color: darkTextSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: darkTextSecondary),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: pureBlack,
        foregroundColor: darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: darkTextPrimary),
        iconTheme: const IconThemeData(color: darkTextPrimary),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceElevated,
        hintStyle: const TextStyle(color: darkTextSecondary),
        labelStyle: const TextStyle(color: darkTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: pureBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: pureBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: darkBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryOrangeLight),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceElevated,
        selectedColor: primaryOrange.withValues(alpha: 0.22),
        checkmarkColor: primaryOrange,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: darkTextPrimary),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: pureBlack,
        elevation: 3,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceElevated,
        contentTextStyle: GoogleFonts.inter(color: darkTextPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: darkBorder),
        ),
      ),
    );
  }
}
