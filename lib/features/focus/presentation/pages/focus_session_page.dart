import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/models/habit.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../goals/presentation/bloc/goals_bloc.dart';
import '../../../goals/presentation/bloc/goals_state.dart';
import '../../../habits/presentation/bloc/habits_bloc.dart';
import '../../../habits/presentation/bloc/habits_event.dart';
import '../../../main_navigation_page.dart';
import '../bloc/focus_bloc.dart';
import '../bloc/focus_event.dart';
import '../bloc/focus_state.dart';

class FocusSessionPage extends StatefulWidget {
  const FocusSessionPage({super.key});

  @override
  State<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends State<FocusSessionPage> {
  FocusLoaded? _latestFocusState;
  GoalsLoaded? _latestGoalsState;

  String? _selectedTarget;
  String? _selectedActivity;
  String _selectedSoundAlert = 'ALARM';
  final TextEditingController _customMinController = TextEditingController(text: '15');

  @override
  void dispose() {
    _customMinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return BlocBuilder<GoalsBloc, GoalsState>(
      builder: (context, goalsState) {
        if (goalsState is GoalsLoaded) {
          _latestGoalsState = goalsState;
        }

        return BlocBuilder<FocusBloc, FocusState>(
          builder: (context, focusState) {
            if (focusState is FocusLoaded) {
              _latestFocusState = focusState;
            }

            final isRunning = _latestFocusState?.isRunning ?? false;
            final remainingTimeStr = _latestFocusState?.formattedRemainingTime ?? '15:00';
            final progressRatio = _latestFocusState?.progressRatio ?? 0.0;
            final selectedDuration = _latestFocusState?.selectedDurationMinutes ?? 15;
            final totalFocusMinutes = _latestFocusState?.totalFocusMinutesToday ?? 0;
            final totalSessions = _latestFocusState?.totalSessionsCount ?? 0;
            final volume = _latestFocusState?.volume ?? 0.75;

            // Compute goals options from GoalsBloc state
            final goals = _latestGoalsState?.goals ?? [];
            final habitsByGoalId = _latestGoalsState?.habitsByGoalId ?? {};
            final hasGoals = goals.isNotEmpty;

            final targetOptions = goals.map((g) => g.title).toList();

            if (_selectedTarget != null && !targetOptions.contains(_selectedTarget)) {
              _selectedTarget = targetOptions.isNotEmpty ? targetOptions.first : null;
            } else if (_selectedTarget == null && targetOptions.isNotEmpty) {
              _selectedTarget = targetOptions.first;
            }

            Goal? activeGoal = goals.where((g) => g.title == _selectedTarget).firstOrNull ??
                goals.where((g) => g.isFocusGoal).firstOrNull ??
                (goals.isNotEmpty ? goals.first : null);

            List<String> activities = [];
            if (activeGoal != null) {
              final habits = habitsByGoalId[activeGoal.id] ?? [];
              activities = habits.map((h) => '${h.title} [${h.timeSpent}m/${h.targetTime}m]').toList();
              if (activities.isEmpty) {
                activities = ['General Focus Session for ${activeGoal.title}'];
              }
            }

            // Track which habits belong to the active goal for session logging
            final activeGoalHabits = activeGoal != null ? (habitsByGoalId[activeGoal.id] ?? []) : <Habit>[];

            if (_selectedActivity != null && !activities.contains(_selectedActivity)) {
              _selectedActivity = activities.isNotEmpty ? activities.first : null;
            } else if (_selectedActivity == null && activities.isNotEmpty) {
              _selectedActivity = activities.first;
            }

            return BlocListener<FocusBloc, FocusState>(
              listenWhen: (prev, curr) {
                // Fire only on the transition to isCompleted = true
                final prevLoaded = prev is FocusLoaded ? prev : null;
                final currLoaded = curr is FocusLoaded ? curr : null;
                return currLoaded != null &&
                    currLoaded.isCompleted &&
                    (prevLoaded == null || !prevLoaded.isCompleted);
              },
              listener: (ctx, state) {
                if (state is! FocusLoaded) return;
                // Find the habit matching the selected activity and log time
                final activityTitle = _selectedActivity?.split(' [').first;
                if (activityTitle == null) return;
                final matchedHabit = activeGoalHabits
                    .where((h) => h.title == activityTitle && h.type == 'time')
                    .firstOrNull;
                if (matchedHabit == null) return;
                // Convert actual seconds spent to whole minutes (minimum 1)
                final totalSecs = state.selectedDurationMinutes * 60;
                final spentSecs = totalSecs - state.remainingSeconds;
                final spentMins = (spentSecs / 60).ceil().clamp(1, state.selectedDurationMinutes);
                ctx.read<HabitsBloc>().add(
                  LogHabitTimeEvent(habitId: matchedHabit.id, minutes: spentMins),
                );
              },
              child: Scaffold(
                backgroundColor: tokens.surfaceElevated,
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1280.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Center / Main Column (Choose Target + Presets + Timer Card)
                                  Expanded(
                                    flex: 7,
                                    child: Column(
                                      children: [
                                        _buildMainFocusCard(
                                          context,
                                          tokens,
                                          targetOptions,
                                          activities,
                                          activeGoalHabits,
                                          selectedDuration,
                                          isRunning,
                                          remainingTimeStr,
                                          progressRatio,
                                          activeGoal,
                                          hasGoals,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20.0),

                                  // Right Bento Column (Stats Bento + Sound Configuration)
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        _buildTopStatsBentoRow(context, tokens, totalFocusMinutes, totalSessions),
                                        const SizedBox(height: 16.0),
                                        _buildAlertConfigurationCard(context, tokens, volume),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildMainFocusCard(
                                    context,
                                    tokens,
                                    targetOptions,
                                    activities,
                                    activeGoalHabits,
                                    selectedDuration,
                                    isRunning,
                                    remainingTimeStr,
                                    progressRatio,
                                    activeGoal,
                                    hasGoals,
                                  ),
                                  const SizedBox(height: 16.0),
                                  _buildTopStatsBentoRow(context, tokens, totalFocusMinutes, totalSessions),
                                  const SizedBox(height: 16.0),
                                  _buildAlertConfigurationCard(context, tokens, volume),
                                ],
                              ),
                          ],
                        ),
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

  // ─────────────────────────────────────────────────────────────
  // 1. MAIN FOCUS CARD (Choose Active Target + Presets + Circular Timer)
  // ─────────────────────────────────────────────────────────────
  Widget _buildMainFocusCard(
    BuildContext context,
    AppThemeTokens tokens,
    List<String> targetOptions,
    List<String> activities,
    List<Habit> activeGoalHabits, // for pre-filling timer from habit targetTime
    int selectedDuration,
    bool isRunning,
    String remainingTimeStr,
    double progressRatio,
    Goal? activeGoal,
    bool hasGoals,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1: Choose Active Target Header & Dropdowns ──
          Row(
            children: [
              Icon(Icons.track_changes, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'CHOOSE ACTIVE TARGET',
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.contentTertiary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Target / Goal Dropdown
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.borderDefault),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: hasGoals ? (targetOptions.contains(_selectedTarget) ? _selectedTarget : targetOptions.firstOrNull) : null,
                      hint: Text(
                        'No goals yet — create one to start a focus session',
                        style: TextStyle(fontSize: 12, color: tokens.contentSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: tokens.iconSubtle),
                      dropdownColor: tokens.surfaceCard,
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.contentPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      onChanged: hasGoals
                          ? (val) {
                              if (val != null) {
                                setState(() => _selectedTarget = val);
                              }
                            }
                          : null,
                      items: hasGoals
                          ? targetOptions.map((obj) => DropdownMenuItem<String?>(
                                value: obj,
                                child: Text(obj, overflow: TextOverflow.ellipsis),
                              )).toList()
                          : [
                              const DropdownMenuItem<String?>(
                                value: null,
                                enabled: false,
                                child: Text(
                                  'No goals yet — create one to start a focus session',
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Activity Dropdown
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: tokens.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.borderDefault),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: (hasGoals && activities.isNotEmpty) ? (activities.contains(_selectedActivity) ? _selectedActivity : activities.firstOrNull) : null,
                      hint: Text(
                        'No habits available',
                        style: TextStyle(fontSize: 12, color: tokens.contentSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: tokens.iconSubtle),
                      dropdownColor: tokens.surfaceCard,
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.contentPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      onChanged: (hasGoals && activities.isNotEmpty)
                          ? (val) {
                              if (val != null) {
                                setState(() => _selectedActivity = val);
                                // Pre-fill timer from the habit's targetTime so
                                // the session duration matches the habit target.
                                final title = val.split(' [').first;
                                final matchedHabit = activeGoalHabits
                                    .where((h) => h.title == title && h.type == 'time' && h.targetTime > 0)
                                    .firstOrNull;
                                if (matchedHabit != null) {
                                  _customMinController.text = matchedHabit.targetTime.toString();
                                  context.read<FocusBloc>().add(SelectDurationEvent(matchedHabit.targetTime));
                                }
                              }
                            }
                          : null,
                      items: (hasGoals && activities.isNotEmpty)
                          ? activities.map((act) {
                              return DropdownMenuItem<String?>(
                                value: act,
                                child: Text(act, overflow: TextOverflow.ellipsis),
                              );
                            }).toList()
                          : [
                              const DropdownMenuItem<String?>(
                                value: null,
                                enabled: false,
                                child: Text(
                                  'No habits available',
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Section 2: Duration Presets ──
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: tokens.contentTertiary),
              const SizedBox(width: 6),
              Text(
                'DURATION PRESET',
                style: GoogleFonts.plusJakartaSans(
                  color: tokens.contentTertiary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildPresetPill(context, tokens, mins: 25, currentMins: selectedDuration),
              const SizedBox(width: 10),
              _buildPresetPill(context, tokens, mins: 45, currentMins: selectedDuration),
              const SizedBox(width: 10),
              _buildPresetPill(context, tokens, mins: 90, currentMins: selectedDuration),
              const SizedBox(width: 14),

              // Custom Input Min Box
              Container(
                height: 40,
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderDefault),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customMinController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.contentPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          final parsed = int.tryParse(val.trim());
                          if (parsed != null && parsed > 0) {
                            context.read<FocusBloc>().add(SelectDurationEvent(parsed));
                          }
                        },
                      ),
                    ),
                    Text(
                      'min',
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.iconSubtle,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Section 3: Neural Focus Session Inner Container ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Column(
              children: [
                // Top Neural Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'NEURAL FOCUS SESSION',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Selected Task Title & Subtitle Project
                Text(
                  _selectedActivity != null
                      ? _selectedActivity!.split(' [').first
                      : (hasGoals ? 'General Focus Session' : 'No Focus Goal Selected'),
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.contentPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.track_changes, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      activeGoal != null ? 'Project: ${activeGoal.title}' : 'No Active Goal Selected',
                      style: GoogleFonts.plusJakartaSans(
                        color: tokens.contentSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Circular Ring Timer
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: isRunning ? progressRatio : 1.0,
                          strokeWidth: 8.0,
                          backgroundColor: tokens.borderDefault,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isRunning ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            remainingTimeStr,
                            style: AppTypography.displayFont(
                              fontSize: 46.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.0,
                              color: tokens.contentPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isRunning ? 'SESSION ACTIVE' : 'SYSTEM READY',
                            style: GoogleFonts.plusJakartaSans(
                              color: isRunning ? AppColors.primary : tokens.iconSubtle,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Big Full-Width Action Button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasGoals
                    ? (isRunning ? Colors.amber.shade800 : AppColors.primary)
                    : tokens.borderDefault,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () {
                if (!hasGoals) {
                  TabNavigationNotification(1).dispatch(context);
                  return;
                }
                if (isRunning) {
                  context.read<FocusBloc>().add(PauseTimerEvent());
                } else {
                  context.read<FocusBloc>().add(StartTimerEvent());
                }
              },
              icon: Icon(
                hasGoals
                    ? (isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded)
                    : Icons.add_circle_outline_rounded,
                size: 22,
              ),
              label: Text(
                hasGoals
                    ? (isRunning ? 'PAUSE FOCUS SESSION' : 'START FOCUS SESSION')
                    : '+ CREATE GOAL FIRST',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetPill(
    BuildContext context,
    AppThemeTokens tokens, {
    required int mins,
    required int currentMins,
  }) {
    final isSelected = mins == currentMins;

    return Expanded(
      child: InkWell(
        onTap: () {
          _customMinController.text = mins.toString();
          context.read<FocusBloc>().add(SelectDurationEvent(mins));
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : tokens.borderDefault,
            ),
          ),
          child: Center(
            child: Text(
              '${mins}m',
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? AppColors.primary : tokens.contentPrimary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. TOP STATS BENTO ROW (Streak, Yield Today, Today Badge)
  // ─────────────────────────────────────────────────────────────
  Widget _buildTopStatsBentoRow(
    BuildContext context,
    AppThemeTokens tokens,
    int totalFocusMinutes,
    int totalSessions,
  ) {
    final hours = totalFocusMinutes ~/ 60;
    final mins = totalFocusMinutes % 60;

    return Row(
      children: [
        // Focus Streak
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'FOCUS STREAK',
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.iconSubtle,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '0d',
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.contentPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Yield Today
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'YIELD TODAY',
                        style: GoogleFonts.plusJakartaSans(
                          color: tokens.iconSubtle,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.6,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalSessions Blks',
                  style: GoogleFonts.plusJakartaSans(
                    color: tokens.contentPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Today
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'TODAY',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${hours}h${mins}m',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. ALERT CONFIGURATION CARD (Zen, Cyber, Bell, Alarm & Volume)
  // ─────────────────────────────────────────────────────────────
  Widget _buildAlertConfigurationCard(
    BuildContext context,
    AppThemeTokens tokens,
    double volume,
  ) {
    final sounds = ['ZEN', 'CYBER', 'BELL', 'ALARM'];

    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 16, color: tokens.contentTertiary),
                  const SizedBox(width: 6),
                  Text(
                    'ALERT CONFIGURATION',
                    style: GoogleFonts.plusJakartaSans(
                      color: tokens.contentTertiary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Icon(Icons.volume_up_outlined, size: 18, color: tokens.iconSubtle),
            ],
          ),
          const SizedBox(height: 16),

          // Sound Presets Buttons
          Row(
            children: sounds.map((sound) {
              final isSelected = sound == _selectedSoundAlert;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedSoundAlert = sound);
                      context.read<FocusBloc>().add(SelectSoundscapeEvent(sound));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : tokens.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : tokens.borderDefault,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          sound,
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected ? AppColors.primary : tokens.contentSecondary,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Volume Slider Row
          Row(
            children: [
              Icon(Icons.volume_off_rounded, size: 16, color: tokens.iconSubtle),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: tokens.borderDefault,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: volume,
                    onChanged: (val) {
                      context.read<FocusBloc>().add(ChangeVolumeEvent(val));
                    },
                  ),
                ),
              ),
              Icon(Icons.volume_up_rounded, size: 16, color: tokens.iconSubtle),
            ],
          ),
        ],
      ),
    );
  }
}
