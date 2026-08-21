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
            const SizedBox(height: 8),
            const AppLogo(width: 150),
            const SizedBox(height: 32),
            Text(
              l10n.aboutName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.primary,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.aboutSub,
              style: TextStyle(
                color: palette.textSoft,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 32),
            Text(
              'ENGLISH CORE TaP  •  v1.0.0',
              style: TextStyle(fontSize: 12, color: palette.textSoft),
            ),
          ],
        ),
      ),
    );
  }
}
