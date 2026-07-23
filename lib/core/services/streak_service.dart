import '../utils/date_utils.dart';

class StreakService {
  const StreakService();

  /// Calculates current streak of consecutive days ending today or yesterday for a date list.
  int calculateStreak(List<String> completedDates) {
    if (completedDates.isEmpty) return 0;

    final sortedDates = List<String>.from(completedDates)..sort();
    final todayStr = AppDateUtils.getTodayString();

    // Find if today or yesterday is present
    if (!sortedDates.contains(todayStr)) {
      final yesterdayStr = AppDateUtils.toLocalYYYYMMDD(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      if (!sortedDates.contains(yesterdayStr)) {
        return 0;
      }
    }

    int streak = 1;
    for (int i = sortedDates.length - 1; i > 0; i--) {
      final current = sortedDates[i];
      final previous = sortedDates[i - 1];

      if (AppDateUtils.isConsecutive(previous, current)) {
        streak++;
      } else if (previous != current) {
        break;
      }
    }
    return streak;
  }

  /// Calculates best streak historically for a date list.
  int calculateBestStreak(List<String> completedDates, int currentBest) {
    final currentStreak = calculateStreak(completedDates);
    return currentStreak > currentBest ? currentStreak : currentBest;
  }

  /// Merges multiple date lists across all habits & tasks to compute global active day streak.
  int calculateMaxGlobalStreak(List<List<String>> allDateLists) {
    final Set<String> mergedSet = {};
    for (var list in allDateLists) {
      mergedSet.addAll(list);
    }
    return calculateStreak(mergedSet.toList());
  }
}
