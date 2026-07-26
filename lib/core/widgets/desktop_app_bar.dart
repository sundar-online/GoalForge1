import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/theme_cubit.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

class DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const DesktopAppBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 70.0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14151F) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Section Title
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20.0,
            ),
          ),
          const SizedBox(width: 32.0),

          // Search Field
          Expanded(
            child: Container(
              height: 40.0,
              constraints: const BoxConstraints(maxWidth: 400.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  hintText: 'Search goals, tasks, notes... (Ctrl+K)',
                  hintStyle: TextStyle(
                    fontSize: 13.0,
                    color: theme.colorScheme.outline,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18.0,
                    color: theme.colorScheme.outline,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
              ),
            ),
          ),
          const Spacer(),

          // Theme Toggle Button
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              final isDarkMode = mode == ThemeMode.dark;
              return Tooltip(
                message: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                child: IconButton(
                  icon: Icon(
                    isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                    size: 20.0,
                  ),
                  onPressed: () {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8.0),

          // Notifications Button
          Tooltip(
            message: 'Notifications',
            child: IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 22.0),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16.0),

          // Vertical Divider
          Container(
            height: 24.0,
            width: 1.0,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 16.0),

          // User Profile Avatar Popup Menu
          PopupMenuButton<String>(
            tooltip: 'User Account',
            onSelected: (val) {
              if (val == 'logout') {
                context.read<AuthBloc>().add(SignOutRequested());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18.0),
                    SizedBox(width: 10.0),
                    Text('User Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18.0, color: Colors.redAccent),
                    SizedBox(width: 10.0),
                    Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18.0,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 20.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8.0),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20.0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
