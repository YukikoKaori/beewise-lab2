import 'package:beewise_core/beewise_core.dart';
import 'package:flutter/material.dart';

export 'package:beewise_core/beewise_core.dart'
    show BeeWiseColors, BeeWiseSpace, BeeWiseRadius, BeeWiseElevation;

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
