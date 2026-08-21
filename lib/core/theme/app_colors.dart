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

  // ---------------------------------------------------------------------------
  // Dark theme — comfortable charcoal with a subtle indigo brand tint.
  // Deliberately NOT pure black and NOT an inversion of light: surfaces are
  // layered (background < surface < surfaceAlt) so cards/inputs stay readable
  // while text keeps strong contrast.
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF15171F);
  static const Color darkSurface = Color(0xFF1E212B);
  static const Color darkSurfaceAlt = Color(0xFF2A2E3C);
  static const Color darkText = Color(0xFFF2F3F8);
  static const Color darkTextSoft = Color(0xFFA9B0C5);
  static const Color darkDivider = Color(0xFF363B4D);

  // Brand colors tuned for dark backgrounds (readability).
  static const Color primaryOnDark = Color(0xFF8B93F8);
  static const Color secondaryOnDark = Color(0xFFB79CF8);

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

  static const LinearGradient softGradientDark = LinearGradient(
    colors: [Color(0xFF232738), Color(0xFF282238)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Theme-aware palette resolved from the current [Theme] brightness.
///
/// Use this instead of hardcoding [AppColors.text] / [AppColors.lavender] /
/// [AppColors.background] so every screen follows dark mode automatically.
class AppPalette {
  final Color background;
  final Color surface;
  final Color surfaceAlt; // "lavender" equivalent
  final Color text;
  final Color textSoft;
  final Color divider;
  final Color primary;
  final Color secondary;
  final LinearGradient softGradient;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textSoft,
    required this.divider,
    required this.primary,
    required this.secondary,
    required this.softGradient,
  });

  static AppPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppPalette(
      background:
          isDark ? AppColors.darkBackground : AppColors.background,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      surfaceAlt: isDark ? AppColors.darkSurfaceAlt : AppColors.lavender,
      text: isDark ? AppColors.darkText : AppColors.text,
      textSoft: isDark ? AppColors.darkTextSoft : AppColors.textSoft,
      divider: isDark ? AppColors.darkDivider : AppColors.divider,
      primary: isDark ? AppColors.primaryOnDark : AppColors.primary,
      secondary: isDark ? AppColors.secondaryOnDark : AppColors.secondary,
      softGradient:
          isDark ? AppColors.softGradientDark : AppColors.softGradient,
    );
  }
}
