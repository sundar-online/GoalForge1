import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/domain/models/habit.dart';
import '../../../../core/theme/app_colors.dart';
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
  bool _isFocusGoal = false;
  String _selectedMode = 'ANY'; // 'ALL', 'ANY', 'CUSTOM'

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
          body: Stack(
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
                          const SizedBox(height: 28.0),

                          // 3. Main Goals Canvas
                          _buildMainCanvas(theme, context),
                          const SizedBox(height: 32.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Overlay Modal for Goal System Builder
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
  Widget _buildHeader(ThemeData theme) {
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
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(Icons.track_changes, color: AppColors.primary, size: 22.0),
            ),
            const SizedBox(width: 14.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goals System',
                  style: AppTypography.displayFont(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2235),
                    fontSize: 24.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Build daily systems to drive long-term progress.',
                  style: AppTypography.bodyFont(
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7A8499),
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Plus Action Button
        GestureDetector(
          onTap: () {
            setState(() {
              _isFormExpanded = true;
            });
          },
          child: Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFE5E9F2)),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8.0, offset: Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.add, color: Color(0xFF1E2235), size: 22.0),
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
    final missingCount = 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E2E),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16.0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCol('$avgMastery%', 'AVG MASTERY', AppColors.primary),
          _buildSummaryCol('$finished', 'FINISHED', const Color(0xFF00D9A5)),
          _buildSummaryCol('$inProgress', 'IN PROGRESS', Colors.white),
          _buildSummaryCol('$missingCount', 'MISSING DREAMS', const Color(0xFFBF5AF2)),
        ],
      ),
    );
  }

  Widget _buildSummaryCol(String val, String label, Color valColor) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22.0,
            fontWeight: FontWeight.w800,
            color: valColor,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
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
                  color: const Color(0xFF8C97AB),
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

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((crossAxisCount - 1) * 20.0)) / crossAxisCount;

        return Wrap(
          spacing: 20.0,
          runSpacing: 20.0,
          children: goals.map((goal) {
            final habits = habitsMap[goal.id] ?? [];
            return SizedBox(
              width: itemWidth,
              child: _buildGoalCard(
                theme: theme,
                context: context,
                goal: goal,
                habits: habits,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- Goal Card Item (Matching Image 2 Reference) ---
  Widget _buildGoalCard({
    required ThemeData theme,
    required BuildContext context,
    required Goal goal,
    required List<Habit> habits,
  }) {
    final tag = goal.tag ?? 'LEARNING';
    final progressRatio = (goal.progress / 100.0).clamp(0.0, 1.0);
    final isExpanded = _expandedGoalIds.contains(goal.id);
    final todayStr = AppDateUtils.getTodayString();

    final isLearning = tag.toUpperCase() == 'LEARNING';
    final badgeBgColor = isLearning ? const Color(0xFFFFF3E0) : const Color(0xFFEEF2FF);
    final badgeTextColor = isLearning ? const Color(0xFFFF9500) : AppColors.primary;

    final completedHabitsCount = habits.where((h) => h.completed || h.completedDates.contains(todayStr)).length;

    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Tag Pill & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  tag.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: badgeTextColor,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.star,
                      color: goal.isFocusGoal ? Colors.amber : const Color(0xFF94A3B8),
                      size: 18.0,
                    ),
                    onPressed: () {
                      context.read<GoalsBloc>().add(ToggleFocusGoalEvent(goal.id));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.nightlight_round_outlined, color: Color(0xFF94A3B8), size: 18.0),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8), size: 18.0),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFF94A3B8), size: 18.0),
                    onPressed: () {
                      context.read<GoalsBloc>().add(DeleteGoalEvent(goal.id));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF94A3B8),
                      size: 20.0,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedGoalIds.remove(goal.id);
                        } else {
                          _expandedGoalIds.add(goal.id);
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Middle Row: Circular Mastery Progress Ring & Title
          Row(
            children: [
              SizedBox(
                width: 64.0,
                height: 64.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64.0,
                      height: 64.0,
                      child: CircularProgressIndicator(
                        value: progressRatio,
                        strokeWidth: 6.0,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${goal.progress.toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'MASTERY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF64748B),
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
                      style: AppTypography.displayFont(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 3.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),

          // Bottom Meta Chips Row (Calendar Date, Flame Streak, Habits Ratio)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetaPill(Icons.calendar_month_rounded, goal.deadline ?? '31 Dec 2026', const Color(0xFF3B82F6)),
              _buildMetaPill(Icons.local_fire_department_rounded, '${goal.streak}/${goal.bestStreak > 0 ? goal.bestStreak : 213}', const Color(0xFFFF5722)),
              _buildMetaPill(Icons.assignment_outlined, '$completedHabitsCount/${habits.length}', const Color(0xFFF59E0B)),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 16.0),
            const Divider(color: Color(0xFFE5E9F2)),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LINKED HABITS SYSTEM (${habits.length})',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 9.0,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddHabitDialog(context, goal.id),
                  icon: const Icon(Icons.add, size: 14.0, color: AppColors.primary),
                  label: Text(
                    'Add Habit',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            if (habits.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFCFF),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFFE5E9F2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'No habits linked to this goal yet.',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF8C97AB),
                        fontSize: 12.0,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddHabitDialog(context, goal.id),
                      icon: const Icon(Icons.add, size: 14.0),
                      label: const Text('Add Habit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...habits.map((habit) {
                final isCompletedToday = habit.completedDates.contains(todayStr) || habit.completed;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: InkWell(
                    onTap: () {
                      context.read<HabitsBloc>().add(ToggleHabitCompletionEvent(
                            habitId: habit.id,
                            dateStr: todayStr,
                          ));
                    },
                    borderRadius: BorderRadius.circular(10.0),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: isCompletedToday ? const Color(0xFFE6FBF5) : const Color(0xFFFAFCFF),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: isCompletedToday ? const Color(0xFF00D9A5) : const Color(0xFFE5E9F2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCompletedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isCompletedToday ? const Color(0xFF00D9A5) : const Color(0xFF8C97AB),
                            size: 20.0,
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
                                    color: const Color(0xFF1E2235),
                                    decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                Text(
                                  'Schedule: ${habit.scheduleDays.join(', ')}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF8C97AB),
                                    fontSize: 10.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16.0, color: Color(0xFFCBD5E1)),
                            onPressed: () {
                              context.read<HabitsBloc>().add(DeleteHabitEvent(
                                    goalId: goal.id,
                                    habitId: habit.id,
                                  ));
                            },
                          ),
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: isCompletedToday ? const Color(0xFF00D9A5) : AppColors.primary,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              isCompletedToday ? 'DONE (+50 XP)' : 'MARK DONE',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 9.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String val, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.0, color: iconColor),
        const SizedBox(width: 5.0),
        Text(
          val,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
                    });
                  },
                  icon: const Icon(Icons.close, size: 18.0),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
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

                  // Row 2: Target Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('TARGET DATE (OPTIONAL)'),
                      const SizedBox(height: 6.0),
                      _buildDateField(_dateController, 'dd-mm-yyyy'),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Advanced Settings Toggle
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showAdvancedSettings = !_showAdvancedSettings;
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.settings_outlined, size: 14.0, color: AppColors.primary),
                        const SizedBox(width: 6.0),
                        Text(
                          'Advanced Settings',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  if (_showAdvancedSettings) ...[
                    // Row 3: Category & Execution Order
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CATEGORY'),
                              const SizedBox(height: 6.0),
                              _buildInputField(_categoryController, 'General', false),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('EXECUTION ORDER'),
                              const SizedBox(height: 6.0),
                              _buildInputField(_orderController, '1', false, isNumber: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Checkbox: Set as Focus Goal
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12.0),
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
                    const SizedBox(height: 16.0),

                  ],

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
                        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
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
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              if (habit.type == 'time')
                                Container(
                                  width: 100.0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: habit.targetTime,
                                      items: const [
                                        DropdownMenuItem(value: 15, child: Text('15 MINS')),
                                        DropdownMenuItem(value: 30, child: Text('30 MINS')),
                                        DropdownMenuItem(value: 45, child: Text('45 MINS')),
                                        DropdownMenuItem(value: 60, child: Text('60 MINS')),
                                        DropdownMenuItem(value: 90, child: Text('90 MINS')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            habit.targetTime = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              if (habit.type == 'count')
                                Container(
                                  width: 100.0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: habit.targetCount,
                                      items: const [
                                        DropdownMenuItem(value: 1, child: Text('1 TIME')),
                                        DropdownMenuItem(value: 2, child: Text('2 TIMES')),
                                        DropdownMenuItem(value: 3, child: Text('3 TIMES')),
                                        DropdownMenuItem(value: 5, child: Text('5 TIMES')),
                                        DropdownMenuItem(value: 10, child: Text('10 TIMES')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            habit.targetCount = val;
                                          });
                                        }
                                      },
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
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12.0, color: Color(0xFF8C97AB)),
                              const SizedBox(width: 4.0),
                              Text(
                                'Active every day',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF8C97AB),
                                  fontSize: 10.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),

                          // Daily Reminder Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.alarm_outlined, size: 14.0, color: Color(0xFF8C97AB)),
                                const SizedBox(width: 8.0),
                                Text(
                                  'DAILY REMINDER',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF8C97AB),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9.0,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
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
    return TextField(
      controller: controller,
      maxLines: isMultiLine ? 3 : 1,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: const Color(0xFF1E2235)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF8C97AB), fontSize: 13.0),
        filled: true,
        fillColor: const Color(0xFFF0F3F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String hintText) {
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
      style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: const Color(0xFF1E2235)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF8C97AB), fontSize: 13.0),
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18.0, color: Color(0xFF8C97AB)),
        filled: true,
        fillColor: const Color(0xFFF0F3F8),
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = modeCode;
        });
      },
      child: Container(
        height: 44.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFFE5E9F2),
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isActive ? AppColors.primary : const Color(0xFF1E2235),
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

  void _showAddHabitDialog(BuildContext context, String goalId) {
    final titleController = TextEditingController();
    String selectedType = 'time';
    int targetTime = 15;
    int targetCount = 1;
    List<String> scheduleDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Add Linked Habit',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.0,
                ),
              ),
              content: SizedBox(
                width: 440.0,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('HABIT TITLE'),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: titleController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.0),
                        decoration: InputDecoration(
                          hintText: 'e.g. Daily Practice',
                          filled: true,
                          fillColor: const Color(0xFFF0F3F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedType,
                              decoration: const InputDecoration(labelText: 'Type'),
                              items: const [
                                DropdownMenuItem(value: 'time', child: Text('Time-Based')),
                                DropdownMenuItem(value: 'count', child: Text('Count-Based')),
                                DropdownMenuItem(value: 'check', child: Text('Checkmark')),
                              ],
                              onChanged: (val) {
                                if (val != null) setDialogState(() => selectedType = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          if (selectedType == 'time')
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: targetTime,
                                decoration: const InputDecoration(labelText: 'Duration'),
                                items: const [
                                  DropdownMenuItem(value: 15, child: Text('15 MINS')),
                                  DropdownMenuItem(value: 30, child: Text('30 MINS')),
                                  DropdownMenuItem(value: 45, child: Text('45 MINS')),
                                  DropdownMenuItem(value: 60, child: Text('60 MINS')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => targetTime = val);
                                },
                              ),
                            ),
                          if (selectedType == 'count')
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: targetCount,
                                decoration: const InputDecoration(labelText: 'Count'),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('1 TIME')),
                                  DropdownMenuItem(value: 2, child: Text('2 TIMES')),
                                  DropdownMenuItem(value: 3, child: Text('3 TIMES')),
                                  DropdownMenuItem(value: 5, child: Text('5 TIMES')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => targetCount = val);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;
                    final newHabit = Habit(
                      id: UuidGenerator.generate(),
                      goalId: goalId,
                      title: title,
                      type: selectedType,
                      targetTime: targetTime,
                      targetCount: targetCount,
                      scheduleDays: scheduleDays,
                      reminderEnabled: false,
                      completedDates: const [],
                      createdAt: DateTime.now().toIso8601String(),
                    );
                    context.read<HabitsBloc>().add(CreateStandAloneHabitEvent(newHabit));
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Habit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _forgeGoalSystem(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal name.')),
      );
      return;
    }

    final goalId = UuidGenerator.generate();
    final nowStr = DateTime.now().toIso8601String();

    final newGoal = Goal(
      id: goalId,
      title: name,
      description: _purposeController.text.trim(),
      mode: _selectedMode,
      tag: _categoryController.text.trim().isEmpty ? 'GENERAL' : _categoryController.text.trim().toUpperCase(),
      deadline: _dateController.text.trim().isEmpty ? null : _dateController.text.trim(),
      isFocusGoal: _isFocusGoal,
      order: int.tryParse(_orderController.text.trim()) ?? 1,
      completedDates: const [],
      dependencies: const [],
      createdAt: nowStr,
    );

    final habits = _stagedHabits.map((staged) {
      return Habit(
        id: UuidGenerator.generate(),
        goalId: goalId,
        title: staged.title.isEmpty ? 'Daily Habit' : staged.title,
        type: staged.type,
        targetTime: staged.targetTime,
        targetCount: staged.targetCount,
        scheduleDays: List<String>.from(staged.scheduleDays),
        reminderEnabled: false,
        completedDates: const [],
        createdAt: nowStr,
      );
    }).toList();

    context.read<GoalsBloc>().add(CreateGoalEvent(goal: newGoal, habits: habits));

    _nameController.clear();
    _purposeController.clear();
    _dateController.clear();
    setState(() {
      _isFormExpanded = false;
      _isFocusGoal = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal system forged successfully!')),
    );
  }
}

class _StagedHabit {
  final TextEditingController controller;
  String type;
  int targetTime;
  int targetCount;
  List<String> scheduleDays;

  _StagedHabit({
    required String title,
    required this.type,
    required this.targetTime,
    required this.targetCount,
    required this.scheduleDays,
  }) : controller = TextEditingController(text: title);

  String get title => controller.text.trim();
}
