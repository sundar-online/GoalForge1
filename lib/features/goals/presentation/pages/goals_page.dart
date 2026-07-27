import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/domain/models/habit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/widgets/flaticon_icon.dart';
import '../../../../core/widgets/flaticon_picker_dialog.dart';
import '../../../habits/presentation/bloc/habits_bloc.dart';
import '../../../habits/presentation/bloc/habits_event.dart';
import '../bloc/goals_bloc.dart';
import '../bloc/goals_event.dart';
import '../bloc/goals_state.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  // Form Controllers
  final _nameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  final _orderController = TextEditingController(text: '1');
  final _dateController = TextEditingController();
  String _selectedFlaticonKey = 'target';

  bool _isFormExpanded = false;
  bool _showAdvancedSettings = true;
  final Set<String> _expandedGoalIds = {};
  bool _hasInitializedExpanded = false;
  bool _isFocusGoal = false;
  String _selectedMode = 'ANY'; // 'ALL', 'ANY', 'CUSTOM'
  bool _isReorderMode = false;

  // Inline Habit Builder State
  String? _inlineAddingHabitGoalId;
  final TextEditingController _inlineHabitTitleController = TextEditingController();
  final TextEditingController _inlineHabitTargetController = TextEditingController(text: '15');
  String _inlineHabitType = 'time';
  final List<String> _inlineScheduleDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Overlay state for modals
  Goal? _editingGoal;
  Goal? _extendingGoal;
  Goal? _deletingGoal;
  Habit? _loggingHabit;
  // ignore: unused_field
  String? _loggingHabitGoalId;

  final List<_StagedHabit> _stagedHabits = [
    _StagedHabit(
      title: 'Daily Practice',
      type: 'time',
      targetTime: 15,
      targetCount: 1,
      scheduleDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    ),
  ];

  GoalsLoaded? _latestState;

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _categoryController.dispose();
    _orderController.dispose();
    _dateController.dispose();
    _inlineHabitTitleController.dispose();
    _inlineHabitTargetController.dispose();
    for (final habit in _stagedHabits) {
      habit.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, state) {
        if (state is GoalsLoaded) {
          _latestState = state;
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Header Row
                          _buildHeader(theme),
                          const SizedBox(height: 20.0),

                          // 2. Top Summary Banner (Dark Navy Capsule)
                          _buildSummaryBanner(theme),
                          const SizedBox(height: 16.0),

                          // 3. Pool Selector Tabs
                          _buildPoolSelector(theme),
                          const SizedBox(height: 20.0),

                          // 4. Main Goals Canvas
                          _buildMainCanvas(theme, context),
                          const SizedBox(height: 32.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Overlay: Extend Deadline Modal
              if (_extendingGoal != null)
                Positioned.fill(
                  child: _buildExtendDeadlineOverlay(theme, context),
                ),

              // Overlay: Delete Confirmation Modal
              if (_deletingGoal != null)
                Positioned.fill(
                  child: _buildDeleteConfirmOverlay(theme, context),
                ),

              // Overlay: Log Time Modal
              if (_loggingHabit != null)
                Positioned.fill(
                  child: _buildLogTimeOverlay(theme, context),
                ),

              // Overlay: Edit Goal confirmation — opens the create form in edit mode
              if (_editingGoal != null && !_isFormExpanded)
                Positioned.fill(
                  child: _buildEditGoalOverlay(theme, context),
                ),

              // Overlay: Goal System Builder (renders last = on top)
              if (_isFormExpanded)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                        child: _buildGoalFormModal(theme, context),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- Header ---
  // --- Header ---
  Widget _buildHeader(ThemeData theme) {
    final tokens = AppThemeTokens.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 42.0,
              height: 42.0,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.track_changes_rounded, color: AppColors.primary, size: 22.0),
            ),
            const SizedBox(width: 14.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goals System',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    color: tokens.contentSecondary,
                    fontSize: 26.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  '🚀 Build daily systems to drive long-term progress.',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w500,
                    color: tokens.contentTertiary,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Circular Plus Button
        GestureDetector(
          onTap: () => setState(() => _isFormExpanded = true),
          child: Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: tokens.surfaceCard,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 10.0, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.add, color: AppColors.primary, size: 22.0),
          ),
        ),
      ],
    );
  }

  // --- Top Dark Summary Banner ---
  Widget _buildSummaryBanner(ThemeData theme) {
    final avgMastery = _latestState?.avgMastery.toInt() ?? 0;
    final finished = _latestState?.finishedCount ?? 0;
    final inProgress = _latestState?.inProgressCount ?? 0;
    final missingCount = _latestState?.missingCount ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 18.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16.0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCol('$avgMastery%', '📈 AVG MASTERY', AppColors.primary),
                _buildSummaryCol('$finished', '🏆 FINISHED', const Color(0xFF00D9A5)),
                _buildSummaryCol('$inProgress', '🚀 IN PROGRESS', Colors.white),
                _buildSummaryCol('$missingCount', '💭 MISSING DREAMS', const Color(0xFFBF5AF2)),
              ],
            ),
          ),
          // Right Controls inside the Dark Banner (Matching Reference Screenshot)
          Container(
            height: 28.0,
            width: 1.0,
            color: Colors.white.withValues(alpha: 0.12),
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          Row(
            children: [
              // 1. Reorder toggle (6-dots grip icon)
              GestureDetector(
                onTap: () => setState(() => _isReorderMode = !_isReorderMode),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    LucideIcons.gripVertical,
                    color: _isReorderMode ? AppColors.primary : Colors.white54,
                    size: 18.0,
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              // 2. Expand all goals
              GestureDetector(
                onTap: () {
                  final goals = _latestState?.goals ?? [];
                  setState(() {
                    for (final g in goals) {
                      _expandedGoalIds.add(g.id);
                    }
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(LucideIcons.maximize2, color: Colors.white54, size: 16.0),
                ),
              ),
              const SizedBox(width: 4.0),
              // 3. Collapse all goals
              GestureDetector(
                onTap: () => setState(() => _expandedGoalIds.clear()),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(LucideIcons.minimize2, color: Colors.white54, size: 16.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCol(String val, String label, Color valColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20.0,
            fontWeight: FontWeight.w900,
            color: valColor,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white54,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // --- Pool Selector Tabs (Active Targets / Missing Dreams) ---
  Widget _buildPoolSelector(ThemeData theme) {
    final tokens = AppThemeTokens.of(context);
    final activeTab = _latestState?.activeTab ?? 'ACTIVE';
    final activeGoalsCount = (_latestState?.goals ?? []).where((g) => !g.isMissingDream).length;
    final missingGoalsCount = (_latestState?.goals ?? []).where((g) => g.isMissingDream).length;

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: tokens.surfaceChip,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPoolTab('Active Targets ($activeGoalsCount)', 'ACTIVE', activeTab, Icons.track_changes_rounded, AppColors.primary),
          _buildPoolTab('Missing Dreams ($missingGoalsCount)', 'MISSING', activeTab, Icons.nightlight_round, const Color(0xFFBF5AF2)),
        ],
      ),
    );
  }

  Widget _buildPoolTab(String label, String tabKey, String activeTab, IconData icon, Color activeColor) {
    final tokens = AppThemeTokens.of(context);
    final isActive = activeTab == tabKey;
    return GestureDetector(
      onTap: () => context.read<GoalsBloc>().add(SwitchActiveTabEvent(tabKey)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: isActive
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8.0, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 15.0, color: isActive ? Colors.white : tokens.contentDisabled),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.0,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : tokens.contentTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Canvas ---
  Widget _buildMainCanvas(ThemeData theme, BuildContext context) {
    final goals = _latestState?.goals ?? [];
    final habitsMap = _latestState?.habitsByGoalId ?? {};

    if (goals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F3F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.track_changes, size: 32.0, color: Color(0xFF8C97AB)),
              ),
              const SizedBox(height: 16.0),
              Text(
                'No Systems Forged Yet',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 20.0,
                  color: const Color(0xFF1E2235),
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'Forge your first goal to start your journey.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppThemeTokens.of(context).iconSubtle,
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isFormExpanded = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Forge Now',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filter by active pool (Active Targets vs Missing Dreams)
    final activeTab = _latestState?.activeTab ?? 'ACTIVE';


    final filteredGoals = goals.where((g) {
      return activeTab == 'MISSING' ? g.isMissingDream : !g.isMissingDream;
    }).toList();

    // Only truly MASTERED goals (progress >= 100%) sort to bottom.
    // "Done today" goals stay in their priority order — sorting them to the
    // bottom every day is disruptive and confusing.
    filteredGoals.sort((a, b) {
      final aMastered = a.progress >= 100.0;
      final bMastered = b.progress >= 100.0;
      if (aMastered != bMastered) {
        return aMastered ? 1 : -1;
      }
      return a.order.compareTo(b.order);
    });

    if (!_hasInitializedExpanded && filteredGoals.isNotEmpty) {
      _hasInitializedExpanded = true;
      // Accordion: only open the first goal on initial load
      _expandedGoalIds.add(filteredGoals.first.id);
    }

    if (filteredGoals.isEmpty && goals.isNotEmpty) {
      // Pool is empty but other pool has goals
      final poolLabel = activeTab == 'MISSING' ? 'Missing Dreams' : 'Active Targets';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Center(
          child: Text(
            'No goals in $poolLabel pool.',
            style: GoogleFonts.plusJakartaSans(color: AppThemeTokens.of(context).iconSubtle, fontSize: 14.0),
          ),
        ),
      );
    }

    if (filteredGoals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 80.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F3F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.track_changes, size: 32.0, color: Color(0xFF8C97AB)),
              ),
              const SizedBox(height: 16.0),
              Text(
                'No Systems Forged Yet',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 20.0,
                  color: AppThemeTokens.of(context).contentSecondary,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'Forge your first goal to start your journey.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppThemeTokens.of(context).iconSubtle,
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () => setState(() => _isFormExpanded = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                  elevation: 0,
                ),
                child: Text('Forge Now', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15.0)),
              ),
            ],
          ),
        ),
      );
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 20.0)) / crossAxisCount;

        return Wrap(
          spacing: 20.0,
          runSpacing: 20.0,
          children: filteredGoals.asMap().entries.map((entry) {
            final idx = entry.key;
            final goal = entry.value;
            final habits = habitsMap[goal.id] ?? [];
            return SizedBox(
              width: itemWidth,
              child: Column(
                children: [
                  // Reorder buttons (shown in reorder mode)
                  if (_isReorderMode)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildReorderBtn(context, goal.id, 'up', idx == 0),
                          const SizedBox(width: 4.0),
                          _buildReorderBtn(context, goal.id, 'down', idx == filteredGoals.length - 1),
                        ],
                      ),
                    ),
                  _buildGoalCard(theme: theme, context: context, goal: goal, habits: habits),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReorderBtn(BuildContext context, String goalId, String direction, bool disabled) {
    final tokens = AppThemeTokens.of(context);
    return GestureDetector(
      onTap: disabled ? null : () => context.read<GoalsBloc>().add(ReorderGoalEvent(goalId: goalId, direction: direction)),
      child: Container(
        width: 28.0,
        height: 28.0,
        decoration: BoxDecoration(
          color: disabled ? tokens.surfaceChip : tokens.surfaceCard,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: tokens.borderDefault),
        ),
        child: Icon(
          direction == 'up' ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 18.0,
          color: disabled ? tokens.contentDisabled : AppColors.primary,
        ),
      ),
    );
  }
  // --- Goal Card Item ---
  Widget _buildGoalCard({
    required ThemeData theme,
    required BuildContext context,
    required Goal goal,
    required List<Habit> habits,
  }) {
    final tag = goal.tag ?? 'GENERAL';
    final progressRatio = (goal.progress / 100.0).clamp(0.0, 1.0);
    final isExpanded = _expandedGoalIds.contains(goal.id);
    final todayStr = AppDateUtils.getTodayString();

    // Tag color tokens
    final (tagBg, tagFg) = _getTagColors(tag);

    // Daily progress calculation
    final dailyProgress = _calculateDailyProgress(goal, habits, todayStr);
    final completedHabitsCount = habits.where((h) => h.completedDates.contains(todayStr) || h.completed).length;
    final dailyHabitRatio = habits.isEmpty ? 0.0 : (completedHabitsCount / habits.length).clamp(0.0, 1.0);

    // Status flags
    // isMastered = long-term goal fully achieved (progress >= 100%)  → green border, DONE badge, sorts to bottom
    // isDoneToday = all of today's scheduled habits done              → teal ring accent only
    final isMastered = goal.progress >= 100.0;
    final isDoneToday = dailyProgress >= 100.0 && habits.isNotEmpty;
    // isGoalDone controls border color, shadow, and DONE badge — only for true mastery
    final isGoalDone = isMastered;

    // Duration: total days of goal (creation → deadline, or elapsed if no deadline)
    final createdAt = DateTime.tryParse(goal.createdAt);
    final deadline = goal.deadline != null ? DateTime.tryParse(goal.deadline!) : null;

    final int totalGoalDays;
    if (createdAt != null && deadline != null) {
      // Full goal lifespan: from start to end date (inclusive)
      totalGoalDays = deadline.difference(createdAt).inDays + 1;
    } else if (createdAt != null) {
      // No deadline: show days elapsed so far (minimum 1)
      totalGoalDays = DateTime.now().difference(createdAt).inDays + 1;
    } else {
      totalGoalDays = 1;
    }

    final completedDays = goal.completedDates.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Tapping anywhere on the card (except inner action buttons) toggles expand.
      // Inner buttons absorb their own taps — this outer handler never fires for them.
      onTap: () => setState(() {
        if (isExpanded) {
          _expandedGoalIds.remove(goal.id);
        } else {
          _expandedGoalIds.clear(); // accordion: close all others
          _expandedGoalIds.add(goal.id);
        }
      }),
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeTokens.of(context).surfaceCard,
          borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: isGoalDone
              ? const Color(0xFF00D9A5)
              : (goal.isFocusGoal ? AppColors.primary.withValues(alpha: 0.35) : AppThemeTokens.of(context).borderSubtle),
          width: isGoalDone ? 2.0 : (goal.isFocusGoal ? 2.0 : 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isGoalDone
                ? const Color(0xFF00D9A5).withValues(alpha: 0.08)
                : (goal.isFocusGoal ? AppColors.primary.withValues(alpha: 0.08) : const Color(0x08000000)),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.0, 18.0, 16.0, isExpanded ? 0.0 : 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Tag Pill & Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6.0,
                        runSpacing: 4.0,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: tagBg,
                              borderRadius: BorderRadius.circular(7.0),
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: tagFg,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Star (Focus - Solid Filled Gold Star when focus goal)
                        _cardIconBtn(
                          icon: goal.isFocusGoal ? Icons.star : LucideIcons.star,
                          color: goal.isFocusGoal ? Colors.amber : const Color(0xFF94A3B8),
                          size: 16.0,
                          onTap: () => context.read<GoalsBloc>().add(ToggleFocusGoalEvent(goal.id)),
                        ),
                        // Moon (Missing Dream toggle)
                        _cardIconBtn(
                          icon: LucideIcons.moon,
                          color: goal.isMissingDream ? const Color(0xFFBF5AF2) : const Color(0xFF94A3B8),
                          size: 16.0,
                          onTap: () => context.read<GoalsBloc>().add(ToggleMissingDreamEvent(goal.id)),
                        ),
                        // Edit
                        _cardIconBtn(
                          icon: LucideIcons.edit3,
                          color: const Color(0xFF94A3B8),
                          size: 16.0,
                          onTap: () => setState(() => _editingGoal = goal),
                        ),
                        // Delete
                        _cardIconBtn(
                          icon: LucideIcons.trash2,
                          color: const Color(0xFF94A3B8),
                          size: 16.0,
                          onTap: () => setState(() => _deletingGoal = goal),
                        ),
                        // Expand chevron
                        _cardIconBtn(
                          icon: isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                          color: const Color(0xFF94A3B8),
                          size: 18.0,
                          onTap: () => setState(() {
                            if (isExpanded) {
                              _expandedGoalIds.remove(goal.id);
                            } else {
                              _expandedGoalIds.clear(); // accordion: close all others
                              _expandedGoalIds.add(goal.id);
                            }
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),

                // Middle Row: Circular Mastery Progress Ring & Title
                Row(
                  children: [
                    SizedBox(
                      width: 60.0,
                      height: 60.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60.0,
                            height: 60.0,
                            child: CircularProgressIndicator(
                              value: progressRatio,
                              strokeWidth: 5.5,
                              backgroundColor: AppThemeTokens.of(context).progressTrack,
                              // Teal color when done today OR mastered; primary blue otherwise
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (isDoneToday || isMastered) ? const Color(0xFF00D9A5) : AppColors.primary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${goal.progress.toInt()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppThemeTokens.of(context).contentSecondary,
                                ),
                              ),
                              Text(
                                'MASTERY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 7.0,
                                  fontWeight: FontWeight.w900,
                                  color: AppThemeTokens.of(context).contentTertiary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w800,
                              color: AppThemeTokens.of(context).contentSecondary,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          // Horizontal Progress Line Under Title (Matching Reference Screenshot)
                          LayoutBuilder(
                            builder: (_, bc) => Stack(
                              children: [
                                Container(
                                  height: 4.0,
                                  width: bc.maxWidth,
                                  decoration: BoxDecoration(
                                    color: AppThemeTokens.of(context).progressTrack,
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  height: 4.0,
                                  width: bc.maxWidth * dailyHabitRatio,
                                  decoration: BoxDecoration(
                                    // Teal bar when done today OR mastered
                                    color: (isDoneToday || isMastered) ? const Color(0xFF00D9A5) : AppColors.primary,
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Bottom Meta Chips Row (Centered)
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 6.0,
                    children: [
                      // Clickable Deadline Chip
                      GestureDetector(
                        onTap: () => setState(() => _extendingGoal = goal),
                        child: _buildMetaPill(
                          '🗓️',
                          goal.deadline != null ? _formatDeadline(goal.deadline!) : 'No Deadline',
                          clickable: true,
                        ),
                      ),
                      // Duration counter: completed days out of total goal days
                      _buildMetaPill(
                        '🔥',
                        '$completedDays/$totalGoalDays',
                      ),
                      // Habits ratio
                      _buildMetaPill(
                        '📋',
                        '$completedHabitsCount/${habits.length}',
                      ),
                      if (isGoalDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6FBF5),
                            borderRadius: BorderRadius.circular(7.0),
                          ),
                          child: Text(
                            '✅ DONE',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00A87A),
                              fontSize: 9.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Habits Panel — animated accordion expand/collapse
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14.0),
                        Divider(height: 1.0, color: AppThemeTokens.of(context).borderDefault),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (habits.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Center(
                                    child: Text(
                                      'No habits linked yet. Add one!',
                                      style: GoogleFonts.plusJakartaSans(color: AppThemeTokens.of(context).iconSubtle, fontSize: 12.0),
                                    ),
                                  ),
                                )
                              else
                                ...habits.map((habit) => _buildHabitRow(context, goal, habit, todayStr)),
                              const SizedBox(height: 10.0),
                              if (_inlineAddingHabitGoalId == goal.id)
                                _buildInlineHabitForm(context, goal)
                              else
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _inlineAddingHabitGoalId = goal.id;
                                      _inlineHabitTitleController.clear();
                                      _inlineHabitTargetController.text = '15';
                                      _inlineHabitType = 'time';
                                      _inlineScheduleDays.clear();
                                      _inlineScheduleDays.addAll(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);
                                    });
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.add, size: 16.0, color: AppColors.primary),
                                          const SizedBox(width: 6.0),
                                          Text(
                                            'Add Daily Habit',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4.0),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      ), // close Container
    ); // close GestureDetector (wraps entire card for tap-to-expand)
  }

  Widget _cardIconBtn({required IconData icon, required Color color, required VoidCallback onTap, double size = 16.0}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }

  Widget _buildInlineHabitForm(BuildContext context, Goal goal) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF141722) : const Color(0xFFF8FAFC);
    final inputBg = isDark ? const Color(0xFF1E2235) : const Color(0xFFFFFFFF);
    final inputBorder = isDark ? Colors.white24 : const Color(0xFFCBD5E1);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSubtle = isDark ? Colors.white54 : const Color(0xFF64748B);
    final pillInactiveBg = isDark ? const Color(0xFF1E2235) : const Color(0xFFE2E8F0);
    final pillInactiveText = isDark ? Colors.white : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: isDark ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x40000000) : const Color(0x0F000000),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Habit Title Input Field
          TextField(
            controller: _inlineHabitTitleController,
            autofocus: true,
            style: GoogleFonts.plusJakartaSans(
              color: textPrimary,
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'New habit name...',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: textSubtle,
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            ),
          ),
          const SizedBox(height: 14.0),

          // 2. Type Dropdown & Target Value Input Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: inputBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _inlineHabitType,
                      dropdownColor: inputBg,
                      isExpanded: true,
                      style: GoogleFonts.plusJakartaSans(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5),
                      items: [
                        DropdownMenuItem(
                          value: 'time',
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('Time-Based', style: GoogleFonts.plusJakartaSans(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'count',
                          child: Row(
                            children: [
                              const Icon(Icons.tag, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('Count-Based', style: GoogleFonts.plusJakartaSans(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'check',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('Checkmark', style: GoogleFonts.plusJakartaSans(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _inlineHabitType = val;
                            if (val == 'time') {
                              _inlineHabitTargetController.text = '15';
                            } else if (val == 'count') {
                              _inlineHabitTargetController.text = '1';
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              if (_inlineHabitType == 'time' || _inlineHabitType == 'count')
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: inputBorder),
                    ),
                    child: TextField(
                      controller: _inlineHabitTargetController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 12.5, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                        suffixText: _inlineHabitType == 'time' ? 'MINS' : 'TIMES',
                        suffixStyle: GoogleFonts.plusJakartaSans(color: textSubtle, fontSize: 10.0, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14.0),

          // 3. Schedule Days Section
          Text(
            'SCHEDULE',
            style: GoogleFonts.plusJakartaSans(
              color: textSubtle,
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              final isSelected = _inlineScheduleDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_inlineScheduleDays.length > 1) {
                        _inlineScheduleDays.remove(day);
                      }
                    } else {
                      _inlineScheduleDays.add(day);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : pillInactiveBg,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: isSelected ? AppColors.primary : inputBorder),
                  ),
                  child: Text(
                    day,
                    style: GoogleFonts.plusJakartaSans(
                      color: isSelected ? Colors.white : pillInactiveText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),

          // 4. Action Buttons Row (Add Daily Habit + Cancel)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final rawTitle = _inlineHabitTitleController.text.trim();
                    final title = rawTitle.isEmpty ? 'Daily Habit' : rawTitle;
                    final parsedVal = int.tryParse(_inlineHabitTargetController.text.trim()) ?? (_inlineHabitType == 'time' ? 15 : 1);
                    final newHabit = Habit(
                      id: UuidGenerator.generate(),
                      goalId: goal.id,
                      title: title,
                      type: _inlineHabitType,
                      targetTime: _inlineHabitType == 'time' ? parsedVal : 15,
                      targetCount: _inlineHabitType == 'count' ? parsedVal : 1,
                      scheduleDays: List<String>.from(_inlineScheduleDays),
                      reminderEnabled: false,
                      completedDates: const [],
                      createdAt: DateTime.now().toIso8601String(),
                    );
                    context.read<HabitsBloc>().add(CreateStandAloneHabitEvent(newHabit));
                    context.read<GoalsBloc>().add(SubscribeToGoals());
                    setState(() {
                      _inlineAddingHabitGoalId = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add Daily Habit',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.0),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              TextButton(
                onPressed: () {
                  setState(() {
                    _inlineAddingHabitGoalId = null;
                  });
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(color: textSubtle, fontWeight: FontWeight.w700, fontSize: 13.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Type-specific Habit Row (Matching Reference Image)
  Widget _buildHabitRow(BuildContext context, Goal goal, Habit habit, String todayStr) {
    final isCompletedToday = habit.completedDates.contains(todayStr) || habit.completed;
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayWeekday = weekdays[DateTime.now().weekday - 1];
    final isRestDay = habit.scheduleDays.isNotEmpty && !habit.scheduleDays.contains(todayWeekday);

    // Type icon lookup
    IconData typeIcon = Icons.access_time_rounded;
    if (habit.type == 'count') typeIcon = Icons.layers_outlined;
    if (habit.type == 'check') typeIcon = Icons.check_box_outlined;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Tapping anywhere on the habit row (except action buttons) marks it complete.
      // Action buttons (Log, +/-, MARK DONE, delete) absorb their own taps.
      onTap: isRestDay
          ? null
          : () => context.read<HabitsBloc>().add(
                ToggleHabitCompletionEvent(habitId: habit.id, dateStr: todayStr),
              ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Opacity(
          opacity: isRestDay ? 0.45 : 1.0,
          child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isCompletedToday ? AppThemeTokens.of(context).successBg : AppThemeTokens.of(context).surfaceElevated,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isCompletedToday ? const Color(0xFF00D9A5) : AppThemeTokens.of(context).borderDefault,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Animated checkbox: empty rounded rect when active, green filled rounded rect with check on completion
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: Container(
                      key: ValueKey('${habit.id}_$isCompletedToday'),
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: isCompletedToday ? const Color(0xFF00D9A5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.0),
                        border: isCompletedToday
                            ? null
                            : Border.all(
                                color: AppThemeTokens.of(context).borderStrong,
                                width: 2.0,
                              ),
                      ),
                      child: isCompletedToday
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18.0,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: AppThemeTokens.of(context).contentSecondary,
                            fontSize: 13.5,
                            decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Row(
                          children: [
                            Text(
                              habit.type == 'time'
                                  ? '${habit.timeSpent}/${habit.targetTime} MINS'
                                  : (habit.type == 'count' ? '${habit.currentCount}/${habit.targetCount} UNITS' : 'CHECKMARK'),
                              style: GoogleFonts.plusJakartaSans(
                                color: isCompletedToday ? AppThemeTokens.of(context).successText : AppThemeTokens.of(context).contentDisabled,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (habit.streak > 0) ...[
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 10.0)),
                                    const SizedBox(width: 3.0),
                                    Text(
                                      '${habit.streak}d',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFFFF9500)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right Action Controls
                  if (!isRestDay) ...[
                    if (habit.type == 'time')
                      GestureDetector(
                        onTap: () => setState(() {
                          _loggingHabit = habit;
                          _loggingHabitGoalId = goal.id;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                          decoration: BoxDecoration(
                            color: isCompletedToday ? const Color(0xFF00D9A5) : AppColors.primary,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            '+ Log',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                      )
                    else if (habit.type == 'count')
                      Row(
                        children: [
                          _countBtn(context, habit, -1, isCompletedToday),
                          const SizedBox(width: 4.0),
                          _countBtn(context, habit, 1, isCompletedToday),
                        ],
                      )
                    else if (habit.type == 'check')
                      GestureDetector(
                        onTap: () => context.read<HabitsBloc>().add(ToggleHabitCompletionEvent(habitId: habit.id, dateStr: todayStr)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                          decoration: BoxDecoration(
                            color: isCompletedToday ? const Color(0xFF00D9A5) : AppColors.primary,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            isCompletedToday ? 'DONE' : 'MARK DONE',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(width: 8.0),

                  // Delete Habit Trash Icon
                  GestureDetector(
                    onTap: () => context.read<HabitsBloc>().add(DeleteHabitEvent(goalId: goal.id, habitId: habit.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline, size: 16.0, color: isCompletedToday ? AppThemeTokens.of(context).successText : AppThemeTokens.of(context).borderStrong),
                    ),
                  ),
                ],
              ),

              // Sub-line: REMINDER indicator
              const SizedBox(height: 6.0),
              Row(
                children: [
                  Icon(Icons.alarm_outlined, size: 11.0, color: AppThemeTokens.of(context).contentDisabled),
                  const SizedBox(width: 4.0),
                  Text(
                    'REMINDER',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppThemeTokens.of(context).contentDisabled,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Container(
                    width: 5.0,
                    height: 5.0,
                    decoration: BoxDecoration(
                      color: AppThemeTokens.of(context).borderStrong,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ), // close Opacity
      ), // close Padding
    ); // close GestureDetector
  }

  Widget _countBtn(BuildContext context, Habit habit, int delta, bool isCompleted) {
    final tokens = AppThemeTokens.of(context);
    return GestureDetector(
      onTap: isCompleted && delta > 0 ? null : () => context.read<HabitsBloc>().add(UpdateHabitCountEvent(habitId: habit.id, delta: delta)),
      child: Container(
        width: 34.0,
        height: 34.0,
        decoration: BoxDecoration(
          color: tokens.surfaceChip,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: tokens.borderDefault),
        ),
        child: Icon(delta > 0 ? Icons.add : Icons.remove, size: 16.0, color: tokens.contentTertiary),
      ),
    );
  }


  // Tag color token lookup

  Widget _buildMetaPill(String emoji, String val, {bool clickable = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13.0)),
        const SizedBox(width: 5.0),
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            color: clickable ? const Color(0xFF3B82F6) : AppThemeTokens.of(context).contentSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // Tag color token lookup
  (Color, Color) _getTagColors(String tag) {
    switch (tag.toUpperCase()) {
      case 'LEARNING':
      case 'EDUCATION':
        return (const Color(0xFFFFF3E0), const Color(0xFFE65100));
      case 'HEALTH':
      case 'FITNESS':
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
      case 'CAREER':
      case 'WORK':
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0));
      case 'PERSONAL':
      case 'GROWTH':
        return (const Color(0xFFF3E5F5), const Color(0xFF7B1FA2));
      case 'FINANCE':
      case 'MONEY':
        return (const Color(0xFFE8F5E9), const Color(0xFF1B5E20));
      case 'CREATIVITY':
      case 'ART':
        return (const Color(0xFFFCE4EC), const Color(0xFFC62828));
      default:
        return (const Color(0xFFEEF2FF), AppColors.primary);
    }
  }

  // Daily progress calculation (matches web spec: mode-aware)
  double _calculateDailyProgress(Goal goal, List<Habit> habits, String todayStr) {
    if (habits.isEmpty) return 0.0;
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayWeekday = weekdays[DateTime.now().weekday - 1];

    // Only count habits scheduled for today
    final todayHabits = habits.where((h) {
      return h.scheduleDays.isEmpty || h.scheduleDays.contains(todayWeekday);
    }).toList();

    if (todayHabits.isEmpty) return 100.0; // Rest day = 100%

    final completedCount = todayHabits.where((h) => h.completedDates.contains(todayStr) || h.completed).length;

    if (goal.mode == 'ANY') {
      return completedCount > 0 ? 100.0 : 0.0;
    } else if (goal.mode == 'CUSTOM') {
      final minRequired = goal.minHabits.clamp(1, todayHabits.length);
      return completedCount >= minRequired ? 100.0 : (completedCount / minRequired * 100.0).clamp(0.0, 100.0);
    } else {
      // ALL mode
      return (completedCount / todayHabits.length * 100.0).clamp(0.0, 100.0);
    }
  }

  String _formatDeadline(String deadline) {
    try {
      final d = DateTime.parse(deadline);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return deadline;
    }
  }

  // --- Extend Deadline Overlay ---
  Widget _buildExtendDeadlineOverlay(ThemeData theme, BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final goal = _extendingGoal!;
    final currentDeadline = goal.deadline != null ? DateTime.tryParse(goal.deadline!) ?? DateTime.now().add(const Duration(days: 30)) : DateTime.now().add(const Duration(days: 30));

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420.0),
          margin: const EdgeInsets.all(24.0),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: tokens.surfaceModal,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24.0, offset: Offset(0, 12))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Extend Deadline', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18.0, color: tokens.contentSecondary)),
                  GestureDetector(
                    onTap: () => setState(() => _extendingGoal = null),
                    child: Icon(Icons.close, color: tokens.iconSubtle),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                'Current: ${_formatDeadline(goal.deadline ?? 'Not set')}',
                style: GoogleFonts.plusJakartaSans(color: tokens.contentTertiary, fontSize: 13.0),
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  _extendBtn(context, goal, currentDeadline, 3, '+3 Days'),
                  const SizedBox(width: 10.0),
                  _extendBtn(context, goal, currentDeadline, 7, '+7 Days'),
                  const SizedBox(width: 10.0),
                  _extendBtn(context, goal, currentDeadline, 30, '+30 Days'),
                ],
              ),
              const SizedBox(height: 14.0),
              GestureDetector(
                onTap: () async {
                  final goalsBloc = context.read<GoalsBloc>();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: currentDeadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null && mounted) {
                    goalsBloc.add(ExtendDeadlineEvent(
                      goalId: goal.id,
                      newDeadline: AppDateUtils.toLocalYYYYMMDD(picked),
                    ));
                    setState(() => _extendingGoal = null);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: tokens.borderDefault),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Center(
                    child: Text(
                      'Pick Custom Date',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13.0, color: tokens.contentTertiary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _extendBtn(BuildContext context, Goal goal, DateTime currentDeadline, int days, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final newDate = currentDeadline.add(Duration(days: days));
          context.read<GoalsBloc>().add(ExtendDeadlineEvent(
            goalId: goal.id,
            newDeadline: AppDateUtils.toLocalYYYYMMDD(newDate),
          ));
          setState(() => _extendingGoal = null);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Center(
            child: Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.0)),
          ),
        ),
      ),
    );
  }

  // --- Delete Confirm Overlay ---
  Widget _buildDeleteConfirmOverlay(ThemeData theme, BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final goal = _deletingGoal!;
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380.0),
          margin: const EdgeInsets.all(24.0),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: tokens.surfaceModal,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24.0, offset: Offset(0, 12))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52.0,
                height: 52.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 26.0),
              ),
              const SizedBox(height: 16.0),
              Text('Delete Goal System?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18.0, color: tokens.contentSecondary)),
              const SizedBox(height: 8.0),
              Text(
                'This will permanently delete "${goal.title}" and all its linked habits. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: tokens.contentTertiary, fontSize: 13.0),
              ),
              const SizedBox(height: 24.0),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _deletingGoal = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: tokens.borderDefault),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Center(child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.0, color: tokens.contentTertiary))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.read<GoalsBloc>().add(DeleteGoalEvent(goal.id));
                        setState(() => _deletingGoal = null);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Center(child: Text('Delete', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.0, color: Colors.white))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Log Time Overlay ---
  Widget _buildLogTimeOverlay(ThemeData theme, BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final habit = _loggingHabit!;
    // BUG FIX: selectedMinutes moved inside StatefulBuilder so parent rebuilds don't reset it
    final List<int> options = [5, 10, 15, 20, 30, 45, 60, 90];

    return StatefulBuilder(builder: (ctx, setOverlayState) {
      int selectedMinutes = 15; // local to StatefulBuilder — survives parent rebuilds
      return Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380.0),
            margin: const EdgeInsets.all(24.0),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: tokens.surfaceModal,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24.0, offset: Offset(0, 12))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Log Time', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18.0, color: tokens.contentSecondary)),
                    GestureDetector(
                      onTap: () => setState(() => _loggingHabit = null),
                      child: Icon(Icons.close, color: tokens.iconSubtle),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  habit.title,
                  style: GoogleFonts.plusJakartaSans(color: tokens.contentTertiary, fontSize: 13.0),
                ),
                const SizedBox(height: 20.0),
                Text('MINUTES', style: GoogleFonts.plusJakartaSans(color: tokens.iconSubtle, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                const SizedBox(height: 10.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: options.map((mins) {
                    final isSelected = selectedMinutes == mins;
                    return GestureDetector(
                      onTap: () => setOverlayState(() => selectedMinutes = mins),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : tokens.surfaceChip,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                        ),
                        child: Text(
                          '$mins min',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.0,
                            color: isSelected ? Colors.white : tokens.contentSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24.0),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _loggingHabit = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: tokens.borderDefault),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.0, color: tokens.contentTertiary))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.read<HabitsBloc>().add(LogHabitTimeEvent(habitId: habit.id, minutes: selectedMinutes));
                          setState(() {
                            _loggingHabit = null;
                            _loggingHabitGoalId = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Center(child: Text('Log $selectedMinutes min', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.0, color: Colors.white))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // --- Edit Goal Overlay (basic: pre-fills form & closes overlay) ---
  Widget _buildEditGoalOverlay(ThemeData theme, BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final goal = _editingGoal!;
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380.0),
          margin: const EdgeInsets.all(24.0),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: tokens.surfaceModal,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24.0, offset: Offset(0, 12))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined, size: 36.0, color: AppColors.primary),
              const SizedBox(height: 12.0),
              Text('Edit Goal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18.0, color: tokens.contentSecondary)),
              const SizedBox(height: 6.0),
              Text('"${goal.title}"', style: GoogleFonts.plusJakartaSans(color: tokens.contentTertiary, fontSize: 13.0)),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _editingGoal = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        decoration: BoxDecoration(border: Border.all(color: tokens.borderDefault), borderRadius: BorderRadius.circular(12.0)),
                        child: Center(child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.0, color: tokens.contentTertiary))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final habitsMap = _latestState?.habitsByGoalId ?? {};
                        final goalHabits = habitsMap[goal.id] ?? [];
                        _openEditGoalModal(goal, goalHabits);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12.0)),
                        child: Center(child: Text('Open Editor', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14.0, color: Colors.white))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Goal System Builder Modal ---
  Widget _buildGoalFormModal(ThemeData theme, BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final maxHeight = mediaQuery.size.height * (isMobile ? 0.92 : 0.85);
    final maxWidth = isMobile ? mediaQuery.size.width - 32.0 : 780.0;

    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 24.0, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. FIXED HEADER (Pinned Top)
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38.0,
                      height: 38.0,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(Icons.track_changes, color: AppColors.primary, size: 20.0),
                    ),
                    const SizedBox(width: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goals System Builder',
                          style: AppTypography.displayFont(
                            fontWeight: FontWeight.w800,
                            fontSize: 20.0,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Define target goals and linked daily habits',
                          style: AppTypography.bodyFont(
                            fontSize: 12.0,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isFormExpanded = false;
                      _editingGoal = null; // BUG FIX: clear editing state so next "create" doesn't overwrite
                    });
                  },
                  icon: const Icon(Icons.close, size: 18.0),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1.0, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),

          // 2. SCROLLABLE FORM BODY
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Goal Name & Goal Description
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLabel('GOAL NAME'),
                                InkWell(
                                  onTap: () async {
                                    final picked = await FlaticonPickerDialog.show(context, _selectedFlaticonKey);
                                    if (picked != null) {
                                      setState(() {
                                        _selectedFlaticonKey = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Row(
                                      children: [
                                        FlaticonIcon(iconKey: _selectedFlaticonKey, size: 14.0, color: AppColors.primary),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          'ICON',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6.0),
                            _buildInputField(_nameController, 'Goal Name', false),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('GOAL DESCRIPTION'),
                            const SizedBox(height: 6.0),
                            _buildInputField(_purposeController, 'What is the deeper purpose behind this goal?', true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Row 2: Category (Required) & Execution Order (Required)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('CATEGORY (REQUIRED)'),
                            const SizedBox(height: 6.0),
                            _buildInputField(_categoryController, 'e.g. Learning, Health, Career', false),
                            const SizedBox(height: 8.0),
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: ['LEARNING', 'HEALTH', 'CAREER', 'FINANCE', 'PERSONAL', 'GENERAL'].map((cat) {
                                final isSelected = _categoryController.text.trim().toUpperCase() == cat;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _categoryController.text = cat;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: isSelected ? AppColors.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      cat,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('EXECUTION ORDER (REQUIRED)'),
                            const SizedBox(height: 6.0),
                            _buildInputField(_orderController, '1 = Highest Priority', false, isNumber: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Row 3: Target Date (Optional) & Focus Goal Checkbox
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('TARGET DATE (OPTIONAL)'),
                            const SizedBox(height: 6.0),
                            _buildDateField(_dateController, 'dd-mm-yyyy'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(top: 14.0),
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _isFocusGoal,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() {
                                    _isFocusGoal = val ?? false;
                                  });
                                },
                              ),
                              Text(
                                'Set as Focus Goal',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Row 5: Strategy Logic Segment Switcher
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('STRATEGY LOGIC'),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Expanded(child: _buildStrategyBtn('Complete All', 'ALL')),
                          const SizedBox(width: 8.0),
                          Expanded(child: _buildStrategyBtn('Any One', 'ANY')),
                          const SizedBox(width: 8.0),
                          Expanded(child: _buildStrategyBtn('Custom', 'CUSTOM')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // Row 6: Daily Systems & Habits Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('DAILY SYSTEMS & HABITS'),
                      TextButton(
                        onPressed: _addHabitBox,
                        child: Text(
                          '+ Add Habit',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),

                  // Habit Card Box
                  ..._stagedHabits.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final habit = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: habit.controller,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Habit Title',
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18.0, color: Color(0xFF8C97AB)),
                                onPressed: () {
                                  setState(() {
                                    habit.controller.dispose();
                                    _stagedHabits.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: habit.type,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 'time', child: Text('Time-Based')),
                                        DropdownMenuItem(value: 'count', child: Text('Count-Based')),
                                        DropdownMenuItem(value: 'check', child: Text('Checkmark')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            habit.type = val;
                                            if (val == 'time') {
                                              habit.targetValueController.text = habit.targetTime.toString();
                                            } else if (val == 'count') {
                                              habit.targetValueController.text = habit.targetCount.toString();
                                            }
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              if (habit.type == 'time' || habit.type == 'count')
                                Container(
                                  width: 120.0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                  ),
                                  child: TextField(
                                    controller: habit.targetValueController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      final parsed = int.tryParse(val.trim());
                                      if (parsed != null && parsed > 0) {
                                        if (habit.type == 'time') {
                                          habit.targetTime = parsed;
                                        } else {
                                          habit.targetCount = parsed;
                                        }
                                      }
                                    },
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12.0, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      suffixText: habit.type == 'time' ? 'MINS' : 'TIMES',
                                      suffixStyle: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          Text(
                            'SCHEDULE',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF8C97AB),
                              fontWeight: FontWeight.w800,
                              fontSize: 8.5,
                            ),
                          ),
                          const SizedBox(height: 6.0),

                          // Day Toggle Pills
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                              final active = habit.scheduleDays.contains(day);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (active) {
                                      habit.scheduleDays.remove(day);
                                    } else {
                                      habit.scheduleDays.add(day);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                  decoration: BoxDecoration(
                                    color: active ? AppColors.primary : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(color: active ? AppColors.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    day,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: active ? Colors.white : theme.colorScheme.onSurface,
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 3. FIXED FOOTER (Pinned Bottom Buttons)
          Divider(height: 1.0, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isFormExpanded = false;
                      _editingGoal = null; // BUG FIX: clear editing state so next "create" doesn't overwrite
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                ElevatedButton(
                  onPressed: () => _forgeGoalSystem(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Forge Goal System',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF8C97AB),
        fontWeight: FontWeight.w800,
        fontSize: 8.5,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText, bool isMultiLine, {bool isNumber = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2235);
    final fillColor = isDark ? const Color(0xFF1E2235) : const Color(0xFFF0F3F8);
    final hintColor = isDark ? Colors.white38 : const Color(0xFF8C97AB);
    return TextField(
      controller: controller,
      maxLines: isMultiLine ? 3 : 1,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(color: hintColor, fontSize: 13.0),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String hintText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E2235);
    final fillColor = isDark ? const Color(0xFF1E2235) : const Color(0xFFF0F3F8);
    final hintColor = isDark ? Colors.white38 : const Color(0xFF8C97AB);
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          controller.text = AppDateUtils.toLocalYYYYMMDD(picked);
        }
      },
      style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(color: hintColor, fontSize: 13.0),
        suffixIcon: Icon(Icons.calendar_today_outlined, size: 18.0, color: hintColor),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStrategyBtn(String label, String modeCode) {
    final isActive = _selectedMode == modeCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final textColor = isDark
        ? (isActive ? AppColors.primary : Colors.white70)
        : (isActive ? AppColors.primary : const Color(0xFF1E2235));
    final borderColor = isActive
        ? AppColors.primary
        : (isDark ? Colors.white24 : const Color(0xFFE5E9F2));
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = modeCode;
        });
      },
      child: Container(
        height: 44.0,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: borderColor,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 12.0,
            ),
          ),
        ),
      ),
    );
  }

  void _addHabitBox() {
    setState(() {
      _stagedHabits.add(
        _StagedHabit(
          title: 'Habit #${_stagedHabits.length + 1}',
          type: 'time',
          targetTime: 15,
          targetCount: 1,
          scheduleDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        ),
      );
    });
  }


  void _openEditGoalModal(Goal goal, List<Habit> habits) {
    _nameController.text = goal.title;
    _purposeController.text = goal.description ?? '';
    _categoryController.text = goal.tag ?? 'GENERAL';
    _orderController.text = goal.order.toString();
    _dateController.text = goal.deadline ?? '';
    _selectedMode = goal.mode;
    _isFocusGoal = goal.isFocusGoal;
    _editingGoal = goal; // keep reference so _forgeGoalSystem knows this is an edit

    _stagedHabits.clear();
    if (habits.isEmpty) {
      _stagedHabits.add(_StagedHabit(
        title: 'Daily Habit',
        type: 'time',
        targetTime: 30,
        targetCount: 1,
        scheduleDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      ));
    } else {
      for (var habit in habits) {
        _stagedHabits.add(_StagedHabit(
          id: habit.id,
          title: habit.title,
          type: habit.type,
          targetTime: habit.targetTime,
          targetCount: habit.targetCount,
          scheduleDays: List<String>.from(habit.scheduleDays),
        ));
      }
    }

    setState(() {
      _isFormExpanded = true;
    });
  }

  void _forgeGoalSystem(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a goal name.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final orderText = _orderController.text.trim();
    final order = int.tryParse(orderText) ?? 1;

    // Validation: Check duplicate execution order among active goals
    final existingGoals = _latestState?.goals ?? [];
    final isDuplicateOrder = existingGoals.any((g) {
      if (_editingGoal != null && g.id == _editingGoal!.id) return false;
      return g.order == order && !g.isMissingDream;
    });

    if (isDuplicateOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Execution Order $order is already assigned to another active goal. Please choose a unique order.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final isEditing = _editingGoal != null;
    final goalId = isEditing ? _editingGoal!.id : UuidGenerator.generate();
    final nowStr = DateTime.now().toIso8601String();

    final category = _categoryController.text.trim().isEmpty ? 'GENERAL' : _categoryController.text.trim().toUpperCase();

    final newOrUpdatedGoal = Goal(
      id: goalId,
      title: name,
      description: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
      mode: _selectedMode,
      tag: category,
      deadline: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
      isFocusGoal: _isFocusGoal,
      isMissingDream: isEditing ? _editingGoal!.isMissingDream : false,
      progress: isEditing ? _editingGoal!.progress : 0.0,
      streak: isEditing ? _editingGoal!.streak : 0,
      bestStreak: isEditing ? _editingGoal!.bestStreak : 0,
      missedDays: isEditing ? _editingGoal!.missedDays : 0,
      completedDates: isEditing ? _editingGoal!.completedDates : const [],
      dependencies: isEditing ? _editingGoal!.dependencies : const [],
      order: order,
      createdAt: isEditing ? _editingGoal!.createdAt : nowStr,
    );

    final existingHabitsMap = <String, Habit>{};
    if (isEditing) {
      final habitsForGoal = _latestState?.habitsByGoalId[goalId] ?? [];
      for (var h in habitsForGoal) {
        existingHabitsMap[h.id] = h;
      }
    }

    final habits = _stagedHabits.map((staged) {
      final habitId = staged.id ?? UuidGenerator.generate();
      final existingHabit = existingHabitsMap[habitId];

      final targetVal = staged.parsedTargetValue;

      return Habit(
        id: habitId,
        goalId: goalId,
        title: staged.title.isEmpty ? 'Daily Habit' : staged.title,
        type: staged.type,
        targetTime: staged.type == 'time' ? targetVal : staged.targetTime,
        targetCount: staged.type == 'count' ? targetVal : staged.targetCount,
        scheduleDays: List<String>.from(staged.scheduleDays),
        reminderEnabled: false,
        completedDates: existingHabit?.completedDates ?? const [],
        timeSpent: existingHabit?.timeSpent ?? 0,
        currentCount: existingHabit?.currentCount ?? 0,
        streak: existingHabit?.streak ?? 0,
        createdAt: existingHabit?.createdAt ?? nowStr,
      );
    }).toList();

    context.read<GoalsBloc>().add(CreateGoalEvent(goal: newOrUpdatedGoal, habits: habits));

    _resetForm();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? 'Goal system updated successfully!' : 'Goal system forged successfully!'),
      ),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _purposeController.clear();
    _dateController.clear();
    _categoryController.text = 'GENERAL';
    _orderController.text = '1';
    for (var h in _stagedHabits) {
      h.controller.dispose();
      h.targetValueController.dispose();
    }
    _stagedHabits.clear();
    _stagedHabits.add(_StagedHabit(
      title: 'Daily Habit',
      type: 'time',
      targetTime: 30,
      targetCount: 1,
      scheduleDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    ));
    setState(() {
      _isFormExpanded = false;
      _isFocusGoal = false;
      _editingGoal = null;
      _selectedMode = 'ANY'; // BUG FIX: match initial default mode
    });
  }
}

class _StagedHabit {
  final String? id;
  final TextEditingController controller;
  final TextEditingController targetValueController;
  String type;
  int targetTime;
  int targetCount;
  List<String> scheduleDays;

  _StagedHabit({
    this.id,
    required String title,
    required this.type,
    required this.targetTime,
    required this.targetCount,
    required this.scheduleDays,
  })  : controller = TextEditingController(text: title),
        targetValueController = TextEditingController(
          text: (type == 'time' ? targetTime : (type == 'count' ? targetCount : 1)).toString(),
        );

  String get title => controller.text.trim();

  int get parsedTargetValue {
    final val = int.tryParse(targetValueController.text.trim());
    return (val != null && val > 0) ? val : (type == 'time' ? 30 : 1);
  }
}
