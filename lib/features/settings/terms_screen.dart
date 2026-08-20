import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.termsTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.termsBody,
          style: const TextStyle(fontSize: 15, height: 1.8),
        ),
      ),
    );
  }
}
