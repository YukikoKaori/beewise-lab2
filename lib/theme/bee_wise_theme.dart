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
    // Type scale (sp): 28 / 24 / 22 / 20 / 18 headings (Nunito),
    // 16 titles + body-large, 14 body + labels, 12 captions (Be Vietnam Pro).
    TextStyle heading(double size, double line, FontWeight weight) => TextStyle(
      fontFamily: 'Nunito',
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      color: BeeWiseColors.ink,
    );
    TextStyle body(
      double size,
      double line, {
      FontWeight weight = FontWeight.w400,
      Color color = BeeWiseColors.ink,
    }) => TextStyle(
      fontFamily: 'Be Vietnam Pro',
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      color: color,
    );
    final textTheme = TextTheme(
      displayLarge: heading(28, 36, FontWeight.w800),
      displayMedium: heading(24, 30, FontWeight.w800),
      displaySmall: heading(22, 28, FontWeight.w800),
      headlineLarge: heading(24, 30, FontWeight.w800),
      headlineMedium: heading(20, 26, FontWeight.w800),
      headlineSmall: heading(18, 24, FontWeight.w800),
      titleLarge: heading(16, 22, FontWeight.w700),
      titleMedium: body(16, 22, weight: FontWeight.w600),
      titleSmall: body(14, 20, weight: FontWeight.w600),
      bodyLarge: body(16, 24),
      bodyMedium: body(14, 21),
      bodySmall: body(
        14,
        20,
        weight: FontWeight.w500,
        color: BeeWiseColors.muted,
      ),
      labelLarge: body(14, 20, weight: FontWeight.w600),
      labelMedium: body(14, 20, weight: FontWeight.w500),
      labelSmall: body(12, 16, weight: FontWeight.w600),
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
      fontFamily: 'Be Vietnam Pro',
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
        helperStyle: textTheme.labelSmall?.copyWith(
          color: BeeWiseColors.muted,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: textTheme.labelSmall?.copyWith(color: BeeWiseColors.error),
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
          textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
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
          textStyle: textTheme.titleMedium?.copyWith(
            color: BeeWiseColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BeeWiseRadius.full),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: BeeWiseColors.surface,
        indicatorColor: BeeWiseColors.highlight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontSize: 12,
            height: 16 / 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? BeeWiseColors.ink : BeeWiseColors.muted,
          );
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
          foregroundColor: BeeWiseColors.primary,
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelLarge,
        backgroundColor: BeeWiseColors.surface,
        selectedColor: BeeWiseColors.highlight,
        side: const BorderSide(color: BeeWiseColors.borderStrong),
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      dividerColor: BeeWiseColors.border,
      visualDensity: VisualDensity.standard,
    );
  }
}
