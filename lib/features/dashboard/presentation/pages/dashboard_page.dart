import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart' as auth;
import '../../../habits/presentation/bloc/habits_bloc.dart';
import '../../../habits/presentation/bloc/habits_state.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../../../tasks/presentation/bloc/tasks_state.dart';
import '../../../analytics/presentation/widgets/monthly_trends_view.dart';
import '../../../analytics/presentation/widgets/weekly_activity_view.dart';
import '../../../../core/domain/models/task_log.dart';
import '../../../../core/domain/repositories/tasks_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class DashboardPage extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;

  const DashboardPage({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isDarkMode = false;
  int _selectedAnalyticsTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width > 600;

    return BlocProvider(
      create: (context) => sl<DashboardBloc>()..add(SubscribeToStreams()),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardInitial || state is DashboardLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          } else if (state is DashboardLoaded) {
            String displayName = 'Sundaramoorthy.S';
            String avatarLetter = 'S';
            final authState = context.read<AuthBloc>().state;
            if (authState is auth.Authenticated) {
              displayName = authState.user.displayName ?? 'Sundaramoorthy.S';
              if (displayName.isNotEmpty) {
                avatarLetter = displayName[0].toUpperCase();
              }
            }

            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.inverseSurface,
                      ),
                      child: Center(
                        child: Text(
                          avatarLetter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Text(
                      'GoalForge',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => widget.onNavigateToTab(2), // Navigate to Tasks/Calendar
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.inverseSurface,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppColors.primary),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8.0),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        Text(
                          'Hey, $displayName 👋',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '"Discipline is choosing between what you want now and what you want most."',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // Bento Section 1 (Focus Goal + Profile Rank)
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _buildFocusGoalCard(theme, state),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                flex: 4,
                                child: _buildProfileRankCard(theme, state),
                              ),
                            ],
                          )
                        else ...[
                          _buildFocusGoalCard(theme, state),
                          const SizedBox(height: 16.0),
                          _buildProfileRankCard(theme, state),
                        ],
                        const SizedBox(height: 24.0),

                        // Task Analytics & Trends Section (MONTHLY TRENDS | WEEKLY ACTIVITY)
                        _buildTaskAnalyticsSection(theme),
                        const SizedBox(height: 24.0),

                        // Quick Thoughts Card
                        CustomCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 48.0,
                                height: 48.0,
                                decoration: BoxDecoration(
                                  color: AppColors.tertiaryContainer.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(color: AppColors.tertiaryContainer.withOpacity(0.2)),
                                ),
                                child: const Icon(
                                  Icons.psychology,
                                  color: AppColors.tertiary,
                                  size: 28.0,
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Quick Thoughts',
                                          style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16.0),
                                        ),
                                        const SizedBox(width: 8.0),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceContainerHigh,
                                            borderRadius: BorderRadius.circular(4.0),
                                          ),
                                          child: Text(
                                            '${state.quickThoughtsCount}',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.outline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      '😌 Capturing minds ideas on the go',
                                      style: TextStyle(color: AppColors.secondary, fontSize: 13.0),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.expand_more, color: AppColors.outline),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // Performance Alert Card
                        Text(
                          'PERFORMANCE STATUS',
                          style: theme.textTheme.labelLarge?.copyWith(color: AppColors.outline, letterSpacing: 0.1),
                        ),
                        const SizedBox(height: 8.0),
                        BlocBuilder<HabitsBloc, HabitsState>(
                          builder: (context, habitsState) {
                            return BlocBuilder<TasksBloc, TasksState>(
                              builder: (context, tasksState) {
                                final todayStr = AppDateUtils.getTodayString();
                                int completedToday = 0;
                                int totalToday = 0;
                                int currentStreak = 0;

                                if (habitsState is HabitsLoaded) {
                                  final habitsToday = habitsState.habitsToday;
                                  totalToday += habitsToday.length;
                                  completedToday += habitsToday.where((h) => h.completedDates.contains(todayStr)).length;
                                  for (final h in habitsState.allHabits) {
                                    if (h.streak > currentStreak) currentStreak = h.streak;
                                  }
                                }

                                if (tasksState is TasksLoaded) {
                                  final tasksToday = tasksState.effectiveAllTasks;
                                  totalToday += tasksToday.length;
                                  completedToday += tasksToday.where((t) => t.completed || t.completedDates.contains(todayStr)).length;
                                }

                                final accuracy = totalToday > 0 ? (completedToday / totalToday) : 1.0;

                                Widget alertWidget;
                                if (currentStreak > 0 && completedToday == 0 && totalToday > 0) {
                                  alertWidget = _buildAlertCard(
                                    icon: Icons.warning,
                                    text: 'Your streak is at risk',
                                    textColor: AppColors.alertWarningText,
                                    bgColor: AppColors.alertWarningBg,
                                    borderColor: AppColors.alertWarningBorder,
                                  );
                                } else if (totalToday > 0 && accuracy < 0.50) {
                                  alertWidget = _buildAlertCard(
                                    icon: Icons.error,
                                    text: 'Low productivity detected',
                                    textColor: AppColors.alertErrorText,
                                    bgColor: AppColors.alertErrorBg,
                                    borderColor: AppColors.alertErrorBorder,
                                  );
                                } else if ((totalToday > 0 && accuracy >= 0.80) || currentStreak >= 3) {
                                  alertWidget = _buildAlertCard(
                                    icon: Icons.auto_awesome,
                                    text: 'Great consistency!',
                                    textColor: AppColors.alertSuccessText,
                                    bgColor: AppColors.alertSuccessBg,
                                    borderColor: AppColors.alertSuccessBorder,
                                  );
                                } else {
                                  alertWidget = _buildAlertCard(
                                    icon: Icons.insights,
                                    text: "You're improving",
                                    textColor: AppColors.alertInfoText,
                                    bgColor: AppColors.alertInfoBg,
                                    borderColor: AppColors.alertInfoBorder,
                                  );
                                }

                                return alertWidget;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24.0),

                        // Bento Section 2 (Upcoming Events + Weekly Performance)
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildUpcomingEvents(theme, state)),
                              const SizedBox(width: 16.0),
                              Expanded(child: _buildWeeklyPerformance(theme, state)),
                            ],
                          )
                        else ...[
                          _buildUpcomingEvents(theme, state),
                          const SizedBox(height: 16.0),
                          _buildWeeklyPerformance(theme, state),
                        ],
                        const SizedBox(height: 48.0),

                        // Footer
                        Center(
                          child: Text(
                            '© 2026 GOALFORGE STRATEGY ADVANCED PRODUCTIVITY SUITE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: AppColors.secondary.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else if (state is DashboardError) {
            return Scaffold(
              body: Center(
                child: Text(state.message, style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // --- Task Analytics & Operations Module (MONTHLY TRENDS | WEEKLY ACTIVITY) ---
  Widget _buildTaskAnalyticsSection(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final taskLogs = sl.isRegistered<TasksRepository>() ? sl<TasksRepository>().getTaskLogs() : <String, TaskLog>{};

    return BlocBuilder<HabitsBloc, HabitsState>(
      builder: (context, habitsState) {
        return BlocBuilder<TasksBloc, TasksState>(
          builder: (context, tasksState) {
            int habitsTotal = 0;
            int habitsDone = 0;
            int tasksTotal = 0;
            int tasksDone = 0;

            if (habitsState is HabitsLoaded) {
              habitsTotal = habitsState.totalTodayCount;
              habitsDone = habitsState.completedTodayCount;
            }
            if (tasksState is TasksLoaded) {
              tasksTotal = tasksState.totalCount;
              tasksDone = tasksState.completedCount;
            }

            final total = habitsTotal + tasksTotal;
            final done = habitsDone + tasksDone;
            final accuracy = total > 0 ? ((done / total) * 100.0) : 100.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab Selector Pill
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF13141C) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: isDark ? const Color(0xFF2C2D35) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAnalyticsTabItem('MONTHLY TRENDS', 0, isDark),
                      _buildAnalyticsTabItem('WEEKLY ACTIVITY', 1, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // Toggled Analytics View
                if (_selectedAnalyticsTabIndex == 0)
                  MonthlyTrendsView(taskLogs: taskLogs)
                else
                  WeeklyActivityView(
                    taskLogs: taskLogs,
                    weeklyAccuracyPercent: accuracy,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTabItem(String label, int index, bool isDark) {
    final isSelected = _selectedAnalyticsTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnalyticsTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C2D35) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? Colors.white54 : const Color(0xFF64748B)),
            fontWeight: FontWeight.w900,
            fontSize: 11.5,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildFocusGoalCard(ThemeData theme, DashboardLoaded state) {
    final goal = state.focusGoal;
    final title = goal?.title ?? 'No Focus Goal Set';
    final progress = goal?.progress ?? 0.0;
    final deadlineStr = goal?.deadline ?? '31 Dec 2026';
    final habitsLeft = state.habitsLeftToday;

    return CustomCard(
      child: Stack(
        children: [
          Positioned(
            right: -24.0,
            top: -24.0,
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.adjust,
                size: 160.0,
                color: AppColors.onBackground.withOpacity(0.5),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.track_changes, size: 14.0, color: AppColors.primary),
                    const SizedBox(width: 4.0),
                    Text(
                      'FOCUS GOAL',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontSize: 10.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 26.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'Due: $deadlineStr',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.outline),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 12.0, color: AppColors.outline),
                        const SizedBox(width: 4.0),
                        Text(
                          '$habitsLeft habits left today',
                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GOAL MASTERY',
                    style: theme.textTheme.labelLarge?.copyWith(color: AppColors.outline),
                  ),
                  Text(
                    '${progress.toInt()}%',
                    style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: progress / 100.0,
                  minHeight: 8.0,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onNavigateToTab(1), // Go to Goals tab
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue Goal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 6.0),
                      Icon(Icons.chevron_right, size: 18.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRankCard(ThemeData theme, DashboardLoaded state) {
    final level = state.xpProfile.level;
    final totalXp = state.xpProfile.totalXP;
    
    final nextLevelXp = AppConstants.levelXpMap[level + 1] ?? (level * 1000);
    final currentLevelXp = AppConstants.levelXpMap[level] ?? 0;
    final requiredXpForNextLevel = nextLevelXp - currentLevelXp;
    final progressXp = totalXp - currentLevelXp;
    final progressPercent = requiredXpForNextLevel > 0 ? (progressXp / requiredXpForNextLevel).clamp(0.0, 1.0) : 1.0;
    final xpNeeded = (nextLevelXp - totalXp).clamp(0, 99999);

    // Map level to title
    String levelTitle = 'Recruit';
    if (level >= 10) {
      levelTitle = 'Grandmaster';
    } else if (level >= 7) {
      levelTitle = 'Master';
    } else if (level >= 5) {
      levelTitle = 'Elite';
    } else if (level >= 3) {
      levelTitle = 'Apprentice';
    }

    final disciplineScore = totalXp ~/ 2 > 0 ? (totalXp ~/ 2) : 40;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 30.0,
            offset: Offset(0, 10.0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16.0,
            top: -16.0,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                Icons.emoji_events,
                size: 100.0,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LEVEL $level',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.secondaryFixedDim.withOpacity(0.7),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                levelTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL XP',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
              Text(
                '$totalXp',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('LEVEL $level', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white30)),
                  Text('LEVEL ${level + 1}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white30)),
                ],
              ),
              const SizedBox(height: 4.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 8.0,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryFixedDim),
                ),
              ),
              const SizedBox(height: 4.0),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$xpNeeded XP to next level',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.secondaryFixedDim.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DISCIPLINE', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white30)),
                          Text('$disciplineScore', style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.primaryFixedDim, size: 16.0),
                          SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              'Your consistency is reaching elite levels.',
                              style: TextStyle(color: Colors.white, fontSize: 9.5, height: 1.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  _buildBadge('🔥'),
                  const SizedBox(width: 4.0),
                  _buildBadge('⚡'),
                  const SizedBox(width: 4.0),
                  _buildBadge('🏆'),
                  const SizedBox(width: 4.0),
                  _buildBadge('🔥'),
                  const SizedBox(width: 8.0),
                  Text(
                    '+${state.xpProfile.earnedBadges.length > 3 ? state.xpProfile.earnedBadges.length - 3 : 2}',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String emoji) {
    return Container(
      width: 28.0,
      height: 28.0,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10, width: 1.5),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 14.0),
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String text,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 32.0,
            height: 32.0,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 18.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents(ThemeData theme, DashboardLoaded state) {
    final eventCount = state.upcomingEvents.length;
    final countText = eventCount > 0 ? '$eventCount event(s) scheduled' : 'No events today';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36.0,
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(Icons.event_note, color: AppColors.primary, size: 20.0),
                  ),
                  const SizedBox(width: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upcoming Events', style: theme.textTheme.bodyLarge),
                      Text(countText, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.outline)),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.outline),
                onPressed: () => widget.onNavigateToTab(2), // Navigate to Tasks/Schedule
              ),
            ],
          ),
          const SizedBox(height: 36.0),
          Center(
            child: Column(
              children: [
                Container(
                  width: 56.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.calendar_today, color: AppColors.outlineVariant, size: 30.0),
                ),
                const SizedBox(height: 12.0),
                Text(
                  eventCount > 0 ? 'You have upcoming events!' : 'No upcoming events scheduled',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () => widget.onNavigateToTab(2),
                  child: Text(
                    eventCount > 0 ? 'View Schedule' : '+ Schedule your first event',
                    style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformance(ThemeData theme, DashboardLoaded state) {
    final accuracyStr = '${state.weeklyAccuracy.toInt()}%';
    final focusStr = state.weeklyFocusDuration;
    final bestDayStr = state.bestDay;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Performance', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18.0)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'LAST 7 DAYS',
                  style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primary, fontSize: 9.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, color: AppColors.primary, size: 14.0),
                          const SizedBox(width: 4.0),
                          Text('ACCURACY', style: theme.textTheme.labelLarge?.copyWith(fontSize: 9.0, color: AppColors.secondary)),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(accuracyStr, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 22.0)),
                      const SizedBox(height: 2.0),
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: AppColors.tertiary, size: 12.0),
                          const SizedBox(width: 2.0),
                          Text(
                            '21% vs last wk',
                            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.bold, fontSize: 9.0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.secondary, size: 14.0),
                          const SizedBox(width: 4.0),
                          Text('FOCUS', style: theme.textTheme.labelLarge?.copyWith(fontSize: 9.0, color: AppColors.secondary)),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(focusStr, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 22.0)),
                      const SizedBox(height: 2.0),
                      Text(
                        'DEEP WORK',
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.outline, fontWeight: FontWeight.bold, fontSize: 9.0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28.0,
                      height: 28.0,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_available, color: AppColors.outline, size: 16.0),
                    ),
                    const SizedBox(width: 10.0),
                    Text('Best Day', style: theme.textTheme.bodyMedium),
                  ],
                ),
                Text(
                  bestDayStr,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
