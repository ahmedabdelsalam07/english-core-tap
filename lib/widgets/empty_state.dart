import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_typography.dart';
import 'app_logo.dart';

/// A respectful empty state (logo / icon + message).
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool useLogo;
  final IconData icon;
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.useLogo = true,
    this.icon = Icons.heart_broken_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useLogo)
              const BrandMark(size: 72)
            else
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: AppRadius.xl,
                ),
                child: Icon(icon, size: 36, color: AppColors.primary),
              ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(color: AppColors.text),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSoft,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}