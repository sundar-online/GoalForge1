import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DesktopSidebarItem {
  final String title;
  final IconData icon;

  const DesktopSidebarItem({
    required this.title,
    required this.icon,
  });
}

class DesktopSidebar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final String? focusGoalTitle;
  final double? focusGoalProgress;

  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.focusGoalTitle,
    this.focusGoalProgress,
  });

  static const List<DesktopSidebarItem> items = [
    DesktopSidebarItem(title: 'Home', icon: Icons.home_rounded),
    DesktopSidebarItem(title: 'Goals', icon: Icons.track_changes_rounded),
    DesktopSidebarItem(title: 'Tasks', icon: Icons.task_alt_rounded),
    DesktopSidebarItem(title: 'Notes', icon: Icons.description_outlined),
    DesktopSidebarItem(title: 'Focus', icon: Icons.timer_outlined),
  ];

  @override
  State<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<DesktopSidebar> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarWidth = widget.isCollapsed ? 76.0 : 230.0;
    final activeBg = isDark ? const Color(0xFF2C2F45) : const Color(0xFF1C2033);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14151F) : Colors.white,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header / Logo Area
          Container(
            height: 70.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.track_changes,
                    color: Colors.white,
                    size: 22.0,
                  ),
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 12.0),
                  Text(
                    'GoalForge',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Navigation Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: DesktopSidebar.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4.0),
              itemBuilder: (context, index) {
                final item = DesktopSidebar.items[index];
                final isSelected = widget.currentIndex == index;
                final isHovered = _hoveredIndex == index;

                final itemWidget = MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeBg
                          : (isHovered
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: InkWell(
                      onTap: () => widget.onTabSelected(index),
                      borderRadius: BorderRadius.circular(10.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: Row(
                          mainAxisAlignment: widget.isCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Icon(
                              item.icon,
                              size: 20.0,
                              color: isSelected
                                  ? Colors.white
                                  : (isHovered
                                      ? AppColors.primary
                                      : theme.colorScheme.onSurfaceVariant),
                            ),
                            if (!widget.isCollapsed) ...[
                              const SizedBox(width: 14.0),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : (isHovered
                                            ? AppColors.primary
                                            : theme.colorScheme.onSurface),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 4.0,
                                  height: 4.0,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                if (widget.isCollapsed) {
                  return Tooltip(
                    message: item.title,
                    preferBelow: false,
                    child: itemWidget,
                  );
                }

                return itemWidget;
              },
            ),
          ),

          // Pinned Bottom Focus Goal Widget Card
          if (!widget.isCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B1E2E)
                      : AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6.0,
                          height: 6.0,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          'FORGE FOCUS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 9.0,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      widget.focusGoalTitle ?? 'No Focus Goal set. Toggle star on any goal card to focus.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.focusGoalProgress != null) ...[
                      const SizedBox(height: 8.0),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: LinearProgressIndicator(
                          value: widget.focusGoalProgress! / 100.0,
                          minHeight: 4.0,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Collapse / Expand Toggle Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: InkWell(
              onTap: widget.onToggleCollapse,
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                height: 38.0,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: theme.colorScheme.surfaceContainerHigh,
                ),
                child: Row(
                  mainAxisAlignment: widget.isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      widget.isCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      size: 20.0,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 8.0),
                      Text(
                        'Collapse Menu',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
