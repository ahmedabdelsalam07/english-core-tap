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
    // Created once and kept alive — never recreated on rebuilds.
    final router = ref.watch(appRouterProvider);

    // Refresh routing only when auth / onboarding state actually changes
    // (language & theme are handled by MaterialApp directly, so changing
    // them does NOT navigate the user away from the current screen).
    ref.listen(authControllerProvider, (_, __) => router.refresh());

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
