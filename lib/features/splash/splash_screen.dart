import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/services_provider.dart';
import '../../widgets/app_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Warm up platform services before the first screen. Never block startup
    // on a plugin that misbehaves: bound each init with a timeout.
    final tts = ref.read(ttsServiceProvider);
    final speech = ref.read(speechServiceProvider);
    final ttsInit = tts
        .init()
        .timeout(const Duration(seconds: 4), onTimeout: () {})
        .catchError((_) {});
    final speechInit = speech
        .init()
        .timeout(const Duration(seconds: 4), onTimeout: () => false)
        .catchError((_) {});
    await Future.wait([ttsInit, speechInit]);
    if (!mounted) return;
    _navigateTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(
                    opacity: _controller,
                    child: const Column(
                      children: [
                        // LOGO ONLY — large, original aspect ratio preserved.
                        LogoMark(size: 230),
                        SizedBox(height: 30),
                        Text(
                          'English Core',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Mr Tharwat Tawfiq',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
