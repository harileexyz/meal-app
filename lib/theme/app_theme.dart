import 'package:flutter/material.dart';

/// Central place to tweak the application's look and feel.
class AppTheme {
  const AppTheme._();

  // Brand colors.
  static const Color primary = Color(0xFF2F855A);
  static const Color secondary = Color(0xFFF6AD55);
  static const Color neutralText = Color(0xFF1F2933);
  static const Color background = Color(0xFFFDFCF9);
  static const Color error = Color(0xFFDC2626);
  static const Color buttonRed = Color(0xFFE53E3E);

  // Spacing & radii used across screens.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: background,
        error: error,
        onSurface: neutralText,
        onPrimary: background,
      ),
      textTheme: ThemeData.light().textTheme,
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        elevation: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: cardRadius),
        ),
      ),
    );
  }
}
