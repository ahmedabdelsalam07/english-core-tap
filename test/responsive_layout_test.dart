import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:english_core_tap/data/models/pronunciation_result.dart';
import 'package:english_core_tap/data/services/backend_client.dart';
import 'package:english_core_tap/features/home/home_screen.dart';
import 'package:english_core_tap/features/onboarding/onboarding_screen.dart';
import 'package:english_core_tap/features/result/result_screen.dart';
import 'package:english_core_tap/features/settings/settings_screen.dart';
import 'package:english_core_tap/l10n/app_localizations.dart';
import 'package:english_core_tap/providers/auth_provider.dart';

/// Signed-in account with a long name — the worst case for the home header.
class _FixedAuth extends AuthController {
  @override
  Future<UserAccount?> build() async =>
      const UserAccount(username: 'Mohammed Abdelsalam', uid: 'u1');
}

const List<Size> _surfaces = [
  // Tiny legacy phones (300dp) up to modern large ones.
  Size(300, 600),
  Size(320, 568),
  Size(360, 640),
  Size(412, 915),
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester, Size size, Widget child) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FixedAuth.new),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: child,
        ),
      ),
    );
    await tester.pump();
  }

  /// Lets pending timers fire and disposes the tree so tickers/controllers
  /// never leak across cases.
  Future<void> drain(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final size in _surfaces) {
    final label = '${size.width}x${size.height}';

    testWidgets('onboarding fits $label without overflow', (tester) async {
      await pumpScreen(tester, size, const OnboardingScreen());
      expect(find.byType(OnboardingScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await drain(tester);
    });

    testWidgets('home fits $label without overflow', (tester) async {
      await pumpScreen(tester, size, const HomeScreen());
      expect(find.byType(HomeScreen), findsOneWidget);
      await drain(tester);
    });

    testWidgets('result fits $label without overflow', (tester) async {
      await pumpScreen(
        tester,
        size,
        ResultScreen(
          result: PronunciationResult(
            englishText: 'Good morning everyone',
            arabicTranslation:
                'صباح الخير عليكم جميعا، اتمنى لكم يوما سعيدا ومليئا بالنجاح',
            arabicPhonetic: 'جود مورنينج إفريوان',
            accent: 'us',
            speed: 1.0,
            createdAt: DateTime(2026, 1, 1),
          ),
        ),
      );
      expect(find.text('Good morning everyone'), findsOneWidget);
      await drain(tester);
    });

    testWidgets('settings fits $label without overflow', (tester) async {
      await pumpScreen(tester, size, const SettingsScreen());
      expect(find.byType(SettingsScreen), findsOneWidget);
      await drain(tester);
    });
  }
}
