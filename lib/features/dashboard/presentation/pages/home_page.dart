import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart' as auth;
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _activeTab = 'OVERVIEW'; // 'OVERVIEW', 'GOALS', 'TASKS'
  DashboardLoaded? _latestState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
          if (state is DashboardLoaded) {
            _latestState = state;
          }

          if (_latestState == null) {
            if (state is DashboardError) {
              return Scaffold(
                body: Center(
                  child: Text(state.message, style: const TextStyle(color: Colors.red)),
                ),
              );
            }
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          return Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        _buildHeader(theme),
                        const SizedBox(height: 24.0),

                        // Focus Goal Card
                        _buildFocusGoalCard(theme),
                        const SizedBox(height: 16.0),

                        // Level Recruit Card
                        _buildRecruitCard(theme),
                        const SizedBox(height: 24.0),

                        // Sub-tab Switcher (OVERVIEW / GOALS / TASKS)
                        _buildTabSwitcher(theme),
                        const SizedBox(height: 24.0),

                        // Dynamic Tab Content
                        _buildTabContent(theme, isWide),
                        const SizedBox(height: 32.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
  }

  // --- Header ---
  Widget _buildHeader(ThemeData theme) {
    String displayName = 'Sundaramoorthy.S';
    String avatarLetter = 'S';
    final authState = context.read<AuthBloc>().state;
    if (authState is auth.Authenticated) {
      displayName = authState.user.displayName ?? 'Sundaramoorthy.S';
      if (displayName.isNotEmpty) {
        avatarLetter = displayName[0].toUpperCase();
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey, $displayName 👋',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.onBackground,
                  fontSize: 26.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '"The only way to predict the future is to create it."',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        Row(
          children: [
            _buildHeaderIconButton(Icons.calendar_today, true),
            const SizedBox(width: 8.0),
            _buildHeaderIconButton(Icons.auto_awesome, true),
            const SizedBox(width: 8.0),
            _buildHeaderIconButton(Icons.brightness_2_outlined, false),
            const SizedBox(width: 8.0),
            _buildProfileAvatarBadge(avatarLetter),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton(IconData icon, bool colored) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: colored ? AppColors.secondaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: colored ? Colors.transparent : AppColors.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Icon(
        icon,
        color: colored ? AppColors.primary : AppColors.secondary,
        size: 20.0,
      ),
    );
  }

  Widget _buildProfileAvatarBadge(String letter) {
    return Container(
      width: 40.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  // --- Focus Goal Card ---
  Widget _buildFocusGoalCard(ThemeData theme) {
    final goal = _latestState?.focusGoal;
    final title = goal?.title ?? 'No Focus Goal Set';
    final progress = goal?.progress ?? 0.0;
    final deadlineStr = goal?.deadline ?? '31 Dec 2026';
    final habitsLeft = _latestState?.habitsLeftToday ?? 0;

    return CustomCard(
      child: Stack(
        children: [
          Positioned(
            right: -40.0,
            top: -20.0,
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _TargetBackgroundPainter(),
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
                  borderRadius: BorderRadius.circular(8.0),
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
                        fontWeight: FontWeight.bold,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'Due: $deadlineStr',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, size: 12.0, color: AppColors.outline),
                        const SizedBox(width: 4.0),
                        Text(
                          '$habitsLeft habits left today',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.outline,
                            fontWeight: FontWeight.bold,
                          ),
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
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.outline,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${progress.toInt()}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: progress / 100.0,
                  minHeight: 8.0,
                  backgroundColor: AppColors.surfaceContainerLow,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 4.0,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue Goal',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
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

  // --- Level Recruit Card ---
  Widget _buildRecruitCard(ThemeData theme) {
    final level = _latestState?.xpProfile.level ?? 1;
    final totalXp = _latestState?.xpProfile.totalXP ?? 0;
    
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

    // Discipline score estimation matching mockup consistency
    final disciplineScore = totalXp ~/ 2 > 0 ? (totalXp ~/ 2) : 40;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 30.0,
            offset: Offset(0, 10.0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.0,
            bottom: -20.0,
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.emoji_events,
                size: 160.0,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          fontSize: 28.0,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$totalXp',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'TOTAL XP',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white60,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LEVEL $level',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'LEVEL ${level + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 8.0,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 4.0),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$xpNeeded XP to next level',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.secondaryFixedDim.withOpacity(0.8),
                    fontSize: 10.0,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISCIPLINE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white30,
                            fontSize: 8.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          '$disciplineScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16.0),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              (_latestState?.insights.isNotEmpty ?? false)
                                  ? '${_latestState!.insights.first.title}: ${_latestState!.insights.first.description}'
                                  : 'Your consistency is reaching elite levels.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.0,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  _buildBadgeBox('🔥'),
                  const SizedBox(width: 4.0),
                  _buildBadgeBox('⚡'),
                  const SizedBox(width: 4.0),
                  _buildBadgeBox('🏗️'),
                  const SizedBox(width: 4.0),
                  _buildBadgeBox('🏆'),
                  const SizedBox(width: 8.0),
                  Text(
                    '+${(_latestState?.xpProfile.earnedBadges.length ?? 0) > 4 ? (_latestState!.xpProfile.earnedBadges.length - 4) : 2}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeBox(String emoji) {
    return Container(
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 16.0),
        ),
      ),
    );
  }

  // --- Tab Switcher ---
  Widget _buildTabSwitcher(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          _buildSwitcherTabItem('OVERVIEW', Icons.dashboard),
          _buildSwitcherTabItem('GOALS', Icons.track_changes),
          _buildSwitcherTabItem('TASKS', Icons.bolt),
        ],
      ),
    );
  }

  Widget _buildSwitcherTabItem(String tabName, IconData icon) {
    final isActive = _activeTab == tabName;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = tabName;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isActive ? AppColors.inverseSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16.0,
                color: isActive ? Colors.white : AppColors.outline,
              ),
              const SizedBox(width: 8.0),
              Text(
                tabName,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.outline,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tab Content ---
  Widget _buildTabContent(ThemeData theme, bool isWide) {
    switch (_activeTab) {
      case 'GOALS':
        return _buildGoalsTab(theme, isWide);
      case 'TASKS':
        return _buildTasksTab(theme);
      case 'OVERVIEW':
      default:
        return _buildOverviewTab(theme, isWide);
    }
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab(ThemeData theme, bool isWide) {
    final quickThoughtsCount = _latestState?.quickThoughtsCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Thoughts Card
        CustomCard(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2E6FF),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.psychology_alt_outlined,
                  color: Color(0xFFBF5AF2),
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Quick Thoughts',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            '$quickThoughtsCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.outline,
                              fontSize: 9.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    const Text(
                      '😌 Capturing minds ideas on the go',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more, color: AppColors.outline),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // 4 Performance Alerts Grid
        _buildAlertCard(
          iconLeft: Icons.warning_amber,
          iconRight: Icons.warning_amber,
          text: 'Your streak is at risk',
          textColor: AppColors.alertWarningText,
          bgColor: AppColors.alertWarningBg,
          borderColor: AppColors.alertWarningBorder,
        ),
        const SizedBox(height: 12.0),
        _buildAlertCard(
          iconLeft: Icons.error_outline,
          iconRight: Icons.trending_down,
          text: 'Low productivity detected',
          textColor: AppColors.alertErrorText,
          bgColor: AppColors.alertErrorBg,
          borderColor: AppColors.alertErrorBorder,
        ),
        const SizedBox(height: 12.0),
        _buildAlertCard(
          iconLeft: Icons.auto_awesome_outlined,
          iconRight: Icons.local_fire_department,
          text: 'Great consistency!',
          textColor: AppColors.alertSuccessText,
          bgColor: AppColors.alertSuccessBg,
          borderColor: AppColors.alertSuccessBorder,
        ),
        const SizedBox(height: 12.0),
        _buildAlertCard(
          iconLeft: Icons.auto_awesome,
          iconRight: Icons.show_chart,
          text: "You're improving",
          textColor: AppColors.alertInfoText,
          bgColor: AppColors.alertInfoBg,
          borderColor: AppColors.alertInfoBorder,
        ),
        const SizedBox(height: 16.0),

        // Upcoming Events
        _buildUpcomingEventsCard(theme),
        const SizedBox(height: 16.0),

        // Weekly Performance
        _buildWeeklyPerformanceCard(theme),
        const SizedBox(height: 16.0),

        // Goal Activity Donut
        _buildGoalActivityCard(theme),
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData iconLeft,
    required IconData iconRight,
    required String text,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(iconLeft, color: textColor, size: 20.0),
          const SizedBox(width: 12.0),
          Icon(iconRight, color: textColor, size: 20.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsCard(ThemeData theme) {
    final eventCount = _latestState?.upcomingEvents.length ?? 0;
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
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 18.0),
                  ),
                  const SizedBox(width: 12.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Events',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        countText,
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
          const SizedBox(height: 32.0),
          Center(
            child: Column(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.outlineVariant, size: 32.0),
                const SizedBox(height: 8.0),
                Text(
                  eventCount > 0 ? 'You have upcoming events!' : 'No upcoming events scheduled',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12.0),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    eventCount > 0 ? 'View Schedule' : '+ Schedule your first event',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformanceCard(ThemeData theme) {
    final accuracyStr = '${_latestState?.weeklyAccuracy.toInt() ?? 47}%';
    final focusStr = _latestState?.weeklyFocusDuration ?? '11h 41m';
    final bestDayStr = _latestState?.bestDay ?? 'N/A';

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Performance',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text(
                  'LAST 7 DAYS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.0,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, color: AppColors.primary, size: 16.0),
                          const SizedBox(width: 6.0),
                          Text(
                            'ACCURACY',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.0,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        accuracyStr,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 28.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Row(
                        children: [
                          Icon(Icons.trending_up, color: AppColors.tertiary, size: 14.0),
                          SizedBox(width: 4.0),
                          Text(
                            '30% vs last wk',
                            style: TextStyle(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.0,
                            ),
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
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.orange, size: 16.0),
                          const SizedBox(width: 6.0),
                          Text(
                            'FOCUS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.0,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        focusStr,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 28.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'DEEP WORK',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                          fontWeight: FontWeight.bold,
                          fontSize: 9.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16.0),
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
                      child: const Icon(Icons.calendar_today, color: AppColors.outline, size: 14.0),
                    ),
                    const SizedBox(width: 12.0),
                    Text(
                      'Best Day',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  bestDayStr,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalActivityCard(ThemeData theme) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANALYTICS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.outline,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Goal Activity',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.badge, color: AppColors.primary, size: 12.0),
                    SizedBox(width: 4.0),
                    Text(
                      'MOST ACTIVE',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // Donut Chart Drawing
          Center(
            child: SizedBox(
              width: 180.0,
              height: 180.0,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GoalActivityPainter(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '58%',
                          style: TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Mind Fit - 🤓',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // Legend list exactly matching Image 5:
          _buildLegendItem(theme, 'Mind Fit - 🤓', 0.58, const Color(0xFF3B75FF), '#1'),
          _buildLegendItem(theme, 'Eloquent English', 0.25, const Color(0xFFBF5AF2)),
          _buildLegendItem(theme, 'Alpha Build', 0.06, const Color(0xFF30D158)),
          _buildLegendItem(theme, 'Quiet Growth', 0.06, const Color(0xFFFFD60A)),
          _buildLegendItem(theme, 'Tech Forge', 0.05, const Color(0xFFFF2D55)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    ThemeData theme,
    String label,
    double percent,
    Color indicatorColor, [
    String? badge,
  ]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: badge != null ? AppColors.primary.withOpacity(0.04) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10.0),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 8.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 48.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.0),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 4.0,
                    backgroundColor: AppColors.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== GOALS TAB ====================
  Widget _buildGoalsTab(ThemeData theme, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Today's Accuracy Circle Card
        CustomCard(
          child: Column(
            children: [
              Text(
                'TODAY\'S ACCURACY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 20.0),
              Center(
                child: SizedBox(
                  width: 140.0,
                  height: 140.0,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          value: 0.0,
                          strokeWidth: 10.0,
                          backgroundColor: AppColors.surfaceContainer,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                      const Center(
                        child: Text(
                          '0%',
                          style: TextStyle(
                            fontSize: 36.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text(
                  'Recovery Needed',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // Deep Work Timer Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.inverseSurface,
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEEP WORK',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16.0),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '00:00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 56.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    'HRS',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Start Session',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                    ),
                    Icon(Icons.chevron_right, size: 18.0),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // Upcoming Events
        _buildUpcomingEventsCard(theme),
      ],
    );
  }

  // ==================== TASKS TAB ====================
  Widget _buildTasksTab(ThemeData theme) {
    return Column(
      children: [
        // Bento Stats Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.surfaceContainerHighest.withOpacity(0.5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1A1C2E),
                blurRadius: 30.0,
                offset: Offset(0, 10.0),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '0',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 28.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'TOTAL',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.secondary,
                        fontSize: 10.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1.0,
                height: 40.0,
                color: Colors.grey.withOpacity(0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '0',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 28.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'DONE',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.secondary,
                        fontSize: 10.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1.0,
                height: 40.0,
                color: Colors.grey.withOpacity(0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '100%',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.tertiaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 28.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'FOCUS',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.secondary,
                        fontSize: 10.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48.0),

        // Empty state tasks
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96.0,
                    height: 96.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 72.0,
                    height: 72.0,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.calendar_today, color: AppColors.outlineVariant, size: 36.0),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Text(
                'Your forge is silent.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Add a task to start crushing your day.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.outline,
                ),
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 6.0,
                ),
                child: Text(
                  'Add First Task',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 16.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom Painter for target background circles on the Focus Goal Card
class _TargetBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 20.0, paint);
    canvas.drawCircle(center, 40.0, paint);
    canvas.drawCircle(center, 60.0, paint);
    canvas.drawCircle(center, 80.0, paint);
    canvas.drawCircle(center, 100.0, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Segment details for the Donut Painter
class _Segment {
  final double percentage;
  final Color color;

  _Segment({required this.percentage, required this.color});
}

class GoalActivityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12.0;
    final strokeWidth = 24.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round; // Using round caps for segments

    double startAngle = -math.pi / 2; // start from top

    final segments = [
      _Segment(percentage: 0.58, color: const Color(0xFF3B75FF)),
      _Segment(percentage: 0.25, color: const Color(0xFFBF5AF2)),
      _Segment(percentage: 0.06, color: const Color(0xFFFFD60A)),
      _Segment(percentage: 0.06, color: const Color(0xFF30D158)),
      _Segment(percentage: 0.05, color: const Color(0xFFFF2D55)),
    ];

    final gapAngle = 0.08; // gap spacing between sections

    for (var segment in segments) {
      final sweepAngle = (segment.percentage * 2 * math.pi) - gapAngle;
      paint.color = segment.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
