import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

/// Natural width/height ratio of the transparent logo asset
/// (assets/logo/logo_transparent.png = 1400x718).
const double kLogoAspectRatio = 1400 / 718;

/// The official ENGLISH CORE logo (transparent, no name/number baked in).
class AppLogo extends StatelessWidget {
  final double width;
  final bool showText;
  const AppLogo({super.key, this.width = 140, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final height = width / kLogoAspectRatio;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo/logo_transparent.png',
          width: width,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.record_voice_over_rounded,
            size: width * 0.5,
            color: palette.primary,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'ENGLISH CORE',
            style: AppTypography.title.copyWith(
              color: palette.primary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'MR. THARWAT TAWFIQ',
            style: AppTypography.caption.copyWith(
              color: palette.textSoft,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

/// The complete personal logo used on onboarding slide 3.
class FullLogo extends StatelessWidget {
  final double width;
  const FullLogo({super.key, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/logo_transparent.png',
      width: width,
      height: width / kLogoAspectRatio,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.record_voice_over_rounded,
        size: width * 0.5,
        color: AppColors.primary,
      ),
    );
  }
}

/// LOGO ONLY — the transparent brand symbol without any name/number text.
/// [size] is the rendered HEIGHT; width follows the natural asset ratio.
/// Used in the header, splash screen and anywhere "logo only" is required.
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/logo_transparent.png',
      height: size,
      width: size * kLogoAspectRatio,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.record_voice_over_rounded,
        size: size * 0.7,
        color: AppColors.primary,
      ),
    );
  }
}

/// Small brand mark (icon-sized) used in app bars and empty states.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return LogoMark(size: size);
  }
}
