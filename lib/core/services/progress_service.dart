import '../domain/models/goal.dart';
import '../domain/models/habit.dart';

class ProgressService {
  const ProgressService();

  /// Returns true if today's habits satisfy the goal's completion strategy.
  /// Used to decide whether today should be added to goal.completedDates.
  bool isDailyGoalMet({
    required String mode,
    required int minHabits,
    required List<Habit> habits,
    required String todayDateStr,
  }) {
    if (habits.isEmpty) return false;

    final completedCount =
        habits.where((h) => h.completedDates.contains(todayDateStr)).length;

    switch (mode.toUpperCase()) {
      case 'ANY':
        return completedCount >= 1;
      case 'CUSTOM':
        return completedCount >= minHabits;
      case 'ALL':
      default:
        return completedCount >= habits.length;
    }
  }

  /// Calculates LONG-TERM mastery progress (0.0–100.0).
  ///
  /// Formula:
  ///   completedDates.length / totalGoalDays × 100
  ///
  /// where totalGoalDays = days between goal.createdAt and goal.deadline
  /// (falls back to days elapsed since creation if no deadline).
  double calculateGoalProgress({
    required Goal goal,
    required List<Habit> habits,
    required String todayDateStr,
  }) {
    // Step 1: Determine the updated set of completed dates for the goal.
    // If today's habits satisfy the strategy, today counts as a completed day.
    final List<String> updatedCompletedDates =
        List<String>.from(goal.completedDates);

    final metToday = isDailyGoalMet(
      mode: goal.mode,
      minHabits: goal.minHabits,
      habits: habits,
      todayDateStr: todayDateStr,
    );

    if (metToday && !updatedCompletedDates.contains(todayDateStr)) {
      updatedCompletedDates.add(todayDateStr);
    } else if (!metToday && updatedCompletedDates.contains(todayDateStr)) {
      updatedCompletedDates.remove(todayDateStr);
    }

    // Step 2: Determine total goal duration in days.
    final createdAtRaw = DateTime.tryParse(goal.createdAt);
    final deadlineRaw =
        goal.deadline != null ? DateTime.tryParse(goal.deadline!) : null;

    // Strip time component so a goal created at 14:00 on day X with deadline on
    // day Y still yields (Y - X + 1) full calendar days, not (Y - X) due to
    // sub-day remainder being truncated by .inDays.
    final createdAt = createdAtRaw != null
        ? DateTime(createdAtRaw.year, createdAtRaw.month, createdAtRaw.day)
        : null;
    final deadline = deadlineRaw != null
        ? DateTime(deadlineRaw.year, deadlineRaw.month, deadlineRaw.day)
        : null;
    final todayDateOnly = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    int totalDays;
    if (createdAt != null && deadline != null) {
      // Total days from creation to deadline (inclusive)
      totalDays = deadline.difference(createdAt).inDays + 1;
    } else if (createdAt != null) {
      // No deadline: use days elapsed since creation (at least 1)
      totalDays = todayDateOnly.difference(createdAt).inDays + 1;
    } else {
      totalDays = 1;
    }

    if (totalDays <= 0) totalDays = 1;

    // Step 3: Mastery = (days goal was fully completed) / totalDays × 100
    final completedDays = updatedCompletedDates.length.clamp(0, totalDays);
    return ((completedDays / totalDays) * 100.0).clamp(0.0, 100.0);
  }

  /// Returns the updated list of goal completedDates after toggling a habit.
  /// Call this alongside calculateGoalProgress to persist the correct dates.
  List<String> calculateUpdatedGoalCompletedDates({
    required Goal goal,
    required List<Habit> habits,
    required String todayDateStr,
  }) {
    final List<String> updated = List<String>.from(goal.completedDates);
    final metToday = isDailyGoalMet(
      mode: goal.mode,
      minHabits: goal.minHabits,
      habits: habits,
      todayDateStr: todayDateStr,
    );

    if (metToday && !updated.contains(todayDateStr)) {
      updated.add(todayDateStr);
    } else if (!metToday && updated.contains(todayDateStr)) {
      updated.remove(todayDateStr);
    }

    return updated;
  }
}
