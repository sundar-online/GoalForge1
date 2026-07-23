import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/habit.dart';
import '../../../../core/domain/models/task.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../habits/presentation/bloc/habits_bloc.dart';
import '../../../habits/presentation/bloc/habits_event.dart';
import '../../../habits/presentation/bloc/habits_state.dart';
import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';
import '../bloc/tasks_state.dart';

class TodayForgePage extends StatefulWidget {
  const TodayForgePage({super.key});

  @override
  State<TodayForgePage> createState() => _TodayForgePageState();
}

class _TodayForgePageState extends State<TodayForgePage> {
  bool _isAddingTask = false;
  bool _reminderEnabled = false;
  String _selectedSchedule = 'Daily';
  String _selectedTracking = 'Check';
  String _selectedPriority = 'Medium';

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  HabitsLoaded? _latestHabitsState;
  TasksLoaded? _latestTasksState;

  @override
  void dispose() {
    _taskController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<HabitsBloc, HabitsState>(
            builder: (context, habitsState) {
              if (habitsState is HabitsLoaded) {
                _latestHabitsState = habitsState;
              }
              return BlocBuilder<TasksBloc, TasksState>(
                builder: (context, tasksState) {
                  if (tasksState is TasksLoaded) {
                    _latestTasksState = tasksState;
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
                                // Header Row
                                _buildHeader(theme),
                                const SizedBox(height: 20.0),

                                // Stats Bento Row
                                _buildStatsBentoRow(theme),
                                const SizedBox(height: 20.0),

                                // Task Creation Form Card (Conditional / Toggleable)
                                if (_isAddingTask) ...[
                                  _buildTaskCreationCard(theme, context),
                                  const SizedBox(height: 20.0),
                                ],

                                // Search Bar
                                _buildSearchBar(theme, context),
                                const SizedBox(height: 20.0),

                                // Combined Habits & Tasks List
                                _buildCombinedList(theme, context),
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
            },
          );
  }

  // --- Header ---
  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
                size: 22.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Forge",
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                    fontSize: 24.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Daily operations and scheduled tasks.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.outline,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isAddingTask = !_isAddingTask;
            });
          },
          child: _isAddingTask
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.close, color: Color(0xFFBA1A1A), size: 16.0),
                      SizedBox(width: 4.0),
                      Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: AppColors.inverseSurface,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16.0),
                      SizedBox(width: 6.0),
                      Text(
                        'Add Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // --- Stats Bento Row ---
  Widget _buildStatsBentoRow(ThemeData theme) {
    final habitsTotal = _latestHabitsState?.totalTodayCount ?? 0;
    final habitsDone = _latestHabitsState?.completedTodayCount ?? 0;

    final tasksTotal = _latestTasksState?.totalCount ?? 0;
    final tasksDone = _latestTasksState?.completedCount ?? 0;

    final total = habitsTotal + tasksTotal;
    final done = habitsDone + tasksDone;
    final focus = total > 0 ? ((done / total) * 100.0).toInt() : 100;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20.0,
            offset: const Offset(0, 8.0),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '$total',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 26.0,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'TOTAL',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.outline,
                    fontSize: 10.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1.0,
            height: 36.0,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$done',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 26.0,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'DONE',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.outline,
                    fontSize: 10.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1.0,
            height: 36.0,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$focus%',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppColors.tertiary,
                    fontWeight: FontWeight.w800,
                    fontSize: 26.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'FOCUS',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.outline,
                    fontSize: 10.0,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Task Creation Form Card ---
  Widget _buildTaskCreationCard(ThemeData theme, BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title Input
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'What are we accomplishing?',
                hintStyle: TextStyle(
                  color: AppColors.outline.withValues(alpha: 0.6),
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Schedule, Priority & Tracking Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCHEDULE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSchedule,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'Standalone', child: Text('Standalone Task')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSchedule = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRIORITY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.outline,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPriority,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'High', child: Text('High')),
                            DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'Low', child: Text('Low')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPriority = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Reminder Alarm Switch Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
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
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.access_time_filled,
                        color: AppColors.primary,
                        size: 18.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REMINDER ALARM',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.outline,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            fontSize: 8.5,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Notify me at specific time',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _reminderEnabled,
                  onChanged: (val) {
                    setState(() {
                      _reminderEnabled = val;
                    });
                  },
                  activeTrackColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Create Task Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _createTaskOrHabit(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 4.0,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: const Text(
                'Create Task',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createTaskOrHabit(BuildContext context) {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    final nowStr = DateTime.now().toIso8601String();

    if (_selectedSchedule == 'Standalone') {
      final task = Task(
        id: UuidGenerator.generate(),
        title: title,
        type: 'single',
        targetDate: AppDateUtils.getTodayString(),
        priority: _selectedPriority,
        completedDates: const [],
        createdAt: nowStr,
      );
      context.read<TasksBloc>().add(CreateTaskEvent(task));
    } else {
      final habit = Habit(
        id: UuidGenerator.generate(),
        goalId: '',
        title: title,
        type: _selectedTracking.toLowerCase(),
        targetTime: 15,
        targetCount: 1,
        scheduleDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        reminderEnabled: _reminderEnabled,
        completedDates: const [],
        createdAt: nowStr,
      );
      context.read<HabitsBloc>().add(CreateStandAloneHabitEvent(habit));
    }

    _taskController.clear();
    setState(() {
      _isAddingTask = false;
    });
  }

  // --- Search Bar ---
  Widget _buildSearchBar(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10.0,
            offset: const Offset(0, 4.0),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.outline, size: 20.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<HabitsBloc>().add(SearchHabitsEvent(query));
                context.read<TasksBloc>().add(FilterTasksEvent(query: query));
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search tasks instantly...',
                hintStyle: TextStyle(
                  color: AppColors.outline.withValues(alpha: 0.6),
                  fontSize: 14.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Combined Habits & Standalone Tasks List ---
  Widget _buildCombinedList(ThemeData theme, BuildContext context) {
    final habits = _latestHabitsState?.habitsToday ?? [];
    final tasks = _latestTasksState?.tasks ?? [];
    final todayStr = AppDateUtils.getTodayString();

    if (habits.isEmpty && tasks.isEmpty) {
      return CustomCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 48.0, color: AppColors.outlineVariant),
                const SizedBox(height: 12.0),
                Text(
                  'No Tasks Scheduled Today',
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Tap "Add Task" above to add daily operations and habits.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...habits.map((habit) {
          final isCompleted = habit.completedDates.contains(todayStr);
          return Column(
            children: [
              _buildHabitCard(theme, context, habit, isCompleted, todayStr),
              const SizedBox(height: 12.0),
            ],
          );
        }),
        ...tasks.map((task) {
          final isCompleted = task.completedDates.contains(todayStr);
          return Column(
            children: [
              _buildTaskCard(theme, context, task, isCompleted, todayStr),
              const SizedBox(height: 12.0),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHabitCard(
    ThemeData theme,
    BuildContext context,
    Habit habit,
    bool isCompleted,
    String todayStr,
  ) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F9F3),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFD1F2E8), width: 1.0),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                context.read<HabitsBloc>().add(ToggleHabitCompletionEvent(
                      habitId: habit.id,
                      dateStr: todayStr,
                    ));
              },
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D9A5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20.0),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.schedule, size: 10.0, color: AppColors.primary),
                            SizedBox(width: 4.0),
                            Text(
                              'DAILY',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 9.0)),
                            const SizedBox(width: 2.0),
                            Text(
                              '${habit.streak}d',
                              style: const TextStyle(
                                color: Color(0xFFB25E09),
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    habit.title,
                    style: const TextStyle(
                      color: Color(0xFF00694E),
                      fontWeight: FontWeight.w800,
                      fontSize: 15.0,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Color(0xFF00694E),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  const Text(
                    'COMPLETED (+50 XP)',
                    style: TextStyle(
                      color: Color(0xFF008564),
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.outline, size: 20.0),
              onPressed: () {
                context.read<HabitsBloc>().add(DeleteHabitEvent(goalId: habit.goalId, habitId: habit.id));
              },
            ),
          ],
        ),
      );
    }

    return CustomCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.read<HabitsBloc>().add(ToggleHabitCompletionEvent(
                    habitId: habit.id,
                    dateStr: todayStr,
                  ));
            },
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant, width: 2.0),
              ),
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        habit.type.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  habit.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.outlineVariant, size: 20.0),
            onPressed: () {
              context.read<HabitsBloc>().add(DeleteHabitEvent(goalId: habit.goalId, habitId: habit.id));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    ThemeData theme,
    BuildContext context,
    Task task,
    bool isCompleted,
    String todayStr,
  ) {
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F9F3),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFD1F2E8), width: 1.0),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                context.read<TasksBloc>().add(ToggleTaskCompletionEvent(
                      taskId: task.id,
                      dateStr: todayStr,
                    ));
              },
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D9A5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20.0),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Color(0xFF00694E),
                      fontWeight: FontWeight.w800,
                      fontSize: 15.0,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Color(0xFF00694E),
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  const Text(
                    'COMPLETED (+10 XP)',
                    style: TextStyle(
                      color: Color(0xFF008564),
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.outline, size: 20.0),
              onPressed: () {
                context.read<TasksBloc>().add(DeleteTaskEvent(task.id));
              },
            ),
          ],
        ),
      );
    }

    return CustomCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              context.read<TasksBloc>().add(ToggleTaskCompletionEvent(
                    taskId: task.id,
                    dateStr: todayStr,
                  ));
            },
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.outlineVariant, width: 2.0),
              ),
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        'PRIORITY: ${task.priority.toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Text(
                  task.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.outlineVariant, size: 20.0),
            onPressed: () {
              context.read<TasksBloc>().add(DeleteTaskEvent(task.id));
            },
          ),
        ],
      ),
    );
  }
}
