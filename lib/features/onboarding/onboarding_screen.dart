import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_logo.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsControllerProvider.notifier).setOnboardingSeen();
    if (!mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    context.go(user == null ? '/login' : '/shell/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: Text(l10n.onboardingSkip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 3,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  // Slide 1 is a complete top-to-bottom design — rendered
                  // full-bleed with no extra text on top of it.
                  if (index == 0) return const _FullDesignSlide();
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: _buildSlide(index, l10n, palette),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : palette.divider,
                    borderRadius: AppRadius.pill,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Material(
                borderRadius: AppRadius.md,
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                  ),
                  child: InkWell(
                    onTap: _page < 2
                        ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                            )
                        : _finish,
                    child: Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: Text(
                        _page < 2 ? l10n.onboardingNext : l10n.onboardingStart,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(int index, AppLocalizations l10n, AppPalette palette) {
    switch (index) {
      case 1:
        return _SlideScaffold(
          visual: const _SafeHeart(),
          title: l10n.onboardingTitle2,
          subtitle: l10n.onboardingSub2,
          palette: palette,
        );
      default:
        return _BrandSlide(palette: palette);
    }
  }
}

/// Slide 1 — the complete ready-made design (girl artwork with its own
/// baked-in text), shown edge-to-edge on its native black background.
class _FullDesignSlide extends StatelessWidget {
  const _FullDesignSlide();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          color: Colors.black,
          child: Center(
            child: Image.asset(
              'assets/images/onboarding_girl.jpeg',
              fit: BoxFit.contain,
              height: constraints.maxHeight,
              errorBuilder: (_, __, ___) => Icon(
                Icons.face_retouching_natural_rounded,
                size: 120,
                color: AppPalette.of(context).primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Common slide layout: visual on top, title + subtitle under it.
class _SlideScaffold extends StatelessWidget {
  final Widget visual;
  final String title;
  final String subtitle;
  final AppPalette palette;
  const _SlideScaffold({
    required this.visual,
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        visual,
        const SizedBox(height: 36),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSoft,
                height: 1.6,
              ),
        ),
      ],
    );
  }
}

/// Slide 2 — the official heart logo (transparent asset).
class _SafeHeart extends StatelessWidget {
  const _SafeHeart();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/onboarding_heart.png',
      height: 280,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.favorite_rounded,
        size: 160,
        color: AppColors.danger,
      ),
    );
  }
}

/// Slide 3 — the complete personal logo with full brand identity.
class _BrandSlide extends StatelessWidget {
  final AppPalette palette;
  const _BrandSlide({required this.palette});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FullLogo(width: 330),
        const SizedBox(height: 22),
        Text(
          l10n.onboardingBrandAr,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.onboardingOwnerAr,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.secondary,
              ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.onboardingBrandEn,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: palette.text,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.onboardingOwnerEn,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.secondary,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            l10n.onboardingTagline,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.primary,
                ),
          ),
        ),
      ],
    );
  }
}
