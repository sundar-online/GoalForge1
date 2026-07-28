import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/models/quick_thought.dart';
import '../../../../core/domain/models/scheduled_event.dart';
import '../../../../core/domain/models/task.dart';
import '../../../../core/domain/models/xp_profile.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart' as auth;
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../events/presentation/bloc/events_bloc.dart';
import '../../../events/presentation/bloc/events_event.dart';
import '../../../events/presentation/bloc/events_state.dart';
import '../../../goals/presentation/bloc/goals_bloc.dart';
import '../../../goals/presentation/bloc/goals_state.dart';
import '../../../logs/presentation/bloc/notes_bloc.dart';
import '../../../logs/presentation/bloc/notes_event.dart';
import '../../../tasks/presentation/bloc/tasks_bloc.dart';
import '../../../tasks/presentation/bloc/tasks_state.dart';
import '../../../focus/presentation/bloc/focus_bloc.dart';
import '../../../focus/presentation/bloc/focus_state.dart';
import '../../../main_navigation_page.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DashboardLoaded? _latestState;
  int _analyticsTab = 0; // 0: MONTHLY TRENDS, 1: WEEKLY ACTIVITY
  DateTime _selectedCalendarDate = DateTime.now();
  DateTime _focusedCalendarMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppThemeTokens.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoaded) {
          _latestState = state;
        }

        if (_latestState == null) {
          if (state is DashboardError) {
            return Scaffold(
              backgroundColor: tokens.surfaceElevated,
              body: Center(
                child: Text(state.message, style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          return Scaffold(
            backgroundColor: tokens.surfaceElevated,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final loaded = _latestState!;
        final xpProfile = loaded.xpProfile;

        return Scaffold(
          backgroundColor: tokens.surfaceElevated,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1380.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── TOP HEADER (Greeting + Actions) ──
                      _buildTopHeader(context, theme, tokens),

                      const SizedBox(height: 24.0),

                      // ── MAIN CONTENT GRID (2 COLUMNS ON DESKTOP) ──
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT COLUMN (65%)
                            Expanded(
                              flex: 65,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildFocusGoalCard(context, tokens, loaded),
                                  const SizedBox(height: 16.0),
                                  _buildLevelXpCard(context, tokens, xpProfile),
                                  const SizedBox(height: 16.0),
                                  _buildAlertBannersStack(context, tokens),
                                  const SizedBox(height: 16.0),
                                  _buildAccuracyAndDeepWorkRow(context, tokens, loaded),
                                  const SizedBox(height: 20.0),
                                  _buildTaskAnalyticsModule(context, tokens, loaded),
                                ],
                              ),
                            ),

                            const SizedBox(width: 24.0),

                            // RIGHT COLUMN (35%)
                            Expanded(
                              flex: 35,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInteractiveCalendarSection(context, tokens),
                                  const SizedBox(height: 16.0),
                                  _buildWeeklyPerformanceCard(context, tokens, loaded),
                                  const SizedBox(height: 16.0),
                                  _buildGoalActivityDonutCard(context, tokens),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFocusGoalCard(context, tokens, loaded),
                            const SizedBox(height: 16.0),
                            _buildLevelXpCard(context, tokens, xpProfile),
                            const SizedBox(height: 16.0),
                            _buildAlertBannersStack(context, tokens),
                            const SizedBox(height: 16.0),
                            _buildAccuracyAndDeepWorkRow(context, tokens, loaded),
                            const SizedBox(height: 20.0),
                            _buildTaskAnalyticsModule(context, tokens, loaded),
                            const SizedBox(height: 24.0),
                            _buildInteractiveCalendarSection(context, tokens),
                            const SizedBox(height: 16.0),
                            _buildWeeklyPerformanceCard(context, tokens, loaded),
                            const SizedBox(height: 16.0),
                            _buildGoalActivityDonutCard(context, tokens),
                          ],
                        ),

                      const SizedBox(height: 32.0),

                      // ── FOOTER ──
                      Center(
                        child: Text(
                          '© 2026 GOALFORGE STRATEGY ADVANCED PRODUCTIVITY SUITE',
                          style: GoogleFonts.plusJakartaSans(
                            color: tokens.contentTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
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

  // ─────────────────────────────────────────────────────────────
  // 1. TOP HEADER (Greeting + Quote + Header Action Buttons)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopHeader(BuildContext context, ThemeData theme, AppThemeTokens tokens) {
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
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.contentPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),
              Text(
                '"Discipline is choosing between what you want now and what you want most."',
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.contentTertiary,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),

        // Action Buttons Row
        Row(
          children: [
            _buildHeaderIconButton(
              icon: theme.brightness == Brightness.dark ? LucideIcons.sun : LucideIcons.moon,
              bgColor: tokens.surfaceCard,
              iconColor: tokens.contentPrimary,
              onTap: () => context.read<ThemeCubit>().toggleTheme(),
            ),
            const SizedBox(width: 8.0),
            // User Avatar Popup Menu
            PopupMenuButton<String>(
              tooltip: 'Profile Menu',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: tokens.surfaceElevated,
              elevation: 8,
              onSelected: (value) {
                if (value == 'profile') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                } else if (value == 'signout') {
                  context.read<AuthBloc>().add(SignOutRequested());
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.contentPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        (authState is auth.Authenticated && authState.user.email != null)
                            ? authState.user.email!
                            : 'sundar@goalforge.app',
                        style: TextStyle(
                          color: tokens.contentSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(LucideIcons.award, size: 16, color: tokens.contentPrimary),
                      const SizedBox(width: 10),
                      Text(
                        'Profile & Achievements',
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.contentPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'signout',
                  child: Row(
                    children: [
                      const Icon(LucideIcons.logOut, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Text(
                        'Sign Out',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 38.0,
                height: 38.0,
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.0,
        height: 38.0,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Icon(icon, size: 18.0, color: iconColor),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. FOCUS GOAL CARD (Left Top)
  // ─────────────────────────────────────────────────────────────
  Widget _buildFocusGoalCard(BuildContext context, AppThemeTokens tokens, DashboardLoaded loaded) {
    final goal = loaded.focusGoal;
    final title = goal?.title ?? 'No Focus Goal Set';
    final progressPct = goal != null
        ? (goal.progress > 1.0 ? goal.progress : goal.progress * 100).toInt()
        : 0;
    final progressValue = goal != null
        ? (goal.progress > 1.0 ? goal.progress / 100.0 : goal.progress).clamp(0.0, 1.0)
        : 0.0;
    final dueDateText = (goal != null && goal.deadline != null && goal.deadline!.isNotEmpty)
        ? 'Due: ${goal.deadline}'
        : 'No Active Target';
    final activeHabitsText = goal != null
        ? '${loaded.habitsLeftToday} Habits/Tasks Active'
        : '0 Habits Active';

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.target, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'FOCUS GOAL',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;

              final goalInfo = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: tokens.contentPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        dueDateText,
                        style: TextStyle(color: tokens.contentTertiary, fontSize: 12),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(color: tokens.contentTertiary, shape: BoxShape.circle),
                      ),
                      Text(
                        activeHabitsText,
                        style: TextStyle(color: tokens.contentTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text(
                        'GOAL MASTERY',
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.contentSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$progressPct%',
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.contentPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 6,
                      backgroundColor: tokens.borderDefault,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              );

              final actionBtn = SizedBox(
                width: isNarrow ? double.infinity : null,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => const TabNavigationNotification(4).dispatch(context), // Focus Tab
                  icon: Text(
                    goal != null ? 'Continue Goal' : 'Forge Goal',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  label: const Icon(LucideIcons.chevronRight, size: 16),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    goalInfo,
                    const SizedBox(height: 16),
                    actionBtn,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: goalInfo),
                  const SizedBox(width: 20),
                  actionBtn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. LEVEL & XP CARD (Dark Navy Card)
  // ─────────────────────────────────────────────────────────────
  Widget _buildLevelXpCard(BuildContext context, AppThemeTokens tokens, XPProfile xpProfile) {
    const gamificationService = GamificationService();
    final levelProgress = gamificationService.calculateLevelProgress(xpProfile.totalXP);
    final level = levelProgress.currentLevel;
    final xp = xpProfile.totalXP;
    final rankTitle = AppConstants.getRankTitle(level);
    final currentXpInLevel = levelProgress.xpInCurrentLevel;
    final xpNeededForNext = levelProgress.xpNeededForNextLevel;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark slate / navy background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEVEL $level',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rankTitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$xp',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'TOTAL XP',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // XP Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: levelProgress.progressRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LEVEL $level',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700),
              ),
              Expanded(
                child: Text(
                  '${xpNeededForNext - currentXpInLevel}/$xpNeededForNext to next level',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'LEVEL 2',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bottom Streak Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'STREAK UNK 40',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(LucideIcons.flame, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your consistency is reaching alpha levels.',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(LucideIcons.zap, size: 14, color: Colors.amber),
                const SizedBox(width: 6),
                const Icon(LucideIcons.trophy, size: 14, color: Colors.amber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4. ALERT BANNERS STACK (3 Pills)
  // ─────────────────────────────────────────────────────────────
  Widget _buildAlertBannersStack(BuildContext context, AppThemeTokens tokens) {
    return Column(
      children: [
        _buildSingleAlertPill(
          icon: LucideIcons.alertTriangle,
          text: 'Your streak is at risk',
          iconColor: Colors.amber.shade800,
          bgColor: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFFDE68A),
        ),
        const SizedBox(height: 8),
        _buildSingleAlertPill(
          icon: LucideIcons.clock,
          text: 'Low productivity detected',
          iconColor: Colors.red.shade700,
          bgColor: const Color(0xFFFEE2E2),
          borderColor: const Color(0xFFFCA5A5),
        ),
        const SizedBox(height: 8),
        _buildSingleAlertPill(
          icon: LucideIcons.zap,
          text: 'Great consistency!',
          iconColor: Colors.green.shade700,
          bgColor: const Color(0xFFDCFCE7),
          borderColor: const Color(0xFF86EFAC),
        ),
      ],
    );
  }

  Widget _buildSingleAlertPill({
    required IconData icon,
    required String text,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: iconColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5. ACCURACY & DEEP WORK ROW (Split 2 Cards)
  // ─────────────────────────────────────────────────────────────
  Widget _buildAccuracyAndDeepWorkRow(BuildContext context, AppThemeTokens tokens, DashboardLoaded loaded) {
    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, goalsState) {
        return BlocBuilder<TasksBloc, TasksState>(
          builder: (context, tasksState) {
            return BlocBuilder<FocusBloc, FocusState>(
              builder: (context, focusState) {
                final todayStr = AppDateUtils.getTodayString();

                int totalTodayTasks = 0;
                int doneTodayTasks = 0;
                if (tasksState is TasksLoaded) {
                  final tasks = tasksState.effectiveAllTasks;
                  totalTodayTasks = tasks.length;
                  doneTodayTasks = tasks.where((t) => t.completed || t.completedDates.contains(todayStr)).length;
                }

                final double accuracyRatio = totalTodayTasks > 0 ? (doneTodayTasks / totalTodayTasks) : 1.0;
                final int accuracyPct = (accuracyRatio * 100).toInt();

                String statusLabel = 'No Tasks Today';
                Color statusBgColor = tokens.surfaceElevated;
                Color statusTextColor = tokens.contentSecondary;

                if (totalTodayTasks > 0) {
                  if (accuracyPct >= 80) {
                    statusLabel = 'Elite Performance';
                    statusBgColor = const Color(0xFFE6FBF5);
                    statusTextColor = const Color(0xFF00D9A5);
                  } else if (accuracyPct >= 50) {
                    statusLabel = 'On Track';
                    statusBgColor = AppColors.primary.withValues(alpha: 0.12);
                    statusTextColor = AppColors.primary;
                  } else {
                    statusLabel = 'Recovery Needed';
                    statusBgColor = Colors.red.withValues(alpha: 0.12);
                    statusTextColor = Colors.red.shade700;
                  }
                }

                int totalFocusMinsToday = 0;
                if (focusState is FocusLoaded) {
                  totalFocusMinsToday = focusState.totalFocusMinutesToday;
                }

                int habitMinsToday = 0;
                if (goalsState is GoalsLoaded) {
                  for (final habitList in goalsState.habitsByGoalId.values) {
                    for (final h in habitList) {
                      if (h.type == 'time' && (h.completedDates.contains(todayStr) || h.timeSpent > 0)) {
                        habitMinsToday += h.timeSpent;
                      }
                    }
                  }
                }

                final int totalDeepWorkMins = totalFocusMinsToday + habitMinsToday;
                final hoursStr = (totalDeepWorkMins ~/ 60).toString().padLeft(2, '0');
                final minsStr = (totalDeepWorkMins % 60).toString().padLeft(2, '0');

                final accuracyCard = CustomCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "TODAY'S ACCURACY",
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.contentTertiary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: CircularProgressIndicator(
                              value: totalTodayTasks > 0 ? accuracyRatio : 1.0,
                              strokeWidth: 8,
                              backgroundColor: tokens.borderDefault,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                totalTodayTasks == 0
                                    ? AppColors.primary
                                    : (accuracyPct >= 80
                                        ? const Color(0xFF00D9A5)
                                        : (accuracyPct >= 50 ? AppColors.primary : Colors.red)),
                              ),
                            ),
                          ),
                          Text(
                            '$accuracyPct%',
                            style: GoogleFonts.plusJakartaSans(
                              color: tokens.contentPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.plusJakartaSans(color: statusTextColor, fontWeight: FontWeight.w800, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );

                final deepWorkCard = Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEEP WORK',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),

                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$hoursStr:$minsStr',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'HRS',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalDeepWorkMins == 0 ? '0 mins completed today' : '🔥 ${totalDeepWorkMins}m deep focus today',
                        style: GoogleFonts.plusJakartaSans(
                          color: totalDeepWorkMins == 0 ? const Color(0xFF64748B) : Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () => const TabNavigationNotification(4).dispatch(context), // Focus Tab
                          icon: Text(
                            'Start Session',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                          label: const Icon(LucideIcons.chevronRight, size: 14),
                        ),
                      ),
                    ],
                  ),
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 550) {
                      return Column(
                        children: [
                          accuracyCard,
                          const SizedBox(height: 16),
                          deepWorkCard,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: accuracyCard),
                        const SizedBox(width: 16),
                        Expanded(child: deepWorkCard),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 6. TASK ANALYTICS MODULE (Productivity Module)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTaskAnalyticsModule(BuildContext context, AppThemeTokens tokens, DashboardLoaded loaded) {
    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, goalsState) {
        return BlocBuilder<TasksBloc, TasksState>(
          builder: (context, tasksState) {
            List<Goal> goals = [];
            if (goalsState is GoalsLoaded) {
              goals = goalsState.goals;
            }

            List<Task> tasks = [];
            if (tasksState is TasksLoaded) {
              tasks = tasksState.effectiveAllTasks;
            }

            final todayStr = AppDateUtils.getTodayString();
            final totalTasks = tasks.length;
            final doneToday = tasks.where((t) => t.completed || t.completedDates.contains(todayStr)).length;
            final totalActive = tasks.length;
            final pending = tasks.where((t) => !t.completed && !t.completedDates.contains(todayStr)).length;

            final accuracyRatio = totalTasks > 0 ? (doneToday / totalTasks) : 1.0;
            final accuracyPct = (accuracyRatio * 100).toInt();
            final disciplineScore = totalTasks > 0 ? accuracyPct : 100;

            String operatorLabel = 'NO TASKS YET';
            Color operatorColor = tokens.contentSecondary;
            if (totalTasks > 0) {
              if (disciplineScore >= 80) {
                operatorLabel = 'OPTIMAL DISCIPLINE';
                operatorColor = Colors.green.shade700;
              } else if (disciplineScore >= 50) {
                operatorLabel = 'MODERATE PACE';
                operatorColor = AppColors.primary;
              } else {
                operatorLabel = 'INITIATE OPERATOR';
                operatorColor = Colors.red.shade700;
              }
            }

            int currentStreak = 0;
            int bestStreak = 0;

            if (tasks.isNotEmpty) {
              final maxTaskStreak = tasks.map((t) => t.streak).reduce((a, b) => a > b ? a : b);
              final maxTaskBestStreak = tasks.map((t) => t.bestStreak).reduce((a, b) => a > b ? a : b);
              currentStreak = maxTaskStreak;
              bestStreak = maxTaskBestStreak;
            }
            if (goals.isNotEmpty) {
              final maxGoalStreak = goals.map((g) => g.streak).reduce((a, b) => a > b ? a : b);
              final maxGoalBestStreak = goals.map((g) => g.bestStreak).reduce((a, b) => a > b ? a : b);
              if (maxGoalStreak > currentStreak) currentStreak = maxGoalStreak;
              if (maxGoalBestStreak > bestStreak) bestStreak = maxGoalBestStreak;
            }

            if (doneToday > 0 && currentStreak == 0) {
              currentStreak = 1;
            }
            if (doneToday > 0 && bestStreak == 0) {
              bestStreak = 1;
            }

            final currentStreakStr = '${currentStreak}d';
            final bestStreakStr = '${bestStreak}d';

            return CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2E6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.layoutGrid, size: 16, color: Color(0xFFBF5AF2)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRODUCTIVITY MODULE',
                              style: GoogleFonts.plusJakartaSans(
                                color: tokens.contentTertiary,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'Task Analytics',
                              style: GoogleFonts.plusJakartaSans(
                                color: tokens.contentPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                        onPressed: () => const TabNavigationNotification(2).dispatch(context),
                        icon: Flexible(
                          child: Text(
                            "Forge",
                            style: GoogleFonts.plusJakartaSans(
                              color: tokens.contentSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        label: Icon(LucideIcons.chevronRight, size: 14, color: tokens.contentSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 6 Mini Metric Grid + Gauge Score Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 550;

                      final gaugeScoreCard = Container(
                        width: isNarrow ? double.infinity : null,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TASK DISCIPLINE SCORE',
                              style: GoogleFonts.plusJakartaSans(
                                color: tokens.contentTertiary,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: CircularProgressIndicator(
                                    value: totalTasks > 0 ? (disciplineScore / 100.0) : 1.0,
                                    strokeWidth: 6,
                                    backgroundColor: tokens.borderDefault,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      totalTasks == 0
                                          ? AppColors.primary
                                          : (disciplineScore >= 80
                                              ? Colors.green
                                              : (disciplineScore >= 50 ? AppColors.primary : Colors.red)),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$disciplineScore',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: tokens.contentPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text('/ 100', style: TextStyle(color: tokens.iconSubtle, fontSize: 9)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              operatorLabel,
                              style: GoogleFonts.plusJakartaSans(color: operatorColor, fontWeight: FontWeight.w900, fontSize: 9),
                            ),
                          ],
                        ),
                      );

                      final statGrid = Column(
                        children: [
                          Row(
                            children: [
                              _buildMiniMetricBox(tokens, LucideIcons.zap, '$totalActive', 'TOTAL ACTIVE', Colors.purple),
                              const SizedBox(width: 8),
                              _buildMiniMetricBox(tokens, LucideIcons.checkCircle, '$doneToday', 'DONE TODAY', Colors.green),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMiniMetricBox(tokens, LucideIcons.clock, '$pending', 'PENDING', Colors.orange),
                              const SizedBox(width: 8),
                              _buildMiniMetricBox(tokens, LucideIcons.target, '$accuracyPct%', 'ACCURACY', Colors.blue),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildMiniMetricBox(tokens, LucideIcons.flame, currentStreakStr, 'STREAK', Colors.orange),
                              const SizedBox(width: 8),
                              _buildMiniMetricBox(tokens, LucideIcons.trophy, bestStreakStr, 'BEST', Colors.amber),
                            ],
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            gaugeScoreCard,
                            const SizedBox(height: 12),
                            statGrid,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(flex: 3, child: gaugeScoreCard),
                          const SizedBox(width: 12),
                          Expanded(flex: 5, child: statGrid),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Tabs: MONTHLY TRENDS | WEEKLY ACTIVITY (Scrollable for mobile)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _analyticsTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _analyticsTab == 0 ? tokens.surfaceCard : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'MONTHLY TRENDS',
                              style: GoogleFonts.plusJakartaSans(
                                color: _analyticsTab == 0 ? tokens.contentPrimary : tokens.contentTertiary,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _analyticsTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _analyticsTab == 1 ? tokens.surfaceCard : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'WEEKLY ACTIVITY',
                              style: GoogleFonts.plusJakartaSans(
                                color: _analyticsTab == 1 ? tokens.contentPrimary : tokens.contentTertiary,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniMetricBox(AppThemeTokens tokens, IconData icon, String value, String label, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(color: tokens.contentPrimary, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(color: tokens.contentTertiary, fontWeight: FontWeight.w700, fontSize: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ─────────────────────────────────────────────────────────────
  // 8. RIGHT COLUMN: INTERACTIVE CREATIVE CALENDAR & ACTIVITY MAP
  // ─────────────────────────────────────────────────────────────
  Widget _buildInteractiveCalendarSection(BuildContext context, AppThemeTokens tokens) {
    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, goalsState) {
        return BlocBuilder<TasksBloc, TasksState>(
          builder: (context, tasksState) {
            return BlocBuilder<EventsBloc, EventsState>(
              builder: (context, eventsState) {
                List<ScheduledEvent> allEvents = [];
                if (eventsState is EventsLoaded) {
                  allEvents = eventsState.allEvents;
                }

                List<Goal> goals = [];
                if (goalsState is GoalsLoaded) {
                  goals = goalsState.goals;
                }

                List<Task> tasks = [];
                if (tasksState is TasksLoaded) {
                  tasks = tasksState.tasks;
                }

                final selectedDateStr = AppDateUtils.toLocalYYYYMMDD(_selectedCalendarDate);
                final eventsForSelectedDate = allEvents.where((e) => e.eventDate == selectedDateStr).toList();

                final year = _focusedCalendarMonth.year;
                final month = _focusedCalendarMonth.month;
                final firstDayOfMonth = DateTime(year, month, 1);
                final daysInMonth = DateTime(year, month + 1, 0).day;

                final startingWeekday = firstDayOfMonth.weekday; // 1 (Mon) to 7 (Sun)
                final leadingEmptyDays = startingWeekday - 1;

                final monthNames = [
                  'January', 'February', 'March', 'April', 'May', 'June',
                  'July', 'August', 'September', 'October', 'November', 'December'
                ];
                final monthName = monthNames[month - 1];

                return CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row (Month Title + Navigation)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CREATIVE CALENDAR & ACTIVITY',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: tokens.contentTertiary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$monthName $year',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: tokens.contentPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _focusedCalendarMonth = DateTime(year, month - 1, 1);
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(LucideIcons.chevronLeft, size: 18, color: tokens.contentPrimary),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _focusedCalendarMonth = DateTime(year, month + 1, 1);
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(LucideIcons.chevronRight, size: 18, color: tokens.contentPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Weekday Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((dayStr) {
                          return Expanded(
                            child: Text(
                              dayStr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: tokens.contentTertiary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),

                      // Days Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leadingEmptyDays + daysInMonth,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (context, index) {
                          if (index < leadingEmptyDays) {
                            return const SizedBox.shrink();
                          }

                          final dayNumber = index - leadingEmptyDays + 1;
                          final dayDate = DateTime(year, month, dayNumber);
                          final dayDateStr = AppDateUtils.toLocalYYYYMMDD(dayDate);
                          final isToday = AppDateUtils.toLocalYYYYMMDD(DateTime.now()) == dayDateStr;
                          final isSelected = selectedDateStr == dayDateStr;

                          // Compute completion percentage for dayDateStr
                          double completionRatio = 0.0;
                          final goalsDone = goals.where((g) => g.completedDates.contains(dayDateStr)).length;
                          final tasksDone = tasks.where((t) => (t.completed && t.targetDate == dayDateStr) || t.completedDates.contains(dayDateStr)).length;
                          final eventsDone = allEvents.where((e) => e.eventDate == dayDateStr && e.completed).length;
                          final totalEventsForDay = allEvents.where((e) => e.eventDate == dayDateStr).length;

                          if (goals.isNotEmpty || tasks.isNotEmpty || totalEventsForDay > 0) {
                            final totalPossible = (goals.isNotEmpty ? goals.length : 0) + (tasks.isNotEmpty ? tasks.length : 0) + totalEventsForDay;
                            final totalDone = goalsDone + tasksDone + eventsDone;
                            if (totalPossible > 0) {
                              completionRatio = (totalDone / totalPossible).clamp(0.0, 1.0);
                            }
                          }

                          // Color scale: 100% Green, 50% Blue, 25% Yellow, 0% White
                          Color bgCellColor = tokens.surfaceElevated;
                          Color textCellColor = tokens.contentPrimary;

                          if (isSelected) {
                            bgCellColor = AppColors.primary;
                            textCellColor = Colors.white;
                          } else if (completionRatio >= 1.0) {
                            bgCellColor = const Color(0xFF4CAF50); // 100% Green
                            textCellColor = Colors.white;
                          } else if (completionRatio >= 0.50) {
                            bgCellColor = const Color(0xFF2196F3); // 50% Blue
                            textCellColor = Colors.white;
                          } else if (completionRatio >= 0.25) {
                            bgCellColor = const Color(0xFFFFC107); // 25% Yellow
                            textCellColor = const Color(0xFF1E1B4B); // Dark text on yellow
                          } else if (isToday) {
                            bgCellColor = AppColors.primary.withValues(alpha: 0.15);
                            textCellColor = AppColors.primary;
                          }

                          final hasEvent = totalEventsForDay > 0;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCalendarDate = dayDate;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgCellColor,
                                borderRadius: BorderRadius.circular(8),
                                border: isToday && !isSelected && completionRatio == 0.0
                                    ? Border.all(color: AppColors.primary, width: 1.5)
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayNumber',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: textCellColor,
                                      fontWeight: isSelected || isToday || completionRatio > 0 ? FontWeight.w900 : FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (hasEvent) ...[
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: (isSelected || completionRatio >= 0.50) ? Colors.white : AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Completion Status Legend Bar (100% Green, 50% Blue, 25% Yellow, 0% White)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegendTag(color: const Color(0xFF4CAF50), label: '100%', tokens: tokens),
                            _buildLegendTag(color: const Color(0xFF2196F3), label: '50%', tokens: tokens),
                            _buildLegendTag(color: const Color(0xFFFFC107), label: '25%', tokens: tokens),
                            _buildLegendTag(color: tokens.borderDefault, label: '0%', tokens: tokens),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selected Date Header + Add Idea Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SELECTED DATE',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: tokens.contentTertiary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                                Text(
                                  _formatSelectedDateHeader(_selectedCalendarDate),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: tokens.contentPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            onPressed: () => _showAddIdeaModal(context, _selectedCalendarDate),
                            icon: const Icon(LucideIcons.plus, size: 12),
                            label: Text(
                              'Add Idea',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Events/Ideas list for selected day
                      if (eventsForSelectedDate.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.lightbulb, size: 16, color: tokens.iconSubtle),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No creative ideas or events for this day yet.',
                                  style: TextStyle(color: tokens.contentSecondary, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: eventsForSelectedDate.map((event) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: tokens.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.sparkles, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: tokens.contentPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (event.description != null && event.description!.isNotEmpty)
                                          Text(
                                            event.description!,
                                            style: TextStyle(color: tokens.contentSecondary, fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      context.read<EventsBloc>().add(DeleteEvent(event.id));
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
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
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLegendTag({required Color color, required String label, required AppThemeTokens tokens}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: tokens.contentSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatSelectedDateHeader(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdayStr = days[date.weekday - 1];
    final monthStr = months[date.month - 1];
    return '$weekdayStr, $monthStr ${date.day}, ${date.year}';
  }

  void _showAddIdeaModal(BuildContext context, DateTime targetDate) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final dateStr = AppDateUtils.toLocalYYYYMMDD(targetDate);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final tokens = AppThemeTokens.of(dialogContext);
        return AlertDialog(
          backgroundColor: tokens.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Add Creative Idea / Event',
            style: GoogleFonts.plusJakartaSans(
              color: tokens.contentPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: $dateStr',
                style: TextStyle(color: tokens.contentSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                autofocus: true,
                style: TextStyle(color: tokens.contentPrimary),
                decoration: InputDecoration(
                  labelText: 'Title / Creative Idea',
                  labelStyle: TextStyle(color: tokens.contentSecondary),
                  hintText: 'e.g. Design new dashboard concept',
                  hintStyle: TextStyle(color: tokens.iconSubtle),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: TextStyle(color: tokens.contentPrimary),
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: TextStyle(color: tokens.contentSecondary),
                  hintText: 'Add details or inspiration...',
                  hintStyle: TextStyle(color: tokens.iconSubtle),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: tokens.contentSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  final newEvent = ScheduledEvent(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    description: descController.text.trim(),
                    eventDate: dateStr,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  context.read<EventsBloc>().add(CreateEvent(newEvent));
                  context.read<NotesBloc>().add(
                        CreateQuickThoughtEvent(
                          QuickThought(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            content: title,
                            createdAt: DateTime.now().toIso8601String(),
                          ),
                        ),
                      );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save Idea'),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 9. RIGHT COLUMN: WEEKLY PERFORMANCE
  // ─────────────────────────────────────────────────────────────
  Widget _buildWeeklyPerformanceCard(BuildContext context, AppThemeTokens tokens, DashboardLoaded loaded) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Weekly Performance',
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.contentPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LAST 7 DAYS',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCURACY',
                      style: GoogleFonts.plusJakartaSans(color: tokens.contentTertiary, fontWeight: FontWeight.w800, fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(loaded.weeklyAccuracy * 100).toInt()}%',
                      style: GoogleFonts.plusJakartaSans(color: tokens.contentPrimary, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                    Text(
                      '↘ -5% vs last wk',
                      style: GoogleFonts.plusJakartaSans(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOCUS',
                      style: GoogleFonts.plusJakartaSans(color: tokens.contentTertiary, fontWeight: FontWeight.w800, fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loaded.weeklyFocusDuration,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                    Text(
                      'PERFORMANCE',
                      style: GoogleFonts.plusJakartaSans(color: tokens.contentSecondary, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Best Day',
                          style: GoogleFonts.plusJakartaSans(color: tokens.contentSecondary, fontWeight: FontWeight.w700, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  loaded.bestDay,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 10. RIGHT COLUMN: GOAL ACTIVITY DONUT CHART
  // ─────────────────────────────────────────────────────────────
  Widget _buildGoalActivityDonutCard(BuildContext context, AppThemeTokens tokens) {
    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, state) {
        List<Goal> goals = [];
        if (state is GoalsLoaded) {
          goals = state.goals;
        }

        final double totalProgress = goals.fold(0.0, (sum, g) => sum + g.progress);
        final topGoal = goals.isNotEmpty
            ? goals.reduce((a, b) => a.progress >= b.progress ? a : b)
            : null;
        final int topPct = (totalProgress > 0 && topGoal != null)
            ? ((topGoal.progress / totalProgress) * 100).toInt()
            : 0;

        final legendColors = [
          AppColors.primary,
          Colors.green,
          Colors.orange,
          Colors.amber,
          Colors.purple,
        ];

        return CustomCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ANALYTICS',
                          style: GoogleFonts.plusJakartaSans(color: tokens.contentTertiary, fontWeight: FontWeight.w800, fontSize: 9),
                        ),
                        Text(
                          'Goal Activity',
                          style: GoogleFonts.plusJakartaSans(color: tokens.contentPrimary, fontWeight: FontWeight.w900, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MOST ACTIVE',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: (topPct / 100.0).clamp(0.0, 1.0),
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$topPct%',
                          style: GoogleFonts.plusJakartaSans(color: tokens.contentPrimary, fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                        Text(
                          topGoal?.title ?? 'No Activity',
                          style: TextStyle(color: tokens.contentSecondary, fontSize: 9, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (goals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No activity data recorded yet.',
                      style: TextStyle(color: tokens.contentSecondary, fontSize: 11),
                    ),
                  ),
                )
              else
                ...goals.take(5).toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final g = entry.value;
                  final pct = totalProgress > 0 ? ((g.progress / totalProgress) * 100).toInt() : 0;
                  final color = legendColors[idx % legendColors.length];
                  return _buildDonutLegendRow(tokens, g.title, '$pct%', color);
                }),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOST ACTIVE GOAL',
                            style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 9),
                          ),
                          Text(
                            topGoal?.title ?? 'None',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF1E1B4B), fontWeight: FontWeight.w900, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$topPct%\nACTIVITY',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonutLegendRow(AppThemeTokens tokens, String title, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: tokens.contentSecondary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            pct,
            style: GoogleFonts.plusJakartaSans(color: tokens.contentPrimary, fontWeight: FontWeight.w800, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
