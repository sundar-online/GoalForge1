import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../bloc/focus_bloc.dart';
import '../bloc/focus_event.dart';
import '../bloc/focus_state.dart';

class FocusSessionPage extends StatefulWidget {
  const FocusSessionPage({super.key});

  @override
  State<FocusSessionPage> createState() => _FocusSessionPageState();
}

class _FocusSessionPageState extends State<FocusSessionPage> {
  FocusLoaded? _latestState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<FocusBloc, FocusState>(
      builder: (context, state) {
          if (state is FocusLoaded) {
            _latestState = state;
          }

          final isRunning = _latestState?.isRunning ?? false;
          final remainingTimeStr = _latestState?.formattedRemainingTime ?? '60:00';
          final progressRatio = _latestState?.progressRatio ?? 0.0;
          final selectedDuration = _latestState?.selectedDurationMinutes ?? 60;
          final totalFocusMinutes = _latestState?.totalFocusMinutesToday ?? 0;
          final totalSessions = _latestState?.totalSessionsCount ?? 0;
          final selectedSound = _latestState?.selectedSound ?? 'BELL';
          final volume = _latestState?.volume ?? 0.75;

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
                        // Duration Preset Card
                        _buildDurationPresetsCard(theme, context, selectedDuration, isRunning),
                        const SizedBox(height: 16.0),

                        // Main Neural Focus Session Card (Timer & Controls)
                        _buildNeuralFocusSessionCard(
                          theme,
                          context,
                          remainingTimeStr,
                          progressRatio,
                          isRunning,
                          selectedDuration,
                        ),
                        const SizedBox(height: 16.0),

                        // Stats Grid Row (3 Bento Boxes)
                        _buildStatsRow(theme, totalFocusMinutes, totalSessions),
                        const SizedBox(height: 16.0),

                        // Alert Configuration Card
                        _buildAlertConfigurationCard(theme, context, selectedSound, volume),
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

  // --- Duration Presets Card ---
  Widget _buildDurationPresetsCard(
    ThemeData theme,
    BuildContext context,
    int selectedDuration,
    bool isRunning,
  ) {
    final presets = [15, 25, 45, 60];

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
          const SizedBox(height: 12.0),
          Row(
            children: presets.map((mins) {
              final isSelected = mins == selectedDuration;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6.0),
                  child: GestureDetector(
                    onTap: isRunning
                        ? null
                        : () {
                            context.read<FocusBloc>().add(SelectDurationEvent(mins));
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Center(
                        child: Text(
                          '${mins}m',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.onBackground,
                            fontWeight: FontWeight.bold,
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

  // --- Main Neural Focus Session Card (Timer & Controls) ---
  Widget _buildNeuralFocusSessionCard(
    ThemeData theme,
    BuildContext context,
    String remainingTimeStr,
    double progressRatio,
    bool isRunning,
    int selectedDuration,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                      color: isRunning ? const Color(0xFF00D9A5) : AppColors.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    isRunning ? 'DEEP FOCUS ACTIVE' : 'TIMER READY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isRunning ? const Color(0xFF00D9A5) : AppColors.outline,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
              Text(
                'PRESET: ${selectedDuration}M',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32.0),

          // Circular Progress & Timer Display
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200.0,
                height: 200.0,
                child: CircularProgressIndicator(
                  value: progressRatio,
                  strokeWidth: 8.0,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remainingTimeStr,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 44.0,
                      letterSpacing: -1.0,
                      color: AppColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    isRunning ? 'REMAINING' : 'TAP START',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.outline,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36.0),

          // Play / Pause / Reset Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () {
                  context.read<FocusBloc>().add(ResetTimerEvent());
                },
                icon: const Icon(Icons.refresh, size: 22.0),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16.0),
                  backgroundColor: AppColors.surfaceContainerHigh,
                ),
              ),
              const SizedBox(width: 20.0),
              ElevatedButton.icon(
                onPressed: () {
                  if (isRunning) {
                    context.read<FocusBloc>().add(PauseTimerEvent());
                  } else {
                    context.read<FocusBloc>().add(StartTimerEvent());
                  }
                },
                icon: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 24.0),
                label: Text(
                  isRunning ? 'Pause' : 'Start Focus',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
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

  // --- Stats Row (3 Bento Boxes) ---
  Widget _buildStatsRow(ThemeData theme, int totalFocusMinutes, int totalSessions) {
    return Row(
      children: [
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOCUS TIME TODAY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.0,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '${totalFocusMinutes}m',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.onBackground,
                    fontSize: 22.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESSIONS COMPLETED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.outline,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.0,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '$totalSessions',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 22.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Alert Configuration Card ---
  Widget _buildAlertConfigurationCard(
    ThemeData theme,
    BuildContext context,
    String selectedSound,
    double volume,
  ) {
    final sounds = ['BELL', 'ZEN', 'CYBER', 'ALARM', 'NONE'];

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sounds.map((sound) {
                final isSelected = sound == selectedSound;
                return Container(
                  margin: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      context.read<FocusBloc>().add(SelectSoundscapeEvent(sound));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        sound,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.outline,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
