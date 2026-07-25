import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FlaticonItem {
  final String key;
  final String name;
  final String assetPath;
  final IconData fallbackIcon;

  const FlaticonItem({
    required this.key,
    required this.name,
    required this.assetPath,
    required this.fallbackIcon,
  });
}

class FlaticonCatalog {
  static const List<FlaticonItem> items = [
    FlaticonItem(key: 'target', name: 'Target Focus', assetPath: 'assets/icons/target.svg', fallbackIcon: Icons.track_changes),
    FlaticonItem(key: 'trophy', name: 'Mastery Trophy', assetPath: 'assets/icons/trophy.svg', fallbackIcon: Icons.emoji_events),
    FlaticonItem(key: 'flame', name: 'Streak Flame', assetPath: 'assets/icons/flame.svg', fallbackIcon: Icons.local_fire_department),
    FlaticonItem(key: 'lightning', name: 'Energy Bolt', assetPath: 'assets/icons/lightning.svg', fallbackIcon: Icons.bolt),
    FlaticonItem(key: 'brain', name: 'Mind Fit', assetPath: 'assets/icons/brain.svg', fallbackIcon: Icons.psychology),
    FlaticonItem(key: 'fitness', name: 'Fitness & Health', assetPath: 'assets/icons/fitness.svg', fallbackIcon: Icons.fitness_center),
    FlaticonItem(key: 'code', name: 'Dev & Tech', assetPath: 'assets/icons/code.svg', fallbackIcon: Icons.code),
    FlaticonItem(key: 'book', name: 'Study & Read', assetPath: 'assets/icons/book.svg', fallbackIcon: Icons.menu_book),
    FlaticonItem(key: 'star', name: 'Star Recruit', assetPath: 'assets/icons/star.svg', fallbackIcon: Icons.star),
    FlaticonItem(key: 'home', name: 'Dashboard', assetPath: 'assets/icons/home.svg', fallbackIcon: Icons.home),
    FlaticonItem(key: 'calendar', name: 'Schedule', assetPath: 'assets/icons/calendar.svg', fallbackIcon: Icons.calendar_today),
    FlaticonItem(key: 'document', name: 'Logs & Notes', assetPath: 'assets/icons/document.svg', fallbackIcon: Icons.description),
    FlaticonItem(key: 'timer', name: 'Deep Work', assetPath: 'assets/icons/timer.svg', fallbackIcon: Icons.timer),
  ];

  static FlaticonItem getItem(String key) {
    return items.firstWhere(
      (item) => item.key.toLowerCase() == key.toLowerCase(),
      orElse: () => items.first,
    );
  }
}

class FlaticonIcon extends StatelessWidget {
  final String iconKey;
  final double size;
  final Color? color;
  final IconData? overrideFallback;

  const FlaticonIcon({
    super.key,
    required this.iconKey,
    this.size = 24.0,
    this.color,
    this.overrideFallback,
  });

  @override
  Widget build(BuildContext context) {
    final item = FlaticonCatalog.getItem(iconKey);
    final theme = Theme.of(context);
    final iconColor = color ?? theme.iconTheme.color ?? theme.colorScheme.onSurface;

    return SvgPicture.asset(
      item.assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      placeholderBuilder: (context) => Icon(
        overrideFallback ?? item.fallbackIcon,
        size: size,
        color: iconColor,
      ),
    );
  }
}
