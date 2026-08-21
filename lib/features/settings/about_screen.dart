import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          children: [
            const SizedBox(height: 48),
            const AppLogo(width: 150, showText: false),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.aboutDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: palette.text,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              l10n.aboutProducts,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: palette.text,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.aboutIpRights,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: palette.textSoft,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.aboutFounder,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: palette.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aboutCopyright,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: palette.textSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
