import 'package:flutter/material.dart';

abstract final class BeeWiseColors {
  static const canvas = Color(0xFFF0F4FF);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF162CD4);
  static const primaryPressed = Color(0xFF280F91);
  static const accent = Color(0xFFFFC500);
  static const accentSoft = Color(0xFFFFF8E0);
  static const highlight = Color(0xFFFADC76);
  static const ink = Color(0xFF0C0C0B);
  static const muted = Color(0xFF435580);
  static const border = Color(0xFFDCE8FB);
  static const borderStrong = Color(0xFFC9D1E3);
  static const success = Color(0xFF1F7A1F);
  static const successSoft = Color(0xFFECFBEC);
  static const warning = Color(0xFF905B0F);
  static const error = Color(0xFFDC2626);
  static const errorSoft = Color(0xFFFEF7F6);
  static const disabled = Color(0xFFDCE8FB);
}

abstract final class BeeWiseSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
}

abstract final class BeeWiseRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const field = 16.0;
  static const card = 24.0;
  static const panel = 32.0;
  static const full = 999.0;
}

abstract final class BeeWiseElevation {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x14280F91), blurRadius: 8, offset: Offset(0, 3)),
  ];
  static const pop = <BoxShadow>[
    BoxShadow(color: Color(0x29280F91), blurRadius: 8, offset: Offset(0, 4)),
  ];
}

class BeeWiseTheme {
  static ThemeData get light {
    final textTheme = TextTheme(
      displayLarge: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w800,
        color: BeeWiseColors.ink,
      ),
      headlineLarge: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w800,
        color: BeeWiseColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w800,
        color: BeeWiseColors.ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w700,
        color: BeeWiseColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Be Vietnam Pro',
        fontSize: 16,
        height: 24 / 16,
        color: BeeWiseColors.ink,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Be Vietnam Pro',
        fontSize: 14,
        height: 21 / 14,
        color: BeeWiseColors.ink,
      ),
      bodySmall: const TextStyle(
        fontFamily: 'Be Vietnam Pro',
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: BeeWiseColors.muted,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'Be Vietnam Pro',
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
        color: BeeWiseColors.ink,
      ),
      labelMedium: const TextStyle(
        fontFamily: 'Be Vietnam Pro',
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: BeeWiseColors.ink,
      ),
    );
    final colorScheme = ColorScheme.fromSeed(
      seedColor: BeeWiseColors.primary,
      brightness: Brightness.light,
      primary: BeeWiseColors.primary,
      onPrimary: Colors.white,
      secondary: BeeWiseColors.accent,
      onSecondary: BeeWiseColors.ink,
      tertiary: BeeWiseColors.accent,
      onTertiary: BeeWiseColors.ink,
      surface: BeeWiseColors.surface,
      onSurface: BeeWiseColors.ink,
      error: BeeWiseColors.error,
      onError: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: BeeWiseColors.canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: BeeWiseColors.surface,
        foregroundColor: BeeWiseColors.ink,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: textTheme.headlineMedium,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: BeeWiseColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BeeWiseRadius.card),
          side: const BorderSide(color: BeeWiseColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BeeWiseColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BeeWiseSpace.x4,
          vertical: BeeWiseSpace.x3,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: BeeWiseColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BeeWiseRadius.field),
          borderSide: const BorderSide(color: BeeWiseColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BeeWiseRadius.field),
          borderSide: const BorderSide(color: BeeWiseColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BeeWiseRadius.field),
          borderSide: const BorderSide(color: BeeWiseColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BeeWiseRadius.field),
          borderSide: const BorderSide(color: BeeWiseColors.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          backgroundColor: BeeWiseColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BeeWiseRadius.full),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: BeeWiseColors.primary,
          side: const BorderSide(color: BeeWiseColors.primary),
          textStyle: textTheme.labelLarge?.copyWith(
            color: BeeWiseColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BeeWiseRadius.full),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: BeeWiseColors.surface,
        indicatorColor: BeeWiseColors.highlight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontSize: 14,
            height: 20 / 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? BeeWiseColors.ink : BeeWiseColors.muted,
          );
        }),
      ),
      dividerColor: BeeWiseColors.border,
      visualDensity: VisualDensity.standard,
    );
  }
}
