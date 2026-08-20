import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';

/// Primary CTA button (brand gradient, large touch target).
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: AppRadius.md,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: AppColors.primary,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        child: InkWell(
          onTap: (loading || onPressed == null) ? null : onPressed,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      if (loadingLabel != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          loadingLabel!,
                          style: AppTypography.button.copyWith(color: Colors.white),
                        ),
                      ],
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        label,
                        style: AppTypography.button.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}