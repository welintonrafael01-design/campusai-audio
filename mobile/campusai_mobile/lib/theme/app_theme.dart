import 'package:flutter/material.dart';

class AppTheme {
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusExtraLarge = 24;

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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: surfaceColor,
      error: danger,
    );
    final textTheme = (isDark
            ? Typography.material2021().white
            : Typography.material2021().black)
        .copyWith(
      displaySmall: TextStyle(
        color: textColor,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        height: 1.08,
      ),
      headlineSmall: TextStyle(
        color: textColor,
        fontSize: 26,
        fontWeight: FontWeight.w900,
        height: 1.15,
      ),
      titleLarge: TextStyle(
        color: textColor,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        color: textColor,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        height: 1.25,
      ),
      bodyLarge: TextStyle(
        color: textColor,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: textColor,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: mutedTextColor,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      scaffoldBackgroundColor: scaffoldBackground,
      primaryColor: primary,
      colorScheme: colorScheme,
      textTheme: textTheme,
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? cardSoft : lightCardSoft,
          disabledForegroundColor: mutedTextColor,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark ? cardSoft : lightCardSoft,
          disabledForegroundColor: mutedTextColor,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
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
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
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
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          foregroundColor: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        hintStyle: TextStyle(
          color: mutedTextColor,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.60),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.60),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primary,
        disabledColor: isDark ? cardSoft : lightCardSoft,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.60),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusExtraLarge),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        modalBackgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusExtraLarge),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: surfaceColor,
        indicatorColor: primary.withValues(alpha: 0.20),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : mutedTextColor,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackBarColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
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
