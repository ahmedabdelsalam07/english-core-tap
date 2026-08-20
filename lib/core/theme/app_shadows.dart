import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Central shadow definitions.
class AppShadows {
  static List<BoxShadow> soft(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ];

  static List<BoxShadow> get brand => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.35),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}