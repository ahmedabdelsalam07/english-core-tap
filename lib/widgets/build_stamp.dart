import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../build_info.dart';

/// Web-only, always-visible label showing which commit and build time the
/// deployed site is running, so a stale cached build is obvious at a glance.
class BuildStamp extends StatelessWidget {
  const BuildStamp({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 6,
          bottom: 4,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x8C000000),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                child: Text(
                  BuildInfo.label,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w500,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
