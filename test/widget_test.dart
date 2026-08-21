import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:english_core_tap/app.dart';
import 'package:english_core_tap/features/onboarding/onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots through splash to onboarding without redirect loop',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EnglishCoreTapApp()),
    );
    await tester.pump();

    // Splash screen renders with brand text.
    expect(find.text('English Core'), findsWidgets);

    // Let the async bootstrap settle (plugin init has a 4s timeout), then
    // fire the splash navigation timer: go('/') must be redirected to
    // /onboarding without bouncing between /onboarding and /login.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}