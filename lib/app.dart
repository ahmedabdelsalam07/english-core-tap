import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/enums.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'routing/app_router.dart';

class EnglishCoreTapApp extends ConsumerWidget {
  const EnglishCoreTapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final router = buildRouter(ref);

    // Refresh routing when auth / settings change (language, theme, onboarding).
    ref.listen(authControllerProvider, (_, __) => router.refresh());
    ref.listen(settingsControllerProvider, (_, __) => router.refresh());

    final locale = settings.locale == AppLocale.en
        ? const Locale('en')
        : const Locale('ar');

    return MaterialApp.router(
      title: Constants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode == AppThemeMode.dark
          ? ThemeMode.dark
          : settings.themeMode == AppThemeMode.light
              ? ThemeMode.light
              : ThemeMode.system,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
