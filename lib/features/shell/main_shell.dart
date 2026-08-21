import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  void _go(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = navigationShell.currentIndex;

    final items = <_NavItem>[
      _NavItem(
        label: l10n.navHome,
        icon: Icons.home_rounded,
        selectedIcon: Icons.home_rounded,
      ),
      _NavItem(
        label: l10n.navFavorites,
        icon: Icons.favorite_border_rounded,
        selectedIcon: Icons.favorite_rounded,
      ),
      const _NavItem(label: '', icon: Icons.mic_none_rounded, selectedIcon: Icons.mic_rounded),
      _NavItem(
        label: l10n.navHistory,
        icon: Icons.history_rounded,
        selectedIcon: Icons.history_rounded,
      ),
      _NavItem(
        label: l10n.navSettings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  if (i == 2)
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _go(0),
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(11),
                              child: Image.asset(
                                'assets/logo/logo_transparent.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: _NavButton(
                        item: items[i],
                        selected: _branchOf(i) == current,
                        onTap: () => _go(_branchOf(i)),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _branchOf(int i) => i == 0 ? 0 : (i == 1 ? 1 : (i == 3 ? 2 : 3));
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = selected ? palette.primary : palette.textSoft;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.selectedIcon : item.icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
