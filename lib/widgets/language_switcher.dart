import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

/// Global language switcher. Switches the whole interface between
/// Arabic (RTL) and English (LTR), persisted immediately.
class LanguageSwitcher extends ConsumerWidget {
  final Color? iconColor;
  const LanguageSwitcher({super.key, this.iconColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final isAr = settings.locale == AppLocale.ar;
    return IconButton(
      tooltip: AppLocalizations.of(context).settingsLanguage,
      icon: Icon(
        Icons.language_rounded,
        color: iconColor ?? Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        final controller = ref.read(settingsControllerProvider.notifier);
        controller.setLocale(isAr ? AppLocale.en : AppLocale.ar);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).languageSwitched),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
