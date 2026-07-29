import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/domain/models/habit.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/domain/models/task.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_tokens.dart';
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
  String _selectedPriority = 'Medium';
  String _selectedType = 'check'; // 'check', 'time', 'count'
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  int _targetTimeMinutes = 15;
  int _targetCount = 1;
  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _targetTimeController = TextEditingController(text: '15');
  final TextEditingController _targetCountController = TextEditingController(text: '1');

  HabitsLoaded? _latestHabitsState;
  TasksLoaded? _latestTasksState;

  @override
  void dispose() {
    _taskController.dispose();
    _searchController.dispose();
    _targetTimeController.dispose();
    _targetCountController.dispose();
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

            final isWide = !ResponsiveLayout.isMobile(context);

            return Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: isWide ? 1100.0 : 600.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          _buildHeader(theme),
                          const SizedBox(height: 20.0),

                          // Top Stats Bento Row (Dark Navy Capsule)
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
    final tokens = AppThemeTokens.of(context);
    // Use narrow mode (icon-only button) on screens narrower than 400px so the
    // title has enough room and never gets clipped unnecessarily.
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 400.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  LucideIcons.calendar,
                  color: AppColors.primary,
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Forge",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: tokens.contentSecondary,
                        fontSize: 24.0,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '🎯 Daily operations and scheduled tasks.',
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.contentTertiary,
                        fontSize: 13.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8.0),
        GestureDetector(
          onTap: () {
            setState(() {
              _isAddingTask = !_isAddingTask;
            });
          },
          child: _isAddingTask
              ? Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 10.0 : 16.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: isNarrow
                      ? const Icon(LucideIcons.x, color: Color(0xFFEF4444), size: 18.0)
                      : Row(
                          children: [
                            const Icon(LucideIcons.x, color: Color(0xFFEF4444), size: 16.0),
                            const SizedBox(width: 4.0),
                            Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w800,
                                fontSize: 13.0,
                              ),
                            ),
                          ],
                        ),
                )
              : Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 10.0 : 18.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 8.0, offset: Offset(0, 4)),
                    ],
                  ),
                  child: isNarrow
                      ? const Icon(LucideIcons.plus, color: Colors.white, size: 20.0)
                      : Row(
                          children: [
                            const Icon(LucideIcons.plus, color: Colors.white, size: 18.0),
                            const SizedBox(width: 6.0),
                            Text(
                              'Add Task',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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

  // --- Stats Bento Row (Dark Navy Banner â€” always dark for contrast) ---
  Widget _buildStatsBentoRow(ThemeData theme) {
    final tokens = AppThemeTokens.of(context);
    final habitsTotal = _latestHabitsState?.totalTodayCount ?? 0;
    final habitsDone = _latestHabitsState?.completedTodayCount ?? 0;

    final tasksTotal = _latestTasksState?.totalCount ?? 0;
    final tasksDone = _latestTasksState?.completedCount ?? 0;

    final total = habitsTotal + tasksTotal;
    final done = habitsDone + tasksDone;
    final focus = total > 0 ? ((done / total) * 100.0).toInt() : 100;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: tokens.surfaceDarkBanner,
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
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '$total',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 24.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '📊 TOTAL',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 8.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1.0,
            height: 32.0,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$done',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 24.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '✅ DONE',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 8.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1.0,
            height: 32.0,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$focus%',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF00D9A5),
                    fontWeight: FontWeight.w800,
                    fontSize: 24.0,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '🎯 FOCUS',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 8.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
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
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: tokens.borderDefault),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 16.0, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title Input
          TextField(
            controller: _taskController,
            style: GoogleFonts.plusJakartaSans(fontSize: 14.0, color: tokens.contentSecondary),
            decoration: InputDecoration(
              hintText: 'What are we accomplishing?',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: tokens.iconSubtle,
                fontSize: 14.0,
              ),
              filled: true,
              fillColor: tokens.surfaceInput,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18.0),

          // Schedule & Priority Dropdowns Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('SCHEDULE', tokens),
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      decoration: BoxDecoration(
                        color: tokens.surfaceInput,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSchedule,
                          isExpanded: true,
                          dropdownColor: tokens.surfaceCard,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: tokens.contentSecondary),
                          items: const [
                            DropdownMenuItem(value: 'Daily', child: Text('Daily Operation')),
                            DropdownMenuItem(value: 'Standalone', child: Text('Standalone Task')),
                            DropdownMenuItem(value: 'Range', child: Text('Date Range Task')),
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
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('PRIORITY', tokens),
                    const SizedBox(height: 6.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      decoration: BoxDecoration(
                        color: tokens.surfaceInput,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPriority,
                          isExpanded: true,
                          dropdownColor: tokens.surfaceCard,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: tokens.contentSecondary),
                          items: const [
                            DropdownMenuItem(value: 'High', child: Text('High Priority')),
                            DropdownMenuItem(value: 'Medium', child: Text('Medium Priority')),
                            DropdownMenuItem(value: 'Low', child: Text('Low Priority')),
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

          // Date Range pickers if Schedule == 'Range'
          if (_selectedSchedule == 'Range') ...[
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('START DATE', tokens),
                      const SizedBox(height: 6.0),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: tokens.surfaceInput,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _startDate != null ? AppDateUtils.toLocalYYYYMMDD(_startDate!) : 'Select Start',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: tokens.contentSecondary),
                              ),
                              Icon(LucideIcons.calendar, size: 16.0, color: tokens.iconSubtle),
                            ],
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
                      _buildLabel('END DATE', tokens),
                      const SizedBox(height: 6.0),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: tokens.surfaceInput,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _endDate != null ? AppDateUtils.toLocalYYYYMMDD(_endDate!) : 'Select End',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: tokens.contentSecondary),
                              ),
                              Icon(LucideIcons.calendar, size: 16.0, color: tokens.iconSubtle),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18.0),

          // Tracking Type Selection (Checkbox, Time-based, Count-based)
          _buildLabel('TRACKING METHOD', tokens),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(child: _buildTypeChip('Checkbox', 'check', LucideIcons.checkSquare, tokens)),
              const SizedBox(width: 8.0),
              Expanded(child: _buildTypeChip('Time-Based', 'time', LucideIcons.clock, tokens)),
              const SizedBox(width: 8.0),
              Expanded(child: _buildTypeChip('Count-Based', 'count', LucideIcons.binary, tokens)),
            ],
          ),

          if (_selectedType == 'time') ...[
            const SizedBox(height: 12.0),
            Row(
              children: [
                Text(
                  'TARGET MINUTES: ',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.0, fontWeight: FontWeight.w800, color: tokens.contentSecondary),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: tokens.surfaceInput,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: TextField(
                      controller: _targetTimeController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: tokens.contentSecondary, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        hintText: '15',
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          _targetTimeMinutes = parsed;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (_selectedType == 'count') ...[
            const SizedBox(height: 12.0),
            Row(
              children: [
                Text(
                  'TARGET UNITS: ',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.0, fontWeight: FontWeight.w800, color: tokens.contentSecondary),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: tokens.surfaceInput,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: TextField(
                      controller: _targetCountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.0, color: tokens.contentSecondary, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        hintText: '1',
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          _targetCount = parsed;
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18.0),

          // Reminder Switch Row & Time Picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: tokens.surfaceInput,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: const Icon(
                              LucideIcons.clock,
                              color: AppColors.primary,
                              size: 18.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('REMINDER ALARM', tokens),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Notify me at specific time',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: tokens.contentSecondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
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
                if (_reminderEnabled) ...[
                  const SizedBox(height: 12.0),
                  Divider(height: 1.0, color: tokens.borderDefault),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.bell, size: 18.0, color: AppColors.primary),
                          const SizedBox(width: 8.0),
                          Text(
                            'NOTIFICATION TIME:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w800,
                              color: tokens.contentSecondary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _reminderTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _reminderTime = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _reminderTime.format(context),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              const Icon(LucideIcons.edit3, size: 14.0, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24.0),

          // Create Task Button
          SizedBox(
            width: double.infinity,
            height: 52.0,
            child: ElevatedButton(
              onPressed: () => _createTaskOrHabit(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 0,
              ),
              child: Text(
                'Create Task',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String typeKey, IconData icon, AppThemeTokens tokens) {
    final isSelected = _selectedType == typeKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = typeKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : tokens.surfaceInput,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.0, color: isSelected ? Colors.white : tokens.contentSecondary),
              const SizedBox(width: 6.0),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : tokens.contentSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, AppThemeTokens tokens) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: tokens.iconSubtle,
        fontWeight: FontWeight.w800,
        fontSize: 8.5,
        letterSpacing: 0.8,
      ),
    );
  }

  void _createTaskOrHabit(BuildContext context) {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;

    final nowStr = DateTime.now().toIso8601String();
    final reminderTimeStr = _reminderEnabled
        ? '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'
        : null;

    if (_selectedSchedule == 'Standalone' || _selectedSchedule == 'Range') {
      final task = Task(
        id: UuidGenerator.generate(),
        title: title,
        type: _selectedSchedule == 'Range' ? 'range' : 'single',
        targetDate: AppDateUtils.getTodayString(),
        startDate: _startDate != null ? AppDateUtils.toLocalYYYYMMDD(_startDate!) : AppDateUtils.getTodayString(),
        endDate: _endDate != null ? AppDateUtils.toLocalYYYYMMDD(_endDate!) : AppDateUtils.getTodayString(),
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
        type: _selectedType,
        targetTime: _selectedType == 'time' ? _targetTimeMinutes : 15,
        targetCount: _selectedType == 'count' ? _targetCount : 1,
        scheduleDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        reminderEnabled: _reminderEnabled,
        reminderTime: reminderTimeStr,
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
    final tokens = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: tokens.surfaceCard,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: tokens.borderDefault),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10.0,
            offset: Offset(0, 4.0),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, color: tokens.iconSubtle, size: 20.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<HabitsBloc>().add(SearchHabitsEvent(query));
                context.read<TasksBloc>().add(FilterTasksEvent(query: query));
              },
              style: GoogleFonts.plusJakartaSans(color: tokens.contentSecondary, fontSize: 14.0),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Search tasks instantly...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: tokens.iconSubtle,
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
    final tokens = AppThemeTokens.of(context);
    final habits = _latestHabitsState?.habitsToday ?? [];
    final tasks = _latestTasksState?.tasks ?? [];
    final todayStr = AppDateUtils.getTodayString();

    if (habits.isEmpty && tasks.isEmpty) {
      return CustomCard(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.checkCircle2, size: 48.0, color: tokens.iconSubtle),
              const SizedBox(height: 12.0),
              Text(
                'No Tasks Scheduled Today',
                style: GoogleFonts.plusJakartaSans(fontSize: 16.0, fontWeight: FontWeight.w800, color: tokens.contentSecondary),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Tap "Add Task" above to add daily operations and habits.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: tokens.iconSubtle, fontSize: 13.0),
              ),
            ],
          ),
        ),
      );
    }

    final List<_TodayItem> items = [
      ...habits.map((h) => _TodayItem(
            habit: h,
            isCompleted: h.completedDates.contains(todayStr),
          )),
      ...tasks.map((t) => _TodayItem(
            task: t,
            isCompleted: t.completedDates.contains(todayStr),
          )),
    ];

    // Sort: Incomplete items FIRST (top of list), Completed items LAST (bottom of list)
    items.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1;
    });

    return Column(
      children: items.map((item) {
        return Column(
          children: [
            if (item.habit != null)
              _buildHabitCard(theme, context, item.habit!, item.isCompleted, todayStr)
            else if (item.task != null)
              _buildTaskCard(theme, context, item.task!, item.isCompleted, todayStr),
            const SizedBox(height: 12.0),
          ],
        );
      }).toList(),
    );
  }

  String _formatStartedDate(String createdAt) {
    if (createdAt.isEmpty) return AppDateUtils.formatDisplayDate(DateTime.now());
    try {
      final dt = DateTime.tryParse(createdAt) ?? DateTime.now();
      return AppDateUtils.formatDisplayDate(dt);
    } catch (_) {
      return AppDateUtils.formatDisplayDate(DateTime.now());
    }
  }

  int _calculateActiveDays(String createdAt) {
    if (createdAt.isEmpty) return 1;
    try {
      final dt = DateTime.tryParse(createdAt) ?? DateTime.now();
      final diff = DateTime.now().difference(dt).inDays;
      return diff < 1 ? 1 : (diff + 1);
    } catch (_) {
      return 1;
    }
  }

  Widget _buildScheduleTypeChip(BuildContext context, String type) {
    final label = (type.toLowerCase() == 'check' || type.toLowerCase() == 'daily') ? 'DAILY' : type.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.clock, size: 10.0, color: AppColors.primary),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 9.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context, String priority) {
    Color bg;
    Color fg;
    switch (priority.toLowerCase()) {
      case 'high':
        bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        fg = const Color(0xFFEF4444);
        break;
      case 'low':
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        fg = const Color(0xFF3B82F6);
        break;
      case 'medium':
      default:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        fg = const Color(0xFFD97706);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.flag, size: 10.0, color: fg),
          const SizedBox(width: 3.0),
          Text(
            '${priority.toUpperCase()} PRIORITY',
            style: GoogleFonts.plusJakartaSans(
              color: fg,
              fontSize: 9.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartedAndActiveRow(BuildContext context, String createdAt) {
    final tokens = AppThemeTokens.of(context);
    final startedStr = _formatStartedDate(createdAt);
    final activeDays = _calculateActiveDays(createdAt);

    // Use IntrinsicWidth so the row shrinks to its content when used inside a
    // Wrap, but individual text values truncate gracefully if the available
    // inline space is truly exhausted.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(LucideIcons.calendar, size: 11.0, color: tokens.iconSubtle),
        const SizedBox(width: 3.0),
        Text(
          'Started: ',
          style: GoogleFonts.plusJakartaSans(
            color: tokens.iconSubtle,
            fontSize: 11.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            startedStr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: tokens.contentSecondary,
              fontSize: 11.0,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Icon(LucideIcons.clock, size: 11.0, color: tokens.iconSubtle),
        const SizedBox(width: 3.0),
        Text(
          'Active: ',
          style: GoogleFonts.plusJakartaSans(
            color: tokens.iconSubtle,
            fontSize: 11.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            '$activeDays ${activeDays == 1 ? "Day" : "Days"}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: tokens.contentSecondary,
              fontSize: 11.0,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
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
    final tokens = AppThemeTokens.of(context);

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: tokens.successBg,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: tokens.successBorder, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  color: const Color(0xFF00D9A5),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(LucideIcons.check, color: Colors.white, size: 20.0),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap lets badges flow to a second line on narrow screens
                  // instead of overflowing horizontally.
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: [
                      _buildPriorityChip(context, 'Medium'),
                      _buildScheduleTypeChip(context, habit.type),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: tokens.warningBg,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 10.0)),
                            const SizedBox(width: 3.0),
                            Text(
                              '${habit.streak}d',
                              style: GoogleFonts.plusJakartaSans(
                                color: tokens.warningText,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      Text(
                        habit.title,
                        style: GoogleFonts.outfit(
                          color: tokens.successText,
                          fontWeight: FontWeight.w800,
                          fontSize: 18.0,
                          letterSpacing: -0.2,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: tokens.successText,
                        ),
                      ),
                      Text(
                        '|',
                        style: GoogleFonts.plusJakartaSans(color: tokens.borderStrong, fontSize: 12.0),
                      ),
                      _buildStartedAndActiveRow(context, habit.createdAt),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.trash2, color: tokens.borderStrong, size: 20.0),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: tokens.borderStrong, width: 2.0),
              ),
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap lets badges flow to a second line on narrow screens
                // instead of overflowing horizontally.
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    _buildPriorityChip(context, 'Medium'),
                    _buildScheduleTypeChip(context, habit.type),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: tokens.warningBg,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 10.0)),
                          const SizedBox(width: 3.0),
                          Text(
                            '${habit.streak}d',
                            style: GoogleFonts.plusJakartaSans(
                              color: tokens.warningText,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    Text(
                      habit.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: tokens.contentSecondary,
                      ),
                    ),
                    Text(
                      '|',
                      style: GoogleFonts.plusJakartaSans(color: tokens.borderStrong, fontSize: 12.0),
                    ),
                    _buildStartedAndActiveRow(context, habit.createdAt),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, color: tokens.borderStrong, size: 20.0),
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
    final tokens = AppThemeTokens.of(context);

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: tokens.successBg,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: tokens.successBorder, width: 1.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                  color: const Color(0xFF00D9A5),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(LucideIcons.check, color: Colors.white, size: 20.0),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap for consistency — single chip today but may grow later.
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: [
                      _buildPriorityChip(context, task.priority),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      Text(
                        task.title,
                        style: GoogleFonts.outfit(
                          color: tokens.successText,
                          fontWeight: FontWeight.w800,
                          fontSize: 18.0,
                          letterSpacing: -0.2,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: tokens.successText,
                        ),
                      ),
                      Text(
                        '|',
                        style: GoogleFonts.plusJakartaSans(color: tokens.borderStrong, fontSize: 12.0),
                      ),
                      _buildStartedAndActiveRow(context, task.createdAt),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.trash2, color: tokens.borderStrong, size: 20.0),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: tokens.borderStrong, width: 2.0),
              ),
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap for consistency — single chip today but may grow later.
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    _buildPriorityChip(context, task.priority),
                  ],
                ),
                const SizedBox(height: 6.0),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: tokens.contentSecondary,
                      ),
                    ),
                    Text(
                      '|',
                      style: GoogleFonts.plusJakartaSans(color: tokens.borderStrong, fontSize: 12.0),
                    ),
                    _buildStartedAndActiveRow(context, task.createdAt),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.trash2, color: tokens.borderStrong, size: 20.0),
            onPressed: () {
              context.read<TasksBloc>().add(DeleteTaskEvent(task.id));
            },
          ),
        ],
      ),
    );
  }
}

class _TodayItem {
  final Habit? habit;
  final Task? task;
  final bool isCompleted;
  _TodayItem({this.habit, this.task, required this.isCompleted});
}
