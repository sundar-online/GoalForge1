import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
      _NavBarItem(icon: Icons.home, activeIcon: Icons.home_filled, label: 'HOME'),
      _NavBarItem(icon: Icons.track_changes, activeIcon: Icons.track_changes, label: 'GOALS'),
      _NavBarItem(icon: Icons.calendar_today, activeIcon: Icons.calendar_today, label: 'TASKS'),
      _NavBarItem(icon: Icons.description, activeIcon: Icons.description, label: 'NOTES'),
      _NavBarItem(icon: Icons.timer_outlined, activeIcon: Icons.timer, label: 'FOCUS'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1C2E).withOpacity(0.06),
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
              decoration: const BoxDecoration(
                color: AppColors.inverseSurface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10.0,
                    offset: Offset(0, 4.0),
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
                      Icon(
                        item.activeIcon,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        item.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9.0,
                          color: Colors.white,
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
                      Icon(
                        item.icon,
                        color: AppColors.secondary.withOpacity(0.8),
                        size: 24.0,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        item.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.0,
                          color: AppColors.secondary.withOpacity(0.8),
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
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
