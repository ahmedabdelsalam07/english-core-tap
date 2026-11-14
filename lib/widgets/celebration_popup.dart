import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Duolingo-style celebration popup.
///
/// A springy overshooting "pop", a gently floating badge and a soft halo of
/// dots. It is used for the two hidden brand moments (the heart easter egg
/// and the logo tap) so both feel like one playful design language.
///
/// This is a plain Flutter dialog, so it behaves identically on mobile and
/// desktop: tap anywhere, press Escape or use the back gesture to dismiss.
class CelebrationPopup extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color accent;

  const CelebrationPopup({
    super.key,
    required this.message,
    this.icon = Icons.favorite_rounded,
    this.accent = AppColors.danger,
  });

  /// Shows the popup and completes when it has been dismissed.
  static Future<void> show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.favorite_rounded,
    Color accent = AppColors.danger,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: message,
      barrierColor: Colors.black.withOpacity(0.42),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => CelebrationPopup(
        message: message,
        icon: icon,
        accent: accent,
      ),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  @override
  State<CelebrationPopup> createState() => _CelebrationPopupState();
}

class _CelebrationPopupState extends State<CelebrationPopup>
    with TickerProviderStateMixin {
  static const List<Offset> _sparkles = <Offset>[
    Offset(-0.95, -0.65),
    Offset(0.95, -0.65),
    Offset(-0.75, 0.55),
    Offset(0.75, 0.55),
    Offset(0.0, -1.0),
  ];

  late final AnimationController _pop;
  late final AnimationController _float;
  late final Animation<double> _scale;
  late final Animation<double> _rise;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _pop,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _rise = Tween<double>(begin: 26, end: 0).animate(
      CurvedAnimation(
        parent: _pop,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _contentFade = CurvedAnimation(
      parent: _pop,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _pop.forward();
  }

  @override
  void dispose() {
    _pop.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ScaleTransition(
          scale: _scale,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: widget.accent.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accent.withOpacity(0.28),
                      blurRadius: 34,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBadge(),
                    const SizedBox(height: 18),
                    AnimatedBuilder(
                      animation: _contentFade,
                      builder: (context, child) => Opacity(
                        opacity: _contentFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _rise.value),
                          child: child,
                        ),
                      ),
                      child: Text(
                        widget.message,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.7,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final t = _float.value;
        return Transform.translate(
          offset: Offset(0, -4 * t),
          child: Transform.rotate(
            angle: math.sin(t * math.pi * 2) * 0.07,
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < _sparkles.length; i++)
              Align(
                alignment: Alignment(_sparkles[i].dx, _sparkles[i].dy),
                child: Container(
                  width: i.isEven ? 7 : 5,
                  height: i.isEven ? 7 : 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accent.withOpacity(i.isEven ? 0.55 : 0.32),
                  ),
                ),
              ),
            Container(
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.accent,
                    Color.lerp(widget.accent, Colors.white, 0.28)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 34),
            ),
          ],
        ),
      ),
    );
  }
}
