import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B1120);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF1E293B);
  static const Color cardSoft = Color(0xFF263449);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardSoft = Color(0xFFE2E8F0);

  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF22D3EE);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF334155);
  static const Color lightTextMuted = Color(0xFF64748B);

  static const LinearGradient mainGradient = LinearGradient(
    colors: [
      primary,
      secondary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      scaffoldBackground: background,
      surfaceColor: surface,
      cardColor: card,
      textColor: textPrimary,
      mutedTextColor: textMuted,
      inputFillColor: card,
      snackBarColor: card,
    );
  }

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      scaffoldBackground: lightBackground,
      surfaceColor: lightSurface,
      cardColor: lightCard,
      textColor: lightTextPrimary,
      mutedTextColor: lightTextMuted,
      inputFillColor: lightCard,
      snackBarColor: lightTextPrimary,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color surfaceColor,
    required Color cardColor,
    required Color textColor,
    required Color mutedTextColor,
    required Color inputFillColor,
    required Color snackBarColor,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackground,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: surfaceColor,
        error: danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? cardSoft : lightCardSoft,
          disabledForegroundColor: mutedTextColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(
            color: primary.withValues(alpha: 0.45),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        hintStyle: TextStyle(
          color: mutedTextColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackBarColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.12),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.15),
      ),
    );
  }
}