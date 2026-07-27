import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class TabletNavRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const TabletNavRail({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTabSelected,
      labelType: NavigationRailLabelType.selected,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.target, color: AppColors.primary, size: 20.0),
        ),
      ),
      selectedIconTheme: const IconThemeData(color: AppColors.primary, size: 22.0),
      unselectedIconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant, size: 20.0),
      selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11.0),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(LucideIcons.layoutDashboard),
          selectedIcon: Icon(LucideIcons.layoutDashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.target),
          selectedIcon: Icon(LucideIcons.target),
          label: Text('Goals'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.checkSquare),
          selectedIcon: Icon(LucideIcons.checkSquare),
          label: Text('Forge'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.fileText),
          selectedIcon: Icon(LucideIcons.fileText),
          label: Text('Logs'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.timer),
          selectedIcon: Icon(LucideIcons.timer),
          label: Text('Focus'),
        ),
        NavigationRailDestination(
          icon: Icon(LucideIcons.barChart2),
          selectedIcon: Icon(LucideIcons.barChart2),
          label: Text('Analytics'),
        ),
      ],
    );
  }
}
