import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/flaticon_icon.dart';
import '../../../goals/presentation/bloc/goals_bloc.dart';
import '../../../goals/presentation/bloc/goals_state.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = ResponsiveLayout.getDeviceType(context);

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
            final remainingTimeStr = _latestFocusState?.formattedRemainingTime ?? '25:00';
            final progressRatio = _latestFocusState?.progressRatio ?? 0.0;
            final selectedDuration = _latestFocusState?.selectedDurationMinutes ?? 25;
            final totalFocusMinutes = _latestFocusState?.totalFocusMinutesToday ?? 0;
            final totalSessions = _latestFocusState?.totalSessionsCount ?? 0;
            final selectedSound = _latestFocusState?.selectedSound ?? 'BELL';
            final sessionsHistory = _latestFocusState?.sessions ?? [];

            // Find active focus goal if any
            Goal? activeGoal;
            if (_latestGoalsState?.goals.isNotEmpty ?? false) {
              activeGoal = _latestGoalsState!.goals.firstWhere(
                (g) => g.isFocusGoal,
                orElse: () => _latestGoalsState!.goals.first,
              );
            }

            // Estimate finish time
            final now = DateTime.now();
            final remainingSecs = _latestFocusState?.remainingSeconds ?? (selectedDuration * 60);
            final finishTime = now.add(Duration(seconds: remainingSecs));
            final finishTimeStr =
                '${finishTime.hour % 12 == 0 ? 12 : finishTime.hour % 12}:${finishTime.minute.toString().padLeft(2, '0')} ${finishTime.hour >= 12 ? 'PM' : 'AM'}';

            final leftColumn = Column(
              children: [
                _buildMainTimerCard(
                  theme: theme,
                  context: context,
                  remainingTimeStr: remainingTimeStr,
                  progressRatio: progressRatio,
                  isRunning: isRunning,
                  selectedDuration: selectedDuration,
                  finishTimeStr: finishTimeStr,
                  activeGoal: activeGoal,
                ),
                const SizedBox(height: 16.0),
                _buildDurationPresetsCard(theme, context, selectedDuration, isRunning),
                const SizedBox(height: 16.0),
                _buildSoundscapeCard(theme, context, selectedSound),
              ],
            );

            final middleColumn = Column(
              children: [
                _buildFocusGoalCard(theme, context, activeGoal),
                const SizedBox(height: 16.0),
                _buildSessionHistoryCard(theme, sessionsHistory),
              ],
            );

            final rightColumn = Column(
              children: [
                _buildSessionStatsBento(theme, totalFocusMinutes, totalSessions),
                const SizedBox(height: 16.0),
                _buildWeeklyFocusChartCard(theme, totalFocusMinutes),
              ],
            );

            return Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1280.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(theme),
                          const SizedBox(height: 24.0),
                          _buildResponsiveLayout(
                            deviceType: deviceType,
                            left: leftColumn,
                            middle: middleColumn,
                            right: rightColumn,
                          ),
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
      children: [
        Row(
          children: [
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: const Center(
                child: FlaticonIcon(iconKey: 'timer', size: 24.0, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 14.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deep Focus Session',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Eliminate distractions and enter high-velocity deep work flow.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- Responsive Layout Builder ---
  Widget _buildResponsiveLayout({
    required DeviceType deviceType,
    required Widget left,
    required Widget middle,
    required Widget right,
  }) {
    switch (deviceType) {
      case DeviceType.desktop:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: left),
            const SizedBox(width: 20.0),
            Expanded(flex: 4, child: middle),
            const SizedBox(width: 20.0),
            Expanded(flex: 3, child: right),
          ],
        );
      case DeviceType.tablet:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                children: [
                  middle,
                  const SizedBox(height: 16.0),
                  right,
                ],
              ),
            ),
          ],
        );
      case DeviceType.mobile:
      default:
        return Column(
          children: [
            left,
            const SizedBox(height: 16.0),
            middle,
            const SizedBox(height: 16.0),
            right,
          ],
        );
    }
  }

  // --- Main Circular Timer Card ---
  Widget _buildMainTimerCard({
    required ThemeData theme,
    required BuildContext context,
    required String remainingTimeStr,
    required double progressRatio,
    required bool isRunning,
    required int selectedDuration,
    required String finishTimeStr,
    required Goal? activeGoal,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: isRunning
                      ? const Color(0xFF00D9A5).withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: isRunning ? const Color(0xFF00D9A5) : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      isRunning ? 'DEEP FOCUS ACTIVE' : 'TIMER READY',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isRunning ? const Color(0xFF00D9A5) : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'EST. FINISH: $finishTimeStr',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32.0),

          // Circular Progress Indicator
          SizedBox(
            width: 220.0,
            height: 220.0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220.0,
                  height: 220.0,
                  child: CircularProgressIndicator(
                    value: progressRatio,
                    strokeWidth: 10.0,
                    backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isRunning ? const Color(0xFF00D9A5) : AppColors.primary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      remainingTimeStr,
                      style: AppTypography.displayFont(
                        fontSize: 48.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      activeGoal != null ? 'TARGET: ${activeGoal.title}' : 'NO TARGET GOAL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32.0),

          // Control Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () {
                  context.read<FocusBloc>().add(ResetTimerEvent());
                },
                icon: const Icon(Icons.refresh, size: 20.0),
                tooltip: 'Reset Timer',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(14.0),
                  backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 16.0),
              ElevatedButton.icon(
                onPressed: () {
                  if (isRunning) {
                    context.read<FocusBloc>().add(PauseTimerEvent());
                  } else {
                    context.read<FocusBloc>().add(StartTimerEvent());
                  }
                },
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 22.0),
                label: Text(
                  isRunning ? 'Pause Flow' : 'Start Focus',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning ? Colors.amber.shade800 : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 4.0,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Duration Presets Card ---
  Widget _buildDurationPresetsCard(
    ThemeData theme,
    BuildContext context,
    int selectedDuration,
    bool isRunning,
  ) {
    final presets = [15, 25, 45, 60, 90];

    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.primary, size: 16.0),
              const SizedBox(width: 6.0),
              Text(
                'DURATION PRESETS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Row(
            children: presets.map((mins) {
              final isSelected = mins == selectedDuration;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.0),
                    onTap: isRunning
                        ? null
                        : () {
                            context.read<FocusBloc>().add(SelectDurationEvent(mins));
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: Text(
                          '${mins}m',
                          style: AppTypography.displayFont(
                            color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Soundscape Card ---
  Widget _buildSoundscapeCard(
    ThemeData theme,
    BuildContext context,
    String selectedSound,
  ) {
    final sounds = ['BELL', 'RAIN', 'FOREST', 'OCEAN', 'CAFE', 'WHITE NOISE', 'NONE'];

    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up, color: AppColors.primary, size: 16.0),
              const SizedBox(width: 6.0),
              Text(
                'SOUNDSCAPE & ALERTS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: sounds.map((sound) {
              final isSelected = sound == selectedSound;
              return InkWell(
                borderRadius: BorderRadius.circular(12.0),
                onTap: () {
                  context.read<FocusBloc>().add(SelectSoundscapeEvent(sound));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    sound,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11.0,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Focus Goal Card ---
  Widget _buildFocusGoalCard(ThemeData theme, BuildContext context, Goal? activeGoal) {
    if (activeGoal == null) {
      return CustomCard(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FlaticonIcon(iconKey: 'target', size: 18.0, color: AppColors.primary),
                const SizedBox(width: 8.0),
                Text(
                  'TARGET GOAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 10.0,
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
                    Icon(
                      Icons.track_changes,
                      size: 40.0,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'No focus goal selected.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Select a goal in Goals System to track daily deep work progress.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
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

    return CustomCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const FlaticonIcon(iconKey: 'target', size: 18.0, color: AppColors.primary),
                  const SizedBox(width: 8.0),
                  Text(
                    'FOCUS GOAL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  activeGoal.tag ?? 'GENERAL',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            activeGoal.title,
            style: AppTypography.displayFont(
              fontSize: 20.0,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            activeGoal.description ?? 'Deep work session focused on long-term mastery.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13.0,
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MASTERY PROGRESS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 9.5,
                ),
              ),
              Text(
                '${activeGoal.progress.toInt()}%',
                style: AppTypography.displayFont(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: (activeGoal.progress / 100.0).clamp(0.0, 1.0),
              minHeight: 6.0,
              backgroundColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // --- Session History Card ---
  Widget _buildSessionHistoryCard(ThemeData theme, List<dynamic> sessions) {
    return CustomCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.primary, size: 18.0),
              const SizedBox(width: 8.0),
              Text(
                'RECENT DEEP WORK SESSIONS',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          if (sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 36.0,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'No sessions recorded yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: sessions.take(4).map((session) {
                final mins = (session.timeSpentSeconds ?? 0) ~/ 60;
                final dateStr = session.createdAt?.substring(0, 10) ?? 'Today';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10.0),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Color(0xFF00D9A5), size: 16.0),
                          const SizedBox(width: 8.0),
                          Text(
                            '${mins}m Deep Work',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.0,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11.0,
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
  }

  // --- Session Stats Bento ---
  Widget _buildSessionStatsBento(ThemeData theme, int totalFocusMinutes, int totalSessions) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FOCUS TIME',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      '${totalFocusMinutes}m',
                      style: AppTypography.displayFont(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SESSIONS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      '$totalSessions',
                      style: AppTypography.displayFont(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEEP WORK SCORE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      '94%',
                      style: AppTypography.displayFont(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00D9A5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: CustomCard(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STREAK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 9.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      '5 Days 🔥',
                      style: AppTypography.displayFont(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Weekly Focus Chart Card ---
  Widget _buildWeeklyFocusChartCard(ThemeData theme, int totalFocusMinutes) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.3, 0.8];

    return CustomCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WEEKLY DISTRIBUTION',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontSize: 10.0,
                ),
              ),
              const Icon(Icons.bar_chart, color: AppColors.primary, size: 16.0),
            ],
          ),
          const SizedBox(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (idx) {
              return Column(
                children: [
                  Container(
                    width: 18.0,
                    height: 80.0 * heights[idx],
                    decoration: BoxDecoration(
                      color: idx == 3 ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    days[idx],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
