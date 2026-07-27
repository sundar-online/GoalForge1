import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'flaticon_icon.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _NavBarItem(flaticonKey: 'home', icon: LucideIcons.layoutDashboard, label: 'HOME'),
      _NavBarItem(flaticonKey: 'target', icon: LucideIcons.target, label: 'GOALS'),
      _NavBarItem(flaticonKey: 'calendar', icon: LucideIcons.checkSquare, label: 'TASKS'),
      _NavBarItem(flaticonKey: 'document', icon: LucideIcons.fileText, label: 'NOTES'),
      _NavBarItem(flaticonKey: 'timer', icon: LucideIcons.timer, label: 'FOCUS'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 30.0,
            offset: const Offset(0, -10.0),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 10.0,
        bottom: MediaQuery.of(context).padding.bottom + 10.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isActive = index == currentIndex;

          if (isActive) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4.0),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FlaticonIcon(
                        iconKey: item.flaticonKey,
                        size: 20.0,
                        color: theme.colorScheme.onPrimary,
                        overrideFallback: item.icon,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        item.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9.0,
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16.0),
                onTap: () => onTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlaticonIcon(
                        iconKey: item.flaticonKey,
                        size: 22.0,
                        color: theme.colorScheme.onSurfaceVariant,
                        overrideFallback: item.icon,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        item.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.0,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}

class _NavBarItem {
  final String flaticonKey;
  final IconData icon;
  final String label;

  _NavBarItem({
    required this.flaticonKey,
    required this.icon,
    required this.label,
  });
}
