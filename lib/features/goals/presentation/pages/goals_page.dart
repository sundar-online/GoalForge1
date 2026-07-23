import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/models/habit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/widgets/custom_card.dart';
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
  final _categoryController = TextEditingController();
  final _orderController = TextEditingController(text: '1');
  final _habitTitleController = TextEditingController();

  bool _isFocusGoal = false;
  String _selectedMode = 'ALL'; // 'ALL', 'ANY', 'CUSTOM'
  String _habitType = 'time'; // 'time', 'count', 'check'
  int _habitTargetTime = 15;
  List<String> _habitScheduleDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final List<_StagedHabit> _stagedHabits = [];
  GoalsLoaded? _latestState;

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _categoryController.dispose();
    _orderController.dispose();
    _habitTitleController.dispose();
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
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    _buildHeader(theme),
                    const SizedBox(height: 20.0),

                    // Filter Stats Bar
                    _buildFilterStatsBar(theme),
                    const SizedBox(height: 24.0),

                    // Goal Builder Form Card
                    _buildGoalForm(theme, context),
                    const SizedBox(height: 24.0),

                    // Active Targets Switcher Row
                    _buildTabSwitcher(theme, context),
                    const SizedBox(height: 16.0),

                    // Goal Cards List
                    _buildGoalCardsList(theme, context),
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            ),
          );
        },
      );
  }

  // --- Header ---
  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.track_changes, color: AppColors.primary, size: 24.0),
                ),
                const SizedBox(width: 12.0),
                Text(
                  'Goals System',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                    fontSize: 24.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Text(
          'Build daily systems to drive long-term progress.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }

  // --- Filter Stats Bar (Dark Navy Capsule) ---
  Widget _buildFilterStatsBar(ThemeData theme) {
    final avgMastery = _latestState?.avgMastery.toInt() ?? 0;
    final finished = _latestState?.finishedCount ?? 0;
    final inProgress = _latestState?.inProgressCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildFilterBadge('AVG MASTERY $avgMastery%', AppColors.primary.withValues(alpha: 0.15), AppColors.primary, Icons.track_changes),
              const SizedBox(width: 4.0),
              _buildFilterBadge('FINISHED ($finished)', Colors.white.withValues(alpha: 0.08), const Color(0xFF30D158), Icons.lens),
              const SizedBox(width: 4.0),
              _buildFilterBadge('IN PROGRESS ($inProgress)', Colors.white.withValues(alpha: 0.08), Colors.white70, Icons.hourglass_empty),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBadge(String label, Color bgColor, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 10.0),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- Goal Builder Form ---
  Widget _buildGoalForm(ThemeData theme, BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormLabel(theme, 'GOAL NAME'),
          const SizedBox(height: 6.0),
          _buildTextField(_nameController, 'Goal Name (e.g. Master Flutter Architecture)', false),
          const SizedBox(height: 16.0),

          _buildFormLabel(theme, 'GOAL PURPOSE / DESCRIPTION'),
          const SizedBox(height: 6.0),
          _buildTextField(_purposeController, 'What is the deeper purpose behind this goal?', true),
          const SizedBox(height: 16.0),

          _buildFormLabel(theme, 'CATEGORY'),
          const SizedBox(height: 6.0),
          _buildTextField(_categoryController, 'General / Learning / Health', false),
          const SizedBox(height: 16.0),

          _buildFormLabel(theme, 'EXECUTION ORDER'),
          const SizedBox(height: 6.0),
          _buildTextField(_orderController, '1', false, isNumber: true),
          const SizedBox(height: 16.0),

          // Focus Goal Checkbox Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _isFocusGoal = !_isFocusGoal;
              });
            },
            child: Row(
              children: [
                Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: BoxDecoration(
                    color: _isFocusGoal ? AppColors.primary : Colors.transparent,
                    border: Border.all(color: _isFocusGoal ? AppColors.primary : AppColors.outline),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: _isFocusGoal
                      ? const Icon(Icons.check, size: 14.0, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Set as Primary Focus Goal',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          _buildFormLabel(theme, 'STRATEGY LOGIC'),
          const SizedBox(height: 8.0),
          _buildStrategyLogicGrid(theme),
          const SizedBox(height: 24.0),

          // Daily Systems Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAILY SYSTEMS & HABITS (${_stagedHabits.length})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Habit Builder Panel
          _buildHabitBuilderPanel(theme),
          const SizedBox(height: 24.0),

          // Forge Goal Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _forgeGoalSystem(context),
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
                'Forge Goal System',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.outline,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, bool isMultiLine, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      maxLines: isMultiLine ? 3 : 1,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.outline.withValues(alpha: 0.6),
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStrategyLogicGrid(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildStrategyOption('Complete All', 'ALL')),
        const SizedBox(width: 8.0),
        Expanded(child: _buildStrategyOption('Any One', 'ANY')),
        const SizedBox(width: 8.0),
        Expanded(child: _buildStrategyOption('Custom', 'CUSTOM')),
      ],
    );
  }

  Widget _buildStrategyOption(String label, String modeCode) {
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
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.outlineVariant,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 13.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitBuilderPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Daily Habit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          _buildTextField(_habitTitleController, 'Habit Name (e.g. Daily Coding)', false),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _habitType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'time', child: Text('Time Based')),
                        DropdownMenuItem(value: 'count', child: Text('Count Based')),
                        DropdownMenuItem(value: 'check', child: Text('Checkmark')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _habitType = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              if (_habitType == 'time')
                Container(
                  width: 90.0,
                  height: 48.0,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _habitTargetTime,
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15m')),
                          DropdownMenuItem(value: 30, child: Text('30m')),
                          DropdownMenuItem(value: 45, child: Text('45m')),
                          DropdownMenuItem(value: 60, child: Text('60m')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _habitTargetTime = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'SCHEDULE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDayToggle('Mon'),
              _buildDayToggle('Tue'),
              _buildDayToggle('Wed'),
              _buildDayToggle('Thu'),
              _buildDayToggle('Fri'),
              _buildDayToggle('Sat'),
              _buildDayToggle('Sun'),
            ],
          ),
          const SizedBox(height: 16.0),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _addStagedHabit,
              icon: const Icon(Icons.add, size: 16.0),
              label: const Text('Add Habit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.primary,
                elevation: 0,
              ),
            ),
          ),
          if (_stagedHabits.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            const Divider(),
            ..._stagedHabits.asMap().entries.map((entry) {
              final idx = entry.key;
              final habit = entry.value;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${habit.type.toUpperCase()} - ${habit.scheduleDays.join(', ')}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18.0, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _stagedHabits.removeAt(idx);
                    });
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDayToggle(String day) {
    final selected = _habitScheduleDays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _habitScheduleDays.remove(day);
          } else {
            _habitScheduleDays.add(day);
          }
        });
      },
      child: Container(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? AppColors.primary : AppColors.outlineVariant),
        ),
        child: Center(
          child: Text(
            day.substring(0, 2),
            style: TextStyle(
              color: selected ? Colors.white : AppColors.onBackground,
              fontSize: 10.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _addStagedHabit() {
    if (_habitTitleController.text.trim().isEmpty) return;
    setState(() {
      _stagedHabits.add(_StagedHabit(
        title: _habitTitleController.text.trim(),
        type: _habitType,
        targetTime: _habitTargetTime,
        scheduleDays: List.from(_habitScheduleDays),
      ));
      _habitTitleController.clear();
    });
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
        title: staged.title,
        type: staged.type,
        targetTime: staged.targetTime,
        targetCount: 1,
        scheduleDays: staged.scheduleDays,
        reminderEnabled: false,
        completedDates: const [],
        createdAt: nowStr,
      );
    }).toList();

    context.read<GoalsBloc>().add(CreateGoalEvent(goal: newGoal, habits: habits));

    _nameController.clear();
    _purposeController.clear();
    _categoryController.clear();
    setState(() {
      _stagedHabits.clear();
      _isFocusGoal = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal system forged successfully!')),
    );
  }

  // --- Active Targets Switcher ---
  Widget _buildTabSwitcher(ThemeData theme, BuildContext context) {
    final activeTab = _latestState?.activeTab ?? 'ACTIVE';
    final goals = _latestState?.goals ?? [];
    final activeGoalsCount = goals.length;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            context.read<GoalsBloc>().add(const SwitchActiveTabEvent('ACTIVE'));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: activeTab == 'ACTIVE' ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.track_changes,
                  size: 14.0,
                  color: activeTab == 'ACTIVE' ? Colors.white : AppColors.outline,
                ),
                const SizedBox(width: 6.0),
                Text(
                  'Active Targets ($activeGoalsCount)',
                  style: TextStyle(
                    color: activeTab == 'ACTIVE' ? Colors.white : AppColors.outline,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        GestureDetector(
          onTap: () {
            context.read<GoalsBloc>().add(const SwitchActiveTabEvent('MISSING'));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: activeTab == 'MISSING' ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_queue,
                  size: 14.0,
                  color: activeTab == 'MISSING' ? Colors.white : AppColors.outline,
                ),
                const SizedBox(width: 6.0),
                Text(
                  'Missing Dreams (0)',
                  style: TextStyle(
                    color: activeTab == 'MISSING' ? Colors.white : AppColors.outline,
                    fontWeight: FontWeight.bold,
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

  // --- Goal Cards List ---
  Widget _buildGoalCardsList(ThemeData theme, BuildContext context) {
    final goals = _latestState?.goals ?? [];
    final habitsMap = _latestState?.habitsByGoalId ?? {};

    if (goals.isEmpty) {
      return CustomCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.track_changes, size: 48.0, color: AppColors.outlineVariant),
                const SizedBox(height: 12.0),
                Text(
                  'No Goals Forged Yet',
                  style: theme.textTheme.headlineSmall?.copyWith(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Use the Goal Builder Form above to forge your first goal system.',
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
      children: goals.map((goal) {
        final habits = habitsMap[goal.id] ?? [];
        return Column(
          children: [
            _buildGoalCard(
              theme: theme,
              context: context,
              goal: goal,
              habitsCount: habits.length,
            ),
            const SizedBox(height: 16.0),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGoalCard({
    required ThemeData theme,
    required BuildContext context,
    required Goal goal,
    required int habitsCount,
  }) {
    final tag = goal.tag ?? 'GENERAL';
    final progressRatio = (goal.progress / 100.0).clamp(0.0, 1.0);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.star,
                      color: goal.isFocusGoal ? Colors.amber : AppColors.outlineVariant,
                      size: 20.0,
                    ),
                    onPressed: () {
                      context.read<GoalsBloc>().add(ToggleFocusGoalEvent(goal.id));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.outlineVariant, size: 20.0),
                    onPressed: () {
                      context.read<GoalsBloc>().add(DeleteGoalEvent(goal.id));
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              SizedBox(
                width: 44.0,
                height: 44.0,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: progressRatio,
                        strokeWidth: 4.0,
                        backgroundColor: AppColors.surfaceContainer,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${goal.progress.toInt()}%',
                        style: const TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (goal.description != null && goal.description!.isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Text(
                        goal.description!,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBottomInfoChip(Icons.calendar_today, goal.deadline ?? '31 Dec 2026'),
              const SizedBox(width: 16.0),
              _buildBottomInfoChip(Icons.local_fire_department, '${goal.streak}d streak'),
              const SizedBox(width: 16.0),
              _buildBottomInfoChip(Icons.check_box_outlined, '$habitsCount habit(s)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfoChip(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 13.0, color: AppColors.primary),
        const SizedBox(width: 4.0),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 11.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StagedHabit {
  final String title;
  final String type;
  final int targetTime;
  final List<String> scheduleDays;

  _StagedHabit({
    required this.title,
    required this.type,
    required this.targetTime,
    required this.scheduleDays,
  });
}
