import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart' as auth;
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_state.dart';
import '../../../../core/theme/theme_cubit.dart';

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

        final isWide = !ResponsiveLayout.isMobile(context);
        final isDesktop = ResponsiveLayout.isDesktop(context);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1380.0 : (isWide ? 950.0 : 600.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(theme),
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

  // --- Top Header ---
  Widget _buildHeader(ThemeData theme) {
    String displayName = 'rajkumar m';
    String avatarLetter = 'R';
    final authState = context.read<AuthBloc>().state;
    if (authState is auth.Authenticated) {
      displayName = authState.user.displayName ?? 'rajkumar m';
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
                style: AppTypography.displayFont(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2235),
                  fontSize: 26.0,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '"Small daily improvements lead to stunning results."',
                style: AppTypography.bodyFont(
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7A8499),
                  fontSize: 13.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        Row(
          children: [
            _buildHeaderIconButton(
              context,
              Icons.psychology_alt_outlined,
              const Color(0xFFF2E6FF),
              const Color(0xFFBF5AF2),
            ),
            const SizedBox(width: 8.0),
            _buildHeaderIconButton(
              context,
              Icons.auto_awesome,
              const Color(0xFFEEF2FF),
              AppColors.primary,
            ),
            const SizedBox(width: 8.0),
            GestureDetector(
              onTap: () {
                context.read<ThemeCubit>().toggleTheme();
              },
              child: Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Icon(
                  theme.brightness == Brightness.dark
                      ? Icons.wb_sunny_outlined
                      : Icons.brightness_2_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 18.0,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            _buildProfileAvatarBadge(context, avatarLetter),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton(
    BuildContext context,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      width: 38.0,
      height: 38.0,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 18.0,
      ),
    );
  }

  Widget _buildProfileAvatarBadge(BuildContext context, String letter) {
    return Container(
      width: 38.0,
      height: 38.0,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E2E),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15.0,
          ),
        ),
      ),
    );
  }

  // --- Dynamic Tab Content ---
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
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Main Column (62% width)
          Expanded(
            flex: 62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_latestState?.focusGoal != null) ...[
                  _buildFocusGoalCard(theme),
                  const SizedBox(height: 20.0),
                ],
                _buildRecruitCard(theme),
                const SizedBox(height: 20.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTodayAccuracyCard(theme)),
                    const SizedBox(width: 20.0),
                    Expanded(child: _buildDeepWorkCard(theme)),
                  ],
                ),
                const SizedBox(height: 20.0),
                _buildTaskAnalyticsCard(theme),
                const SizedBox(height: 24.0),
                _buildMainTargetsSection(theme),
              ],
            ),
          ),
          const SizedBox(width: 24.0),

          // Right Widgets Panel Column (38% width)
          Expanded(
            flex: 38,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickThoughtsCard(theme),
                const SizedBox(height: 16.0),
                _buildUpcomingEventsCard(theme),
                const SizedBox(height: 16.0),
                _buildWeeklyPerformanceCard(theme),
                const SizedBox(height: 16.0),
                _buildGoalActivityCard(theme),
                const SizedBox(height: 16.0),
                _buildConsistencyMapWidget(theme),
                const SizedBox(height: 16.0),
                _buildGoalHeatmapWidget(theme),
                const SizedBox(height: 16.0),
                _buildTaskOverviewWidget(theme),
                const SizedBox(height: 24.0),
                _buildFooterWidget(theme),
              ],
            ),
          ),
        ],
      );
    }

    // Mobile layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_latestState?.focusGoal != null) ...[
          _buildFocusGoalCard(theme),
          const SizedBox(height: 16.0),
        ],
        _buildRecruitCard(theme),
        const SizedBox(height: 16.0),
        _buildQuickThoughtsCard(theme),
        const SizedBox(height: 16.0),
        _buildTodayAccuracyCard(theme),
        const SizedBox(height: 16.0),
        _buildDeepWorkCard(theme),
        const SizedBox(height: 16.0),
        _buildUpcomingEventsCard(theme),
        const SizedBox(height: 16.0),
        _buildWeeklyPerformanceCard(theme),
        const SizedBox(height: 16.0),
        _buildGoalActivityCard(theme),
        const SizedBox(height: 16.0),
        _buildTaskAnalyticsCard(theme),
        const SizedBox(height: 24.0),
        _buildMainTargetsSection(theme),
        const SizedBox(height: 24.0),
        _buildFooterWidget(theme),
      ],
    );
  }

  // --- Focus Goal Card ---
  Widget _buildFocusGoalCard(ThemeData theme) {
    final goal = _latestState?.focusGoal;
    if (goal == null) return const SizedBox.shrink();

    final title = goal.title;
    final progress = goal.progress;
    final deadlineStr = goal.deadline ?? '31 Dec 2026';
    final habitsLeft = _latestState?.habitsLeftToday ?? 4;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.track_changes, size: 14.0, color: AppColors.primary),
                const SizedBox(width: 4.0),
                Text(
                  'FOCUS GOAL',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24.0,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2235),
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
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.outline,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0,
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
                      '$habitsLeft hours left today',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GOAL MASTERY',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.outline,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.0,
                ),
              ),
              Text(
                '${progress.toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.0,
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
          const SizedBox(height: 16.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue Goal',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.0),
                  ),
                  const SizedBox(width: 6.0),
                  const Icon(Icons.chevron_right, size: 18.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Level Recruit Card ---
  Widget _buildRecruitCard(ThemeData theme) {
    final level = _latestState?.xpProfile.level ?? 1;
    final totalXp = _latestState?.xpProfile.totalXP ?? 0;

    final nextLevelXp = AppConstants.levelXpMap[level + 1] ?? (level * 100);
    final currentLevelXp = AppConstants.levelXpMap[level] ?? 0;
    final requiredXpForNextLevel = nextLevelXp - currentLevelXp;
    final progressXp = totalXp - currentLevelXp;
    final progressPercent = requiredXpForNextLevel > 0 ? (progressXp / requiredXpForNextLevel).clamp(0.0, 1.0) : 0.0;
    final xpNeeded = (nextLevelXp - totalXp).clamp(0, 99999);

    String levelTitle = 'Recruit';
    if (level >= 10) {
      levelTitle = 'Grandmaster';
    } else if (level >= 7) {
      levelTitle = 'Master';
    } else if (level >= 5) {
      levelTitle = 'Elite';
    } else if (level >= 3) {
      levelTitle = 'Initiate';
    }

    final disciplineScore = (totalXp / 10 + 40).toInt().clamp(10, 100);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E2E),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20.0,
            offset: Offset(0, 10.0),
          ),
        ],
      ),
      child: Column(
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
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontSize: 9.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    levelTitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 28.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalXp',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 32.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '⭐ TOTAL XP',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontWeight: FontWeight.w800,
                      fontSize: 8.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏆 LEVEL $level',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 8.5,
                ),
              ),
              Text(
                '🚀 LEVEL ${level + 1}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 6.0,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4.0),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '⚡ $xpNeeded XP to next level',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18.0),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISCIPLINE',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white38,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '$disciplineScore',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14.0),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'Exceptional output today. Keep your momentum.',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
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
        ],
      ),
    );
  }

  // --- Today's Accuracy Card ---
  Widget _buildTodayAccuracyCard(ThemeData theme) {
    return CustomCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'TODAY\'S ACCURACY',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF7A8499),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontSize: 9.0,
            ),
          ),
          const SizedBox(height: 20.0),
          Center(
            child: SizedBox(
              width: 130.0,
              height: 130.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130.0,
                    height: 130.0,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 10.0,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9A5)),
                    ),
                  ),
                  Text(
                    '100%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32.0,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2235),
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
              color: const Color(0xFFE6FBF5),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              'Elite Performance',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF00D9A5),
                fontWeight: FontWeight.w800,
                fontSize: 11.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Deep Work Card ---
  Widget _buildDeepWorkCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E2E),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEEP WORK',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              fontSize: 9.0,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '00:00',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 50.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                'HRS',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start Session',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.0),
                ),
                const Icon(Icons.chevron_right, size: 18.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Task Productivity Card ---
  Widget _buildTaskAnalyticsCard(ThemeData theme) {
    return CustomCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.0,
                height: 34.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2E6FF),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(Icons.analytics_outlined, color: Color(0xFFBF5AF2), size: 18.0),
              ),
              const SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANALYTICS',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8C97AB),
                      fontWeight: FontWeight.w800,
                      fontSize: 8.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'Task Productivity',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.0,
                      color: const Color(0xFF1E2235),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24.0),
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFCFF),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE5E9F2)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F3F8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_outlined, size: 24.0, color: Color(0xFF8C97AB)),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'No tasks forged yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.0,
                      color: const Color(0xFF1E2235),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Create your first task in Today\'s Forge to activate Task Analytics.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8C97AB),
                      fontSize: 12.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Main Targets Section ---
  Widget _buildMainTargetsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE GOALS',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8C97AB),
                    fontWeight: FontWeight.w800,
                    fontSize: 8.5,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Main Targets',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18.0,
                    color: const Color(0xFF1E2235),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All Systems',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.0,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        CustomCard(
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F3F8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.track_changes, size: 24.0, color: Color(0xFF8C97AB)),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'No systems defined',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16.0,
                    color: const Color(0xFF1E2235),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Forge your first goal to start tracking.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8C97AB),
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Right Side Panel Widgets ---
  Widget _buildQuickThoughtsCard(ThemeData theme) {
    final count = _latestState?.quickThoughtsCount ?? 0;

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: const Color(0xFFF2E6FF),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              color: Color(0xFFBF5AF2),
              size: 20.0,
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2235),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3F8),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        '$count/5',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF8C97AB),
                          fontSize: 8.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Capture a spark before it fades...',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8C97AB),
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8C97AB), size: 20.0),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsCard(ThemeData theme) {
    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 16.0),
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Events',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.0,
                          color: const Color(0xFF1E2235),
                        ),
                      ),
                      Text(
                        'No events today',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF8C97AB),
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8C97AB), size: 18.0),
            ],
          ),
          const SizedBox(height: 24.0),
          Center(
            child: Column(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Color(0xFFCBD5E1), size: 28.0),
                const SizedBox(height: 8.0),
                Text(
                  'No upcoming events scheduled',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8C97AB),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    '+ Schedule your first event',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.0,
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
    final bestDayStr = _latestState?.bestDay ?? '2026-07-24';

    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Performance',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.0,
                  color: const Color(0xFF1E2235),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'LAST 7 DAYS',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3F8),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, color: AppColors.primary, size: 14.0),
                          const SizedBox(width: 4.0),
                          Text(
                            'ACCURACY',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF8C97AB),
                              fontWeight: FontWeight.w800,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '0%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2235),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3F8),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.orange, size: 14.0),
                          const SizedBox(width: 4.0),
                          Text(
                            'FOCUS',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF8C97AB),
                              fontWeight: FontWeight.w800,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '0h 0m',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2235),
                        ),
                      ),
                      Text(
                        'DEEP WORK',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF8C97AB),
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F8),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF8C97AB), size: 14.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'Best Day',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                        color: const Color(0xFF1E2235),
                      ),
                    ),
                  ],
                ),
                Text(
                  bestDayStr,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.0,
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
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.bolt, color: AppColors.primary, size: 16.0),
              ),
              const SizedBox(width: 8.0),
              Text(
                'GOAL ACTIVITY',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8C97AB),
                  fontWeight: FontWeight.w800,
                  fontSize: 8.5,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  Text(
                    'No activity data yet.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2235),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Start completing habits to see your distribution.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8C97AB),
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyMapWidget(ThemeData theme) {
    return CustomCard(
      padding: const EdgeInsets.all(20.0),
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
                    'CONSISTENCY MAP',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8C97AB),
                      fontWeight: FontWeight.w800,
                      fontSize: 8.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '30-Day Activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15.0,
                      color: const Color(0xFF1E2235),
                    ),
                  ),
                  Text(
                    'Task & habit completion accuracy per day',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8C97AB),
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ACCURACY',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8C97AB),
                      fontWeight: FontWeight.w800,
                      fontSize: 8.0,
                    ),
                  ),
                  Text(
                    '100%',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF00D9A5),
                      fontWeight: FontWeight.w800,
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // Sub-switcher Buttons (TASKS / GOALS / FOCUS)
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F8),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 4.0),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 12.0, color: Color(0xFF1E2235)),
                        const SizedBox(width: 4.0),
                        Text(
                          'TASKS',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 10.0, color: const Color(0xFF1E2235)),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'GOALS',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 10.0, color: const Color(0xFF8C97AB)),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'FOCUS',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 10.0, color: const Color(0xFF8C97AB)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // 30-Day Dot Matrix Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(24, (i) {
              final isToday = i == 23;
              return Container(
                width: 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF00D9A5) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30D AGO', style: GoogleFonts.plusJakartaSans(fontSize: 8.0, fontWeight: FontWeight.bold, color: const Color(0xFF8C97AB))),
              Text('TODAY', style: GoogleFonts.plusJakartaSans(fontSize: 8.0, fontWeight: FontWeight.bold, color: const Color(0xFF8C97AB))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalHeatmapWidget(ThemeData theme) {
    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28.0,
                    height: 28.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FBF5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.verified, color: Color(0xFF00D9A5), size: 16.0),
                  ),
                  const SizedBox(width: 8.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOAL CONSISTENCY',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF8C97AB),
                          fontWeight: FontWeight.w800,
                          fontSize: 8.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '30-Day Goal Heatmap',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.0,
                          color: const Color(0xFF1E2235),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'GOAL ACCURACY',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8C97AB),
                      fontWeight: FontWeight.w800,
                      fontSize: 8.0,
                    ),
                  ),
                  Text(
                    '0%',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1E2235),
                      fontWeight: FontWeight.w800,
                      fontSize: 14.0,
                    ),
                  ),
                  Text(
                    '30-day avg',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF8C97AB),
                      fontSize: 7.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Goal completion rule satisfaction per day',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF8C97AB),
              fontSize: 10.0,
            ),
          ),
          const SizedBox(height: 16.0),

          // Dot Matrix Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(24, (i) {
              final isToday = i == 23;
              return Container(
                width: 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF00D9A5) : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('30D AGO', style: GoogleFonts.plusJakartaSans(fontSize: 8.0, fontWeight: FontWeight.bold, color: const Color(0xFF8C97AB))),
              Text('TODAY', style: GoogleFonts.plusJakartaSans(fontSize: 8.0, fontWeight: FontWeight.bold, color: const Color(0xFF8C97AB))),
            ],
          ),
          const SizedBox(height: 16.0),
          Center(
            child: Text(
              'Set up goals with habits to track consistency',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF8C97AB),
                fontWeight: FontWeight.w700,
                fontSize: 11.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskOverviewWidget(ThemeData theme) {
    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TASK OVERVIEW',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF8C97AB),
              fontWeight: FontWeight.w800,
              fontSize: 8.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              Expanded(child: _buildMiniStat(theme, '0', 'CURRENT ACTIVE TASKS', Icons.bolt, const Color(0xFFEEF2FF), AppColors.primary)),
              const SizedBox(width: 8.0),
              Expanded(child: _buildMiniStat(theme, '0', 'CURRENT COMPLETED TASKS', Icons.check_circle, const Color(0xFFE6FBF5), const Color(0xFF00D9A5))),
              const SizedBox(width: 8.0),
              Expanded(child: _buildMiniStat(theme, '0d', 'HIGHEST TASK COMPLETION STREAK', Icons.local_fire_department, const Color(0xFFFFF4E5), Colors.orange)),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 14.0),
              const SizedBox(width: 4.0),
              Text(
                'TOP SYSTEM STREAKS',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF8C97AB),
                  fontWeight: FontWeight.w800,
                  fontSize: 8.0,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Center(
            child: Text(
              'No active task streaks today — keep completing tasks!',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF8C97AB),
                fontStyle: FontStyle.italic,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(ThemeData theme, String val, String label, IconData icon, Color iconBg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Column(
        children: [
          Container(
            width: 26.0,
            height: 26.0,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14.0, color: iconColor),
          ),
          const SizedBox(height: 8.0),
          Text(val, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16.0, color: const Color(0xFF1E2235))),
          const SizedBox(height: 2.0),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 7.0, color: const Color(0xFF8C97AB), fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildFooterWidget(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            '© 2026 GOALFORGE STRATEGY',
            style: GoogleFonts.plusJakartaSans(fontSize: 9.0, fontWeight: FontWeight.w800, color: const Color(0xFF8C97AB)),
          ),
        ),
        const SizedBox(height: 2.0),
        Center(
          child: Text(
            'ADVANCED PRODUCTIVITY SUITE',
            style: GoogleFonts.plusJakartaSans(fontSize: 8.0, fontWeight: FontWeight.w700, color: const Color(0xFF8C97AB)),
          ),
        ),
      ],
    );
  }

  // ==================== GOALS TAB ====================
  Widget _buildGoalsTab(ThemeData theme, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTodayAccuracyCard(theme),
        const SizedBox(height: 16.0),
        _buildDeepWorkCard(theme),
        const SizedBox(height: 16.0),
        _buildUpcomingEventsCard(theme),
      ],
    );
  }

  // ==================== TASKS TAB ====================
  Widget _buildTasksTab(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '0',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 28.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'TOTAL',
                      style: GoogleFonts.plusJakartaSans(
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
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '0',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 28.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'DONE',
                      style: GoogleFonts.plusJakartaSans(
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
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '100%',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.tertiaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 28.0,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'FOCUS',
                      style: GoogleFonts.plusJakartaSans(
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
                      color: AppColors.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 72.0,
                    height: 72.0,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.calendar_today, color: AppColors.outlineVariant, size: 36.0),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              Text(
                'Your forge is silent.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Add a task to start crushing your day.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
