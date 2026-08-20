import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Displays the official ENGLISH CORE logo (real asset, aspect-ratio kept).
class AppLogo extends StatelessWidget {
  final double width;
  final bool showText;
  const AppLogo({super.key, this.width = 140, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final height = width * 600 / 1000; // natural ratio of the logo asset
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo/english_core_tap.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.record_voice_over_rounded,
            size: width * 0.5,
            color: AppColors.primary,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'ENGLISH CORE',
            style: AppTypography.title.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'MR. THARWAT TAWFIQ',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSoft,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

/// Small brand mark (icon-sized) used in app bars and empty states.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/english_core_tap.png',
      width: size,
      height: size * 600 / 1000,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.record_voice_over_rounded,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }
}