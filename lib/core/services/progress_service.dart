import '../domain/models/habit.dart';

class ProgressService {
  const ProgressService();

  /// Calculates goal progress percentage (0.0 to 100.0) based on strategy mode and habits completion status.
  double calculateGoalProgress({
    required String mode,
    required List<Habit> habits,
    required String todayDateStr,
  }) {
    if (habits.isEmpty) return 0.0;

    final completedCount = habits.where((h) => h.completedDates.contains(todayDateStr)).length;

    switch (mode.toUpperCase()) {
      case 'ANY':
        return completedCount > 0 ? 100.0 : 0.0;
      case 'CUSTOM':
      case 'ALL':
      default:
        return ((completedCount / habits.length) * 100.0).clamp(0.0, 100.0);
    }
  }
}
