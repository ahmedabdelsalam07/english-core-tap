import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/result/result_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/terms_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/splash/splash_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

/// Builds the app router with auth/onboarding redirects.
GoRouter buildRouter(Ref ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final settings = ref.read(settingsControllerProvider);
      final user = auth.valueOrNull;
      final path = state.matchedLocation;

      if (path == '/splash') return null;

      // Root has no dedicated route (used by web initial load and after
      // splash); delegate immediately based on current state.
      if (path == '/') {
        if (!settings.onboardingSeen) return '/onboarding';
        return user == null ? '/login' : '/shell/home';
      }

      // Onboarding gate: only /onboarding is reachable until completed.
      if (!settings.onboardingSeen) {
        return path == '/onboarding' ? null : '/onboarding';
      }

      // Onboarding done: leave it, then guard the authenticated area.
      if (path == '/onboarding') {
        return user == null ? '/login' : '/shell/home';
      }

      if (user == null) {
        return path == '/login' ? null : '/login';
      }

      if (path == '/login') return '/shell/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => ResultScreen(
          result: state.extra as dynamic,
        ),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shell/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shell/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shell/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shell/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return router;
}

/// The app router must be created exactly ONCE and kept alive for the whole
/// app session. Recreating it (e.g. inside a build method) resets navigation
/// to [GoRouter.initialLocation] whenever any watched provider changes —
/// that was the root cause of "selecting speed/voice jumps back to Home".
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildRouter(ref);
  ref.onDispose(router.dispose);
  return router;
});