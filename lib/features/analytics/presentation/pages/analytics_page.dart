import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsLoaded? _latestState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => sl<AnalyticsBloc>()..add(SubscribeToAnalytics()),
      child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoaded) {
            _latestState = state;
          }

          final accuracy = _latestState?.weeklyAccuracyPercent ?? 100.0;
          final focusMins = _latestState?.totalFocusMinutesThisWeek ?? 0;
          final totalXp = _latestState?.totalXP ?? 0;
          final level = _latestState?.currentLevel ?? 1;
          final levelRatio = _latestState?.levelProgressRatio ?? 0.0;
          final activeHabits = _latestState?.activeHabitsCount ?? 0;
          final weeklyXpData = _latestState?.weeklyXpData ?? {};
          final goals = _latestState?.goalMasteryList ?? [];
          final badges = _latestState?.earnedBadges ?? [];

          final isWide = !ResponsiveLayout.isMobile(context);

          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isWide ? 1300.0 : 600.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Analytics & Mastery',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onBackground,
                            fontSize: 26.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'PERFORMANCE & GROWTH INSIGHTS',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // Executive Bento Grid
                        _buildExecutiveBentoGrid(theme, accuracy, focusMins, totalXp, level, levelRatio, activeHabits),
                        const SizedBox(height: 20.0),

                        // 7-Day XP Bar Visualizer Card
                        _buildWeeklyXpVisualizerCard(theme, weeklyXpData),
                        const SizedBox(height: 20.0),

                        // Goal Mastery Distribution Card
                        _buildGoalMasteryCard(theme, goals),
                        const SizedBox(height: 20.0),

                        // Badges Showcase Card
                        _buildBadgesShowcaseCard(theme, badges),
                        const SizedBox(height: 32.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Executive Bento Grid ---
  Widget _buildExecutiveBentoGrid(
    ThemeData theme,
    double accuracy,
    int focusMins,
    int totalXp,
    int level,
    double levelRatio,
    int activeHabits,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACCURACY %',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.outline,
                            fontWeight: FontWeight.bold,
                            fontSize: 9.0,
                          ),
                        ),
                        const Icon(Icons.show_chart, color: AppColors.primary, size: 16.0),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      '${accuracy.toStringAsFixed(1)}%',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 24.0,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'FOCUS TIME',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.outline,
                            fontWeight: FontWeight.bold,
                            fontSize: 9.0,
                          ),
                        ),
                        const Icon(Icons.timer_outlined, color: AppColors.tertiary, size: 16.0),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      '${focusMins}m',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 24.0,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        CustomCard(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(Icons.military_tech, color: AppColors.primary, size: 24.0),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LEVEL $level RECRUIT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                          ),
                        ),
                        Text(
                          '$totalXp XP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: LinearProgressIndicator(
                        value: levelRatio,
                        minHeight: 6.0,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 7-Day XP Bar Visualizer Card ---
  Widget _buildWeeklyXpVisualizerCard(ThemeData theme, Map<String, int> weeklyXpData) {
    final maxXp = weeklyXpData.values.fold<int>(1, (max, xp) => xp > max ? xp : max);

    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7-DAY XP GAINS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontSize: 10.0,
                ),
              ),
              const Icon(Icons.bar_chart, color: AppColors.primary, size: 18.0),
            ],
          ),
          const SizedBox(height: 20.0),
          SizedBox(
            height: 120.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyXpData.entries.map((entry) {
                final heightRatio = (entry.value / maxXp).clamp(0.08, 1.0);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24.0,
                      height: 80.0 * heightRatio,
                      decoration: BoxDecoration(
                        color: entry.value > 0 ? AppColors.primary : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      entry.key,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.0,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Goal Mastery Distribution Card ---
  Widget _buildGoalMasteryCard(ThemeData theme, List dynamicGoals) {
    if (dynamicGoals.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GOAL MASTERY DISTRIBUTION',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.outline,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                fontSize: 10.0,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              'No goals created yet. Create goals in the Goals tab to track mastery.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.outline, fontSize: 13.0),
            ),
          ],
        ),
      );
    }

    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GOAL MASTERY DISTRIBUTION',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontSize: 10.0,
            ),
          ),
          const SizedBox(height: 16.0),
          Column(
            children: dynamicGoals.map((goal) {
              final pct = goal.progress.clamp(0.0, 100.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          goal.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${pct.toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: LinearProgressIndicator(
                        value: pct / 100.0,
                        minHeight: 5.0,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Badges Showcase Card ---
  Widget _buildBadgesShowcaseCard(ThemeData theme, List<String> earnedBadges) {
    final allBadges = [
      {'id': 'recruit_initiate', 'name': 'Recruit Initiate', 'icon': Icons.star_border},
      {'id': 'streak_apprentice', 'name': '3-Day Apprentice', 'icon': Icons.local_fire_department},
      {'id': 'streak_warrior', 'name': '7-Day Warrior', 'icon': Icons.whatshot},
      {'id': 'focus_master', 'name': 'Focus Master', 'icon': Icons.psychology},
      {'id': 'forge_master', 'name': 'Forge Master', 'icon': Icons.military_tech},
    ];

    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EARNED BADGES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontSize: 10.0,
            ),
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: allBadges.map((b) {
              final isUnlocked = earnedBadges.contains(b['id']);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isUnlocked ? AppColors.primary : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      b['icon'] as IconData,
                      size: 16.0,
                      color: isUnlocked ? AppColors.primary : AppColors.outline,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      b['name'] as String,
                      style: TextStyle(
                        color: isUnlocked ? AppColors.primary : AppColors.outline,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
