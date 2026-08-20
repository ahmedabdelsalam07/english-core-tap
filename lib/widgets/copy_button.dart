import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Copy button with "copied" feedback.
class CopyButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  const CopyButton({
    super.key,
    required this.text,
    this.icon = Icons.copy_rounded,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.resultCopy,
      icon: Icon(icon, size: 20, color: color ?? AppColors.textSoft),
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.resultCopied),
                duration: const Duration(seconds: 2),
              ),
            );
        }
      },
    );
  }
}
