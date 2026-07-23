import '../models/goal.dart';
import '../models/habit.dart';

abstract class GoalsRepository {
  /// Stream goals list locally.
  Stream<List<Goal>> watchGoals();

  /// Get cached goals.
  List<Goal> getGoals();

  /// Stream habits under a goal.
  Stream<List<Habit>> watchHabits(String goalId);

  /// Stream all habits across goals.
  Stream<List<Habit>> watchAllHabits();

  /// Get cached habits for a goal.
  List<Habit> getHabits(String goalId);

  /// Get all cached habits.
  List<Habit> getAllHabits();

  /// Create or update a goal.
  Future<void> upsertGoal(Goal goal);

  /// Delete a goal.
  Future<void> deleteGoal(String goalId);

  /// Create or update a habit.
  Future<void> upsertHabit(Habit habit);

  /// Toggle habit completion for a specific date (defaults to today YYYY-MM-DD).
  Future<void> toggleHabitCompletion(String habitId, String dateStr);

  /// Update habit transient progress (time spent or count).
  Future<void> updateHabitProgress(String habitId, {int? timeSpent, int? currentCount});

  /// Delete a habit.
  Future<void> deleteHabit(String goalId, String habitId);

  /// Force fetch from Firestore and refresh local cache.
  Future<void> fetchRemoteGoalsAndHabits();
}
