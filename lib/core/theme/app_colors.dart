import 'package:flutter/material.dart';

/// Central brand palette — extracted from the ENGLISH CORE logo and UI reference.
class AppColors {
  // Brand primary (deep royal blue / purple)
  static const Color primary = Color(0xFF4338CA);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color secondary = Color(0xFF6D28D9);

  // Lavender tints
  static const Color lavender = Color(0xFFEEF0FF);
  static const Color lavenderSoft = Color(0xFFF6F7FF);

  // Cream / beige accent (from logo)
  static const Color cream = Color(0xFFF6EEDF);
  static const Color creamAccent = Color(0xFFC9A24B);

  // Neutrals
  static const Color background = Color(0xFFF8F8FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1E2240);
  static const Color textSoft = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE7E9F2);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Dark theme
  static const Color darkBackground = Color(0xFF0D1126);
  static const Color darkSurface = Color(0xFF161B38);
  static const Color darkSurfaceAlt = Color(0xFF1E2450);
  static const Color darkText = Color(0xFFF3F4FF);
  static const Color darkTextSoft = Color(0xFF9CA3C9);
  static const Color darkDivider = Color(0xFF262C54);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [lavender, Color(0xFFFDF4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}