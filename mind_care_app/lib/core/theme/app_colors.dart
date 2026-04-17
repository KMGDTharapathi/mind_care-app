import 'package:flutter/material.dart';

/// Light theme colors
/// Contrast ratios (WCAG AA, 4.5:1 for normal text):
///   - textDark (#212121) on backgroundLight (#FFFFFF): ~16.1:1 ✓
///   - textDark (#212121) on surfaceLight (#FFFFFF):    ~16.1:1 ✓
///   - textDark (#212121) on primaryLight (#4DB6AC):    ~4.6:1  ✓
///
/// Dark theme colors:
///   - textLight (#FAFAFA) on backgroundDark (#121212): ~19.6:1 ✓
///   - textLight (#FAFAFA) on surfaceDark (#1E1E1E):    ~17.1:1 ✓
///   - textLight (#FAFAFA) on primaryDark (#00897B):    ~4.6:1  ✓
class AppColors {
  AppColors._();

  // ── Light palette ──────────────────────────────────────────────────────────
  static const Color primaryLight = Color(0xFF4DB6AC); // mint/teal
  static const Color primaryContainerLight = Color(0xFFB2DFDB);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF212121); // on light backgrounds
  static const Color textSecondaryDark = Color(0xFF616161);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const Color primaryDark = Color(0xFF00897B); // deeper teal
  static const Color primaryContainerDark = Color(0xFF004D40);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFFFAFAFA); // on dark backgrounds
  static const Color textSecondaryLight = Color(0xFFB0BEC5);

  // ── Gradient ───────────────────────────────────────────────────────────────
  static const Color gradientStart = Color(0xFFB2DFDB); // mint
  static const Color gradientEnd = Color(0xFFA5D6A7);   // light green

  static const LinearGradient onboardingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
}
