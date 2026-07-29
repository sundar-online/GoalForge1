import 'package:flutter/material.dart';
import '../../../../core/domain/models/task_log.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/widgets/custom_card.dart';

class WeeklyActivityView extends StatelessWidget {
  final Map<String, TaskLog> taskLogs;
  final double weeklyAccuracyPercent;

  const WeeklyActivityView({
    super.key,
    required this.taskLogs,
    required this.weeklyAccuracyPercent,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 7 days (index 0 = 6 days ago, index 6 = today)
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: "WEEKLY OPERATION LOG" & "43% Avg Completion"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'WEEKLY OPERATION LOG',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),

            // "43% Avg Completion" Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${weeklyAccuracyPercent.clamp(0.0, 100.0).round()}% Avg Completion',
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w900,
                  fontSize: 11.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // 7-Day Operation Log Day Cards Row
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - (6 * 8.0)) / 7.0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = days[i];
                final dateStr = AppDateUtils.toLocalYYYYMMDD(day);
                final log = taskLogs[dateStr];
                final count = log?.completedCount ?? 0;
                final isToday = i == 6;

                final dayLabel = dayNames[day.weekday - 1];

                return SizedBox(
                  width: cardWidth,
                  child: CustomCard(
                    padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
                    border: Border.all(
                      color: isToday
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF2C2D35),
                      width: isToday ? 1.5 : 1.0,
                    ),
                    backgroundColor: isToday
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                        : const Color(0xFF1C1D26),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Day Label (THU, FRI, SAT, SUN, MON, TUE, WED)
                        Text(
                          dayLabel,
                          style: TextStyle(
                            color: isToday ? Colors.white : Colors.white70,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10.0),

                        // Center Status Pill
                        _buildCenterStatusPill(count),
                        const SizedBox(height: 10.0),

                        // Bottom Intensity Dots Indicator
                        _buildIntensityDots(count),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCenterStatusPill(int count) {
    if (count == 0) {
      // Pink Pill for 0 completions
      return Container(
        width: 32.0,
        height: 28.0,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: const Text(
          '0',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w900,
            fontSize: 12.0,
          ),
        ),
      );
    } else if (count == 1) {
      // Soft Green Pill with Checkmark for 1 completion
      return Container(
        width: 32.0,
        height: 28.0,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.check,
          color: Color(0xFF10B981),
          size: 16.0,
        ),
      );
    } else if (count == 2) {
      // Soft Yellow/Orange Pill for 2 completions
      return Container(
        width: 32.0,
        height: 28.0,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: const Text(
          '2',
          style: TextStyle(
            color: Color(0xFFF59E0B),
            fontWeight: FontWeight.w900,
            fontSize: 12.0,
          ),
        ),
      );
    } else {
      // Soft Green Pill with count for 3+ completions
      return Container(
        width: 32.0,
        height: 28.0,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w900,
            fontSize: 12.0,
          ),
        ),
      );
    }
  }

  Widget _buildIntensityDots(int count) {
    int dotCount = 1;
    Color dotColor = Colors.white24;

    if (count == 0) {
      dotCount = 1;
      dotColor = Colors.white24;
    } else if (count == 1) {
      dotCount = 1;
      dotColor = const Color(0xFF10B981);
    } else if (count == 2) {
      dotCount = 2;
      dotColor = const Color(0xFF10B981);
    } else {
      dotCount = 3;
      dotColor = const Color(0xFF10B981);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotCount, (i) {
        return Container(
          width: 4.0,
          height: 4.0,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        );
      }),
    );
  }
}
