import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

/// Central theme factory. Dark mode keeps brand colors + contrast.
class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: isDark ? AppColors.darkSurface : AppColors.surface,
      primary: isDark ? AppColors.primaryOnDark : AppColors.primary,
      secondary: isDark ? AppColors.secondaryOnDark : AppColors.secondary,
    );

    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      fontFamily: AppTypography.fontFamily,
    );

    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        bodyColor: isDark ? AppColors.darkText : AppColors.text,
        displayColor: isDark ? AppColors.darkText : AppColors.text,
        fontFamily: AppTypography.fontFamily,
      ),
      iconTheme: IconThemeData(
        color: isDark ? AppColors.darkText : AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? AppColors.darkText : AppColors.text,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        titleTextStyle: AppTypography.h3.copyWith(
          color: isDark ? AppColors.darkText : AppColors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkDivider : AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurfaceAlt : AppColors.lavender,
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: isDark ? AppColors.primaryOnDark : AppColors.primary,
          fontWeight: FontWeight.w600,
          fontFamily: AppTypography.fontFamily,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontFamily: AppTypography.fontFamily,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.text,
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.darkText : Colors.white,
          fontFamily: AppTypography.fontFamily,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.darkSurfaceAlt : AppColors.lavenderSoft,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextSoft : AppColors.textSoft,
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.darkTextSoft : AppColors.textSoft,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryOnDark : AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: isDark ? AppColors.primaryOnDark : AppColors.primary,
        selectionColor: (isDark
                ? AppColors.primaryOnDark
                : AppColors.primary)
            .withOpacity(0.25),
        selectionHandleColor:
            isDark ? AppColors.primaryOnDark : AppColors.primary,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(
          color: isDark ? AppColors.darkText : AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: AppTypography.fontFamily,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppColors.darkSurfaceAlt : AppColors.surface,
        textStyle: TextStyle(
          color: isDark ? AppColors.darkText : AppColors.text,
          fontFamily: AppTypography.fontFamily,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTypography.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor:
              isDark ? AppColors.primaryOnDark : AppColors.primary,
          side: BorderSide(
            color: isDark ? AppColors.primaryOnDark : AppColors.primary,
          ),
          textStyle:
              AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              isDark ? AppColors.primaryOnDark : AppColors.primary,
          textStyle:
              AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor:
            isDark ? AppColors.primaryOnDark : AppColors.primary,
        thumbColor: isDark ? AppColors.primaryOnDark : AppColors.primary,
        inactiveTrackColor:
            isDark ? AppColors.darkDivider : AppColors.divider,
        overlayColor: AppColors.primary.withOpacity(0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : isDark
                  ? AppColors.darkTextSoft
                  : AppColors.textSoft,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : isDark
                  ? AppColors.darkDivider
                  : AppColors.divider,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return isDark ? AppColors.darkSurfaceAlt : AppColors.lavenderSoft;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return isDark ? AppColors.darkTextSoft : AppColors.textSoft;
          }),
          side: WidgetStateProperty.all(BorderSide.none),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
          shape: WidgetStateProperty.all(
              const RoundedRectangleBorder(borderRadius: AppRadius.md)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? AppColors.primaryOnDark : AppColors.primary,
        linearTrackColor:
            isDark ? AppColors.darkDivider : AppColors.divider,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        titleTextStyle: AppTypography.h3.copyWith(
          color: isDark ? AppColors.darkText : AppColors.text,
        ),
        contentTextStyle: AppTypography.body.copyWith(
          color: isDark ? AppColors.darkTextSoft : AppColors.textSoft,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        selectedItemColor:
            isDark ? AppColors.primaryOnDark : AppColors.primary,
        unselectedItemColor:
            isDark ? AppColors.darkTextSoft : AppColors.textSoft,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: AppTypography.fontFamily,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
        ),
      ),
      shadowColor: Colors.transparent,
    );
  }
}
